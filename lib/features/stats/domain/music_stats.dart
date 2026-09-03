import 'package:freezed_annotation/freezed_annotation.dart';

part 'music_stats.freezed.dart';

/// What the owner has played most (play history design).
///
/// One object holding every ranking, because the core answers them in one
/// read: four separate reads could each see a different instant and put
/// totals on the screen that disagree with the lists beneath them.
@freezed
abstract class MusicStats with _$MusicStats {
  /// Creates the statistics.
  const factory MusicStats({
    /// Every play ever recorded, including tracks carrying no tags.
    required int totalPlays,

    /// How many distinct tracks those plays are spread across.
    required int distinctTracks,

    /// The oldest and newest play, so the screen can say what period the
    /// numbers cover. Both null when nothing has been played.
    DateTime? firstPlayedAt,
    DateTime? lastPlayedAt,
    @Default([]) List<TrackPlays> topTracks,
    @Default([]) List<ArtistPlays> topArtists,
    @Default([]) List<AlbumPlays> topAlbums,
    @Default([]) List<GenrePlays> topGenres,
  }) = _MusicStats;

  const MusicStats._();

  /// Whether nothing has been played yet.
  ///
  /// Read off the total rather than off the lists: a track played once with
  /// no tags at all fills `topTracks` and none of the others, and that is a
  /// library with listening in it, not an empty one.
  bool get isEmpty => totalPlays == 0;
}

/// One track in the ranking.
@freezed
abstract class TrackPlays with _$TrackPlays {
  /// Creates a row.
  const factory TrackPlays({
    required String fileUuid,

    /// Its title, or its filename when nothing tagged it — the core has
    /// already made that substitution, so this is never empty.
    required String title,
    required int plays,
    required DateTime lastPlayedAt,
    String? artist,
    String? album,
  }) = _TrackPlays;
}

/// One artist in the ranking, credited by album artist where a track
/// carries one.
@freezed
abstract class ArtistPlays with _$ArtistPlays {
  /// Creates a row.
  const factory ArtistPlays({
    required String artist,
    required int plays,

    /// How many distinct tracks of theirs were played — what tells a deep
    /// catalogue apart from one song on repeat.
    required int tracks,
  }) = _ArtistPlays;
}

/// One album in the ranking.
@freezed
abstract class AlbumPlays with _$AlbumPlays {
  /// Creates a row.
  const factory AlbumPlays({
    required String album,
    required int plays,

    /// Whose album it is, when every played track that names an artist
    /// agrees. Null for a compilation whose tracks disagree — there is no
    /// single answer, and naming one of them would be picking arbitrarily.
    String? artist,
  }) = _AlbumPlays;
}

/// One genre in the ranking.
@freezed
abstract class GenrePlays with _$GenrePlays {
  /// Creates a row.
  const factory GenrePlays({required String genre, required int plays}) =
      _GenrePlays;
}
