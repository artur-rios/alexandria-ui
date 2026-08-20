import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/catalog_gateway.dart';
import '../domain/video_metadata.dart';

/// Where the video metadata form is (UC-16).
enum VideoEditorStage {
  /// Open, with the owner editing.
  editing,

  /// The marking is being changed from series to movie and something records
  /// per-episode progress, so the owner is asked first (AF-03).
  confirmingMarkingChange,

  /// The call is in flight (main flow step 4).
  saving,

  /// The core stored it, so the form is finished (main flow step 6).
  saved,

  /// The core has no such file, so the form closes (AF-04).
  gone,
}

/// The video metadata form's state (UC-16).
class VideoEditorState {
  /// Creates a state.
  const VideoEditorState({
    required this.draft,
    this.errors = const {},
    this.rejection,
    this.stage = VideoEditorStage.editing,
  });

  /// What the owner has typed and picked.
  final VideoDraft draft;

  /// What local validation refused, by field (AF-01).
  final Map<VideoField, VideoFieldError> errors;

  /// What the core refused, if it did (AF-02).
  ///
  /// Held beside the draft rather than replacing it: the form stays open with
  /// what the owner wrote, because the core's reason is a thing to act on and
  /// they need what they typed to act on it.
  final Failure? rejection;

  /// Where the form is.
  final VideoEditorStage stage;

  /// Whether the call is in flight.
  bool get isSaving => stage == VideoEditorStage.saving;

  /// Whether the owner is being asked about the marking change (AF-03).
  bool get isConfirmingMarkingChange =>
      stage == VideoEditorStage.confirmingMarkingChange;

  /// A copy with the given changes.
  ///
  /// [rejection] is cleared rather than carried whenever a new one is not
  /// given: every transition here either raises a fresh reason or moves past
  /// the old one, and a stale rejection under a new edit would be a lie.
  VideoEditorState copyWith({
    VideoDraft? draft,
    Map<VideoField, VideoFieldError>? errors,
    Failure? rejection,
    VideoEditorStage? stage,
  }) => VideoEditorState(
    draft: draft ?? this.draft,
    errors: errors ?? this.errors,
    rejection: rejection,
    stage: stage ?? this.stage,
  );
}

/// The form over one video file's metadata (UC-16, FR-ME-02, FR-ME-03).
///
/// The same shape as the music form it sits beside, with one flow of its own:
/// the movie-or-series marking is not just another field, because changing it
/// from series to movie collapses per-episode progress into single-item
/// progress (FR-TR-07). AF-03 is why this asks the core what progress exists
/// before it asks the owner to confirm.
class VideoMetadataEditor extends Notifier<VideoEditorState> {
  /// What the file held when the form opened.
  VideoMetadata _original = const VideoMetadata();

  /// The file being edited.
  String _uuid = '';

  @override
  VideoEditorState build() =>
      VideoEditorState(draft: draftFromVideo(const VideoMetadata()));

  /// Opens the form on [metadata] for the file [uuid] (main flow steps 1
  /// and 2).
  void open(String uuid, VideoMetadata metadata) {
    _uuid = uuid;
    _original = metadata;
    state = VideoEditorState(draft: draftFromVideo(metadata));
  }

  /// Records what the owner typed into [field] (main flow step 3).
  ///
  /// The field's own error is dropped as it is edited: the mark said the value
  /// was wrong, and this is no longer that value.
  void edit(VideoField field, String value) {
    state = state.copyWith(
      draft: {...state.draft, field: value},
      errors: {...state.errors}..remove(field),
    );
  }

  /// Picks the movie-or-series marking (main flow step 3, FR-ME-02).
  void markAs(MediaKind kind) => edit(VideoField.mediaKind, kind.wireName);

  /// Validates and sends (main flow steps 4 through 6).
  ///
  /// Everything that decides whether the core is called at all happens before
  /// the call: invalid fields (AF-01), an unchanged record, and the marking
  /// confirmation (AF-03) all stop here.
  Future<void> submit() async {
    if (state.isSaving) return;

    // AF-01: marked, and the core is not called.
    final errors = validateVideoDraft(state.draft);
    if (errors.isNotEmpty) {
      state = state.copyWith(errors: errors);
      return;
    }

    // Nothing actually changed, so the form closes without a call. Compared
    // against what the file held rather than against whether any key was
    // touched — typing a character and deleting it is not a change.
    final edited = videoMetadataFrom(state.draft);
    if (edited == _original) {
      state = state.copyWith(stage: VideoEditorStage.saved);
      return;
    }

    // AF-03: the marking is going from series to movie. Whether that costs
    // the owner anything depends on what progress exists, so the core is
    // asked before they are.
    if (await _needsMarkingConfirmation(edited)) {
      state = state.copyWith(stage: VideoEditorStage.confirmingMarkingChange);
      return;
    }

    await _send(edited);
  }

  /// Sends after the owner confirmed the marking change (AF-03).
  Future<void> confirmMarkingChange() async {
    if (!state.isConfirmingMarkingChange) return;
    await _send(videoMetadataFrom(state.draft));
  }

  /// Goes back to editing without calling the core (AF-03's other answer).
  ///
  /// The draft is left exactly as it was, marking included: the owner said no
  /// to losing the progress, not to everything else they had typed, and
  /// putting the marking back would be this deciding that for them.
  void cancelMarkingChange() {
    if (!state.isConfirmingMarkingChange) return;
    state = state.copyWith(stage: VideoEditorStage.editing);
  }

  /// Whether AF-03's warning stands between this edit and the core.
  Future<bool> _needsMarkingConfirmation(VideoMetadata edited) async {
    final wasSeries = _original.mediaKind == MediaKind.series;
    final becomesMovie = edited.mediaKind == MediaKind.movie;
    if (!wasSeries || !becomesMovie) return false;

    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return false;

    return ref
        .read(watchProgressGatewayProvider)
        .episodesRecordedFor(uuid: _uuid, credential: credential);
  }

  /// Steps 4 to 6, and the flows the core's answer selects.
  Future<void> _send(VideoMetadata edited) async {
    state = state.copyWith(stage: VideoEditorStage.saving);

    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (credential == null) {
      state = state.copyWith(stage: VideoEditorStage.editing);
      return;
    }

    final outcome = await ref
        .read(catalogGatewayProvider)
        .editVideoMetadata(
          uuid: _uuid,
          metadata: edited,
          credential: credential,
        );

    switch (outcome) {
      case VideoMetadataEditSaved(:final metadata):
        _original = metadata;
        // FR-ME-05: the detail view and every open listing read the core
        // again, so the edit shows up without the owner refreshing anything.
        ref.invalidate(fileDetailsControllerProvider);
        ref.invalidate(listingControllerProvider);
        ref.invalidate(catalogSearchProvider);
        state = VideoEditorState(
          draft: draftFromVideo(metadata),
          stage: VideoEditorStage.saved,
        );

      // AF-05: the session is discarded, which returns the owner to login.
      case VideoMetadataEditFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);
        state = state.copyWith(stage: VideoEditorStage.editing);

      // AF-04: the record is gone, so there is nothing to keep the form open
      // for. The listing is refreshed by the screen that closes it.
      case VideoMetadataEditFailed(failure: NotFoundFailure()):
        state = state.copyWith(stage: VideoEditorStage.gone);

      // AF-02: the core's reason is final and the form stays open with what
      // the owner wrote, so they can act on it. Nothing was stored.
      case VideoMetadataEditFailed(:final failure):
        state = state.copyWith(
          rejection: failure,
          stage: VideoEditorStage.editing,
        );
    }
  }
}
