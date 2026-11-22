/// The areas of the shell (FR-UX-01, spec §3).
///
/// The left menu goes to three kinds of them: home, the bookmarks, and each
/// library.
///
/// The shell owns *that there is an area and which one is shown*; what each
/// area holds is its own feature's content.
sealed class ShellDestination {
  const ShellDestination();

  /// The destination the shell opens on (UC-14 main flow step 1).
  static const ShellDestination initial = HomeDestination();
}

/// The dashboard the application opens on (UC-14).
final class HomeDestination extends ShellDestination {
  /// Creates the destination.
  const HomeDestination();

  @override
  bool operator ==(Object other) => other is HomeDestination;

  @override
  int get hashCode => (HomeDestination).hashCode;
}

/// Saved links, the one area holding no file on disk (UC-28).
final class BookmarksDestination extends ShellDestination {
  /// Creates the destination.
  const BookmarksDestination();

  @override
  bool operator ==(Object other) => other is BookmarksDestination;

  @override
  int get hashCode => (BookmarksDestination).hashCode;
}

/// One library, the folder the owner chose (spec §3).
///
/// Compared by [uuid]: picking the library already shown is no move at all.
final class LibraryDestination extends ShellDestination {
  /// Creates the destination for the library [uuid] identifies.
  const LibraryDestination(this.uuid);

  /// The library shown.
  final String uuid;

  @override
  bool operator ==(Object other) =>
      other is LibraryDestination && other.uuid == uuid;

  @override
  int get hashCode => Object.hash(LibraryDestination, uuid);
}
