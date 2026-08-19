import '../../shell/domain/shell_destination.dart';

/// The types the Alexandria core classifies a file into (FR-CT-02).
///
/// Seven, which is the core's own `FileType` and not a reinterpretation of it.
/// The navigation panel's entries map onto these; where the two disagree, the
/// core wins, because classifying a file is domain work the core owns (BR-02).
enum LibraryType {
  /// `audio` — the panel's music.
  audio('audio'),

  /// `video` — everything filmed.
  ///
  /// The panel has one entry for this. FR-CT-01 originally listed movies and
  /// series separately, but a `File` carries no video subtype, so the two
  /// would be the same query returning the same rows. That distinction is a
  /// watchlist's (UC-29), not the catalog's.
  video('video'),

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

  const LibraryType(this.wireName);

  /// The string the core uses in a filter and returns on a file.
  final String wireName;

  /// The type [wireName] names, or `null` when the core answers one this
  /// application does not know.
  ///
  /// `null` rather than a fallback: a file of an unknown type belongs in no
  /// listing, and putting it in an arbitrary one would be worse than leaving
  /// it out until the type is supported.
  static LibraryType? fromWire(String? wireName) {
    for (final type in LibraryType.values) {
      if (type.wireName == wireName) return type;
    }
    return null;
  }
}

/// The listing a navigation destination shows, or `null` when it shows none.
///
/// [ShellDestination.home] is the dashboard (UC-14) and
/// [ShellDestination.bookmarks] is not a file listing at all — bookmarks are a
/// separate entity with their own core call, which UC-28 owns.
LibraryType? libraryTypeFor(ShellDestination destination) =>
    switch (destination) {
      ShellDestination.music => LibraryType.audio,
      ShellDestination.videos => LibraryType.video,
      ShellDestination.books => LibraryType.document,
      ShellDestination.comicBooks => LibraryType.comic,
      ShellDestination.notes => LibraryType.text,
      ShellDestination.pages => LibraryType.html,
      ShellDestination.images => LibraryType.image,
      ShellDestination.home || ShellDestination.bookmarks => null,
    };
