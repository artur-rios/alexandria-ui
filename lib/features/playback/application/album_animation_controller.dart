import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/album_medium.dart';
import '../domain/playback_queue.dart';

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
  /// What the last insertion was shown for, as `(kind, identity)`.
  ///
  /// `null` until one has been shown, which is what makes the session's first
  /// play owe one. Held here rather than in [state] so that it survives every
  /// rebuild [build] runs for — a rebuild is not a new session — while still
  /// resetting whenever the provider itself is invalidated or recreated,
  /// which is what a new session is.
  (Object, String)? _shownFor;

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
      insertionOwed: _shownFor != _identityOf(queue),
    );
  }

  /// Records that the insertion for what is playing has been shown.
  ///
  /// Whether this may safely be called synchronously from a widget's build
  /// phase is not settled here — this controller has no consumer yet. What is
  /// known is that it is cheap and free of side effects beyond the state
  /// assignment; Task 7's caller is what determines, and should test, whether
  /// calling it from a build is safe.
  void insertionShown() {
    final queue = ref.read(audioPlaybackControllerProvider).queue;
    _shownFor = _identityOf(queue);
    state = AlbumAnimationState(medium: state.medium);
  }

  /// What identifies "which record is playing", as `(kind, identity)`.
  ///
  /// The label alone is not enough: `albumOf`/`artistOf`
  /// (`music_grouping.dart`) already treat an absent tag as "this file's own
  /// group of one" rather than as a shared value — two different untitled
  /// albums are not the same record, and folding them together here would
  /// silently break that rule for the one consumer that reads `label` as an
  /// identity instead of a display string. Falling back to the first track's
  /// uuid keeps the tracks of one untagged record identified with each other
  /// (the uuid does not change between them) while telling two different
  /// untagged records apart (their first tracks differ). Called only once
  /// [build] has confirmed the queue is non-empty, so `tracks.first` is safe.
  (Object, String) _identityOf(PlaybackQueue queue) =>
      (queue.kind, queue.label ?? queue.tracks.first.uuid);
}
