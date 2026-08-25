import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/album_medium.dart';
import '../domain/playback_queue.dart';

/// What the animation should be showing, and whether it owes an insertion
/// (UC-21 main flow step 2, FR-PL-07, FR-PL-11).
class AlbumAnimationState {
  /// Creates a state.
  const AlbumAnimationState({this.medium, this.insertionOwed = false});

  /// The medium to draw, or `null` when the owner turned the animation off,
  /// or when the queue is a single track (UC-21 AF-02) — a lone track is not
  /// a record, so there is nothing here for the caller to draw or to open a
  /// player over.
  final AlbumMedium? medium;

  /// Whether the medium has to be put into its device before it turns.
  ///
  /// Always `false` when [medium] is `null`: there is no consumer for which
  /// "owed, but nothing to show for it" is a meaningful state to be in, and
  /// keeping the two facts tied together here is what stops a caller (the
  /// shell's auto-open, `NowPlayingScreen`'s own stage) from having to
  /// re-derive "is this queue even the kind of thing that owes one" for
  /// itself and risk answering it differently than this class did.
  final bool insertionOwed;
}

/// Whether the medium has to go in again (UC-21 main flow step 2).
///
/// An insertion is owed on the session's first play, and whenever the album or
/// the artist changes — never between the tracks of one record, which is what
/// a record already on the platter does not need, and never for a single track
/// (AF-02), which never owes one at all. The queue's kind and label are what
/// say which record is playing: two queues with the same pair are the same
/// record continuing.
///
/// AF-02 lives here, not only in whichever widget draws the stage: a single
/// track queue's `insertionOwed` has to be `false`, permanently, not merely
/// "owed but not drawn" — the flag is a level, cleared only by
/// [insertionShown], and a caller that hid the stage without also clearing the
/// flag would leave it stuck `true` through every track that plays until the
/// caller happens to draw a stage again. A record played straight after a lone
/// track would then find the flag already `true` and never see the edge that
/// says "this became newly owed."
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

    // `showsAlbumAnimation` already requires a non-empty queue, so there is
    // no separate `queue.isEmpty` check left to make here.
    if (medium == null || !queue.showsAlbumAnimation) {
      return const AlbumAnimationState();
    }

    return AlbumAnimationState(
      medium: medium,
      insertionOwed: _shownFor != _identityOf(queue),
    );
  }

  /// Records that the insertion for what is playing has been shown.
  ///
  /// Settled by Task 7: never called synchronously from a build. Both of its
  /// callers — `AlbumStage`'s own animation-status listener, and
  /// `NowPlayingScreen`'s `ref.listen` for the case where motion is reduced
  /// and that listener never fires — run after a build has already
  /// committed, which is what a state assignment here requires.
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
