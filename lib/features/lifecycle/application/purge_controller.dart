import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../catalog/application/catalog_projections.dart';
import '../domain/deleted_record.dart';
import '../domain/lifecycle_gateway.dart';

/// What a purge is reporting, if anything (UC-35, UC-36).
enum PurgeNotice {
  /// Nothing.
  none,

  /// The record is not deleted, so it cannot be purged yet (UC-35 AF-03).
  notDeleted,

  /// The retention window has not elapsed (UC-35 AF-02).
  tooSoon,

  /// The core has no such record (UC-35 AF-04, UC-36 AF-04).
  notFound,

  /// The record went, and there was no file on disk to go with it
  /// (UC-36 AF-02).
  nothingOnDisk,

  /// The disk refused (UC-36 AF-03).
  diskFailed,

  /// The core refused for a reason of its own.
  refused,
}

/// What a screen shows after a purge (UC-35, UC-36).
class PurgeState {
  /// Creates a state.
  const PurgeState({
    this.notice = PurgeNotice.none,
    this.refusal,
    this.daysRemaining,
  });

  /// What the screen is reporting.
  final PurgeNotice notice;

  /// The core's own reason, when it gave one.
  final Failure? refusal;

  /// How much of the retention window is left, for [PurgeNotice.tooSoon].
  ///
  /// FR-LC-07 asks for an explanation of when purging becomes possible rather
  /// than a status code, and this is what that sentence counts.
  final int? daysRemaining;
}

/// Drives UC-35 and UC-36: removing a record for good, and — separately —
/// removing the file on disk with it.
class PurgeController extends Notifier<PurgeState> {
  @override
  PurgeState build() => const PurgeState();

  /// Clears whatever the screen was reporting.
  void acknowledge() => state = const PurgeState();

  /// Purges [record] from the catalog (UC-35 main flow steps 4 to 6).
  ///
  /// The confirmation is the screen's: it has to state that the record goes
  /// permanently and that the file on disk does not (FR-LC-05, BR-07).
  Future<void> purge(DeletedRecord record) async {
    // AF-03: a record that is not deleted is deleted first, and the core is
    // not called. The core would refuse it too — this answers immediately and
    // says what to do instead.
    if (!record.isDeleted) {
      state = const PurgeState(notice: PurgeNotice.notDeleted);
      return;
    }

    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (credential == null) return;

    final gateway = ref.read(lifecycleGatewayProvider);
    final outcome = switch (record.kind) {
      DeletedRecordKind.file => await gateway.purgeFile(
        uuid: record.uuid,
        credential: credential,
      ),
      DeletedRecordKind.bookmark => await gateway.purgeBookmark(
        uuid: record.uuid,
        credential: credential,
      ),
    };

    switch (outcome) {
      case LifecycleWriteDone():
        state = const PurgeState();
        await _refresh(record.uuid);

      // AF-05: the session is discarded, which returns the owner to login.
      case LifecycleWriteFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);

      // AF-02: the core refuses a record still inside its retention window,
      // and this says when that changes rather than showing its status code
      // (FR-LC-07).
      case LifecycleWriteFailed(failure: final InvalidStateFailure failure):
        state = PurgeState(
          notice: PurgeNotice.tooSoon,
          refusal: failure,
          daysRemaining: record
              .retentionAt(
                ref.read(clockProvider)(),
                days: ref.read(retentionWindowProvider).value,
              )
              .daysRemaining,
        );

      // AF-04: the core has no such record, so the view is read again.
      case LifecycleWriteFailed(failure: final NotFoundFailure failure):
        state = PurgeState(notice: PurgeNotice.notFound, refusal: failure);
        await _refresh(record.uuid);

      case LifecycleWriteFailed(:final failure):
        state = PurgeState(notice: PurgeNotice.refused, refusal: failure);
    }
  }

  /// Purges the file [uuid] identifies from disk as well (UC-36 steps 4 to 6).
  ///
  /// The confirmation is the screen's, and FR-LC-06 is specific about it: it
  /// names the exact path and says the deletion cannot be undone. AF-05 —
  /// whatever has the file open — is let go of here, before the call.
  Future<void> purgeOnDisk(String uuid) async {
    // The session first, then the holds. Releasing them first shut whatever
    // had the file open — a viewer, the player — for a purge that then never
    // happened, so the owner lost what they were reading and nothing was
    // deleted.
    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (credential == null) return;

    for (final hold
        in ref.read(deletionControllerProvider.notifier).holdsOn(uuid)) {
      await hold.release();
    }

    final outcome = await ref
        .read(lifecycleGatewayProvider)
        .purgeFileOnDisk(uuid: uuid, credential: credential);

    switch (outcome) {
      case PurgeOnDiskPurged(:final diskFilePresent):
        // AF-02: the record went, and there was nothing on disk to go with
        // it. Said plainly rather than reported as a failure — the core
        // succeeded.
        state = PurgeState(
          notice: diskFilePresent
              ? PurgeNotice.none
              : PurgeNotice.nothingOnDisk,
        );
        await _refresh(uuid);

      // AF-06: the session is discarded, which returns the owner to login.
      case PurgeOnDiskFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);

      // AF-03: neither the file nor the record was removed, so nothing is
      // refreshed — what is on screen is still what the core holds.
      case PurgeOnDiskFailed(failure: final DiskFailure failure):
        state = PurgeState(notice: PurgeNotice.diskFailed, refusal: failure);

      // AF-04: the core has no such record.
      case PurgeOnDiskFailed(failure: final NotFoundFailure failure):
        state = PurgeState(notice: PurgeNotice.notFound, refusal: failure);
        await _refresh(uuid);

      case PurgeOnDiskFailed(:final failure):
        state = PurgeState(notice: PurgeNotice.refused, refusal: failure);
    }
  }

  /// Step 6: every listing and count reads the core again (FR-LC-09), and the
  /// resume position the application held for the record goes with it — it
  /// points at something that no longer exists.
  Future<void> _refresh(String uuid) async {
    await ref.read(playbackPositionsProvider).forget(uuid);

    invalidateCatalogProjections(ref);
    // A purge can take a bookmark record as well as a file, so this one is
    // added to the shared set rather than folded into it.
    ref.invalidate(bookmarksControllerProvider);

    await ref.read(deletedItemsControllerProvider.notifier).reload();
  }
}
