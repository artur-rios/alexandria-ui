import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../catalog/domain/catalog_file.dart';
import '../../catalog/domain/music_metadata.dart';
import '../../stats/domain/play_threshold.dart';
import '../domain/media_player.dart';
import '../domain/music_grouping.dart';
import '../domain/playback_position_store.dart';
import '../domain/playback_queue.dart';
import '../domain/playback_session.dart';
import '../domain/playback_source.dart';

/// Where audio playback is (UC-20).
enum AudioStage {
  /// Nothing is queued.
  idle,

  /// The queue is being built, or a track is being opened.
  starting,

  /// A track is open, whether running or paused.
  playing,

  /// A resume position exists for a single track and the owner has not
  /// answered yet (AF-04).
  offeringResume,

  /// Nothing in the selection could be played (AF-03).
  allFailed,
}

/// The audio player's state (UC-20).
class AudioPlaybackState {
  /// Creates a state.
  const AudioPlaybackState({
    this.queue = PlaybackQueue.empty,
    this.stage = AudioStage.idle,
    this.status = const PlaybackStatus(),
    this.resumeFrom,
    this.lastSkipped,
  });

  /// What is queued and where playback is in it.
  final PlaybackQueue queue;

  /// Where the player is.
  final AudioStage stage;

  /// What the engine last reported.
  final PlaybackStatus status;

  /// The position the owner is being offered (AF-04).
  final Duration? resumeFrom;

  /// The track most recently skipped (AF-01, AF-02).
  ///
  /// Named rather than counted, because "one track was skipped" tells the
  /// owner nothing about which of their files to go and look at.
  final CatalogFile? lastSkipped;

  /// The track playing now, or `null`.
  CatalogFile? get current => queue.current;

  /// Whether anything is queued.
  bool get isActive => stage != AudioStage.idle;

  /// Whether the engine is running.
  bool get isPlaying => status.isPlaying;

  /// A copy with the given changes.
  ///
  /// [resumeFrom] and the skip report are cleared rather than carried whenever
  /// they are not given: each belongs to one moment.
  AudioPlaybackState copyWith({
    PlaybackQueue? queue,
    AudioStage? stage,
    PlaybackStatus? status,
    Duration? resumeFrom,
    CatalogFile? lastSkipped,
  }) => AudioPlaybackState(
    queue: queue ?? this.queue,
    stage: stage ?? this.stage,
    status: status ?? this.status,
    resumeFrom: resumeFrom,
    lastSkipped: lastSkipped,
  );
}

/// What [AudioPlaybackController._playGrouped] gathers a queue for.
///
/// Not [QueueKind]: that type also has `track` and `playlist`, and
/// [_playGrouped] is never called for either — [playTrack] and [playPlaylist]
/// build their queues directly, from a file and from a curated order
/// respectively, without gathering anything from the library.
///
/// A two-value type rules those arms out at the call site instead of leaving
/// switch cases that could never run.
enum _GroupKind {
  /// An album.
  album,

  /// An artist.
  artist,
}

/// The player outlives the screen the owner started it from (FR-PL-05), which
/// is why the queue and the engine live here and the player bar is only a view
/// of them.
class AudioPlaybackController extends Notifier<AudioPlaybackState> {
  /// How often, at most, a resume position is written while playing.
  static const Duration positionWriteInterval = Duration(seconds: 5);

  StreamSubscription<PlaybackStatus>? _statuses;
  DateTime _lastWrite = DateTime.fromMillisecondsSinceEpoch(0);

  /// Whether the track now open has already been counted as played (play
  /// history design).
  ///
  /// Cleared every time a track opens, which is what makes a track played
  /// twice two plays rather than one — the same record put on again is the
  /// listening the rankings exist to count. It also keeps the status stream,
  /// which reports several times a second, from writing a row each time it
  /// passes the threshold.
  bool _playCounted = false;

  /// Which run of [_openAt] is the current one.
  ///
  /// Every call takes the next number and abandons itself the moment a later
  /// call takes one, which settles two things at once. Two opens can overlap
  /// — [_openAt] awaits a source resolve and the engine, and the queue index
  /// is written before either — so the end of a track landing while the owner
  /// presses next, or next pressed twice, had both runs stepping the same
  /// queue and the player jumping a track. And when the overlap is deliberate
  /// — a new album started while a track is still opening — the newest ask is
  /// the one the owner means, so it is the older run that gives way.
  int _openGeneration = 0;

  MediaPlayer get _player => ref.read(audioPlayerProvider);
  PlaybackPositionStore get _positions => ref.read(playbackPositionsProvider);

  @override
  AudioPlaybackState build() {
    ref.onDispose(() => unawaited(_statuses?.cancel()));
    return const AudioPlaybackState();
  }

  /// Plays [file] on its own (main flow step 1).
  ///
  /// AF-04: a single track with a resume position asks before it starts. An
  /// album does not — the question is about one file, and an album is a
  /// sequence.
  Future<void> playTrack(CatalogFile file) async {
    await _stopOtherMedia();

    final resume = _positions.positionFor(file.uuid);
    if (resume != null && resume.position > Duration.zero) {
      state = AudioPlaybackState(
        queue: PlaybackQueue(tracks: [file], kind: QueueKind.track),
        stage: AudioStage.offeringResume,
        resumeFrom: resume.position,
      );
      return;
    }

    await _playQueue(
      PlaybackQueue(tracks: [file], kind: QueueKind.track),
      at: Duration.zero,
    );
  }

  /// Plays the album [file] belongs to (main flow steps 1 and 3).
  ///
  /// [shuffled] plays the same tracks in an order nobody chose (FR-PL-06):
  /// the record, out of order, which is the one thing a shuffle is for.
  Future<void> playAlbum(CatalogFile file, {bool shuffled = false}) =>
      _playGrouped(file, _GroupKind.album, shuffled: shuffled);

  /// Plays everything by [file]'s artist (main flow steps 1 and 3).
  Future<void> playArtist(CatalogFile file, {bool shuffled = false}) =>
      _playGrouped(file, _GroupKind.artist, shuffled: shuffled);

  /// Plays the whole audio library in an order nobody chose (FR-PL-06).
  ///
  /// [label] is what the bar calls it, passed in for the reason
  /// [playPlaylist]'s name is: this is application code with no
  /// `AppLocalizations` to name anything, and a label written here would be
  /// in one language for every owner.
  ///
  /// Every audio file the library holds, not the view the owner is looking
  /// at: "shuffle everything" said while standing in one artist would
  /// otherwise mean something different from the same words said in Songs,
  /// and neither reading is written anywhere an owner could check.
  Future<void> playEverythingShuffled({required String label}) async {
    await _stopOtherMedia();

    state = state.copyWith(stage: AudioStage.starting);

    final List<MusicEntry> library;
    try {
      library = (await ref.read(musicLibraryProvider.future)).entries;
    } on Object {
      // The catalog could not be asked, so there is nothing to shuffle —
      // reported the same way a group that could not be gathered is.
      state = const AudioPlaybackState(stage: AudioStage.allFailed);
      return;
    }

    if (library.isEmpty) return;

    await _playQueue(
      PlaybackQueue(
        tracks: _shuffled([for (final entry in library) entry.file]),
        // A playlist, because that is what it is: a sequence with a name and
        // no record of its own, so the player resolves the record from
        // whichever track is playing rather than pinning the whole shuffle to
        // whatever came out first.
        kind: QueueKind.playlist,
        label: label,
      ),
      at: Duration.zero,
    );
  }

  /// Plays [tracks], in the order given, as the playlist called [name]
  /// (playlists design section 6).
  ///
  /// Not [_playGrouped]: nothing is gathered here. The order *is* the thing
  /// the owner curated, so it is taken exactly as handed over and the music
  /// library is never consulted to build the queue — which also means a
  /// playlist plays even while the library listing is unavailable.
  ///
  /// [name] rides along as the queue's label, for the bar to show. It is not
  /// the record's identity: a playlist names no record of its own, so
  /// `recordOf` resolves that from whichever track is playing (see
  /// [PlaybackQueue.namesOwnRecord]).
  ///
  /// No year, and no resume offer. A playlist is a sequence, and AF-04 asks
  /// its question about one file — the same reason an album does not ask it.
  ///
  /// Entries whose files are missing are queued like any other: whether a
  /// file opens is the resolve's answer, and [_openAt] already names and
  /// steps over the ones that do not (AF-01), ending in AF-03 when none of
  /// them does. Filtering them out here would be a second opinion about what
  /// is playable, would disagree with a stale missing flag in both
  /// directions, and would cost the owner the report naming which file was
  /// stepped over.
  Future<void> playPlaylist({
    required String name,
    required List<CatalogFile> tracks,
    bool shuffled = false,
  }) async {
    // Nothing was asked to play, which is not AF-03 — there, tracks were
    // tried and every one failed. Whatever is playing keeps playing, and an
    // empty queue never reaches `_openAt`, which would otherwise leave the
    // player parked in `starting` with nothing to open.
    if (tracks.isEmpty) return;

    await _stopOtherMedia();

    await _playQueue(
      PlaybackQueue(
        tracks: shuffled ? _shuffled(tracks) : tracks,
        kind: QueueKind.playlist,
        label: name,
      ),
      at: Duration.zero,
    );
  }

  /// Answers AF-04 by resuming where playback stopped.
  Future<void> resume() async {
    final at = state.resumeFrom;
    if (at == null) return;

    await _playQueue(state.queue, at: at);
  }

  /// Answers AF-04 by playing from the beginning.
  Future<void> startOver() async {
    final file = state.queue.current;
    if (file == null) return;

    await _positions.forget(file.uuid);
    await _playQueue(state.queue, at: Duration.zero);
  }

  /// Pauses or resumes (main flow step 6).
  Future<void> togglePlaying() async {
    if (state.stage != AudioStage.playing) return;

    if (state.isPlaying) {
      await _player.pause();
      await _recordPosition(force: true);
    } else {
      await _player.play();
    }
  }

  /// Moves playback to [position] within the track playing (FR-PL-12).
  ///
  /// Bounded here rather than trusted from the caller: the slider on the
  /// player hands over a fraction of a duration the engine reported, and a
  /// duration that has since changed — a track that ended, a queue that moved
  /// on — would otherwise be a seek past the end of whatever is playing now.
  ///
  /// The resume position is written straight away. A seek is the owner saying
  /// where they are in the track, and a session that ended before the next
  /// periodic write would otherwise come back to where they were before it.
  Future<void> seekTo(Duration position) async {
    if (state.stage != AudioStage.playing) return;

    final duration = state.status.duration;
    final bounded = switch (position) {
      final at when at < Duration.zero => Duration.zero,
      final at when duration != null && at > duration => duration,
      final at => at,
    };

    await _player.seek(bounded);
    await _recordPosition(force: true);
  }

  /// Moves to the next track in the queue (main flow step 6, FR-PL-06).
  Future<void> next() async {
    if (!state.queue.hasNext) return;

    await _openAt(state.queue.index + 1);
  }

  /// Moves to the previous track (main flow step 6, FR-PL-06).
  Future<void> previous() async {
    if (!state.queue.hasPrevious) return;

    await _openAt(state.queue.index - 1);
  }

  /// Stops and clears the queue (main flow step 7).
  Future<void> stop() async {
    // Any open still in flight gives way, as it does to a newer one. Without
    // this it would come back from its await after the queue was cleared and
    // set the player playing again — a stop the owner asked for, undone a
    // moment later by work that was already running.
    _openGeneration++;

    await _recordPosition(force: true);
    unawaited(_statuses?.cancel());
    _statuses = null;
    await _player.stop();
    state = const AudioPlaybackState();
  }

  /// Stops because another medium is starting (AF-05, FR-PL-08).
  Future<void> stopForOtherMedium() async {
    if (!state.isActive) return;
    await stop();
  }

  /// Clears the report of a skipped track once the owner has seen it.
  void acknowledgeSkip() => state = state.copyWith();

  /// Clears the report that nothing in the selection could be played (AF-03).
  ///
  /// The queue was already cleared when the report was raised; this is the
  /// owner saying they have read it. Without it the bar carried the message
  /// for the rest of the session.
  void acknowledgeAllFailed() => state = const AudioPlaybackState();

  /// Builds and plays an album or artist queue.
  ///
  /// [kind] is [_GroupKind] rather than [QueueKind]: [playTrack] builds a
  /// single-track queue directly and never calls this, so a `QueueKind.track`
  /// arm here would be dead code that reads as if single-track playback
  /// waited on the whole library too. Narrowing the parameter's type rules
  /// that reading out at the call site instead of a runtime check.
  Future<void> _playGrouped(
    CatalogFile file,
    _GroupKind kind, {
    bool shuffled = false,
  }) async {
    await _stopOtherMedia();

    state = state.copyWith(stage: AudioStage.starting);

    final List<MusicEntry> library;
    try {
      library = (await ref.read(musicLibraryProvider.future)).entries;
    } on Object {
      // AF-03: the catalog itself could not be asked, so no album or artist
      // grouping is knowable — there is nothing this can queue. Reported
      // through the same stage the bar already renders as "nothing in the
      // selection could be played" rather than left parked in `starting`
      // forever: a queue built by falling back to the single track the
      // owner asked for would silently turn "play the album" into "play the
      // track" without ever saying so, which is worse than telling them the
      // catalog could not be reached.
      //
      // lastSkipped stays null on purpose: nothing was ever attempted here —
      // the listing itself failed before any track was resolved — so naming
      // [file] as skipped would claim a specific track failed to play, which
      // did not happen and may not even be true of that file. That field is
      // for a track _openAt actually tried and actually failed; this is a
      // different failure; and it shows a second, contradictory banner
      // ("Skipped … it could not be played") stacked on this one otherwise.
      state = const AudioPlaybackState(stage: AudioStage.allFailed);
      return;
    }

    final entry = library.firstWhere(
      (candidate) => candidate.file.uuid == file.uuid,
      // A file the library index does not hold is still playable on its own.
      orElse: () => MusicEntry(file: file, metadata: const MusicMetadata()),
    );

    final gathered = switch (kind) {
      _GroupKind.album => albumOf(entry, library),
      _GroupKind.artist => artistOf(entry, library),
    };
    final tracks = shuffled ? _shuffled(gathered) : gathered;

    // Never the file name (FR-CT-13): an absent tag is carried as `null`
    // rather than defaulting to `file.name` here, because this is
    // application code with no `AppLocalizations` to turn that absence into
    // the right word. That decision belongs to whichever presentation site
    // renders the label — see `queueLabelOf` in `music_display_name.dart`.
    final label = switch (kind) {
      _GroupKind.album => entry.album,
      // The album artist, because `artistOf` above gathered the queue by it:
      // a label naming the guest performer would title a queue of the host's
      // whole catalog after one track's guest.
      _GroupKind.artist => entry.albumArtist,
    };

    // Starting where the owner started, not at the top: they picked this
    // track, and an album started from track seven begins at seven.
    //
    // Except when shuffled, which begins at the top of the order the shuffle
    // made: starting a shuffle at the track the owner happened to right-click
    // would make the first track the one predictable thing about it.
    final startIndex = shuffled
        ? 0
        : tracks.indexWhere((candidate) => candidate.uuid == file.uuid);

    await _playQueue(
      PlaybackQueue(
        tracks: tracks,
        kind: switch (kind) {
          _GroupKind.album => QueueKind.album,
          _GroupKind.artist => QueueKind.artist,
        },
        label: label,
        // What UC-21 picks the medium from.
        year: entry.metadata.year,
        index: startIndex < 0 ? 0 : startIndex,
      ),
      at: Duration.zero,
    );
  }

  /// The same tracks in an order nobody chose (FR-PL-06).
  ///
  /// A copy, never the list it was given: the caller's list is the library's
  /// own order (or a playlist's curated one), and shuffling it in place would
  /// reorder what every other reader of it sees.
  ///
  /// The source of randomness comes from a provider so a test can pin it. A
  /// shuffle nobody can reproduce is a shuffle nobody can test: with a seeded
  /// source, "these are the same tracks in a different order" is an assertion
  /// rather than a hope.
  List<CatalogFile> _shuffled(List<CatalogFile> tracks) =>
      [...tracks]..shuffle(ref.read(shuffleRandomProvider));

  /// Stops any other medium (main flow step 2, FR-PL-08).
  Future<void> _stopOtherMedia() async {
    for (final session in ref.read(playbackSessionsProvider)) {
      if (session.medium != PlaybackMedium.audio && session.isActive) {
        await session.stop();
      }
    }
  }

  /// Opens [queue] at its current index, [at] into the track.
  Future<void> _playQueue(PlaybackQueue queue, {required Duration at}) async {
    state = state.copyWith(queue: queue, stage: AudioStage.starting);
    _listenToEngine();
    await _openAt(queue.index, at: at);
  }

  /// Opens the track at [index], skipping past anything that will not play.
  ///
  /// AF-01 and AF-02 are the same movement from the player's side — a file it
  /// cannot open, named and stepped over — and AF-03 is what happens when that
  /// movement runs out of queue.
  Future<void> _openAt(int index, {Duration at = Duration.zero}) async {
    final generation = ++_openGeneration;

    var queue = state.queue.copyWith(index: index);
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, so nothing can be opened — and the player is cleared rather
    // than left in `starting`, which is a spinner with nothing behind it for
    // the rest of the session. The same answer the rejected-session arm below
    // gives, because it is the same situation reached a moment earlier.
    if (credential == null) {
      state = const AudioPlaybackState();
      return;
    }

    // Carried across the loop rather than read back out of the state: every
    // step of it replaces the state, and the owner is owed the name of the
    // file that was skipped even once the queue has moved past it.
    var skipped = state.lastSkipped;

    while (queue.current != null) {
      if (generation != _openGeneration) return;

      final file = queue.current!;
      state = state.copyWith(
        queue: queue,
        stage: AudioStage.starting,
        lastSkipped: skipped,
      );

      final outcome = await ref
          .read(playbackSourceGatewayProvider)
          .resolve(uuid: file.uuid, credential: credential);

      if (generation != _openGeneration) return;

      switch (outcome) {
        case PlaybackSourceResolved(:final source):
          // [at] belongs to the track that was asked for, not to whichever
          // one the queue reached after stepping over the ones that would not
          // open: a resume offer is about one file, and carrying its offset
          // onto a different track would start that one part-way through for
          // no reason the owner could see.
          await _player.open(
            source.path,
            startAt: queue.index == index ? at : Duration.zero,
          );
          // A different track, or the same one again: either way this is a
          // playthrough that has not been counted yet.
          _playCounted = false;
          state = state.copyWith(
            queue: queue,
            stage: AudioStage.playing,
            status: _player.currentStatus,
            lastSkipped: skipped,
          );
          return;

        // A rejected session returns the owner to login, as everywhere else.
        case PlaybackSourceFailed(failure: final UnauthorizedFailure failure):
          ref.read(sessionControllerProvider.notifier).invalidate(failure);
          state = const AudioPlaybackState();
          return;

        // AF-01 and AF-02: named, stepped over, and the queue carries on.
        //
        // The failure itself is not kept. Why a track would not open is the
        // same answer for every skip the queue makes, so the bar names the
        // file and says no more — see `_SkipNotice` in `playback_bar.dart`,
        // which is where that decision is recorded.
        case PlaybackSourceFailed():
          queue = queue.skipping(file);
          skipped = file;
          state = state.copyWith(queue: queue, lastSkipped: skipped);

          if (!queue.hasNext) {
            // AF-03: nothing in the selection could be played. The queue is
            // cleared, because there is nothing left in it to come back to.
            state = AudioPlaybackState(
              stage: AudioStage.allFailed,
              lastSkipped: skipped,
            );
            return;
          }

          queue = queue.copyWith(index: queue.index + 1);
      }
    }
  }

  /// Follows the engine, which is where AF-02 and the end of a track arrive
  /// from.
  void _listenToEngine() {
    unawaited(_statuses?.cancel());

    _statuses = _player.status.listen((status) async {
      // AF-02: the engine could not decode this one. Skipped like a missing
      // file, and the queue carries on (FR-PL-10).
      if (status.failedToDecode) {
        final file = state.queue.current;
        if (file == null) return;

        final queue = state.queue.skipping(file);
        state = state.copyWith(queue: queue, lastSkipped: file);

        if (queue.hasNext) {
          await _openAt(queue.index + 1);
        } else {
          state = AudioPlaybackState(
            stage: AudioStage.allFailed,
            lastSkipped: file,
          );
        }
        return;
      }

      state = state.copyWith(status: status, lastSkipped: state.lastSkipped);

      if (status.hasEnded) {
        // Heard to the end, so it is a play whatever its length — counted
        // before the queue moves on, while the finished track is still the
        // current one.
        _countPlay();

        // Step 7: a track played through leaves no position, and the queue
        // moves on — or ends.
        unawaited(_forgetPosition());
        if (state.queue.hasNext) {
          await _openAt(state.queue.index + 1);
        } else {
          state = const AudioPlaybackState();
        }
        return;
      }

      // Half of it, or four minutes — the point at which a track the owner
      // moved on from still counts (`countsAsPlayed`). Checked on the status
      // stream rather than only at the end, because a track skipped after
      // most of it was heard was listened to.
      if (countsAsPlayed(
        position: status.position,
        duration: status.duration,
      )) {
        _countPlay();
      }

      unawaited(_recordPosition());
    });
  }

  /// Records a play of the open track, at most once per time it opened.
  ///
  /// Fire-and-forget: the recorder never throws, and nothing the owner is
  /// doing waits on a statistic being written. The flag is set before the
  /// call rather than after it, so the several statuses that arrive while
  /// the write is in flight cannot each start one of their own.
  void _countPlay() {
    if (_playCounted) return;

    final file = state.queue.current;
    if (file == null) return;

    _playCounted = true;
    unawaited(ref.read(playRecorderProvider).record(file.uuid));
  }

  Future<void> _forgetPosition() async {
    final file = state.queue.current;
    if (file == null) return;

    await _positions.forget(file.uuid);
  }

  /// Writes where playback is (FR-PL-09).
  Future<void> _recordPosition({bool force = false}) async {
    final file = state.queue.current;
    if (file == null || state.stage != AudioStage.playing) return;

    final position = state.status.position;
    if (position <= Duration.zero) return;

    final now = ref.read(clockProvider)();
    if (!force && now.difference(_lastWrite) < positionWriteInterval) return;
    _lastWrite = now;

    await _positions.record(
      PlaybackPosition(
        fileUuid: file.uuid,
        position: position,
        duration: state.status.duration,
        updatedAt: now,
      ),
    );
  }
}
