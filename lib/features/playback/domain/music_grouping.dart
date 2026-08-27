import '../../catalog/domain/catalog_file.dart';
import '../../catalog/domain/music_metadata.dart';

/// A tag, trimmed, or `null` when it names nothing.
///
/// The one place blank-or-absent becomes `null` rather than a word — what
/// word to show instead is a presentation decision, which is what `tagOr` in
/// `music_display_name.dart` makes from this. [MusicEntry] uses this same
/// function for its own getters, so there is one trimming rule rather than
/// two that could drift apart.
String? trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// One audio file and the metadata the queue is grouped by (FR-PL-06).
class MusicEntry {
  /// Creates an entry.
  const MusicEntry({required this.file, required this.metadata});

  /// The file itself.
  final CatalogFile file;

  /// What the core holds about it.
  final MusicMetadata metadata;

  /// The album it belongs to, or `null` when it names none.
  String? get album => trimmedOrNull(metadata.album);

  /// The artist, or `null` when it names none.
  ///
  /// Who performed *this track*, which is what a track row shows: on a record
  /// with guests, the guest is the answer, and that is the point of the tag.
  /// It is not what the library is grouped by — see [albumArtist].
  String? get artist => trimmedOrNull(metadata.artist);

  /// Who the record is by, falling back to the performer.
  ///
  /// The one key every grouping and every queue is built from: a compilation
  /// under one album artist is one record rather than one record per
  /// performer, and a guest appearance stays on the host's album.
  ///
  /// The fallback is what makes this safe on a real library. Most files carry
  /// no `ALBUMARTIST` frame at all, and a grouping keyed on the raw field
  /// would empty the Artists list for everyone whose collection predates the
  /// tag. A library with no album-artist tags therefore groups exactly as it
  /// did before the field existed, and every file that has one is grouped
  /// better.
  String? get albumArtist => trimmedOrNull(metadata.albumArtist) ?? artist;

  /// The track's title, or `null` when it names none.
  ///
  /// What a row shows. A file whose tags carry no title has no name in this
  /// application's terms — its name on disk is not one (FR-CT-13).
  String? get title => trimmedOrNull(metadata.title);
}

/// The tracks of [entry]'s album, in track order (main flow step 3).
///
/// A file whose album the core does not name is its own album of one: two
/// untitled files are not the same record, and treating a blank field as a
/// grouping key would queue an owner's whole collection of loose tracks
/// together.
///
/// Keyed by the album's artist rather than the track's, as `albumsIn` is: a
/// queue built from a group has to contain what the group showed, and keying
/// this on the performer would mean pressing play on a compilation queued
/// only the tracks whose performer matched the one started from.
List<CatalogFile> albumOf(MusicEntry entry, List<MusicEntry> library) {
  final album = entry.album;
  if (album == null) return [entry.file];

  final artist = entry.albumArtist;
  final matches = [
    for (final candidate in library)
      // Two different artists can name an album the same thing, so the album
      // is the pair. Exact equality including the absent case: an album whose
      // artist no tag names is its own record, and a permissive `null` arm
      // here would have queued every album of that title — a properly tagged
      // artist's record included — under a group that listed only the
      // untagged files. `tracksOfAlbum` has always matched exactly; this is
      // the same rule, so for a *titled* album a queue holds what the group
      // showed. The untitled album is the documented exception above: it is
      // this file's own record of one, where `albumsIn` gathers an artist's
      // untitled tracks together.
      if (candidate.album == album && candidate.albumArtist == artist)
        candidate,
  ];

  return _inTrackOrder(matches);
}

/// Every track by [entry]'s album artist, album by album (main flow step 3).
///
/// The album artist, so that what an artist queue plays is what the Artists
/// list showed under that name — including the guest tracks on their records.
List<CatalogFile> artistOf(MusicEntry entry, List<MusicEntry> library) {
  final artist = entry.albumArtist;
  if (artist == null) return [entry.file];

  final matches = [
    for (final candidate in library)
      if (candidate.albumArtist == artist) candidate,
  ];

  // Grouped by album and ordered within it, because an artist's tracks played
  // in file-name order is not how anyone listens to them.
  matches.sort((a, b) {
    final byAlbum = (a.album ?? '').compareTo(b.album ?? '');
    if (byAlbum != 0) return byAlbum;

    return _trackComparison(a, b);
  });

  return [for (final entry in matches) entry.file];
}

List<CatalogFile> _inTrackOrder(List<MusicEntry> entries) {
  final ordered = [...entries]..sort(_trackComparison);

  return [for (final entry in ordered) entry.file];
}

/// Track number first, and the file name where the core holds no number —
/// which is what an unnumbered rip falls back to.
int _trackComparison(MusicEntry a, MusicEntry b) {
  final left = a.metadata.track;
  final right = b.metadata.track;

  if (left != null && right != null) return left.compareTo(right);
  if (left != null) return -1;
  if (right != null) return 1;

  return a.file.name.compareTo(b.file.name);
}
