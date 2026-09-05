import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../bindings/core_client.dart';
import '../bindings/core_environment.dart';
import '../bindings/core_isolate.dart';
import '../di/providers.dart';
import '../failures/core_status.dart';
import '../failures/failure.dart';
import '../settings/settings_store.dart';
import 'core_paths.dart';
import 'core_version.dart';
import 'startup_state.dart';

/// What became of a music-lookup change handed to the core.
enum MusicLookupApplication {
  /// The core is running with it now.
  applied,

  /// Nothing was asked of the core: there is none yet, or the configuration
  /// was already the one it is running with.
  unchanged,

  /// The core is scanning and will not be reconfigured until it stops. The
  /// preference is saved; it takes effect when the scan settles, and the next
  /// call is what applies it.
  deferred,

  /// The core refused, or could not be reached. It keeps the configuration it
  /// started with.
  failed,
}

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

  /// The database the core was last initialized against, kept so
  /// [applyMusicLookup] can initialize it again against the same one.
  String? _databasePath;

  /// What the core was last initialized with, so a preference change that
  /// does not actually change the core's configuration costs nothing.
  MusicLookup? _appliedMusicLookup;

  /// The loaded core, once startup has reached [StartupReady].
  CoreClient? get core => _core;

  /// The loaded settings store, once startup has passed step 3.
  ///
  /// Non-null even when the load failed: the fallback store is still bound, so
  /// the shell has somewhere to write the owner's next choice.
  SettingsStore? get settings => _settings;

  /// The music-enrichment configuration the core should be running with —
  /// the owner's stored choice, or the shipped default when the settings
  /// store could not be read (music enrichment design).
  MusicLookup get musicLookup {
    final settings = _settings;

    return settings == null
        ? const MusicLookup(
            enabled: true,
            contact: defaultMusicLookupContact,
          )
        : MusicLookup(
            enabled: settings.musicLookupEnabled,
            contact: settings.musicLookupContact,
          );
  }

  /// Re-initializes the core so a music-lookup preference changed after
  /// startup takes effect now rather than at the next launch.
  ///
  /// The core reads that setting once, at `alexandria_index_init`, so there
  /// is no other way to apply it — and leaving it until the next launch is
  /// exactly the dead end this exists to remove: an owner who switches the
  /// lookup on, asks for lyrics, and is told the feature is switched off for
  /// this installation. `alexandria_index_init` is safe to call again while
  /// the core is idle, sessions live in the database rather than in the
  /// process, and a refused re-initialization leaves the core's existing
  /// services exactly where they were.
  ///
  /// Does nothing when the configuration has not actually changed, which is
  /// every call but the one that follows a change.
  ///
  /// Answers whether the core took it. `MusicLookupApplication.deferred` is
  /// the one worth acting on: the core will not replace its services while it
  /// is walking a disk, because a run already executing would be left behind
  /// by the replacement — unpausable, uncancellable, and with its row
  /// rewritten under it. The preference is saved either way, so this is a
  /// "not yet" rather than a failure, and the owner is owed that sentence
  /// rather than a switch that appears to do nothing.
  Future<MusicLookupApplication> applyMusicLookup() async {
    final core = _core;
    final databasePath = _databasePath;
    if (core == null || databasePath == null) {
      return MusicLookupApplication.unchanged;
    }

    final lookup = musicLookup;
    if (lookup == _appliedMusicLookup) return MusicLookupApplication.unchanged;

    try {
      final status = await core.initialize(databasePath, musicLookup: lookup);
      if (coreIsBusy(status)) {
        // Deliberately *not* recorded as applied: leaving `_appliedMusicLookup`
        // where it is means the next call tries again, which is what makes
        // [PreferencesController] retrying once the scan settles work at all.
        _log.info(
          'the core is scanning, so the music-lookup change waits for it',
        );
        return MusicLookupApplication.deferred;
      }
      if (!CoreStatusFamily.indexing.isOk(status)) {
        _log.warning(
          'the core refused to be reconfigured for music lookup '
          '(status $status); it keeps the configuration it started with',
        );
        return MusicLookupApplication.failed;
      }
      _appliedMusicLookup = lookup;
      return MusicLookupApplication.applied;
    } on CoreCallException catch (error) {
      // Logged, not raised: the owner changed a preference, the preference
      // is saved, and the core carries on with what it already had. What
      // they must not get is a broken application because a switch moved.
      _log.warning(
        'the core could not be reconfigured for music lookup',
        error,
      );
      return MusicLookupApplication.failed;
    }
  }

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

    if (!await _step4Initialize(databasePath)) return;

    final version = await _step5Verify();
    if (version == null) return;

    _databasePath = databasePath;

    _log.info('startup settled; core $version, database ready');
    state = StartupState.ready(
      coreVersion: version,
      databasePath: databasePath,
      warning: warning,
    );
  }

  /// Re-runs the sequence from step 1 (§5.2).
  Future<void> retry() => start();

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

  Future<bool> _step4Initialize(String databasePath) async {
    state = const StartupState.running(step: StartupStep.initializingCore);

    try {
      final lookup = musicLookup;
      final status = await _core!.initialize(
        databasePath,
        musicLookup: lookup,
      );
      _appliedMusicLookup = lookup;
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

  Future<String?> _step5Verify() async {
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
    _databasePath = null;
    _appliedMusicLookup = null;
    await core?.dispose();
  }
}
