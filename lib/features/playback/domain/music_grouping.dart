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
  String? get artist => trimmedOrNull(metadata.artist);

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
List<CatalogFile> albumOf(MusicEntry entry, List<MusicEntry> library) {
  final album = entry.album;
  if (album == null) return [entry.file];

  final matches = [
    for (final candidate in library)
      if (candidate.album == album &&
          // Two different artists can name an album the same thing. Where the
          // starting track names an artist, the album is that artist's.
          (entry.artist == null || candidate.artist == entry.artist))
        candidate,
  ];

  return _inTrackOrder(matches);
}

/// Every track by [entry]'s artist, album by album (main flow step 3).
List<CatalogFile> artistOf(MusicEntry entry, List<MusicEntry> library) {
  final artist = entry.artist;
  if (artist == null) return [entry.file];

  final matches = [
    for (final candidate in library)
      if (candidate.artist == artist) candidate,
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
