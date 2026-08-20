import '../../catalog/domain/catalog_file.dart';
import '../../catalog/domain/library_type.dart';
import '../../organization/domain/bookmark.dart';
import 'retention.dart';

/// What kind of record was deleted (UC-34 main flow step 3).
enum DeletedRecordKind {
  /// A catalog file. Restoring it returns it to its type's listing.
  file,

  /// A bookmark, which has no file on disk.
  bookmark,
}

/// One soft-deleted record, as the deleted view lists it (UC-34, FR-LC-03).
///
/// A projection over the two things UC-33 can delete rather than a union of
/// them: the view treats them the same way — a name, how long is left, and a
/// restore — and the kind is the one thing it has to keep, because it selects
/// which core call the restore is.
class DeletedRecord {
  /// Creates a record.
  const DeletedRecord({
    required this.uuid,
    required this.kind,
    required this.name,
    required this.deletedAt,
    this.type,
  });

  /// The deleted file [file] is.
  factory DeletedRecord.ofFile(CatalogFile file) => DeletedRecord(
    uuid: file.uuid,
    kind: DeletedRecordKind.file,
    name: file.name,
    deletedAt: file.deletedAt,
    type: file.type,
  );

  /// The deleted bookmark [bookmark] is.
  factory DeletedRecord.ofBookmark(Bookmark bookmark) => DeletedRecord(
    uuid: bookmark.uuid,
    kind: DeletedRecordKind.bookmark,
    name: bookmark.title,
    deletedAt: bookmark.deletedAt,
  );

  /// The public identifier the restore is sent with.
  final String uuid;

  /// Which core call restores it.
  final DeletedRecordKind kind;

  /// What it is called, which is a file's name or a bookmark's title.
  final String name;

  /// When it was deleted, when the core said.
  final DateTime? deletedAt;

  /// The file's type, and `null` for a bookmark.
  final LibraryType? type;

  /// Where this record stands in its retention window, as of [now].
  Retention retentionAt(DateTime now) => Retention.since(deletedAt, now: now);
}
