/// The areas the navigation panel offers (FR-UX-01, FR-CT-01).
///
/// Nine of these are FR-CT-01's file types, in its order: music, movies,
/// series, books, comic books, notes and text files, HTML pages, images, and
/// bookmarks. [home] is the tenth and is not a file type — it is where UC-14's
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

  /// Standalone films.
  movies,

  /// Episodic video.
  series,

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
  bookmarks;

  /// The destination the shell opens on, after login (UC-14 main flow step 1).
  static const ShellDestination initial = ShellDestination.home;

  /// Whether this destination lists a file type, and so will carry a count and
  /// a listing once UC-09 fills the content area.
  bool get isFileType => this != ShellDestination.home;
}
