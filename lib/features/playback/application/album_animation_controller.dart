import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/album_medium.dart';

/// What the animation should be showing, and whether it owes an insertion
/// (UC-21 main flow step 2, FR-PL-07, FR-PL-11).
class AlbumAnimationState {
  /// Creates a state.
  const AlbumAnimationState({this.medium, this.insertionOwed = false});

  /// The medium to draw, or `null` when the owner turned the animation off.
  final AlbumMedium? medium;

  /// Whether the medium has to be put into its device before it turns.
  final bool insertionOwed;
}

/// Whether the medium has to go in again (UC-21 main flow step 2).
///
/// An insertion is owed on the session's first play, and whenever the album or
/// the artist changes — never between the tracks of one record, which is what
/// a record already on the platter does not need. The queue's kind and label
/// are what say which record is playing: two queues with the same pair are the
/// same record continuing.
class AlbumAnimationController extends Notifier<AlbumAnimationState> {
  /// What the last insertion was shown for, as `(kind, label)`.
  ///
  /// `null` until one has been shown, which is what makes the session's first
  /// play owe one. Held here rather than in [state] so that it survives every
  /// rebuild [build] runs for — a rebuild is not a new session — while still
  /// resetting whenever the provider itself is invalidated or recreated,
  /// which is what a new session is.
  (Object, String?)? _shownFor;

  @override
  AlbumAnimationState build() {
    final queue = ref.watch(audioPlaybackControllerProvider).queue;
    final mode = ref.watch(preferencesControllerProvider).albumAnimation;
    final medium = mediumFor(mode, queue.year);

    if (medium == null || queue.isEmpty) {
      return const AlbumAnimationState();
    }

    return AlbumAnimationState(
      medium: medium,
      insertionOwed: _shownFor != (queue.kind, queue.label),
    );
  }

  /// Records that the insertion for what is playing has been shown.
  ///
  /// Called from `AlbumStage` once its own insertion has actually played
  /// (never for a no-op skip), which happens from a build phase — this only
  /// writes an instance field and reassigns [state], both of which are safe
  /// there.
  void insertionShown() {
    final queue = ref.read(audioPlaybackControllerProvider).queue;
    _shownFor = (queue.kind, queue.label);
    state = AlbumAnimationState(medium: state.medium);
  }
}
