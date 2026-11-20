import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/di/providers.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/failure.dart';
import '../../catalog/application/catalog_projections.dart';
import '../domain/library.dart';
import '../domain/library_gateway.dart';

/// What a write answers when there is no session to make it with.
///
/// Returned rather than `null`, because `null` is this file's word for "it
/// worked". A caller that could not tell the two apart would report a
/// library added, moved or removed that never was. No call was made, so the
/// code is the library family's own unauthorized rather than anything the
/// core said.
const Failure _noSession = Failure.unauthorized(
  family: CoreStatusFamily.library,
  code: LIBRARY_ERR_UNAUTHORIZED,
);

/// The registered libraries (libraries design).
class LibrariesController extends AsyncNotifier<List<Library>> {
  @override
  Future<List<Library>> build() async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07).
    if (credential == null) return const [];

    final browse = await ref
        .read(libraryGatewayProvider)
        .browse(credential: credential);

    switch (browse) {
      case LibraryBrowseLoaded(:final libraries):
        return libraries;

      // A rejected session returns the owner to login, as everywhere else.
      case LibraryBrowseFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        return const [];

      case LibraryBrowseFailed(:final failure):
        throw failure;
    }
  }

  /// Reads them again, which is how a write's effect reaches the screen.
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  /// Removes the library [uuid] (core 0.6.0).
  ///
  /// The core deletes its catalog records — its files with their reading and
  /// watching positions and collection membership, and its runs, a paused
  /// one included — and touches nothing on disk. Refused while a run of it is
  /// running. Everything that showed those records is read again afterwards,
  /// and the run this session followed for it is forgotten, so neither the
  /// panels nor the activity strip keep showing what the core no longer has.
  Future<Failure?> remove(String uuid) async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07) — and the caller is told so.
    if (credential == null) return _noSession;

    final outcome = await ref
        .read(libraryGatewayProvider)
        .remove(uuid: uuid, credential: credential);

    switch (outcome) {
      case LibraryWriteDone():
        ref.read(indexRunsControllerProvider.notifier).dismiss(uuid);
        invalidateCatalogProjections(ref);
        ref
          ..invalidate(collectionsControllerProvider)
          ..invalidate(collectionMembersControllerProvider)
          ..invalidate(watchlistsControllerProvider)
          ..invalidate(readingListsControllerProvider);
        await ref.read(activeRunsControllerProvider.notifier).refresh();
        await reload();
        return null;

      // The owner goes back to login, and the caller still learns the write
      // did not happen — its follow-up must not run either way.
      case LibraryWriteFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        return failure;

      case LibraryWriteFailed(:final failure):
        return failure;
    }
  }

  /// Points the library at [rootPath], the folder it moved to.
  ///
  /// Answers the refusal rather than throwing it, like [register]: the
  /// destination overlapping another library, or the catalog already holding
  /// files there, is a sentence to show beside the folder the owner just
  /// picked — not a failure state for the screen.
  Future<Failure?> move({
    required String uuid,
    required String rootPath,
  }) async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07) — and the caller is told so.
    if (credential == null) return _noSession;

    final outcome = await ref
        .read(libraryGatewayProvider)
        .move(uuid: uuid, rootPath: rootPath, credential: credential);

    switch (outcome) {
      case LibraryWriteDone():
        await reload();
        return null;

      // The owner goes back to login, and the caller still learns the write
      // did not happen — its follow-up must not run either way.
      case LibraryWriteFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        return failure;

      case LibraryWriteFailed(:final failure):
        return failure;
    }
  }

  /// Adds [rootPath] as a library called [name], and follows the index run
  /// the core starts for it.
  ///
  /// Answers the refusal rather than throwing it: registering is something
  /// the owner does from a form, and a conflict — the folder already sits
  /// inside another library — is a sentence that belongs beside the field
  /// rather than a failure state for the whole screen.
  Future<Failure?> register({
    required String name,
    required String rootPath,
  }) async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07) — and the caller is told so.
    if (credential == null) return _noSession;

    final outcome = await ref
        .read(libraryGatewayProvider)
        .register(name: name, rootPath: rootPath, credential: credential);

    switch (outcome) {
      case LibraryRegistered(:final library, :final runId):
        await reload();
        // The core started the library's first run with it; following it is
        // what puts its progress beside the new row and its outcome there
        // once it settles.
        await ref
            .read(indexRunsControllerProvider.notifier)
            .follow(library.uuid, runId);
        return null;

      // The owner goes back to login, and the caller still learns the write
      // did not happen — its follow-up must not run either way.
      case LibraryRegistrationFailed(
        failure: final UnauthorizedFailure failure,
      ):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        return failure;

      case LibraryRegistrationFailed(:final failure):
        return failure;
    }
  }
}

/// Which folder of which library is open.
typedef LibraryLocation = ({String uuid, String path});

/// One level of one library's tree.
class LibraryTreeController extends AsyncNotifier<LibraryListing?> {
  /// Creates the controller for [location].
  LibraryTreeController(this.location);

  /// The library and folder this instance reads.
  final LibraryLocation location;

  @override
  Future<LibraryListing?> build() async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return null;

    final outcome = await ref
        .read(libraryGatewayProvider)
        .read(uuid: location.uuid, path: location.path, credential: credential);

    switch (outcome) {
      case LibraryReadLoaded(:final listing):
        return listing;

      case LibraryReadFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        return null;

      // Including the library no longer being registered — the screen's
      // failure state is what says so, with a retry.
      case LibraryReadFailed(:final failure):
        throw failure;
    }
  }
}
