import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../features/library_sources/data/settings_library_source_store.dart';
import '../../features/library_sources/domain/audio_scope_cleanup.dart';
import '../../features/library_sources/domain/library_source.dart';
import '../bindings/core_client.dart';
import '../bindings/core_isolate.dart';
import '../di/providers.dart';
import '../failures/core_status.dart';
import '../failures/failure.dart';
import '../settings/settings_store.dart';
import 'core_paths.dart';
import 'core_version.dart';
import 'startup_state.dart';

/// Runs the startup sequence in Operations & Infrastructure Document §5.1
/// (IR-04, IR-05, IR-06).
///
/// The sequence is a straight line with one property that matters: every step
/// reports its own failure, and [retry] re-runs from step 1. Recovering from
/// step 3 alone would leave a half-initialized core behind, which is exactly the
/// state that produces a confusing second failure.
class StartupController extends Notifier<StartupState> {
  static final Logger _log = Logger('startup');

  // Read from the composition root in build() rather than taken as constructor
  // arguments: a NotifierProvider builds its notifier without a ref, and reading
  // here is what lets a test override corePathsProvider, coreLoaderProvider, and
  // settingsLoaderProvider wholesale (IR-07, IR-14).
  late CorePaths _paths;
  late Future<CoreClient> Function(String libraryPath) _loadCore;
  late Future<SettingsStore> Function() _loadSettings;

  CoreClient? _core;
  SettingsStore? _settings;
  List<LibrarySource> _audioLibrariesToRemove = const [];

  /// The loaded core, once startup has reached [StartupReady].
  CoreClient? get core => _core;

  /// The loaded settings store, once startup has passed step 3.
  ///
  /// Non-null even when the load failed: the fallback store is still bound, so
  /// the shell has somewhere to write the owner's next choice.
  SettingsStore? get settings => _settings;

  @override
  StartupState build() {
    _paths = ref.read(corePathsProvider);
    _loadCore = ref.read(coreLoaderProvider);
    _loadSettings = ref.read(settingsLoaderProvider);

    ref.onDispose(() => unawaited(_disposeCore()));
    return const StartupState.idle();
  }

  /// Runs the sequence from step 1.
  Future<void> start() async {
    await _disposeCore();

    final libraryPath = await _step1LoadLibrary();
    if (libraryPath == null) return;

    final databasePath = await _step2ResolvePaths();
    if (databasePath == null) return;

    // Before the core is initialized, not after: the core reads its own
    // settings exactly once, at `alexandria_index_init`, and whether it may
    // look music up is one of them (§5.1 step 3). Loading the owner's
    // preferences afterwards would mean the choice they made last session
    // could only take effect the session after this one.
    final warning = await _step3LoadPreferences();

    // Verified before it is initialized, not after: initializing is what
    // creates and migrates the catalog. A core outside the supported range
    // that is initialized first has already rewritten the owner's database by
    // the time it is refused — a newer one migrates it past what the
    // supported core can open again, and an older one fails on a schema it
    // does not know and reports that, hiding the version message this check
    // exists to give. The version and health are both answerable before
    // initialization.
    final version = await _step4Verify();
    if (version == null) return;

    if (!await _step5Initialize(databasePath)) return;

    await _cleanUpAudioScopes();

    _log.info('startup settled; core $version, database ready');
    state = StartupState.ready(
      coreVersion: version,
      databasePath: databasePath,
      warning: warning,
    );
  }

  /// Re-runs the sequence from step 1 (§5.2).
  Future<void> retry() => start();

  /// The library folders this launch unregistered for tracking nothing but
  /// audio, handed over once and then forgotten.
  ///
  /// Their library in the core still has to be removed, and that takes a
  /// credential, which startup runs before there is one. The session that
  /// follows removes them (`AudioLibraryCleanupActivity`); this only
  /// remembers which they were until it asks.
  List<LibrarySource> takeAudioLibrariesToRemove() {
    final taken = _audioLibrariesToRemove;
    _audioLibrariesToRemove = const [];
    return taken;
  }

  /// Takes audio out of the stored tracked folders, now that it is not a type
  /// (remove-music design, "Stored index scopes").
  ///
  /// Here because it is the first point that has the owner's settings and an
  /// initialized core, and it must run before anything reads the folders.
  /// It runs on every launch and needs no flag: once the stored folders name
  /// no audio it finds nothing to change, and writes nothing.
  ///
  /// A folder that tracked only audio is unregistered the way the owner's own
  /// Remove does it (`LibrarySourcesController.unregisterFolder`): it leaves
  /// the stored list, and nothing in the catalog or on disk is touched. That
  /// controller cannot be used from here — it is built over providers that
  /// only answer once startup is ready — so the same store write is made
  /// directly. One that was also a library is remembered for
  /// [takeAudioLibrariesToRemove].
  ///
  /// Never fails the launch. Settings that cannot be written leave the
  /// folders as they were, and the next launch tries again.
  Future<void> _cleanUpAudioScopes() async {
    final settings = _settings;
    if (settings == null) return;

    try {
      final store = SettingsLibrarySourceStore(settings);
      final sources = store.read();
      final (:kept, :removed) = cleanUpAudioScopes(sources);

      // The cleanup passes an untouched folder through as the same record,
      // so identity is what says nothing changed.
      var changed = removed.isNotEmpty;
      for (var i = 0; !changed && i < kept.length; i++) {
        changed = !identical(kept[i], sources[i]);
      }
      if (!changed) return;

      await store.write(kept);

      for (final source in removed) {
        _log.info('music-only folder unregistered on upgrade: ${source.path}');
      }
      _audioLibrariesToRemove = [
        ..._audioLibrariesToRemove,
        for (final source in removed)
          if (source.isLibrary) source,
      ];
    } on Object catch (error, stackTrace) {
      _log.warning(
        'audio could not be removed from the tracked folders',
        error,
        stackTrace,
      );
    }
  }

  Future<String?> _step1LoadLibrary() async {
    state = const StartupState.running(step: StartupStep.loadingCore);

    final resolved = _paths.resolveLibraryPath();
    if (resolved == null) {
      return _fail(
        StartupStep.loadingCore,
        Failure.coreLibraryNotLoaded(
          path: _paths.librarySearchPaths.join(', '),
        ),
      );
    }

    try {
      _core = await _loadCore(resolved);
      return resolved;
    } on CoreCallException catch (error) {
      return _fail(
        StartupStep.loadingCore,
        Failure.coreLibraryNotLoaded(path: resolved),
        error: error,
      );
    }
  }

  Future<String?> _step2ResolvePaths() async {
    state = const StartupState.running(step: StartupStep.resolvingPaths);

    try {
      return await _paths.resolveDatabasePath();
    } on Object catch (error) {
      // Broad by intent: path_provider surfaces a MissingPlatformDirectoryException,
      // dart:io a FileSystemException, and the owner needs the folder either way.
      return _fail(
        StartupStep.resolvingPaths,
        const Failure.applicationDirectoryUnavailable(
          path: CorePaths.applicationFolderName,
        ),
        error: error,
      );
    }
  }

  Future<bool> _step5Initialize(String databasePath) async {
    state = const StartupState.running(step: StartupStep.initializingCore);

    try {
      final status = await _core!.initialize(databasePath);
      if (CoreStatusFamily.indexing.isOk(status)) return true;

      _fail(
        StartupStep.initializingCore,
        Failure.coreInitializationFailed(code: status),
      );
      return false;
    } on CoreCallException catch (error) {
      _fail(
        StartupStep.initializingCore,
        const Failure.coreInitializationFailed(code: -1),
        error: error,
      );
      return false;
    }
  }

  Future<String?> _step4Verify() async {
    state = const StartupState.running(step: StartupStep.verifyingCore);

    try {
      final health = await _core!.healthStatus();
      if (health != coreHealthyStatusCode) {
        return _fail(
          StartupStep.verifyingCore,
          Failure.coreUnhealthy(code: health),
        );
      }

      final version = await _core!.version();
      if (!CoreVersionRange.supports(version)) {
        return _fail(
          StartupStep.verifyingCore,
          Failure.coreVersionUnsupported(
            found: version ?? 'unknown',
            required: CoreVersionRange.description,
          ),
        );
      }

      return version;
    } on CoreCallException catch (error) {
      return _fail(
        StartupStep.verifyingCore,
        const Failure.coreUnhealthy(code: -1),
        error: error,
      );
    }
  }

  /// Step 3 never fails the launch: unreadable preferences fall back to the
  /// system theme and language — and, for the core's own configuration, to
  /// the same defaults the store answers with — and are reported (§5.1).
  Future<Failure?> _step3LoadPreferences() async {
    state = const StartupState.running(step: StartupStep.loadingPreferences);

    try {
      _settings = await _loadSettings();
      return null;
    } on Object catch (error) {
      _log.warning(
        'preferences could not be read; using system defaults',
        error,
      );
      return const Failure.preferencesUnreadable();
    }
  }

  Null _fail(StartupStep step, Failure failure, {Object? error}) {
    // Every failure the owner sees is logged once, with the core's status code,
    // so a report can be traced without the owner reading a code on screen
    // (Operations & Infrastructure Document §4).
    _log.severe(
      'startup failed at ${step.name} (status ${failure.coreStatusCode})',
      error,
    );
    state = StartupState.failed(step: step, failure: failure);
    return null;
  }

  Future<void> _disposeCore() async {
    final core = _core;
    _core = null;
    await core?.dispose();
  }
}
