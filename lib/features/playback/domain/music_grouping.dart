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
  const MusicEntry({
    required this.file,
    required this.metadata,
    this.albumArtistOfRecord,
  });

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

  /// What the rest of this record says its artist is — see
  /// [albumArtistsAcross], which is the only thing that sets it.
  ///
  /// `null` for an entry read on its own, outside a library: a single track
  /// is no evidence about the record it came from.
  final String? albumArtistOfRecord;

  /// Who the record is by.
  ///
  /// The one key every grouping and every queue is built from: a compilation
  /// under one album artist is one record rather than one record per
  /// performer, and a guest appearance stays on the host's album.
  ///
  /// Three answers, in order of how much they know:
  ///
  /// 1. this file's own `ALBUMARTIST`, which is the record answering for
  ///    itself;
  /// 2. what the rest of the record says ([albumArtistOfRecord]) — for a
  ///    file that carries no such tag, which most files do not;
  /// 3. this track's own performer, for a track that belongs to no record
  ///    the library can see.
  ///
  /// The middle one is what keeps a rap album out of the artists list twelve
  /// times over. A record whose tracks are tagged `50 Cent`, `50 Cent feat.
  /// Nate Dogg` and `Eminem, 50 Cent` and carries no album artist anywhere
  /// is one record by one artist, and falling straight through to the
  /// performer listed every guest on it as an artist in their own right.
  String? get albumArtist =>
      trimmedOrNull(metadata.albumArtist) ?? albumArtistOfRecord ?? artist;

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

/// [entries], grouped by album and ordered within each album — the order an
/// artist's own row bulk-adds its tracks in (Task 5, playlists design entry
/// point 2).
///
/// [artistOf] performs the same album-then-track ordering, but it starts
/// from a single seed track and a whole library to filter down from, and it
/// deliberately answers just that one file when the seed names no artist
/// (`playArtist` from an untagged track has no other artist to gather). That
/// early return is wrong here: [entries] is already `artistsIn`'s own
/// untagged-artist row, gathered by [_groupedBy] — every track in it belongs
/// in the result, not only the first, so this sorts the list it is given
/// rather than re-deriving one from a single file.
List<CatalogFile> inArtistOrder(List<MusicEntry> entries) {
  final ordered = [...entries]..sort((a, b) {
    final byAlbum = (a.album ?? '').compareTo(b.album ?? '');
    if (byAlbum != 0) return byAlbum;

    return _trackComparison(a, b);
  });

  return [for (final entry in ordered) entry.file];
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

/// [entries] again, each told who the record it belongs to is by.
///
/// Read once when the library is built, because the answer is a property of
/// the *record* and no single file holds it: a track carrying no
/// `ALBUMARTIST` cannot say whose album it is on, and the tracks beside it
/// can.
///
/// Two ways a record answers, in order:
///
/// 1. **A tag on any of its tracks.** Files are half-tagged all the time —
///    one editor writes the frame, another does not — and one track saying
///    `50 Cent` settles the record for the ones that say nothing.
/// 2. **Its most common performer.** With no tag anywhere, the artist most
///    of the record's tracks name is whose record it is; the others are
///    guests on it.
///
/// A record with no name of its own is left alone: two untitled files are
/// not the same record, and grouping on a blank field would make one record
/// of an owner's every loose track.
///
/// The second rule is a judgement, and worth naming as one: a genuine
/// various-artists compilation with no album artist anywhere lands under
/// whichever performer has the most tracks on it. That is a worse answer for
/// that one record than listing all of them — and a far better one for every
/// ordinary album with a guest on it, which is what most libraries are made
/// of. An owner who disagrees has the tag, and it wins.
List<MusicEntry> albumArtistsAcross(List<MusicEntry> entries) {
  final tagged = <String, Map<String, int>>{};
  final performers = <String, Map<String, int>>{};

  for (final entry in entries) {
    final album = entry.album;
    if (album == null) continue;

    if (trimmedOrNull(entry.metadata.albumArtist) case final artist?) {
      tagged.putIfAbsent(album, () => {}).update(
        artist,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    if (entry.artist case final artist?) {
      performers.putIfAbsent(album, () => {}).update(
        artist,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
  }

  return [
    for (final entry in entries)
      MusicEntry(
        file: entry.file,
        metadata: entry.metadata,
        albumArtistOfRecord: entry.album == null
            ? null
            : _commonest(tagged[entry.album!]) ??
                  _commonest(performers[entry.album!]),
      ),
  ];
}

/// The name most of them carry, or `null` when there are none.
///
/// Ties break alphabetically rather than by encounter order: a library
/// listing its artists differently depending on which track the core
/// happened to answer first would be a library that reorders itself for no
/// reason the owner can see.
String? _commonest(Map<String, int>? counts) {
  if (counts == null || counts.isEmpty) return null;

  final names = counts.keys.toList()..sort();

  return names.reduce(
    (best, name) => counts[name]! > counts[best]! ? name : best,
  );
}
