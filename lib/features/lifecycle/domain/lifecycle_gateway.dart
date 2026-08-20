import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';

part 'lifecycle_gateway.freezed.dart';

/// What a lifecycle change produced (UC-33 main flow steps 4 and 5).
///
/// The record the core echoes is not carried: every screen that shows a
/// deleted record reads the core again afterwards (FR-LC-09), so the echo has
/// nothing left to tell them.
@freezed
sealed class LifecycleWrite with _$LifecycleWrite {
  /// The core applied it.
  const factory LifecycleWrite.done() = LifecycleWriteDone;

  /// The core refused (AF-02, AF-03, AF-05).
  const factory LifecycleWrite.failed({required Failure failure}) =
      LifecycleWriteFailed;
}

/// What a purge on disk produced (UC-36 main flow step 5).
@freezed
sealed class PurgeOnDiskOutcome with _$PurgeOnDiskOutcome {
  /// The core removed the record, and [diskFilePresent] says whether there was
  /// a file on disk to remove with it (AF-02).
  const factory PurgeOnDiskOutcome.purged({required bool diskFilePresent}) =
      PurgeOnDiskPurged;

  /// The core refused, or the disk did (AF-03, AF-04, AF-06).
  const factory PurgeOnDiskOutcome.failed({required Failure failure}) =
      PurgeOnDiskFailed;
}

/// The core's deletion-lifecycle operations (FR-LC-01, UC-33).
abstract interface class LifecycleGateway {
  /// Soft-deletes the file [uuid] identifies (FR-LC-01).
  ///
  /// The record is hidden and stays restorable; the file on disk is untouched,
  /// which is what the confirmation is able to promise.
  Future<LifecycleWrite> softDeleteFile({
    required String uuid,
    required String credential,
  });

  /// Soft-deletes the bookmark [uuid] identifies (FR-LC-01).
  Future<LifecycleWrite> softDeleteBookmark({
    required String uuid,
    required String credential,
  });

  /// Restores the file [uuid] identifies (FR-LC-04, UC-34).
  ///
  /// The core enforces the retention window; a record past it comes back as
  /// not found, which is what AF-02 and AF-03 both read.
  Future<LifecycleWrite> restoreFile({
    required String uuid,
    required String credential,
  });

  /// Restores the bookmark [uuid] identifies (FR-LC-04, UC-34).
  Future<LifecycleWrite> restoreBookmark({
    required String uuid,
    required String credential,
  });

  /// Purges the file [uuid] identifies from the catalog (FR-LC-05, UC-35).
  ///
  /// The record only. The file on disk is untouched, which is what the
  /// confirmation promises.
  Future<LifecycleWrite> purgeFile({
    required String uuid,
    required String credential,
  });

  /// Purges the bookmark [uuid] identifies (FR-LC-05, UC-35).
  Future<LifecycleWrite> purgeBookmark({
    required String uuid,
    required String credential,
  });

  /// Purges the file [uuid] identifies from disk and from the catalog
  /// (FR-LC-06, UC-36).
  ///
  /// The one operation in this application that removes the owner's data from
  /// disk. Answers whether there was a file to remove (AF-02).
  Future<PurgeOnDiskOutcome> purgeFileOnDisk({
    required String uuid,
    required String credential,
  });
}
