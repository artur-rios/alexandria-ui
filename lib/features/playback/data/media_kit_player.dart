import 'dart:async';

import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;

import '../domain/media_player.dart';

/// [MediaPlayer] over media_kit (Technology Stack Document §5).
///
/// Everything media_kit-shaped stops here. Above this line the application
/// knows about a position, a pair of track lists, and whether the file could
/// be decoded — which is why the flows are testable without libmpv.
class MediaKitPlayer implements MediaPlayer {
  /// Wraps a media_kit player.
  MediaKitPlayer([mk.Player? player]) : _player = player ?? mk.Player() {
    _subscriptions.addAll([
      _player.stream.playing.listen((playing) {
        _update(_status.copyWith(isPlaying: playing));
      }),
      _player.stream.position.listen((position) {
        _update(_status.copyWith(position: position));
      }),
      _player.stream.duration.listen((duration) {
        // Zero is media_kit's "not known yet", and reporting it as a duration
        // would make a seek bar that jumps when the real one arrives.
        _update(
          _status.copyWith(
            duration: duration == Duration.zero ? null : duration,
          ),
        );
      }),
      _player.stream.completed.listen((completed) {
        _update(_status.copyWith(hasEnded: completed));
      }),
      _player.stream.tracks.listen((tracks) {
        _update(
          _status.copyWith(
            // media_kit's synthetic "auto" entry is not a track the file
            // provides, and offering it would make AF-03's "none available"
            // unreachable for a file that carries nothing.
            subtitleTracks: [
              for (final track in tracks.subtitle)
                if (track.id != 'auto' && track.id != 'no')
                  MediaTrack(
                    id: track.id,
                    title: track.title,
                    language: track.language,
                  ),
            ],
            audioTracks: [
              for (final track in tracks.audio)
                if (track.id != 'auto' && track.id != 'no')
                  MediaTrack(
                    id: track.id,
                    title: track.title,
                    language: track.language,
                  ),
            ],
          ),
        );
      }),
      // media_kit reports a decode failure on its error stream rather than by
      // throwing from `open`, which is why AF-02 is a status rather than an
      // exception (FR-PL-10).
      _player.stream.error.listen((_) {
        _update(_status.copyWith(failedToDecode: true, isPlaying: false));
      }),
    ]);
  }

  final mk.Player _player;

  /// The controller media_kit's own video widget draws from.
  ///
  /// Created once with the player, because the surface has to outlive any one
  /// file: it is the same window whichever video is open.
  late final mkv.VideoController videoController = mkv.VideoController(_player);
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final StreamController<PlaybackStatus> _statuses =
      StreamController<PlaybackStatus>.broadcast();

  PlaybackStatus _status = const PlaybackStatus();

  @override
  Stream<PlaybackStatus> get status => _statuses.stream;

  @override
  PlaybackStatus get currentStatus => _status;

  @override
  Future<void> open(String path, {Duration startAt = Duration.zero}) async {
    // A fresh status per file: the previous file's tracks and its decode
    // failure say nothing about this one.
    _update(const PlaybackStatus(isPlaying: true));

    await _player.open(mk.Media(path));
    if (startAt > Duration.zero) await _player.seek(startAt);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    _update(const PlaybackStatus());
  }

  @override
  Future<void> selectSubtitle(String? trackId) async {
    final track = trackId == null
        ? mk.SubtitleTrack.no()
        : _player.state.tracks.subtitle.firstWhere(
            (candidate) => candidate.id == trackId,
            orElse: mk.SubtitleTrack.no,
          );

    await _player.setSubtitleTrack(track);
    _update(_status.copyWith(selectedSubtitleId: trackId, clearSubtitle: true));
  }

  @override
  Future<void> selectAudio(String trackId) async {
    final tracks = _player.state.tracks.audio;
    if (tracks.isEmpty) return;

    final track = tracks.firstWhere(
      (candidate) => candidate.id == trackId,
      orElse: () => tracks.first,
    );

    await _player.setAudioTrack(track);
    _update(_status.copyWith(selectedAudioId: track.id));
  }

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _statuses.close();
    await _player.dispose();
  }

  void _update(PlaybackStatus status) {
    _status = status;
    if (!_statuses.isClosed) _statuses.add(status);
  }
}
