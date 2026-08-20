import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';

part 'retention.freezed.dart';

/// How long a soft-deleted record stays restorable, as the core reports it
/// (UC-34, FR-LC-03).
@freezed
sealed class RetentionWindow with _$RetentionWindow {
  /// The core answered with the window it enforces, in days.
  const factory RetentionWindow.loaded({required int days}) =
      RetentionWindowLoaded;

  /// The core could not be read.
  ///
  /// The view still lists what is deleted and still offers a restore — it
  /// simply cannot count down. Guessing a window here is what reading it was
  /// meant to remove.
  const factory RetentionWindow.failed({required Failure failure}) =
      RetentionWindowFailed;
}

/// The core's settings read (UC-34, FR-LC-03).
abstract interface class RetentionGateway {
  /// The retention window this core enforces.
  Future<RetentionWindow> window({required String credential});
}

/// Where a deleted record stands in its retention window (FR-LC-03).
class Retention {
  /// Creates a standing.
  const Retention({required this.remaining});

  /// What [deletedAt] leaves, as of [now], against a window of [days].
  ///
  /// A record the core answered without a timestamp has an unknown standing,
  /// and so does one whose window could not be read. Neither is the same as an
  /// elapsed one: both are still offered for restore, and the core is what
  /// refuses if the window has in fact passed.
  factory Retention.since(
    DateTime? deletedAt, {
    required DateTime now,
    required int? days,
  }) => Retention(
    remaining: deletedAt == null || days == null
        ? null
        : Duration(days: days) - now.difference(deletedAt),
  );

  /// How long is left, or `null` when it cannot be told.
  final Duration? remaining;

  /// Whether the window has run out (UC-34 AF-02).
  ///
  /// The core's own boundary: elapsed time up to and including the window
  /// leaves a record restorable, and strictly past it the record is purgeable.
  /// A remaining duration of exactly zero is therefore still restorable.
  bool get hasElapsed => remaining != null && remaining! < Duration.zero;

  /// Whether the countdown can be shown at all.
  bool get isKnown => remaining != null;

  /// Whole days left, rounded up, so a record with an hour to go reads as one
  /// day rather than as none.
  int get daysRemaining {
    final left = remaining;
    if (left == null || left <= Duration.zero) return 0;

    return (left.inMinutes / Duration.minutesPerDay).ceil();
  }
}
