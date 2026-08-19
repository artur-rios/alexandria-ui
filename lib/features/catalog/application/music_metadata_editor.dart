import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/catalog_gateway.dart';
import '../domain/music_metadata.dart';

/// Where the metadata form is (UC-15).
enum MusicEditorStage {
  /// Open, with the owner editing.
  editing,

  /// The call is in flight (main flow step 5).
  saving,

  /// The core stored it, so the form is finished (main flow step 7).
  saved,

  /// The core has no such file, so the form closes (AF-03).
  gone,
}

/// The metadata form's state (UC-15).
class MusicEditorState {
  /// Creates a state.
  const MusicEditorState({
    required this.draft,
    this.errors = const {},
    this.rejection,
    this.stage = MusicEditorStage.editing,
  });

  /// What the owner has typed.
  final MusicDraft draft;

  /// What local validation refused, by field (AF-01).
  final Map<MusicField, MusicFieldError> errors;

  /// What the core refused, if it did (AF-02).
  ///
  /// Held beside the draft rather than replacing it: AF-02 keeps the form open
  /// with what the owner wrote still in it, because the core's reason is a
  /// thing to act on and they need what they typed to act on it.
  final Failure? rejection;

  /// Where the form is.
  final MusicEditorStage stage;

  /// Whether the call is in flight.
  bool get isSaving => stage == MusicEditorStage.saving;

  /// A copy with the given changes.
  ///
  /// [rejection] is cleared rather than carried whenever a new one is not
  /// given: every transition here either raises a fresh reason or moves past
  /// the old one, and a stale rejection under a new edit would be a lie.
  MusicEditorState copyWith({
    MusicDraft? draft,
    Map<MusicField, MusicFieldError>? errors,
    Failure? rejection,
    MusicEditorStage? stage,
  }) => MusicEditorState(
    draft: draft ?? this.draft,
    errors: errors ?? this.errors,
    rejection: rejection,
    stage: stage ?? this.stage,
  );
}

/// The form over one audio file's metadata (UC-15, FR-ME-01, FR-ME-03).
class MusicMetadataEditor extends Notifier<MusicEditorState> {
  /// What the file held when the form opened, to compare against for AF-04.
  MusicMetadata _original = const MusicMetadata();

  /// The file being edited.
  String _uuid = '';

  @override
  MusicEditorState build() =>
      MusicEditorState(draft: draftFrom(const MusicMetadata()));

  /// Opens the form on [metadata] for the file [uuid] (main flow steps 1
  /// and 2).
  void open(String uuid, MusicMetadata metadata) {
    _uuid = uuid;
    _original = metadata;
    state = MusicEditorState(draft: draftFrom(metadata));
  }

  /// Records what the owner typed into [field] (main flow step 3).
  ///
  /// The field's own error is dropped as it is edited: the mark said the value
  /// was wrong, and this is no longer that value.
  void edit(MusicField field, String value) {
    state = state.copyWith(
      draft: {...state.draft, field: value},
      errors: {...state.errors}..remove(field),
    );
  }

  /// Validates and sends (main flow steps 4 through 7).
  ///
  /// Returns once the form has reached a stage the screen acts on. Everything
  /// that decides whether the core is called at all happens before the call:
  /// invalid fields (AF-01) and an unchanged record (AF-04) both stop here.
  Future<void> submit() async {
    if (state.isSaving) return;

    // AF-01: marked, and the core is not called.
    final errors = validateDraft(state.draft);
    if (errors.isNotEmpty) {
      state = state.copyWith(errors: errors);
      return;
    }

    // AF-04: nothing actually changed, so the form closes without a call.
    // Compared against what the file held rather than against whether any key
    // was touched — typing a character and deleting it is not a change.
    final edited = metadataFrom(state.draft);
    if (edited == _original) {
      state = state.copyWith(stage: MusicEditorStage.saved);
      return;
    }

    state = state.copyWith(stage: MusicEditorStage.saving);

    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (credential == null) {
      state = state.copyWith(stage: MusicEditorStage.editing);
      return;
    }

    final outcome = await ref
        .read(catalogGatewayProvider)
        .editMusicMetadata(
          uuid: _uuid,
          metadata: edited,
          credential: credential,
        );

    switch (outcome) {
      case MetadataEditSaved(:final metadata):
        _original = metadata;
        // FR-ME-05: the detail view and every open listing read the core
        // again, so the edit shows up without the owner refreshing anything.
        // Invalidated rather than patched in place, because the core is what
        // holds the catalog and a locally patched copy would be a guess at
        // what it now says.
        ref.invalidate(fileDetailsControllerProvider);
        ref.invalidate(listingControllerProvider);
        ref.invalidate(catalogSearchProvider);
        state = MusicEditorState(
          draft: draftFrom(metadata),
          stage: MusicEditorStage.saved,
        );

      // AF-05: the session is discarded, which returns the owner to login.
      case MetadataEditFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);
        state = state.copyWith(stage: MusicEditorStage.editing);

      // AF-03: the record is gone, so there is nothing to keep the form open
      // for. The listing is refreshed by the screen that closes it.
      case MetadataEditFailed(failure: NotFoundFailure()):
        state = state.copyWith(stage: MusicEditorStage.gone);

      // AF-02: the core's reason is final and the form stays open with what
      // the owner wrote, so they can act on it. Nothing was stored.
      case MetadataEditFailed(:final failure):
        state = state.copyWith(
          rejection: failure,
          stage: MusicEditorStage.editing,
        );
    }
  }
}
