/// The types the Alexandria core classifies a file into (FR-CT-07, FR-CT-22).
///
/// Seven, which is the core's own `FileType` and not a reinterpretation of it.
/// A library's type filter and home's statistics list these; where a label and
/// the core disagree, the core wins, because classifying a file is domain work
/// the core owns (BR-02).
enum FileType {
  /// `video` — everything filmed.
  ///
  /// One type, not two: movies and series were once listed separately, but a
  /// `File` carries no video subtype, so the two would be the same query
  /// returning the same rows. That distinction is a watchlist's (UC-29), not
  /// the catalog's.
  video('video'),

  /// `audio` — music and other recordings, played rather than read
  /// (core 0.6.0). Their tags ride on the file, so a listing can name a
  /// track by its title and order an album by its track numbers.
  audio('audio'),

  /// `document` — books: PDFs and e-books.
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
