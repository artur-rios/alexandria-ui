import '../../catalog/domain/catalog_file.dart';

/// What the owner asked to play (UC-20 main flow step 1).
enum QueueKind {
  /// One track.
  track,

  /// Every track on an album, in order.
  album,

  /// Every track by an artist.
  artist,

  /// A playlist the owner assembled, in the order they arranged it
  /// (playlists design section 6).
  playlist,
}

/// The tracks queued for playback, and where in them playback is
/// (FR-PL-06).
class PlaybackQueue {
  /// Creates a queue over [tracks], starting at [index].
  const PlaybackQueue({
    required this.tracks,
    required this.kind,
    this.label,
    this.year,
    this.index = 0,
    this.skipped = const [],
  });

  /// An empty queue, which is what stopping leaves behind.
  static const PlaybackQueue empty = PlaybackQueue(
    tracks: [],
    kind: QueueKind.track,
  );

  /// The tracks, in the order they will play.
  final List<CatalogFile> tracks;

  /// What the owner asked for (UC-20 main flow step 1). The animation no
  /// longer reads this to decide whether it shows (see [showsAlbumAnimation]):
  /// a track, an album and an artist all own the same rule now.
  final QueueKind kind;

  /// The album or artist name, or `null` — for a single track, where the
  /// presentation layer shows the track's own title beside this label
  /// instead; for an album or an artist whose tags name none, where an
  /// absent label means the *tag* is absent (FR-CT-13). Neither the
  /// application layer that builds this queue nor this domain class has the
  /// localized strings to turn that absence into a word, so this class only
  /// carries it; the presentation layer decides what to say.
  final String? label;

  /// The year the album carries, which is what picks the medium the animation
  /// shows (UC-21, FR-PL-07).
  final int? year;

  /// Which track is playing.
  final int index;

  /// The tracks that could not be played, in the order they were skipped
  /// (AF-01, AF-02).
  final List<CatalogFile> skipped;

  /// Whether there is anything queued at all.
  bool get isEmpty => tracks.isEmpty;

  /// The track playing now, or `null` when the queue is empty or finished.
  CatalogFile? get current =>
      index >= 0 && index < tracks.length ? tracks[index] : null;

  /// Whether there is a track after this one.
  bool get hasNext => index + 1 < tracks.length;

  /// Whether there is a track before this one.
  bool get hasPrevious => index > 0;

  /// Whether every queued track was skipped (AF-03).
  bool get everythingFailed =>
      tracks.isNotEmpty && skipped.length == tracks.length;

  /// A copy with the given changes.
  PlaybackQueue copyWith({
    List<CatalogFile>? tracks,
    QueueKind? kind,
    String? label,
    int? year,
    int? index,
    List<CatalogFile>? skipped,
  }) => PlaybackQueue(
    tracks: tracks ?? this.tracks,
    kind: kind ?? this.kind,
    label: label ?? this.label,
    year: year ?? this.year,
    index: index ?? this.index,
    skipped: skipped ?? this.skipped,
  );

  /// Whether the record playing is the queue's own, rather than the current
  /// track's (playlists design section 6).
  ///
  /// An album or an artist queue *is* a record: it carries the label and the
  /// year that identify it, every track in it belongs to the same one, and
  /// `recordOf` reads both straight off this class.
  ///
  /// A track queue and a playlist queue are not. A lone track's record is
  /// whatever that track's own tags say it is, resolved from the music
  /// library; a playlist's is the same question asked again on every track,
  /// because a playlist deliberately names no record of its own — which is
  /// what makes crossing from one album to the next inside one insert the new
  /// medium while skipping within an album does not. A playlist's [label] is
  /// its name, for the bar to show; it is never its record's identity.
  ///
  /// Named here, once, rather than left as a `kind == QueueKind.track` check
  /// repeated at each of the four places that ask: `recordOf` and the two
  /// controllers that call it have to agree on this or a cover swaps under a
  /// record that never re-inserted, and a fifth kind added later would
  /// otherwise have to be remembered at every one of them.
  bool get namesOwnRecord => switch (kind) {
    QueueKind.album || QueueKind.artist => true,
    QueueKind.track || QueueKind.playlist => false,
  };

  /// Whether this queue is one the animation belongs to (UC-21 main flow).
  ///
  /// Anything with tracks queued: a lone track is a record too — its own
  /// album and artist, resolved from the music library by
  /// `AlbumAnimationController` — so the only queue that owes no animation is
  /// one with nothing in it at all.
  bool get showsAlbumAnimation => tracks.isNotEmpty;

  /// The queue with [file] recorded as unplayable (AF-01, AF-02).
  PlaybackQueue skipping(CatalogFile file) =>
      copyWith(skipped: [...skipped, file]);
}
