import '../../catalog/domain/file_type.dart';

/// The areas of the shell (FR-UX-01, spec §3).
///
/// The left menu goes to three kinds of them: home, the bookmarks, and each
/// library. [TypeDestination] and [LibrariesDestination] are temporary: they
/// are reached from elsewhere in the shell but never listed in the left menu,
/// and each goes once what replaces it exists.
///
/// The shell owns *that there is an area and which one is shown*; what each
/// area holds is its own feature's content.
sealed class ShellDestination {
  const ShellDestination();

  /// The destination the shell opens on (UC-14 main flow step 1).
  static const ShellDestination initial = HomeDestination();

  /// The file type this destination lists, or `null` when it lists none.
  FileType? get listedType => null;
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

/// The listing of one file type (UC-09).
///
/// Temporary. The left menu no longer lists the types; this stays only until
/// a library's own page shows its files with the listing's tiles, and goes
/// with `CatalogListing` then (library navigation plan, Task 4).
final class TypeDestination extends ShellDestination {
  /// Creates the destination listing [type].
  const TypeDestination(this.type);

  /// The type listed.
  final FileType type;

  @override
  FileType get listedType => type;

  @override
  bool operator ==(Object other) =>
      other is TypeDestination && other.type == type;

  @override
  int get hashCode => Object.hash(TypeDestination, type);
}

/// The registered libraries, with their runs and the add, scan, move and
/// remove actions.
///
/// Temporary. Reached from the Library menu, the activity strip's "View all"
/// and every "add a library" offer, never from the left menu; the Manage
/// libraries dialog replaces it (library navigation plan, Task 5).
final class LibrariesDestination extends ShellDestination {
  /// Creates the destination.
  const LibrariesDestination();

  @override
  bool operator ==(Object other) => other is LibrariesDestination;

  @override
  int get hashCode => (LibrariesDestination).hashCode;
}
