import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../catalog/domain/catalog_file.dart';
import '../../catalog/domain/music_metadata.dart';
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
    this.lastSkipReason,
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

  /// Why it was skipped.
  final Failure? lastSkipReason;

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
    Failure? lastSkipReason,
  }) => AudioPlaybackState(
    queue: queue ?? this.queue,
    stage: stage ?? this.stage,
    status: status ?? this.status,
    resumeFrom: resumeFrom,
    lastSkipped: lastSkipped,
    lastSkipReason: lastSkipReason,
  );
}

/// Drives UC-20: listening to a track, an album, or an artist.
///
/// The player outlives the screen the owner started it from (FR-PL-05), which
/// is why the queue and the engine live here and the player bar is only a view
/// of them.
class AudioPlaybackController extends Notifier<AudioPlaybackState> {
  /// How often, at most, a resume position is written while playing.
  static const Duration positionWriteInterval = Duration(seconds: 5);

  StreamSubscription<PlaybackStatus>? _statuses;
  DateTime _lastWrite = DateTime.fromMillisecondsSinceEpoch(0);

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
  Future<void> playAlbum(CatalogFile file) =>
      _playGrouped(file, QueueKind.album);

  /// Plays everything by [file]'s artist (main flow steps 1 and 3).
  Future<void> playArtist(CatalogFile file) =>
      _playGrouped(file, QueueKind.artist);

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

  /// Builds and plays an album or artist queue.
  Future<void> _playGrouped(CatalogFile file, QueueKind kind) async {
    await _stopOtherMedia();

    state = state.copyWith(stage: AudioStage.starting);

    final library = await ref.read(musicLibraryProvider.future);
    final entry = library.firstWhere(
      (candidate) => candidate.file.uuid == file.uuid,
      // A file the library index does not hold is still playable on its own.
      orElse: () => MusicEntry(file: file, metadata: const MusicMetadata()),
    );

    final tracks = switch (kind) {
      QueueKind.album => albumOf(entry, library),
      QueueKind.artist => artistOf(entry, library),
      QueueKind.track => [file],
    };

    final label = switch (kind) {
      QueueKind.album => entry.album ?? file.name,
      QueueKind.artist => entry.artist ?? file.name,
      QueueKind.track => file.name,
    };

    // Starting where the owner started, not at the top: they picked this
    // track, and an album started from track seven begins at seven.
    final startIndex = tracks.indexWhere(
      (candidate) => candidate.uuid == file.uuid,
    );

    await _playQueue(
      PlaybackQueue(
        tracks: tracks,
        kind: kind,
        label: label,
        // What UC-21 picks the medium from.
        year: entry.metadata.year,
        index: startIndex < 0 ? 0 : startIndex,
      ),
      at: Duration.zero,
    );
  }

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
    var queue = state.queue.copyWith(index: index);
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return;

    // Carried across the loop rather than read back out of the state: every
    // step of it replaces the state, and the owner is owed the name of the
    // file that was skipped even once the queue has moved past it.
    var skipped = state.lastSkipped;
    var skipReason = state.lastSkipReason;

    while (queue.current != null) {
      final file = queue.current!;
      state = state.copyWith(
        queue: queue,
        stage: AudioStage.starting,
        lastSkipped: skipped,
        lastSkipReason: skipReason,
      );

      final outcome = await ref
          .read(playbackSourceGatewayProvider)
          .resolve(uuid: file.uuid, credential: credential);

      switch (outcome) {
        case PlaybackSourceResolved(:final source):
          await _player.open(source.path, startAt: at);
          state = state.copyWith(
            queue: queue,
            stage: AudioStage.playing,
            status: _player.currentStatus,
            lastSkipped: skipped,
            lastSkipReason: skipReason,
          );
          return;

        // A rejected session returns the owner to login, as everywhere else.
        case PlaybackSourceFailed(failure: final UnauthorizedFailure failure):
          ref.read(sessionControllerProvider.notifier).invalidate(failure);
          state = const AudioPlaybackState();
          return;

        // AF-01 and AF-02: named, stepped over, and the queue carries on.
        case PlaybackSourceFailed(:final failure):
          queue = queue.skipping(file);
          skipped = file;
          skipReason = failure;
          state = state.copyWith(
            queue: queue,
            lastSkipped: skipped,
            lastSkipReason: skipReason,
          );

          if (!queue.hasNext) {
            // AF-03: nothing in the selection could be played. The queue is
            // cleared, because there is nothing left in it to come back to.
            state = AudioPlaybackState(
              stage: AudioStage.allFailed,
              lastSkipped: skipped,
              lastSkipReason: skipReason,
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

      final skipped = state.lastSkipped;
      final skipReason = state.lastSkipReason;
      state = state.copyWith(
        status: status,
        lastSkipped: skipped,
        lastSkipReason: skipReason,
      );

      if (status.hasEnded) {
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

      unawaited(_recordPosition());
    });
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
