import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../catalog/domain/catalog_gateway.dart';
import '../domain/text_content_gateway.dart';

/// Where the editor is (UC-18, Use Case Specification §4.6).
enum EditorStage {
  /// Nothing is open.
  closed,

  /// The content is being read (main flow step 2).
  loading,

  /// Open, and what is on screen is what is on disk.
  clean,

  /// Open, with edits that are not on disk (FR-ME-09).
  dirty,

  /// The write is in flight (main flow step 6).
  saving,

  /// The content could not be read, so there is nothing to edit.
  loadFailed,
}

/// What the editor is asking the owner, if anything.
///
/// Separate from [EditorStage] because a question does not change where the
/// content is: the editor is still dirty while it asks whether to overwrite,
/// and it is still dirty if the answer is no.
enum EditorQuestion {
  /// Nothing is being asked.
  none,

  /// The content is unchanged, so there was nothing to write (AF-01).
  nothingToSave,

  /// Leaving would discard unsaved changes (AF-02, FR-ME-09).
  leavingWithUnsavedChanges,

  /// The file changed on disk since it was read (AF-05).
  changedOnDisk,

  /// The core no longer has this record (AF-04).
  ///
  /// A question rather than a closing, because what the owner typed is still
  /// on screen and closing the editor under them would lose it silently.
  recordIsGone,

  /// The session was rejected mid-edit and the content could not be saved
  /// (AF-06). Acknowledging it is what discards the session.
  sessionRejected,
}

/// The editor's state (UC-18).
class TextEditorState {
  /// Creates a state.
  const TextEditorState({
    this.uuid,
    this.name = '',
    this.loaded = '',
    this.content = '',
    this.stage = EditorStage.closed,
    this.question = EditorQuestion.none,
    this.failure,
  });

  /// The file being edited, or `null` when nothing is open.
  final String? uuid;

  /// Its name, for the editor's heading.
  final String name;

  /// The content as it was read, which is what a save compares against
  /// (FR-ME-08).
  final String loaded;

  /// The content as it is now.
  final String content;

  /// Where the editor is.
  final EditorStage stage;

  /// What the editor is asking, if anything.
  final EditorQuestion question;

  /// What the core refused, if it did (AF-03, AF-04, AF-06).
  final Failure? failure;

  /// Whether the content differs from what was read (FR-ME-08, FR-ME-09).
  bool get isDirty => content != loaded;

  /// Whether the editor is open at all.
  bool get isOpen => stage != EditorStage.closed;

  /// Whether a write is in flight.
  bool get isSaving => stage == EditorStage.saving;

  /// A copy with the given changes.
  ///
  /// [failure] is cleared rather than carried whenever a new one is not
  /// given, as is [question]: each transition either raises a fresh one or
  /// moves past the old one.
  TextEditorState copyWith({
    String? uuid,
    String? name,
    String? loaded,
    String? content,
    EditorStage? stage,
    EditorQuestion question = EditorQuestion.none,
    Failure? failure,
  }) => TextEditorState(
    uuid: uuid ?? this.uuid,
    name: name ?? this.name,
    loaded: loaded ?? this.loaded,
    content: content ?? this.content,
    stage: stage ?? this.stage,
    question: question,
    failure: failure,
  );
}

/// The Markdown and text editor (UC-18, FR-ME-06 … FR-ME-10).
///
/// The preview is the presentation's; what is here is the content, whether it
/// differs from disk, and what each of the core's answers means for the text
/// the owner has typed. The rule running through all of it is that nothing
/// typed is lost without being told: every failure path keeps the content on
/// screen.
class TextEditorController extends Notifier<TextEditorState> {
  /// The content hash the file had when the content was read.
  ///
  /// What AF-05 compares against: if the core reports a different one at save
  /// time, something else wrote the file in between.
  String _hashWhenLoaded = '';

  @override
  TextEditorState build() => const TextEditorState();

  /// Opens [uuid] and reads its content (main flow steps 1 and 2).
  Future<void> open({
    required String uuid,
    required String name,
    required String contentHash,
  }) async {
    _hashWhenLoaded = contentHash;
    state = TextEditorState(uuid: uuid, name: name, stage: EditorStage.loading);

    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return;

    final outcome = await ref
        .read(textContentGatewayProvider)
        .readContent(uuid: uuid, credential: credential);

    switch (outcome) {
      case TextContentLoaded(:final content):
        state = state.copyWith(
          loaded: content,
          content: content,
          stage: EditorStage.clean,
        );

      // Nothing was read, so there is nothing to edit. The screen says why.
      case TextContentReadFailed(:final failure):
        state = state.copyWith(stage: EditorStage.loadFailed, failure: failure);
    }
  }

  /// Records what the owner typed (main flow step 4).
  void edit(String content) {
    if (!state.isOpen || state.isSaving) return;

    state = state.copyWith(
      content: content,
      stage: content == state.loaded ? EditorStage.clean : EditorStage.dirty,
    );
  }

  /// Saves (main flow steps 5 to 7).
  ///
  /// [overwriting] is AF-05's answer: the owner was told the file changed on
  /// disk and chose to continue anyway.
  Future<void> save({bool overwriting = false}) async {
    if (state.isSaving || !state.isOpen) return;

    // AF-01: the content is what was read, so there is nothing to write and
    // the owner is told rather than left wondering whether the save happened.
    if (!state.isDirty) {
      state = state.copyWith(question: EditorQuestion.nothingToSave);
      return;
    }

    final uuid = state.uuid;
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (uuid == null || credential == null) return;

    // AF-05: something else wrote the file since it was read. Asked before the
    // write rather than after, because after is too late to offer a reload.
    if (!overwriting && await _changedOnDisk(uuid)) {
      state = state.copyWith(
        stage: EditorStage.dirty,
        question: EditorQuestion.changedOnDisk,
      );
      return;
    }

    state = state.copyWith(stage: EditorStage.saving);

    final outcome = await ref
        .read(textContentGatewayProvider)
        .writeContent(
          uuid: uuid,
          content: state.content,
          credential: credential,
        );

    switch (outcome) {
      case TextContentWritten(:final file):
        // The record the core refreshed is the truth about what is on disk
        // now, so the next save compares against its hash.
        _hashWhenLoaded = file.contentHash;
        // FR-ME-05's neighbours: the listing and the detail view read the core
        // again, because the record's hash and index time have moved.
        ref.invalidate(fileDetailsControllerProvider);
        ref.invalidate(listingControllerProvider);
        ref.invalidate(catalogSearchProvider);
        state = state.copyWith(loaded: state.content, stage: EditorStage.clean);

      // AF-06: the session is gone, and the owner is told before it takes
      // them to the login screen — what they typed is not on disk, and being
      // moved away from it without a word would lose it silently.
      case TextContentWriteFailed(failure: final UnauthorizedFailure failure):
        state = state.copyWith(
          stage: EditorStage.dirty,
          question: EditorQuestion.sessionRejected,
          failure: failure,
        );

      // AF-04: the record is gone. The content stays exactly where it is
      // until the owner dismisses the message.
      case TextContentWriteFailed(failure: final NotFoundFailure failure):
        state = state.copyWith(
          stage: EditorStage.dirty,
          question: EditorQuestion.recordIsGone,
          failure: failure,
        );

      // AF-03 and FR-ME-10: a disk that refused the write changes nothing on
      // screen. The content is still exactly what was typed, and still
      // unsaved.
      case TextContentWriteFailed(:final failure):
        state = state.copyWith(stage: EditorStage.dirty, failure: failure);
    }
  }

  /// Reads the file again, discarding what was typed (AF-05's other answer).
  Future<void> reloadFromDisk() async {
    final uuid = state.uuid;
    if (uuid == null) return;

    await open(uuid: uuid, name: state.name, contentHash: await _hashNow(uuid));
  }

  /// Clears whatever the editor was asking, leaving the content alone.
  void dismissQuestion() => state = state.copyWith();

  /// Answers AF-06 by letting the rejected session go.
  ///
  /// The content is lost with it, which is precisely why the owner had to
  /// acknowledge this rather than simply arriving at the login screen.
  void acceptSessionRejection() {
    final failure = state.failure;
    state = const TextEditorState();
    if (failure is UnauthorizedFailure) {
      ref.read(sessionControllerProvider.notifier).invalidate(failure);
    }
  }

  /// Asks to close the editor (AF-02).
  ///
  /// Returns `true` when it closed. Unsaved changes make it ask instead, and
  /// the owner then saves, discards, or cancels.
  bool close() {
    if (state.isDirty) {
      state = state.copyWith(
        question: EditorQuestion.leavingWithUnsavedChanges,
      );
      return false;
    }

    state = const TextEditorState();
    return true;
  }

  /// Closes without saving (AF-02's discard).
  void discardAndClose() => state = const TextEditorState();

  /// Saves and then closes, if the save succeeded (AF-02's save).
  Future<void> saveAndClose() async {
    await save();
    if (state.stage == EditorStage.clean) state = const TextEditorState();
  }

  /// Whether the file's content hash has moved since it was read (AF-05).
  ///
  /// An unanswerable question is not a conflict: the core is the authority,
  /// and blocking a save on a reading nobody could take would make the editor
  /// unusable whenever the catalog hiccups.
  Future<bool> _changedOnDisk(String uuid) async {
    final hash = await _hashNow(uuid);
    if (hash.isEmpty || _hashWhenLoaded.isEmpty) return false;

    return hash != _hashWhenLoaded;
  }

  /// The content hash the core reports for [uuid] now, or empty when it will
  /// not say.
  Future<String> _hashNow(String uuid) async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return '';

    final outcome = await ref
        .read(catalogGatewayProvider)
        .fileDetails(uuid: uuid, credential: credential);

    return switch (outcome) {
      FileDetailsRead(:final details) => details.file.contentHash,
      FileDetailsFailed() => '',
    };
  }
}
