import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../catalog/domain/music_metadata.dart';
import '../domain/album_medium.dart';
import '../domain/music_grouping.dart';
import '../domain/playback_queue.dart';
import 'music_library_controller.dart';

/// What identifies "which record is playing", as `(kind, identity)`
/// (see [recordOf]).
typedef AlbumIdentity = (Object, String);

/// The record [queue] plays: its identity — what a caller pairs with
/// [PlaybackQueue.kind] to get an [AlbumIdentity] — and the year that picks
/// its medium.
///
/// Shared by `AlbumAnimationController` and `AlbumCoverController` rather
/// than duplicated between them, because the two have to agree on when a
/// track change is still the same record and when it is a new one: if they
/// disagreed, a cover could swap under a case that never re-inserted, or an
/// insertion could play under a cover left over from the record before it
/// (Finding 2). `AlbumCoverController` only ever reads the identity half —
/// it has no use for a year — but calls this all the same, so there is
/// exactly one place either fact is computed.
///
/// For an album or an artist queue, both come from the queue itself: the
/// label alone is not enough for the identity, because `albumOf`/`artistOf`
/// (`music_grouping.dart`) already treat an absent tag as "this file's own
/// group of one" rather than as a shared value — two different untitled
/// albums are not the same record, and folding them together here would
/// silently break that rule for the one consumer that reads `label` as an
/// identity instead of a display string. Falling back to the first track's
/// uuid keeps the tracks of one untagged record identified with each other
/// (the uuid does not change between them) while telling two different
/// untagged records apart (their first tracks differ).
///
/// For a queue that names no record of its own — a lone track, or a playlist
/// (playlists design §6) — both are read from [library] instead, off the
/// track *playing now*: its own album, artist and year, resolved the same way
/// every other surface resolves a track's metadata (`MusicLibrary.entryFor`,
/// design §2, §3). A track with no album tag falls back to its own uuid, the
/// same untagged rule `albumOf` states; one with an album tag identifies by
/// album and album artist together, since two different artists can name an
/// album the same thing — the album artist, so that two tracks of one
/// compilation are the same record here as they are in the browsing area
/// rather than two records with two insertions. `library` is `null` while it
/// has not loaded, or does not hold the track — the fallback entry that
/// answers then has no album and no year, so the identity falls back to the
/// uuid and the medium falls back to a disc, exactly as an unknown record
/// does everywhere else.
///
/// Reading a playlist per track is what makes crossing from one album into
/// the next inside one insert the new medium, while moving between two tracks
/// of the same album does not — the behaviour the design asked for, falling
/// out of the rule already here rather than a second rule beside it. A
/// playlist's own `label` is its name, for the bar to show, and is
/// deliberately not read as an identity: one value standing for the whole
/// playlist would mean no crossing inside it was ever seen.
///
/// Called only once a caller has confirmed [queue] is non-empty, so the
/// `tracks.first` fallback is safe.
({String identity, int? year}) recordOf(
  PlaybackQueue queue,
  MusicLibrary? library,
) {
  if (queue.namesOwnRecord) {
    return (identity: queue.label ?? queue.tracks.first.uuid, year: queue.year);
  }

  // The track playing now, not `tracks.first`: for a single-track queue they
  // are the same file, but a playlist's record changes as it plays through,
  // and reading the first track would pin every one of its records to the
  // one it opened with. `current` is null only for an index past the end,
  // which no caller reaches here — the fallback keeps the read total rather
  // than standing in for a state this is called in.
  final track = queue.current ?? queue.tracks.first;
  final entry =
      library?.entryFor(track) ??
      MusicEntry(file: track, metadata: const MusicMetadata());
  final album = entry.album;

  return (
    // A plain space between them: it keeps an untagged-artist album from
    // reading as the same identity as a different, shorter album name that
    // happens to share a prefix, without needing a character no tag could
    // ever carry.
    identity: album == null ? track.uuid : '$album ${entry.albumArtist ?? ''}',
    year: entry.metadata.year,
  );
}

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
/// Once per track played, which is a deliberate reversal. This owed an
/// insertion only when the *record* changed — a record already on the platter
/// does not need putting on again, which is true of a real one and was the
/// rule here for as long as there was one. What it meant in use is that the
/// animation played once and then never again for the rest of an album, and
/// the player screen it opens stopped opening: the owner asked for it back on
/// every track, and the machine putting the medium in again is the thing they
/// are playing music to watch.
///
/// The record is still what picks the medium (see [recordOf]) — a 1971 album
/// is a record on every one of its tracks — but what an insertion is owed
/// *for* is the track now playing.
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

    // Watched only for a queue whose record is the current track's, which is
    // the only case [recordOf] reads it for.
    final library = queue.namesOwnRecord
        ? null
        : ref.watch(musicLibraryProvider).value;
    final record = recordOf(queue, library);
    final medium = mediumFor(mode, record.year);

    if (medium == null) {
      return const AlbumAnimationState();
    }

    final identity = (queue.kind, _identityOf(queue, record.identity));
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
    // `!queue.isEmpty` guards the read the same way `build`'s own
    // `showsAlbumAnimation` check does: an empty queue's `kind` is still
    // `QueueKind.track` (`PlaybackQueue.empty`'s own definition), so it names
    // no record of its own and would otherwise pass the check below. This is
    // only ever called for a queue an insertion actually played over, so
    // there is nothing to gain from reading `musicLibraryProvider` — and a
    // real risk of building it before a session exists to read a credential
    // from — if that guard were ever skipped.
    final library = !queue.isEmpty && !queue.namesOwnRecord
        ? ref.read(musicLibraryProvider).value
        : null;
    _shownFor = (
      queue.kind,
      _identityOf(queue, recordOf(queue, library).identity),
    );
    state = AlbumAnimationState(medium: state.medium);
  }

  /// What an insertion is owed for: the track playing, falling back to the
  /// record.
  ///
  /// The track's uuid alone would do for every queue that has one, and the
  /// record is kept behind it for the one case that does not — an index past
  /// the end of the queue, where `current` is null and the record is still a
  /// perfectly good answer to "what is this".
  String _identityOf(PlaybackQueue queue, String record) =>
      queue.current?.uuid ?? record;

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
}
