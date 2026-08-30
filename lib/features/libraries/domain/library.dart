import 'package:freezed_annotation/freezed_annotation.dart';

import '../../catalog/domain/catalog_file.dart';
import '../../catalog/domain/music_metadata.dart';

part 'library.freezed.dart';

/// A registered folder browsed as a tree, whose files are shown only there
/// (libraries design).
@freezed
abstract class Library with _$Library {
  /// Creates a library.
  const factory Library({
    required String uuid,

    /// The owner's name for it, not the folder's.
    ///
    /// A directory called `2024-final-v2` is a path, not a title, and
    /// renaming the library must not mean renaming the directory.
    required String name,

    /// The folder every entry's position is relative to.
    required String rootPath,
  }) = _Library;
}

/// A folder directly inside the level being browsed.
///
/// Carries no contents: a tree is drawn one level at a time, and a folder is
/// something to open rather than something to unpack.
@freezed
abstract class LibraryFolder with _$LibraryFolder {
  /// Creates a folder.
  const factory LibraryFolder({
    /// Its own name, as it is on disk.
    required String name,

    /// Its path relative to the library root — what opening it sends back.
    required String path,
  }) = _LibraryFolder;
}

/// One file at the level being browsed.
@freezed
abstract class LibraryFile with _$LibraryFile {
  /// Creates an entry.
  const factory LibraryFile({
    required CatalogFile file,

    /// The track's tags, when it is audio the core has read.
    MusicMetadata? metadata,
  }) = _LibraryFile;
}

/// One level of a library's tree.
///
/// Folders and files kept apart rather than interleaved: a tree draws them
/// differently and almost always groups them, and a caller that wanted them
/// mixed can concatenate far more easily than one that wanted them separate
/// can partition.
@freezed
abstract class LibraryListing with _$LibraryListing {
  /// Creates a listing.
  const factory LibraryListing({
    required Library library,

    /// The folder being shown, relative to the root. Empty at the top.
    required String path,
    required List<LibraryFolder> folders,
    required List<LibraryFile> files,
  }) = _LibraryListing;

  const LibraryListing._();

  /// Whether this folder holds nothing at all.
  bool get isEmpty => folders.isEmpty && files.isEmpty;

  /// The path of the folder containing this one, or `null` at the top.
  ///
  /// Derived rather than carried: the parent of `a/b/c` is `a/b` by
  /// definition, and a field for it would be a second thing to keep true.
  String? get parentPath {
    if (path.isEmpty) return null;

    final cut = path.lastIndexOf('/');
    return cut < 0 ? '' : path.substring(0, cut);
  }
}
