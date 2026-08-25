/// Which jacket colour an album gets (UC-21).
///
/// The core carries no cover art for audio, so the case shows a designed
/// jacket instead of an empty square. Derived from the album's own name rather
/// than picked at random, because a record whose sleeve changed colour between
/// two plays would read as a bug — and derived rather than stored, because
/// there is nothing here worth a row in a settings file.
///
/// Replaced wholesale when the core starts answering with the picture the file
/// usually already contains; nothing else about the case changes then.
int sleeveIndexFor(String? album, int hueCount) {
  final name = album?.trim() ?? '';

  // An unnamed album is not an error and gets a colour like any other. The
  // first one, deliberately: every untitled record looking alike is right,
  // because as far as the catalog knows they are alike.
  if (name.isEmpty) return 0;

  // FNV-1a: stable across runs and platforms, which `hashCode` is not
  // promised to be — and this value decides what the owner sees.
  //
  // `hash * 0x01000193` can exceed 2^53 before the `& 0xffffffff` mask
  // brings it back into range, which would lose precision if this ever ran
  // on dart2js, where a Dart int is a JS double. Harmless on the native
  // desktop VM this project targets, where ints are true 64-bit integers —
  // flagged here so a future web target doesn't have to rediscover it.
  var hash = 0x811c9dc5;
  for (final unit in name.toLowerCase().codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }

  return hash % hueCount;
}
