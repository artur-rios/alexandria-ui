import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../catalog/application/catalog_projections.dart';
import '../domain/library.dart';
import '../domain/library_gateway.dart';

/// The registered libraries (libraries design).
class LibrariesController extends AsyncNotifier<List<Library>> {
  @override
  Future<List<Library>> build() async {
    final browse = await ref.read(libraryGatewayProvider).browse();

    switch (browse) {
      case LibraryBrowseLoaded(:final libraries):
        return libraries;

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
    final outcome = await ref.read(libraryGatewayProvider).remove(uuid: uuid);

    switch (outcome) {
      case LibraryWriteDone():
        ref.read(indexRunsControllerProvider.notifier).dismiss(uuid);
        // Its tracks' records are gone with it, so none of them can play.
        await ref
            .read(audioPlaybackControllerProvider.notifier)
            .dropLibrary(uuid);
        invalidateCatalogProjections(ref);
        ref
          ..invalidate(collectionsControllerProvider)
          ..invalidate(collectionMembersControllerProvider)
          ..invalidate(watchlistsControllerProvider)
          ..invalidate(readingListsControllerProvider);
        await ref.read(activeRunsControllerProvider.notifier).refresh();
        await reload();
        return null;

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
    final outcome = await ref
        .read(libraryGatewayProvider)
        .move(uuid: uuid, rootPath: rootPath);

    switch (outcome) {
      case LibraryWriteDone():
        await reload();
        return null;

      case LibraryWriteFailed(:final failure):
        return failure;
    }
  }

  /// Pins the library [uuid] to the top of the left menu, or unpins it.
  ///
  /// Answers the refusal and leaves the list as it was: the list changes
  /// only when the core says it did.
  Future<Failure?> setPinned(String uuid, bool pinned) => _change(
    () =>
        ref.read(libraryGatewayProvider).setPinned(uuid: uuid, pinned: pinned),
  );

  /// Marks the library [uuid] a favorite, or clears it.
  Future<Failure?> setFavorite(String uuid, bool favorite) => _change(
    () => ref
        .read(libraryGatewayProvider)
        .setFavorite(uuid: uuid, favorite: favorite),
  );

  /// Calls the library [uuid] [name] from now on.
  ///
  /// Answers the refusal rather than throwing it, so the dialog asking for
  /// the name can say why and stay open.
  Future<Failure?> rename(String uuid, String name) => _change(
    () => ref.read(libraryGatewayProvider).rename(uuid: uuid, name: name),
  );

  Future<Failure?> _change(Future<LibraryWrite> Function() write) async {
    switch (await write()) {
      case LibraryWriteDone():
        await reload();
        return null;

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
    final outcome = await ref
        .read(libraryGatewayProvider)
        .register(name: name, rootPath: rootPath);

    switch (outcome) {
      case LibraryRegistered(:final library, :final runId):
        await reload();
        ref.invalidate(catalogStatsProvider);
        // The core started the library's first run with it; following it is
        // what puts its progress beside the new row and its outcome there
        // once it settles.
        await ref
            .read(indexRunsControllerProvider.notifier)
            .follow(library.uuid, runId);
        return null;

      case LibraryRegistrationFailed(:final failure):
        return failure;
    }
  }
}

/// Which folder of which library is open.
typedef LibraryLocation = ({String uuid, String path});

/// One level of one library's tree.
class LibraryTreeController extends AsyncNotifier<LibraryListing> {
  /// Creates the controller for [location].
  LibraryTreeController(this.location);

  /// The library and folder this instance reads.
  final LibraryLocation location;

  @override
  Future<LibraryListing> build() async {
    final outcome = await ref
        .read(libraryGatewayProvider)
        .read(uuid: location.uuid, path: location.path);

    switch (outcome) {
      case LibraryReadLoaded(:final listing):
        return listing;

      // Including the library no longer being registered — the screen's
      // failure state is what says so, with a retry.
      case LibraryReadFailed(:final failure):
        throw failure;
    }
  }
}
