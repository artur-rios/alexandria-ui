import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/file_hold.dart';
import '../domain/lifecycle_gateway.dart';

/// What the deletion is reporting, if anything (UC-33).
enum DeletionNotice {
  /// Nothing.
  none,

  /// The record was already deleted (AF-02).
  alreadyDeleted,

  /// The core has no such record (AF-03).
  notFound,

  /// The core refused for a reason of its own.
  refused,
}

/// What a screen shows after a deletion (UC-33).
class DeletionState {
  /// Creates a state.
  const DeletionState({this.notice = DeletionNotice.none, this.refusal});

  /// What the screen is reporting.
  final DeletionNotice notice;

  /// The core's own reason, when it gave one.
  final Failure? refusal;
}

/// Drives UC-33: hiding a file or a bookmark, restorably.
class DeletionController extends Notifier<DeletionState> {
  @override
  DeletionState build() => const DeletionState();

  /// Clears whatever the screen was reporting.
  void acknowledge() => state = const DeletionState();

  /// What currently has the file [uuid] identifies open (AF-04).
  ///
  /// The confirmation names these before it is shown, and lets them go on the
  /// way through [deleteFile].
  List<FileHold> holdsOn(String uuid) => [
    for (final hold in ref.read(fileHoldsProvider))
      if (hold.holds(uuid)) hold,
  ];

  /// Soft-deletes the file [uuid] identifies (main flow steps 4 to 6).
  ///
  /// The confirmation is the screen's: it has to state that the record is
  /// hidden, that it stays restorable, and that the file on disk is untouched
  /// before this is reached (FR-LC-01, BR-07).
  Future<void> deleteFile(String uuid) async {
    // AF-04: whatever has the file open lets it go first. Before the call and
    // not after it: a player reading a record the core is deleting underneath
    // it is the race this avoids.
    for (final hold in holdsOn(uuid)) {
      await hold.release();
    }

    await _delete(
      (gateway, credential) =>
          gateway.softDeleteFile(uuid: uuid, credential: credential),
      onDone: () {
        // FR-LC-09: every listing, count, and detail view reads the core
        // again, so the record leaves the default listings without a manual
        // refresh.
        ref.invalidate(listingControllerProvider);
        ref.invalidate(typeCountsControllerProvider);
        ref.invalidate(recentFilesProvider);
        ref.invalidate(catalogSearchProvider);
        ref.invalidate(fileDetailsControllerProvider);
      },
    );
  }

  /// Soft-deletes the bookmark [uuid] identifies (main flow steps 4 to 6).
  Future<void> deleteBookmark(String uuid) => _delete(
    (gateway, credential) =>
        gateway.softDeleteBookmark(uuid: uuid, credential: credential),
    onDone: () => ref.read(bookmarksControllerProvider.notifier).reload(),
  );

  /// Runs [call] and turns its answer into what the screen shows.
  Future<void> _delete(
    Future<LifecycleWrite> Function(LifecycleGateway, String credential) call, {
    required void Function() onDone,
  }) async {
    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (credential == null) return;

    final outcome = await call(ref.read(lifecycleGatewayProvider), credential);

    switch (outcome) {
      case LifecycleWriteDone():
        state = const DeletionState();
        onDone();

      // AF-05: the session is discarded, which returns the owner to login.
      case LifecycleWriteFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);

      // AF-02: the record was already deleted. The listing is read again,
      // which is what makes it agree with the core.
      case LifecycleWriteFailed(failure: final InvalidStateFailure failure):
        state = DeletionState(
          notice: DeletionNotice.alreadyDeleted,
          refusal: failure,
        );
        onDone();

      // AF-03: the core has no such record, and the listing is read again for
      // the same reason.
      case LifecycleWriteFailed(failure: final NotFoundFailure failure):
        state = DeletionState(
          notice: DeletionNotice.notFound,
          refusal: failure,
        );
        onDone();

      case LifecycleWriteFailed(:final failure):
        state = DeletionState(notice: DeletionNotice.refused, refusal: failure);
    }
  }
}
