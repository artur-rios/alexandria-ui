import '../domain/catalog_file.dart';
import '../domain/file_type.dart';

/// The `File` object [row] describes, or `null` when its type is one this
/// application does not know.
///
/// Shared by every gateway that reads a `FileView` — the catalog listing, the
/// single-file read, and a playlist's entries all answer this same shape
/// (playlists design section 4) — so there is one parse rather than a second
/// copy that could drift from it.
///
/// Dropping an unrecognized type rather than guessing: a file of an
/// unrecognized type belongs in no listing, and a core that grows a type must
/// not make the listing it appears in unreadable.
CatalogFile? fileFromFileView(Map<String, dynamic> row) {
  final type = FileType.fromWire(row['fileType'] as String?);
  if (type == null) return null;

  final missingAt = row['missingAt'] as String?;
  final indexedAt = row['indexedAt'] as String?;
  final deletedAt = row['deletedAt'] as String?;

  return CatalogFile(
    uuid: row['uuid'] as String,
    name: row['name'] as String,
    path: row['path'] as String? ?? '',
    type: type,
    contentHash: row['contentHash'] as String? ?? '',
    // The change signal indexing actually maintains, unlike the hash above.
    sizeBytes: row['sizeBytes'] as int?,
    mtime: switch (row['mtime']) {
      final String raw => DateTime.tryParse(raw),
      _ => null,
    },
    isDeleted: row['state'] == 'deleted',
    indexedAt: indexedAt == null ? null : DateTime.tryParse(indexedAt),
    missingAt: missingAt == null ? null : DateTime.tryParse(missingAt),
    deletedAt: deletedAt == null ? null : DateTime.tryParse(deletedAt),
  );
}

/// The metadata object [metadata] describes, as labelled fields.
///
/// Read generically rather than per subtype: a caller displays or converts
/// what the core sent, and a core that grows a field should show it rather
/// than have it silently dropped by a parser that predates it. The typed
/// shape belongs to the use cases that edit metadata (UC-15, UC-16).
Map<String, String> metadataFromFileView(Object? metadata) {
  if (metadata is! Map<String, dynamic>) return const {};

  return {
    for (final entry in metadata.entries)
      // The tag serde adds to name the variant is not a field the owner
      // reads: the file's type already says which shape this is.
      if (entry.key != 'type' && entry.value != null)
        entry.key: '${entry.value}',
  };
}
