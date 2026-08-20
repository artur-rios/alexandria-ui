import 'package:freezed_annotation/freezed_annotation.dart';

part 'reading_list.freezed.dart';

/// How far through a book or comic the owner is (System Requirements §4.6).
enum ReadingState {
  /// Not started.
  pending('pending'),

  /// Part way through.
  reading('reading'),

  /// Finished.
  read('read');

  const ReadingState(this.wireName);

  /// The string the core uses.
  final String wireName;

  /// The state [wireName] names, or `null` when the core answers one this
  /// application does not know.
  static ReadingState? fromWireName(String? wireName) {
    for (final state in ReadingState.values) {
      if (state.wireName == wireName) return state;
    }
    return null;
  }
}

/// What kind of thing a reading list is tracking (FR-TR-14).
enum ReadingTargetKind {
  /// A book document.
  document('document'),

  /// A comic book.
  comic('comic');

  const ReadingTargetKind(this.wireName);

  /// The string the core uses.
  final String wireName;

  /// The kind [wireName] names, or `null` when the core answers one this
  /// application does not know.
  static ReadingTargetKind? fromWireName(String? wireName) {
    for (final kind in ReadingTargetKind.values) {
      if (kind.wireName == wireName) return kind;
    }
    return null;
  }
}

/// One item's progress inside one reading list (System Requirements §4.6).
@freezed
abstract class ReadingProgress with _$ReadingProgress {
  /// Creates a progress entry.
  const factory ReadingProgress({
    required String readingListUuid,
    required String itemUuid,
    required ReadingTargetKind targetKind,
    required ReadingState state,
    int? currentIssue,
    int? totalIssues,
  }) = _ReadingProgress;

  const ReadingProgress._();

  /// Whether this entry counts issues (FR-TR-14).
  bool get countsIssues => currentIssue != null || totalIssues != null;
}

/// A reading list and everything it tracks (FR-TR-08, FR-TR-11).
@freezed
abstract class ReadingList with _$ReadingList {
  /// Creates a reading list.
  const factory ReadingList({
    required String uuid,
    required String name,
    @Default(<ReadingProgress>[]) List<ReadingProgress> items,
  }) = _ReadingList;

  const ReadingList._();

  /// The progress this list holds for [itemUuid], if it tracks it.
  ReadingProgress? progressFor(String itemUuid) {
    for (final item in items) {
      if (item.itemUuid == itemUuid) return item;
    }
    return null;
  }

  /// Whether this list already tracks [itemUuid] (UC-31 AF-03).
  bool tracks(String itemUuid) => progressFor(itemUuid) != null;
}

/// Why a reading list name cannot be sent (UC-31 AF-01, FR-TR-08).
enum ReadingListNameError {
  /// Blank after trimming.
  empty,
}

/// What is wrong with [name], or `null` when it can be sent (AF-01).
ReadingListNameError? validateReadingListName(String name) =>
    name.trim().isEmpty ? ReadingListNameError.empty : null;
