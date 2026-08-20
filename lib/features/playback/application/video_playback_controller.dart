import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/di/providers.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/failure.dart';
import '../../catalog/domain/catalog_file.dart';
import '../domain/media_player.dart';
import '../domain/playback_position_store.dart';
import '../domain/playback_session.dart';
import '../domain/playback_source.dart';

/// Where video playback is (UC-19).
enum VideoStage {
  /// Nothing is open.
  closed,

  /// A resume position exists and the owner has not answered yet (AF-04).
  offeringResume,

  /// The source is being resolved and the file opened (main flow step 3).
  opening,

  /// The file is open, whether running or paused.
  playing,

  /// The file could not be opened or decoded (AF-01, AF-02).
  failed,
}

/// The video player's state (UC-19).
class VideoPlaybackState {
  /// Creates a state.
  const VideoPlaybackState({
    this.file,
    this.stage = VideoStage.closed,
    this.status = const PlaybackStatus(),
    this.resumeFrom,
    this.failure,
    this.isMissing = false,
    this.isFullScreen = false,
  });

  /// The file being played, or `null` when nothing is.
  final CatalogFile? file;

  /// Where playback is.
  final VideoStage stage;

  /// What the engine last reported.
  final PlaybackStatus status;

  /// The position the owner is being offered (AF-04).
  final Duration? resumeFrom;

  /// Why playback could not start (AF-01, AF-02).
  final Failure? failure;

  /// Whether the failure is the file being absent from disk (AF-01).
  ///
  /// Told apart from any other failure because AF-01 offers a re-scan and the
  /// others do not: a codec nobody has is not fixed by indexing again.
  final bool isMissing;

  /// Whether the player fills the window (FR-PL-02).
  final bool isFullScreen;

  /// Whether the player is on screen at all.
  bool get isOpen => stage != VideoStage.closed;

  /// Whether the engine is running (FR-PL-02).
  bool get isPlaying => status.isPlaying;

  /// A copy with the given changes.
  ///
  /// [resumeFrom], [failure], and [isMissing] are cleared rather than carried
  /// whenever they are not given: each belongs to one moment, and a stale one
  /// under a later state would be a lie about what is on screen.
  VideoPlaybackState copyWith({
    CatalogFile? file,
    VideoStage? stage,
    PlaybackStatus? status,
    Duration? resumeFrom,
    Failure? failure,
    bool isMissing = false,
    bool? isFullScreen,
  }) => VideoPlaybackState(
    file: file ?? this.file,
    stage: stage ?? this.stage,
    status: status ?? this.status,
    resumeFrom: resumeFrom,
    failure: failure,
    isMissing: isMissing,
    isFullScreen: isFullScreen ?? this.isFullScreen,
  );
}

/// Drives UC-19: watching a video.
///
/// The engine is behind [MediaPlayer], the file's location behind
/// [PlaybackSourceGateway], and the resume point behind
/// [PlaybackPositionStore] — so what is here is the *order* of those three and
/// what each of their answers means, which is what the flows describe.
class VideoPlaybackController extends Notifier<VideoPlaybackState> {
  /// How often, at most, a resume position is written while playing.
  ///
  /// The engine reports a position several times a second, and a settings
  /// write per report would be thousands of writes an hour for no gain.
  static const Duration positionWriteInterval = Duration(seconds: 5);

  StreamSubscription<PlaybackStatus>? _statuses;
  DateTime _lastWrite = DateTime.fromMillisecondsSinceEpoch(0);

  MediaPlayer get _player => ref.read(videoPlayerProvider);
  PlaybackPositionStore get _positions => ref.read(playbackPositionsProvider);

  @override
  VideoPlaybackState build() {
    ref.onDispose(() => unawaited(_statuses?.cancel()));
    return const VideoPlaybackState();
  }

  /// Opens [file] (main flow steps 1 to 3).
  ///
  /// AF-04: a resume position stops here and asks first, because the answer
  /// decides where the file is opened at.
  Future<void> open(CatalogFile file) async {
    // Main flow step 2 / FR-PL-08: at most one playback session, so every
    // other medium stops before this one starts. Read from the registry
    // rather than by naming the audio player, which UC-20 builds.
    for (final session in ref.read(playbackSessionsProvider)) {
      if (session.medium != PlaybackMedium.video && session.isActive) {
        await session.stop();
      }
    }

    final resume = _positions.positionFor(file.uuid);
    if (resume != null && resume.position > Duration.zero) {
      state = VideoPlaybackState(
        file: file,
        stage: VideoStage.offeringResume,
        resumeFrom: resume.position,
      );
      return;
    }

    await _start(file, at: Duration.zero);
  }

  /// Answers AF-04 by resuming where playback stopped.
  Future<void> resume() async {
    final file = state.file;
    final at = state.resumeFrom;
    if (file == null || at == null) return;

    await _start(file, at: at);
  }

  /// Answers AF-04 by playing from the beginning.
  Future<void> startOver() async {
    final file = state.file;
    if (file == null) return;

    await _positions.forget(file.uuid);
    await _start(file, at: Duration.zero);
  }

  /// Pauses or resumes (main flow step 4, FR-PL-02).
  Future<void> togglePlaying() async {
    if (state.stage != VideoStage.playing) return;

    if (state.isPlaying) {
      await _player.pause();
      // Pausing is a natural moment to write: the owner may close the window
      // from here, and the interval would otherwise lose the last few seconds.
      await _recordPosition(force: true);
    } else {
      await _player.play();
    }
  }

  /// Moves playback by [offset], forward or backward (FR-PL-02).
  Future<void> seekBy(Duration offset) async {
    if (state.stage != VideoStage.playing) return;

    final target = state.status.position + offset;
    final duration = state.status.duration;
    final bounded = switch (target) {
      final position when position < Duration.zero => Duration.zero,
      final position when duration != null && position > duration => duration,
      final position => position,
    };

    await _player.seek(bounded);
  }

  /// Moves playback to [position] (FR-PL-02).
  Future<void> seekTo(Duration position) async {
    if (state.stage != VideoStage.playing) return;
    await _player.seek(position);
  }

  /// Fills the window, or stops doing so (FR-PL-02).
  void toggleFullScreen() =>
      state = state.copyWith(isFullScreen: !state.isFullScreen);

  /// Selects a subtitle track, or turns subtitles off (main flow step 5,
  /// FR-PL-03).
  Future<void> selectSubtitle(String? trackId) =>
      _player.selectSubtitle(trackId);

  /// Selects an audio track (main flow step 6, FR-PL-04).
  Future<void> selectAudio(String trackId) => _player.selectAudio(trackId);

  /// Stops and closes the player (main flow step 7).
  Future<void> close() async {
    await _recordPosition(force: true);
    // Not awaited: cancelling a subscription resolves on a later turn of the
    // loop, and stopping the engine has no reason to wait for it.
    unawaited(_statuses?.cancel());
    _statuses = null;
    await _player.stop();
    state = const VideoPlaybackState();
  }

  /// Stops because another medium is starting (AF-05, FR-PL-08).
  Future<void> stopForOtherMedium() async {
    if (!state.isOpen) return;
    await close();
  }

  /// Resolves the file and opens it at [at] (main flow step 3).
  Future<void> _start(CatalogFile file, {required Duration at}) async {
    state = VideoPlaybackState(file: file, stage: VideoStage.opening);

    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return;

    final outcome = await ref
        .read(playbackSourceGatewayProvider)
        .resolve(uuid: file.uuid, credential: credential);

    switch (outcome) {
      case PlaybackSourceResolved(:final source):
        _listenToEngine();
        await _player.open(source.path, startAt: at);
        state = state.copyWith(
          stage: VideoStage.playing,
          status: _player.currentStatus,
        );

      // AF-01: the record is there and the file is not. Told apart from every
      // other refusal because this one has an answer — index again.
      case PlaybackSourceFailed(failure: DiskFailure() || NotFoundFailure()):
        state = state.copyWith(
          stage: VideoStage.failed,
          failure: outcome.failure,
          isMissing: true,
        );

      // A rejected session returns the owner to login, as everywhere else.
      case PlaybackSourceFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        state = const VideoPlaybackState();

      case PlaybackSourceFailed(:final failure):
        state = state.copyWith(stage: VideoStage.failed, failure: failure);
    }
  }

  /// Follows the engine, which is where AF-02 and step 7 arrive from.
  void _listenToEngine() {
    unawaited(_statuses?.cancel());

    _statuses = _player.status.listen((status) {
      // AF-02: the engine could not decode it. The player says so and the
      // application carries on rather than terminating (FR-PL-10).
      if (status.failedToDecode) {
        state = state.copyWith(
          stage: VideoStage.failed,
          status: status,
          failure: const Failure.unexpected(
            family: CoreStatusFamily.playback,
            code: PLAYBACK_ERR_INVALID_STATE,
          ),
        );
        return;
      }

      state = state.copyWith(status: status);

      // Step 7: reaching the end leaves no position to resume from, and
      // stopping short of it leaves one.
      if (status.hasEnded) {
        unawaited(_forgetPosition());
      } else {
        unawaited(_recordPosition());
      }
    });
  }

  Future<void> _forgetPosition() async {
    final file = state.file;
    if (file == null) return;

    await _positions.forget(file.uuid);
  }

  /// Writes where playback is (FR-PL-09), at most every
  /// [positionWriteInterval] unless [force] says otherwise.
  Future<void> _recordPosition({bool force = false}) async {
    final file = state.file;
    if (file == null || state.stage != VideoStage.playing) return;

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
