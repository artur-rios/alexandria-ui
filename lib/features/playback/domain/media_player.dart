/// One selectable track inside a media file (FR-PL-03, FR-PL-04).
class MediaTrack {
  /// Creates a track.
  const MediaTrack({required this.id, this.title, this.language});

  /// The engine's identifier for it, which is what selecting one carries.
  final String id;

  /// What the file calls it, when it says.
  final String? title;

  /// Its language tag, when the file carries one.
  final String? language;
}

/// What the engine is doing, as the interface needs to know it.
class PlaybackStatus {
  /// Creates a status.
  const PlaybackStatus({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration,
    this.hasEnded = false,
    this.failedToDecode = false,
    this.subtitleTracks = const [],
    this.audioTracks = const [],
    this.selectedSubtitleId,
    this.selectedAudioId,
  });

  /// Whether audio or video is currently running.
  final bool isPlaying;

  /// Where playback is, which is what a resume position is written from
  /// (FR-PL-09).
  final Duration position;

  /// How long the file is, once the engine has worked it out.
  final Duration? duration;

  /// Whether playback reached the end of the file.
  final bool hasEnded;

  /// Whether the engine could not decode the file (AF-02, FR-PL-10).
  final bool failedToDecode;

  /// The subtitle tracks the file provides (FR-PL-03).
  ///
  /// Empty is an answer, not an absence: AF-03 requires the control to say
  /// that none is available rather than to disappear.
  final List<MediaTrack> subtitleTracks;

  /// The audio tracks the file provides (FR-PL-04).
  final List<MediaTrack> audioTracks;

  /// The subtitle track in use, or `null` for subtitles off (FR-PL-03).
  final String? selectedSubtitleId;

  /// The audio track in use.
  final String? selectedAudioId;

  /// A copy with the given changes.
  ///
  /// [clearSubtitle] is how subtitles are turned off: the selected track is
  /// nullable and "leave it alone" and "set it to none" cannot otherwise be
  /// told apart (FR-PL-03).
  PlaybackStatus copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? hasEnded,
    bool? failedToDecode,
    List<MediaTrack>? subtitleTracks,
    List<MediaTrack>? audioTracks,
    String? selectedSubtitleId,
    bool clearSubtitle = false,
    String? selectedAudioId,
  }) => PlaybackStatus(
    isPlaying: isPlaying ?? this.isPlaying,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    hasEnded: hasEnded ?? this.hasEnded,
    failedToDecode: failedToDecode ?? this.failedToDecode,
    subtitleTracks: subtitleTracks ?? this.subtitleTracks,
    audioTracks: audioTracks ?? this.audioTracks,
    selectedSubtitleId: clearSubtitle
        ? selectedSubtitleId
        : selectedSubtitleId ?? this.selectedSubtitleId,
    selectedAudioId: selectedAudioId ?? this.selectedAudioId,
  );
}

/// The playback engine, as the application uses it (IR-02).
///
/// Behind an interface for the usual reason and one more: the engine is a
/// native library that cannot run in a widget test, so every flow above this
/// line is testable only because this line exists.
abstract interface class MediaPlayer {
  /// What the engine is doing, as it changes.
  Stream<PlaybackStatus> get status;

  /// The last status the engine reported.
  PlaybackStatus get currentStatus;

  /// Opens [path] and begins playing from [startAt] (FR-PL-01, FR-PL-05).
  Future<void> open(String path, {Duration startAt = Duration.zero});

  /// Resumes (FR-PL-02).
  Future<void> play();

  /// Pauses, leaving the position where it is (FR-PL-02).
  Future<void> pause();

  /// Moves playback to [position] (FR-PL-02).
  Future<void> seek(Duration position);

  /// Stops playback and releases the file.
  Future<void> stop();

  /// Selects a subtitle track, or turns subtitles off with `null`
  /// (FR-PL-03).
  Future<void> selectSubtitle(String? trackId);

  /// Selects an audio track (FR-PL-04).
  Future<void> selectAudio(String trackId);

  /// Releases the engine.
  Future<void> dispose();
}
