import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../catalog/domain/file_type.dart';
import '../domain/folder_picker.dart';
import '../domain/folder_registration.dart';
import '../domain/library_source.dart';
import '../domain/library_source_store.dart';
import '../presentation/index_scope_dialog.dart';
import 'library_sources_state.dart';

/// Drives UC-05: registering a folder on disk as a source of files to index.
///
/// The order it works in is the specification's: pick, probe, check against
/// what is registered, then record. Nothing is written until every check has
/// answered, so a refused folder leaves the stored set exactly as it was.
class LibrarySourcesController extends Notifier<LibrarySourcesState> {
  static final Logger _log = Logger('library_sources');

  late FolderPicker _picker;
  late FolderProbe _probe;
  late LibrarySourceStore _store;
  late DateTime Function() _now;

  @override
  LibrarySourcesState build() {
    _picker = ref.read(folderPickerProvider);
    _probe = ref.read(folderProbeProvider);
    _store = ref.read(librarySourceStoreProvider);
    _now = ref.read(clockProvider);

    return LibrarySourcesState(sources: _store.read());
  }

  /// Opens the picker and registers what the owner chose (main flow steps
  /// 2–6).
  ///
  /// [onOverlapConfirmed] is asked only when the chosen folder overlaps one
  /// already registered (AF-04); answering `false` cancels and changes
  /// nothing. It is a callback rather than a second method because the
  /// question belongs in the middle of this flow — the folder has been picked
  /// and probed, and the owner is deciding whether to keep going. It takes
  /// both folders because the warning names both.
  ///
  /// Returns the [LibrarySource] that was recorded, or `null` on every path
  /// that changed nothing — the picker was cancelled, the verdict refused the
  /// folder, or the overlap confirmation was declined. A `void` return forced
  /// the caller to guess what had happened from state; the caller needs to
  /// know exactly what was registered so it can start indexing it (UC-06)
  /// without a second, separate click.
  ///
  /// [onScopeChosen] asks what the folder is for — which types an index of it
  /// records. It is asked last, after the folder has been accepted and after
  /// any overlap has been confirmed: asking earlier would ask about a folder
  /// that is then refused for not being there. An empty list is every type,
  /// held the same way the core holds it. `null` is the owner cancelling, and
  /// it abandons the registration entirely — a folder registered with a scope
  /// nobody chose is not what was asked for.
  /// [path] is the folder to register, for a caller that has already picked
  /// one. The Libraries screen has: it picks first because what it does next
  /// depends on whether the folder is registered already, and a second
  /// picker there would ask the owner to choose the same folder twice.
  Future<LibrarySource?> registerFolder({
    required Future<bool> Function(String path, LibrarySource existing)
    onOverlapConfirmed,
    required Future<FolderPurpose?> Function(String path) onScopeChosen,
    String? path,
  }) async {
    if (state.registering) return null;

    path ??= await _picker.pickFolder();
    // AF-01: the owner cancelled. Nothing is registered and nothing on the
    // screen changes — including any notice already there, which was about a
    // different attempt and is not answered by this one.
    if (path == null) return null;

    state = state.copyWith(
      registering: true,
      refusal: null,
      refusedPath: null,
      conflictingSource: null,
    );

    final exists = await _probe.exists(path);
    // Probed only when it is there: `isReadable` on a missing folder answers
    // false, and reporting "cannot be read" about a folder that is not there
    // sends the owner after the wrong problem (FR-LB-02).
    final readable = exists && await _probe.isReadable(path);

    final verdict = verdictFor(
      path: path,
      exists: exists,
      readable: readable,
      registered: state.sources,
    );

    if (refuses(verdict)) {
      _log.info('source folder refused (${verdict.name}): $path');
      state = state.copyWith(
        registering: false,
        refusal: verdict,
        refusedPath: path,
        conflictingSource: conflictingSource(path, state.sources),
      );
      return null;
    }

    if (verdict == FolderRegistrationVerdict.overlaps) {
      final existing = conflictingSource(path, state.sources)!;
      if (!await onOverlapConfirmed(path, existing)) {
        // AF-04, cancelled: nothing is registered, and no refusal is recorded
        // either — the owner was asked and said no, which is not an error.
        state = state.copyWith(registering: false);
        return null;
      }
    }

    final purpose = await onScopeChosen(path);
    // Cancelled: nothing is registered, and no refusal is recorded either —
    // the owner was asked and did not answer, which is not an error.
    if (purpose == null) {
      state = state.copyWith(registering: false);
      return null;
    }

    return _record(path, purpose.types, purpose.libraryName);
  }

  /// Records [path] and persists the set (main flow steps 5 and 6).
  Future<LibrarySource> _record(
    String path,
    List<FileType> scope,
    String? libraryName,
  ) async {
    // Every type chosen is the same thing as no scope at all, and is stored
    // as the absence: the core reads them identically, and keeping one
    // spelling means a folder that covers everything reads the same whether
    // the owner left the default alone or ticked all seven boxes.
    //
    // Held here even though the one caller that exists — IndexScopeDialog —
    // already collapses it. A guarantee that holds only because every caller
    // remembers to is not one, and this is what makes "a stored scope is
    // either absent or a real narrowing" true of the store rather than of one
    // widget. `index_scope_test` calls this with all seven and asserts what
    // lands in the store.
    final scoped = scope.length == FileType.values.length
        ? const <FileType>[]
        : scope;

    // The core is asked before the store is written: a row badged as a
    // library whose files are still in the type panels claims something that
    // is not true, and the core is the one that decides.
    //
    // A refusal here — the folder sitting inside a library the core already
    // has — registers the folder as an ordinary source rather than failing
    // the whole registration. The owner asked for two things and gets the one
    // that was available, which is better than losing both; the folder is
    // still indexable, and the row's mark action offers the other half again.
    final marked =
        libraryName != null && await _tellCoreAboutLibrary(path, libraryName);

    final source = LibrarySource(
      path: path,
      label: defaultLabelFor(path),
      registeredAt: _now(),
      scope: [for (final type in scoped) type.wireName],
      libraryName: marked ? libraryName : null,
    );
    final sources = [...state.sources, source];

    await _store.write(sources);
    _log.info('source folder registered: $path');

    state = state.copyWith(sources: sources, registering: false);

    return source;
  }

  /// Asks the core to treat [path] as a library called [name]; whether it did.
  ///
  /// Logged rather than surfaced on this path. The registration it is part of
  /// succeeded and the folder is usable; what did not happen is the grouping,
  /// and the row not being badged is the visible half of that.
  Future<bool> _tellCoreAboutLibrary(String path, String name) async {
    final failure = await ref
        .read(librariesControllerProvider.notifier)
        .register(name: name, rootPath: path);
    if (failure == null) return true;

    _log.warning('folder registered but not marked as a library: $failure');

    return false;
  }

  /// Marks an already-registered folder as a library called [name].
  ///
  /// The other way in. Registration asks at the moment the folder is picked,
  /// which is the right time for a folder the owner is adding now — but a
  /// course that has been indexed for a year was registered before this
  /// question existed, and re-registering it to answer would mean
  /// un-registering it first.
  ///
  /// Returns the refusal to show, or `null` when it worked. The store is
  /// written only after the core has agreed: a row badged as a library whose
  /// files are still in the type panels is worse than one that never claimed
  /// to be.
  Future<Failure?> markAsLibrary({
    required String path,
    required String name,
  }) async {
    final failure = await ref
        .read(librariesControllerProvider.notifier)
        .register(name: name, rootPath: path);
    if (failure != null) return failure;

    await _rewrite(path, (source) => source.copyWith(libraryName: name));
    _log.info('source folder marked as a library: $path');

    return null;
  }

  /// Forgets that [path] was a library, after the core has stopped treating
  /// it as one.
  ///
  /// Called by the screen that removes the library rather than removing it
  /// here, because a library can outlive its source folder — un-registering a
  /// source leaves the catalog alone (BR-12), and the files it grouped stay
  /// grouped. So the core's list is the authority on what a library is, and
  /// this only keeps the folder's row from claiming otherwise.
  Future<void> clearLibraryMark(String path) async {
    if (!state.sources.any((source) => source.path == path)) return;

    await _rewrite(path, (source) => source.copyWith(libraryName: null));
  }

  /// Follows a library's folder to where it moved.
  ///
  /// The registration is keyed by path, so a library that moved leaves the
  /// source folder pointing at somewhere that is no longer there — and the
  /// next scan of it would walk a missing folder. Called by the screen that
  /// moves the library, for the same reason [clearLibraryMark] is: the core
  /// owns what a library is, and this keeps the folder's own record from
  /// contradicting it.
  ///
  /// Does nothing when [from] is not registered — a library can outlive its
  /// source folder — or when [to] already is, which would collapse two
  /// registrations into one and silently drop the other's scope.
  Future<void> followLibraryMove({
    required String from,
    required String to,
  }) async {
    if (!state.sources.any((source) => source.path == from)) return;
    if (state.sources.any((source) => source.path == to)) {
      _log.warning('library moved to a folder already registered: $to');
      return;
    }

    await _rewrite(from, (source) => source.copyWith(path: to));
    _log.info('source folder followed its library: $from -> $to');
  }

  /// Replaces the source at [path] with [change] applied, and persists.
  Future<void> _rewrite(
    String path,
    LibrarySource Function(LibrarySource source) change,
  ) async {
    final sources = [
      for (final source in state.sources)
        if (source.path == path) change(source) else source,
    ];

    await _store.write(sources);
    state = state.copyWith(sources: sources);
  }

  /// Removes [path] from the registered sources (UC-08 main flow step 4,
  /// FR-LB-10).
  ///
  /// The catalog is not touched and neither is the disk: this un-registers a
  /// source, and the records the core made from it stay exactly as they are
  /// (BR-12). That is what the confirmation the screen shows first promises,
  /// and this method is the whole of what it promises.
  ///
  /// AF-02: a folder the core is still scanning is refused until the run
  /// settles. Removing it mid-run would leave a run reporting against a source
  /// the application no longer knows.
  Future<void> unregisterFolder(String path) async {
    if (ref.read(indexRunsControllerProvider).runFor(path)?.isInFlight ??
        false) {
      _log.info('unregister refused while a run is in flight: $path');
      state = state.copyWith(unregisterRefusedFor: path);
      return;
    }

    final sources = [
      for (final source in state.sources)
        if (source.path != path) source,
    ];

    await _store.write(sources);
    _log.info('source folder unregistered: $path');

    // AF-03 needs nothing of its own: removing the last folder empties the
    // list, and an empty list is already what puts the first-run guidance back
    // on screen (FR-LB-11).
    state = state.copyWith(
      sources: sources,
      unregisterRefusedFor: null,
      refusal: null,
      refusedPath: null,
      conflictingSource: null,
    );
  }

  /// Clears the AF-02 notice once the owner has read it.
  void acknowledgeUnregisterRefusal() =>
      state = state.copyWith(unregisterRefusedFor: null);

  /// Clears the notice once the owner has read it, so it does not outlive the
  /// attempt it was about.
  void acknowledgeRefusal() {
    if (state.refusal == null) return;

    state = state.copyWith(
      refusal: null,
      refusedPath: null,
      conflictingSource: null,
    );
  }
}
