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
}
