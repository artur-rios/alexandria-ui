import 'dart:async';

import 'package:alexandria_ui/features/playback/domain/media_player.dart';

/// A [MediaPlayer] that never loads libmpv (Testing Specification §2.3).
///
/// The engine is a native library, so this is what makes every flow around it
/// testable: the tests drive what the engine would have reported, and assert
/// what the application did with it.
class FakeMediaPlayer implements MediaPlayer {
  final StreamController<PlaybackStatus> _statuses =
      StreamController<PlaybackStatus>.broadcast();

  PlaybackStatus _status = const PlaybackStatus();

  /// Every path opened, in order.
  final List<String> opened = [];

  /// The position each open started from.
  final List<Duration> startedAt = [];

  /// Every seek asked for, in order.
  final List<Duration> seeks = [];

  /// Every subtitle selection, in order. `null` is subtitles off.
  final List<String?> subtitleSelections = [];

  /// Every audio-track selection, in order.
  final List<String> audioSelections = [];

  /// How many times playback was stopped.
  int stopCount = 0;

  /// How many times it was paused and resumed.
  int pauseCount = 0;

  /// How many times it was resumed.
  int playCount = 0;

  @override
  Stream<PlaybackStatus> get status => _statuses.stream;

  @override
  PlaybackStatus get currentStatus => _status;

  /// Reports [status] as though the engine had.
  void report(PlaybackStatus status) {
    _status = status;
    _statuses.add(status);
  }

  /// Reports a position, which is what a playing engine does continuously.
  ///
  /// One report is a *jump*, not listening. Anything asserting on how much
  /// of a track was heard — the play history's threshold, most of all —
  /// wants [hearUpTo] instead: a single report from zero to the middle of a
  /// track is the shape of a seek, and the player is entitled to read it as
  /// one.
  void reportPosition(Duration position, {Duration? duration}) => report(
    _status.copyWith(isPlaying: true, position: position, duration: duration),
  );

  /// Plays from the current position up to [position], the way a real engine
  /// does: a run of statuses, each a short step past the last.
  ///
  /// The step is a second, comfortably inside the tolerance the player
  /// credits as playing, so what this reports is heard rather than jumped.
  void hearUpTo(Duration position, {Duration? duration}) {
    const step = Duration(seconds: 1);
    var at = _status.position;

    while (at < position) {
      at = at + step;
      if (at > position) at = position;
      reportPosition(at, duration: duration);
    }
  }

  @override
  Future<void> open(String path, {Duration startAt = Duration.zero}) async {
    opened.add(path);
    startedAt.add(startAt);
    _status = PlaybackStatus(isPlaying: true, position: startAt);
  }

  @override
  Future<void> play() async {
    playCount++;
    report(_status.copyWith(isPlaying: true));
  }

  @override
  Future<void> pause() async {
    pauseCount++;
    report(_status.copyWith(isPlaying: false));
  }

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
    report(_status.copyWith(position: position));
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _status = const PlaybackStatus();
  }

  @override
  Future<void> selectSubtitle(String? trackId) async {
    subtitleSelections.add(trackId);
    report(_status.copyWith(selectedSubtitleId: trackId, clearSubtitle: true));
  }

  @override
  Future<void> selectAudio(String trackId) async {
    audioSelections.add(trackId);
    report(_status.copyWith(selectedAudioId: trackId));
  }

  @override
  Future<void> dispose() async => _statuses.close();
}
