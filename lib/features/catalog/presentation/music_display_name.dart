import '../domain/catalog_file.dart';
import '../domain/file_type.dart';

/// What [file] is called wherever it appears: an audio file's title, every
/// other file's name.
///
/// One name for a track across the listing, search, the dashboard, a
/// library's folder, the delete and missing-files reviews, and the player
/// bar. A file the ripper called `03 - track.flac` is a song the owner knows
/// by its title.
String displayName(CatalogFile file) =>
    file.type == FileType.audio ? musicTitle(file) : file.name;

/// [file]'s title, or its file name when it has none.
String musicTitle(CatalogFile file) => tagOr(file.tags?.title, file.name);

/// Who and from what: the artist and the album, either alone when the other
/// is missing, or null when both are.
String? musicByline(CatalogFile file) {
  final parts = [
    tagOr(file.tags?.artist, ''),
    tagOr(file.tags?.album, ''),
  ].where((part) => part.isNotEmpty);

  return parts.isEmpty ? null : parts.join(' · ');
}

/// [value] trimmed, or [whenAbsent] when there is nothing left of it.
String tagOr(String? value, String whenAbsent) {
  final trimmed = value?.trim();

  return trimmed == null || trimmed.isEmpty ? whenAbsent : trimmed;
}

/// [seconds] as a track length is written: `4:05`, or `1:02:05` past an
/// hour.
String formatDuration(double seconds) {
  final total = seconds.floor();
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final rest = (total % 60).toString().padLeft(2, '0');

  return hours > 0
      ? '$hours:${minutes.toString().padLeft(2, '0')}:$rest'
      : '$minutes:$rest';
}
