/// The types the Alexandria core classifies a file into (FR-CT-02).
///
/// Seven, which is the core's own `FileType` and not a reinterpretation of it.
/// The navigation panel's entries map onto these; where the two disagree, the
/// core wins, because classifying a file is domain work the core owns (BR-02).
enum FileType {
  /// `video` — everything filmed.
  ///
  /// The panel has one entry for this. FR-CT-01 originally listed movies and
  /// series separately, but a `File` carries no video subtype, so the two
  /// would be the same query returning the same rows. That distinction is a
  /// watchlist's (UC-29), not the catalog's.
  video('video'),

  /// `audio` — music and other recordings, played rather than read
  /// (core 0.6.0). Their tags ride on the file, so a listing can name a
  /// track by its title and order an album by its track numbers.
  audio('audio'),

  /// `document` — the panel's books.
  document('document'),

  /// `comic` — comic book archives.
  comic('comic'),

  /// `text` — notes, Markdown, and plain text.
  text('text'),

  /// `html` — saved pages.
  html('html'),

  /// `image` — still images.
  image('image');

  const FileType(this.wireName);

  /// The string the core uses in a filter and returns on a file.
  final String wireName;

  /// The type [wireName] names, or `null` when the core answers one this
  /// application does not know.
  ///
  /// `null` rather than a fallback: a file of an unknown type belongs in no
  /// listing, and putting it in an arbitrary one would be worse than leaving
  /// it out until the type is supported.
  static FileType? fromWire(String? wireName) {
    for (final type in FileType.values) {
      if (type.wireName == wireName) return type;
    }
    return null;
  }
}
