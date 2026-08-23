import 'package:freezed_annotation/freezed_annotation.dart';

import 'file_stamp.dart';
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

    /// The core's hash of the file's contents.
    ///
    /// Read-only, and empty for most records: indexing no longer computes one,
    /// so only a file this application has written since carries a hash. What
    /// tells that a file changed on disk is [stamp], not this.
    @Default('') String contentHash,

    /// The file's size on disk in bytes, as the core last saw it.
    ///
    /// Half of [stamp]. Nullable because a core that answers without it must
    /// not make the record unreadable.
    int? sizeBytes,

    /// When the file was last modified on disk, as the core last saw it.
    ///
    /// The other half of [stamp], and nullable for the same reason.
    DateTime? mtime,

    /// When the core last indexed this file.
    ///
    /// What a date sort orders on (UC-12, FR-CT-08). Nullable because a core
    /// that answers without it must not make the listing unreadable.
    DateTime? indexedAt,

    /// Whether the core reports the record as deleted.
    ///
    /// The core's verdict and not this application's: a purge is offered for a
    /// deleted record and refused for an active one (UC-35 AF-03), and the
    /// answer to which it is has to come from the same listing the record did.
    @Default(false) bool isDeleted,

    /// When the record was soft-deleted.
    ///
    /// What the deleted view counts the retention window from (UC-34,
    /// FR-LC-03). `null` on an active record, and on a deleted one the core
    /// answered without a timestamp — which reads as "restorable, for an
    /// unknown while" rather than as "not restorable".
    DateTime? deletedAt,

    /// When re-indexing last found the on-disk file gone.
    ///
    /// Orthogonal to the soft-delete lifecycle: a missing file is still an
    /// active record, and UC-37 is what reviews them.
    DateTime? missingAt,
  }) = _CatalogFile;

  const CatalogFile._();

  /// Whether the last refresh could not find this file on disk.
  bool get isMissing => missingAt != null;

  /// What this file looked like on disk when the core last read it.
  ///
  /// The change signal the editor compares before it overwrites (UC-33 AF-05),
  /// now that a content hash is no longer generally computed.
  FileStamp get stamp => FileStamp(sizeBytes: sizeBytes, mtime: mtime);
}
