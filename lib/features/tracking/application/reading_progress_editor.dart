import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/issue_progress.dart';
import '../domain/reading_list.dart';
import '../domain/reading_list_gateway.dart';

/// The progress being edited, and which item it belongs to (UC-32).
class ReadingProgressEditorState {
  /// Creates a state.
  const ReadingProgressEditorState({
    this.readingListUuid,
    this.itemUuid,
    this.state = ReadingState.pending,
    this.issues = const IssueDraft(),
    this.currentError,
    this.totalError,
    this.rejection,
    this.isSaving = false,
  });

  /// The reading list the progress belongs to, or `null` when nothing is open.
  ///
  /// The reading list and not only the item: the same book in two lists has two
  /// progresses, and setting one leaves the other alone (AF-05).
  final String? readingListUuid;

  /// The book or comic.
  final String? itemUuid;

  /// The state the owner has chosen.
  final ReadingState state;

  /// What they have typed into the issue fields.
  final IssueDraft issues;

  /// What local validation refused (AF-02).
  final IssueError? currentError;

  /// And for the total.
  final IssueError? totalError;

  /// What the core refused (AF-03, AF-04).
  final Failure? rejection;

  /// Whether the update is in flight.
  final bool isSaving;

  /// Whether an item is open for editing.
  bool get isOpen => readingListUuid != null && itemUuid != null;

  /// Whether [progress] is the entry being edited.
  bool isEditing(ReadingProgress progress) =>
      progress.readingListUuid == readingListUuid &&
      progress.itemUuid == itemUuid;

  /// A copy with the given changes.
  ///
  /// The marks and the rejection are cleared rather than carried whenever they
  /// are not given: each belongs to one attempt.
  ReadingProgressEditorState copyWith({
    String? readingListUuid,
    String? itemUuid,
    ReadingState? state,
    IssueDraft? issues,
    IssueError? currentError,
    IssueError? totalError,
    Failure? rejection,
    bool? isSaving,
  }) => ReadingProgressEditorState(
    readingListUuid: readingListUuid ?? this.readingListUuid,
    itemUuid: itemUuid ?? this.itemUuid,
    state: state ?? this.state,
    issues: issues ?? this.issues,
    currentError: currentError,
    totalError: totalError,
    rejection: rejection,
    isSaving: isSaving ?? this.isSaving,
  );
}

/// Drives UC-32: recording how far through a book or a comic the owner is.
class ReadingProgressEditor extends Notifier<ReadingProgressEditorState> {
  @override
  ReadingProgressEditorState build() => const ReadingProgressEditorState();

  /// Opens [progress] for editing (main flow step 3).
  void open(ReadingProgress progress) => state = ReadingProgressEditorState(
    readingListUuid: progress.readingListUuid,
    itemUuid: progress.itemUuid,
    state: progress.state,
    issues: IssueDraft(
      current: progress.currentIssue?.toString() ?? '',
      total: progress.totalIssues?.toString() ?? '',
    ),
  );

  /// Closes it, changing nothing.
  void close() => state = const ReadingProgressEditorState();

  /// Chooses a read state (main flow step 3, FR-TR-13).
  void chooseState(ReadingState readState) =>
      state = state.copyWith(state: readState);

  /// Records the issue the owner is on (step 4).
  void editCurrentIssue(String current) => state = state.copyWith(
    issues: state.issues.copyWith(current: current),
    totalError: state.totalError,
  );

  /// Records the total (step 4).
  void editTotalIssues(String total) => state = state.copyWith(
    issues: state.issues.copyWith(total: total),
    currentError: state.currentError,
  );

  /// Sends the update (main flow steps 5 and 6).
  ///
  /// [countsIssues] is whether this item is a comic in a series. A standalone
  /// book's issue fields are never shown (AF-01), so they are never sent
  /// either — an issue number on a book would be this application inventing a
  /// series that is not there.
  Future<void> submit({required bool countsIssues}) async {
    if (state.isSaving || !state.isOpen) return;

    // AF-02: marked, and the core is not called.
    if (countsIssues) {
      final currentError = validateCurrentIssue(state.issues);
      final totalError = validateTotalIssues(state.issues);
      if (currentError != null || totalError != null) {
        state = state.copyWith(
          currentError: currentError,
          totalError: totalError,
        );
        return;
      }
    }

    state = state.copyWith(isSaving: true);

    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (credential == null) {
      state = state.copyWith(isSaving: false);
      return;
    }

    final outcome = await ref
        .read(readingListGatewayProvider)
        .updateProgress(
          uuid: state.readingListUuid!,
          itemUuid: state.itemUuid!,
          state: state.state,
          credential: credential,
          currentIssue: countsIssues ? state.issues.currentIssue : null,
          totalIssues: countsIssues ? state.issues.totalIssues : null,
        );

    switch (outcome) {
      case ReadingListWriteDone():
        // Step 6: what the screen shows comes from the core, so it is read
        // again rather than patched here.
        await ref.read(readingListsControllerProvider.notifier).reload();
        state = const ReadingProgressEditorState();

      // AF-06: the session is discarded, which returns the owner to login.
      case ReadingListWriteFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);
        state = const ReadingProgressEditorState();

      // AF-04: the reading list or the item is gone. The screen is read again,
      // and the editor stays open over what is no longer there.
      case ReadingListWriteFailed(failure: final NotFoundFailure failure):
        await ref.read(readingListsControllerProvider.notifier).reload();
        state = state.copyWith(isSaving: false, rejection: failure);

      // AF-03: the core refused the state. The stored progress is unchanged,
      // which is why nothing is reloaded — the screen is already showing what
      // the core holds.
      case ReadingListWriteFailed(:final failure):
        state = state.copyWith(isSaving: false, rejection: failure);
    }
  }
}
