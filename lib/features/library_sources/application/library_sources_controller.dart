import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/di/providers.dart';
import '../../catalog/domain/library_type.dart';
import '../domain/folder_picker.dart';
import '../domain/folder_registration.dart';
import '../domain/library_source.dart';
import '../domain/library_source_store.dart';
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
  Future<LibrarySource?> registerFolder({
    required Future<bool> Function(String path, LibrarySource existing)
    onOverlapConfirmed,
    required Future<List<LibraryType>?> Function(String path) onScopeChosen,
  }) async {
    if (state.registering) return null;

    final path = await _picker.pickFolder();
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
      _log.info('library folder refused (${verdict.name}): $path');
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

    final scope = await onScopeChosen(path);
    // Cancelled: nothing is registered, and no refusal is recorded either —
    // the owner was asked and did not answer, which is not an error.
    if (scope == null) {
      state = state.copyWith(registering: false);
      return null;
    }

    return _record(path, scope);
  }

  /// Records [path] and persists the set (main flow steps 5 and 6).
  Future<LibrarySource> _record(String path, List<LibraryType> scope) async {
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
    final scoped = scope.length == LibraryType.values.length
        ? const <LibraryType>[]
        : scope;

    final source = LibrarySource(
      path: path,
      label: defaultLabelFor(path),
      registeredAt: _now(),
      scope: [for (final type in scoped) type.wireName],
    );
    final sources = [...state.sources, source];

    await _store.write(sources);
    _log.info('library folder registered: $path');

    state = state.copyWith(sources: sources, registering: false);

    return source;
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
    _log.info('library folder unregistered: $path');

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
