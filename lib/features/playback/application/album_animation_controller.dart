import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../catalog/domain/music_metadata.dart';
import '../domain/album_medium.dart';
import '../domain/music_grouping.dart';
import '../domain/playback_queue.dart';
import 'music_library_controller.dart';

/// What identifies "which record is playing", as `(kind, identity)`
/// (see `AlbumAnimationController._recordOf`).
typedef AlbumIdentity = (Object, String);

/// What the animation should be showing, and whether it owes an insertion
/// (UC-21 main flow step 2, FR-PL-07, FR-PL-11).
class AlbumAnimationState {
  /// Creates a state.
  const AlbumAnimationState({
    this.medium,
    this.insertionOwed = false,
    this.owedIdentity,
  });

  /// The medium to draw, or `null` when the owner turned the animation off,
  /// or the queue is empty — the only queue with nothing here for the caller
  /// to draw or to open a player over.
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

  /// *Which* record [insertionOwed] is true for — `null` whenever
  /// [insertionOwed] is `false` (Finding 1).
  ///
  /// `insertionOwed` alone is a level, not an edge: a stage that is closed
  /// mid-insertion never calls `AlbumStage.onInserted`, so the flag can stay
  /// stuck `true` across a later album that also owes one — the boolean
  /// value never actually changes, it is `true` before and `true` after. A
  /// listener that edge-triggers on the boolean would then never fire for
  /// that later album. This field changes with every record that becomes
  /// newly owed, including one owed right behind an interrupted one, because
  /// it is derived straight from the queue's own identity on every rebuild —
  /// so a caller can edge-trigger on *this* changing instead, which it always
  /// does when the record actually playing has changed, whether or not the
  /// previous insertion ever finished.
  final AlbumIdentity? owedIdentity;
}

/// Whether the medium has to go in again (UC-21 main flow step 2).
///
/// An insertion is owed on the session's first play, and whenever the record
/// changes — never between the tracks of one record, which is what a record
/// already on the platter does not need. A record is its album and its
/// artist, however the queue that plays it was built: an album or an artist
/// queue carries that label itself, and a track queue's record is resolved
/// from the current track's own metadata (see [_recordOf]).
class AlbumAnimationController extends Notifier<AlbumAnimationState> {
  /// What the last insertion was shown for, as `(kind, identity)`.
  ///
  /// `null` until one has been shown, which is what makes the session's first
  /// play owe one. Held here rather than in [state] so that it survives every
  /// rebuild [build] runs for — a rebuild is not a new session — while still
  /// being forgotten explicitly by [forgetSession] when one actually ends
  /// (Finding 4). Not reset by `ref.invalidate` alone: a `Notifier` provider
  /// reruns [build] on the *same* instance when it is invalidated rather than
  /// replacing it, so a plain instance field here would otherwise survive
  /// every session unless something clears it on purpose.
  AlbumIdentity? _shownFor;

  @override
  AlbumAnimationState build() {
    final queue = ref.watch(audioPlaybackControllerProvider).queue;
    final mode = ref.watch(preferencesControllerProvider).albumAnimation;

    // The only queue with nothing to show: an empty one. A queue with
    // tracks in it always names a record, even a single-track one (design
    // §1), so there is no further kind check to make here.
    if (!queue.showsAlbumAnimation) {
      return const AlbumAnimationState();
    }

    final library = queue.kind == QueueKind.track
        ? ref.watch(musicLibraryProvider).value
        : null;
    final record = _recordOf(queue, library);
    final medium = mediumFor(mode, record.year);

    if (medium == null) {
      return const AlbumAnimationState();
    }

    final identity = (queue.kind, record.identity);
    final owed = _shownFor != identity;

    return AlbumAnimationState(
      medium: medium,
      insertionOwed: owed,
      owedIdentity: owed ? identity : null,
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
    final library = queue.kind == QueueKind.track
        ? ref.read(musicLibraryProvider).value
        : null;
    _shownFor = (queue.kind, _recordOf(queue, library).identity);
    state = AlbumAnimationState(medium: state.medium);
  }

  /// Forgets which record has already had its insertion shown, so the next
  /// play — even of the very same record — owes one again (Finding 4).
  ///
  /// Called by `PlaybackSessionActivity.end`, which both `SignOutController`
  /// and `SessionController.establish` run, so both a sign-out and a fresh
  /// sign-in over it count as ending the session this memory belongs to.
  /// `ref.invalidate` alone cannot do this: a `Notifier` reruns [build] on
  /// the *same* instance rather than replacing it, so `_shownFor` would
  /// otherwise survive untouched. Recomputing [state] directly, rather than
  /// only clearing the field and waiting for the next natural rebuild, is
  /// what makes the reset visible immediately rather than only the next time
  /// something else happens to change the queue or the mode.
  void forgetSession() {
    _shownFor = null;
    state = build();
  }

  /// The record [queue] plays: its identity — what [build] pairs with
  /// [PlaybackQueue.kind] to get an [AlbumIdentity] — and the year that picks
  /// its medium.
  ///
  /// For an album or an artist queue, both come from the queue itself, exactly
  /// as before this method existed: the label alone is not enough for the
  /// identity, because `albumOf`/`artistOf` (`music_grouping.dart`) already
  /// treat an absent tag as "this file's own group of one" rather than as a
  /// shared value — two different untitled albums are not the same record,
  /// and folding them together here would silently break that rule for the
  /// one consumer that reads `label` as an identity instead of a display
  /// string. Falling back to the first track's uuid keeps the tracks of one
  /// untagged record identified with each other (the uuid does not change
  /// between them) while telling two different untagged records apart (their
  /// first tracks differ).
  ///
  /// For a track queue — which carries no label and no year at all — both are
  /// read from [library] instead, off the current track's own album, artist
  /// and year, resolved the same way every other surface resolves a track's
  /// metadata (`MusicLibrary.entryFor`, design §2, §3). A track with no album
  /// tag falls back to its own uuid, the same untagged rule `albumOf` states;
  /// one with an album tag identifies by album and artist together, since two
  /// different artists can name an album the same thing. `library` is `null`
  /// while it has not loaded, or does not hold the track — the fallback entry
  /// that answers then has no album and no year, so the identity falls back
  /// to the uuid and the medium falls back to a disc, exactly as an unknown
  /// record does everywhere else.
  ///
  /// Called only once [build] has confirmed the queue is non-empty, so
  /// `tracks.first` is safe.
  ({String identity, int? year}) _recordOf(
    PlaybackQueue queue,
    MusicLibrary? library,
  ) {
    if (queue.kind != QueueKind.track) {
      return (
        identity: queue.label ?? queue.tracks.first.uuid,
        year: queue.year,
      );
    }

    final track = queue.tracks.first;
    final entry =
        library?.entryFor(track) ??
        MusicEntry(file: track, metadata: const MusicMetadata());
    final album = entry.album;

    return (
      // U+0000 joins them: not a character a tag can carry, so no
      // album/artist pair can collide with a different one once joined
      // this way, unlike a plain separator a tag might itself contain.
      identity: album == null ? track.uuid : '$album ${entry.artist ?? ''}',
      year: entry.metadata.year,
    );
  }
}
