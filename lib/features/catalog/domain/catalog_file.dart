import 'package:freezed_annotation/freezed_annotation.dart';

import 'library_type.dart';

part 'catalog_file.freezed.dart';

/// A file in the catalog, as the application consumes it
/// (System Requirements §4.2).
///
/// A projection of a core-owned record: the fields here are what the interface
/// reads, not what the core stores. Everything about it — its type, its
/// lifecycle state, whether it is missing — is the core's verdict.
@freezed
abstract class CatalogFile with _$CatalogFile {
  /// Creates a file.
  const factory CatalogFile({
    /// The public identifier passed on every call about this file.
    required String uuid,

    /// The file name on disk.
    required String name,

    /// The absolute on-disk path.
    required String path,

    /// What the core classified it as.
    required LibraryType type,

    /// When re-indexing last found the on-disk file gone.
    ///
    /// Orthogonal to the soft-delete lifecycle: a missing file is still an
    /// active record, and UC-37 is what reviews them.
    DateTime? missingAt,
  }) = _CatalogFile;

  const CatalogFile._();

  /// Whether the last refresh could not find this file on disk.
  bool get isMissing => missingAt != null;
}
