import 'music_grouping.dart';

/// One artist, or one album, and the tracks under it (UC-46, FR-CT-13).
///
/// [name] is `null` for the group of files whose tags name none. A null name
/// rather than a translated "Unknown artist" string, because this is the
/// domain: what the catalog knows is that the tag is absent, and what to call
/// that is the presentation's decision and the translator's.
class MusicGroup {
  /// Creates a group.
  const MusicGroup({required this.name, required this.entries});

  /// What the group is called, or `null` when its files name nothing.
  final String? name;

  /// The tracks in it.
  final List<MusicEntry> entries;

  /// Whether this is the group of files that carry no tag.
  bool get isUntagged => name == null;
}

/// Every artist in [library], alphabetically, with the untagged files last.
List<MusicGroup> artistsIn(List<MusicEntry> library) =>
    _groupedBy(library, (entry) => entry.artist);

/// Every album in [library], alphabetically, with the untagged files last.
///
/// Keyed by album *and* artist: two different artists can name a record the
/// same thing, and merging them would show one artist's tracks inside
/// another's album — the same rule `albumOf` applies when it builds a queue.
List<MusicGroup> albumsIn(List<MusicEntry> library) {
  final byKey = <(String?, String?), List<MusicEntry>>{};
  for (final entry in library) {
    byKey.putIfAbsent((entry.album, entry.artist), () => []).add(entry);
  }

  final groups = [
    for (final key in byKey.keys)
      MusicGroup(name: key.$1, entries: _inTrackOrder(byKey[key]!)),
  ];

  return _sortedByName(groups);
}

/// [artist]'s albums, alphabetically.
///
/// `null` selects the files that name no artist, which is what drilling into
/// the untagged group does.
List<MusicGroup> albumsOfArtist(String? artist, List<MusicEntry> library) =>
    albumsIn([
      for (final entry in library)
        if (entry.artist == artist) entry,
    ]);

/// The tracks of [artist]'s [album], in track order.
List<MusicEntry> tracksOfAlbum(
  String? album,
  String? artist,
  List<MusicEntry> library,
) => _inTrackOrder([
  for (final entry in library)
    if (entry.album == album && entry.artist == artist) entry,
]);

/// Every track in [library], by title, with the untitled ones last.
List<MusicEntry> songsIn(List<MusicEntry> library) {
  final sorted = [...library]
    ..sort((a, b) => _byName(a.title, b.title));

  return sorted;
}

List<MusicGroup> _groupedBy(
  List<MusicEntry> library,
  String? Function(MusicEntry entry) key,
) {
  final byName = <String?, List<MusicEntry>>{};
  for (final entry in library) {
    byName.putIfAbsent(key(entry), () => []).add(entry);
  }

  return _sortedByName([
    for (final name in byName.keys)
      MusicGroup(name: name, entries: _inTrackOrder(byName[name]!)),
  ]);
}

List<MusicGroup> _sortedByName(List<MusicGroup> groups) =>
    [...groups]..sort((a, b) => _byName(a.name, b.name));

/// Case-insensitively by name, with an absent name last.
///
/// Absent last rather than first: the untagged files are a chore to work
/// through, not the first thing an owner came to see.
int _byName(String? left, String? right) {
  if (left == null && right == null) return 0;
  if (left == null) return 1;
  if (right == null) return -1;

  return left.toLowerCase().compareTo(right.toLowerCase());
}

/// Track number first, then title — the order a record is listened to.
///
/// A track with no number sorts after the numbered ones rather than at the
/// front, which is where a missing number would otherwise put it.
List<MusicEntry> _inTrackOrder(List<MusicEntry> entries) =>
    [...entries]..sort((a, b) {
      final left = a.metadata.track;
      final right = b.metadata.track;

      if (left != null && right != null && left != right) {
        return left.compareTo(right);
      }
      if (left != null && right == null) return -1;
      if (left == null && right != null) return 1;

      return _byName(a.title, b.title);
    });
