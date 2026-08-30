import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/library.dart';
import '../domain/library_gateway.dart';

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

  /// Stops treating a folder as a library.
  ///
  /// The files return to the type panels; nothing on disk is touched. Both
  /// listings are invalidated afterwards, because the files that come back
  /// are exactly the ones the type panels were not showing.
  Future<Failure?> remove(String uuid) async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return null;

    final outcome = await ref
        .read(libraryGatewayProvider)
        .remove(uuid: uuid, credential: credential);

    switch (outcome) {
      case LibraryWriteDone():
        await reload();
        return null;

      case LibraryWriteFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        return null;

      case LibraryWriteFailed(:final failure):
        return failure;
    }
  }

  /// Treats [rootPath] as a library called [name].
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
    if (credential == null) return null;

    final outcome = await ref
        .read(libraryGatewayProvider)
        .register(name: name, rootPath: rootPath, credential: credential);

    switch (outcome) {
      case LibraryWriteDone():
        await reload();
        return null;

      case LibraryWriteFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        return null;

      case LibraryWriteFailed(:final failure):
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
        .read(
          uuid: location.uuid,
          path: location.path,
          credential: credential,
        );

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
