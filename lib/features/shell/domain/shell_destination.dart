/// The areas the navigation panel offers (FR-UX-01, FR-CT-01).
///
/// Eight of these are the library's types: the seven the core classifies files
/// into, plus bookmarks, which are not files at all and are listed through
/// their own core call (UC-28). [home] is the tenth and is not a file type — it is where UC-14's
/// dashboard lands, and the panel carries it because "the application opens the
/// dashboard after login" (UC-14 main flow step 1) would otherwise describe a
/// screen the owner can never navigate back to.
///
/// The shell owns *that there is a panel and what it selects*. The item count
/// beside each type and the listing behind it are UC-09's, and arrive as a
/// content area rather than as a change to this enum.
enum ShellDestination {
  /// The dashboard the application opens on (UC-14).
  home,

  /// Audio files.
  music,

  /// Video of every kind.
  ///
  /// One entry, not the two FR-CT-01 originally listed. The core classifies a
  /// file as `video` and carries no subtype, so "movies" and "series" would be
  /// the same query and the same list. The distinction is real in this product
  /// — it is what a watchlist tracks (UC-29) — but it is not a property of the
  /// catalog, and inventing one here would be the front-end doing domain
  /// classification the core owns (BR-02).
  videos,

  /// Books, including e-book formats and PDFs read as books.
  books,

  /// Comic book archives.
  comicBooks,

  /// Notes, Markdown, and plain text.
  notes,

  /// Saved HTML pages.
  pages,

  /// Still images.
  images,

  /// Saved links, which are the one destination holding no file on disk.
  bookmarks,

  /// The registered libraries — folders browsed as the trees they are, whose
  /// files are shown only there (libraries design).
  ///
  /// Not a file type, and the second entry that is not: a library holds
  /// whatever its folder holds, of every type at once. It is a destination
  /// rather than an entry in the tools menu because it is somewhere the
  /// owner browses, like the panels above it, rather than something they do
  /// to the library.
  libraries;

  /// The destination the shell opens on, after login (UC-14 main flow step 1).
  static const ShellDestination initial = ShellDestination.home;

  /// Whether this destination lists a file type, and so carries a count and a
  /// listing.
  ///
  /// False for [home], which is the dashboard, and for [libraries], which
  /// lists folders rather than files of any one type.
  bool get isFileType =>
      this != ShellDestination.home && this != ShellDestination.libraries;
}
