import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import 'reading_list.dart';

part 'reading_list_gateway.freezed.dart';

/// What browsing the reading lists produced (UC-31, UC-32 step 2).
@freezed
sealed class ReadingListBrowse with _$ReadingListBrowse {
  /// The core answered, possibly with nothing.
  const factory ReadingListBrowse.loaded({
    required List<ReadingList> readingLists,
  }) = ReadingListBrowseLoaded;

  /// The core could not answer.
  const factory ReadingListBrowse.failed({required Failure failure}) =
      ReadingListBrowseFailed;
}

/// What a reading-list write produced (UC-31 steps 2, 4, 5 and 6).
@freezed
sealed class ReadingListWrite with _$ReadingListWrite {
  /// The core did it.
  const factory ReadingListWrite.done() = ReadingListWriteDone;

  /// The core refused (AF-03, AF-04, AF-06).
  const factory ReadingListWrite.failed({required Failure failure}) =
      ReadingListWriteFailed;
}

/// The core's reading-list operations (FR-TR-08 … FR-TR-14).
abstract interface class ReadingListGateway {
  /// Every reading list and the progress of everything it tracks (FR-TR-11).
  Future<ReadingListBrowse> browse();

  /// Creates a reading list called [name] (FR-TR-08).
  Future<ReadingListWrite> create({required String name});

  /// Deletes the reading list [uuid] identifies (FR-TR-09).
  ///
  /// The books and comics are untouched: what goes is the tracking.
  Future<ReadingListWrite> delete({required String uuid});

  /// Adds [itemUuid] to the reading list [uuid] identifies (FR-TR-10).
  Future<ReadingListWrite> addItem({
    required String uuid,
    required String itemUuid,
  });

  /// Removes it again (FR-TR-11).
  Future<ReadingListWrite> removeItem({
    required String uuid,
    required String itemUuid,
  });

  /// Records how far through [itemUuid] the owner is, in this list alone
  /// (FR-TR-12 … FR-TR-14, UC-32).
  Future<ReadingListWrite> updateProgress({
    required String uuid,
    required String itemUuid,
    required ReadingState state,
    int? currentIssue,
    int? totalIssues,
  });
}
