import 'dart:convert';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../../catalog/domain/catalog_file.dart';
import '../../catalog/domain/library_type.dart';
import '../domain/text_content_gateway.dart';

/// [TextContentGateway] over the core's content calls (UC-18).
class CoreTextContentGateway implements TextContentGateway {
  /// Wraps [_core].
  const CoreTextContentGateway(this._core);

  final CoreClient _core;

  @override
  Future<TextContentRead> readContent({
    required String uuid,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.fileReadContent(uuid, credential);
    } on CoreCallException {
      return _unreadableRead();
    }

    // AF-04 and AF-06 arrive here and are told apart by the status the mapper
    // reads, as does a disk that would not give the bytes up.
    if (!CoreStatusFamily.file.isOk(response.status)) {
      return TextContentRead.failed(
        failure: mapCoreStatus(CoreStatusFamily.file, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadableRead();

    try {
      final body = jsonDecode(json) as Map<String, dynamic>;

      // An absent content field is an empty file, not an unreadable answer: a
      // note with nothing in it is a note the owner may want to write into.
      return TextContentRead.loaded(content: body['content'] as String? ?? '');
    } on Object {
      return _unreadableRead();
    }
  }

  @override
  Future<TextContentWrite> writeContent({
    required String uuid,
    required String content,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.fileEditContent(
        uuid,
        jsonEncode({'content': content}),
        credential,
      );
    } on CoreCallException {
      return _unwritable();
    }

    // AF-03's disk failure, AF-04's missing record, and AF-06's rejected
    // session are three different statuses on the same call.
    if (!CoreStatusFamily.file.isOk(response.status)) {
      return TextContentWrite.failed(
        failure: mapCoreStatus(CoreStatusFamily.file, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unwritable();

    try {
      final row = jsonDecode(json) as Map<String, dynamic>;
      final type = LibraryType.fromWire(row['fileType'] as String?);
      if (type == null) return _unwritable();

      final indexedAt = row['indexedAt'] as String?;
      final missingAt = row['missingAt'] as String?;

      return TextContentWrite.written(
        file: CatalogFile(
          uuid: row['uuid'] as String,
          name: row['name'] as String,
          path: row['path'] as String? ?? '',
          type: type,
          contentHash: row['contentHash'] as String? ?? '',
          // What the next AF-05 check compares against: the refreshed record
          // is the truth about what is on disk after this write.
          sizeBytes: row['sizeBytes'] as int?,
          mtime: switch (row['mtime']) {
            final String raw => DateTime.tryParse(raw),
            _ => null,
          },
          indexedAt: indexedAt == null ? null : DateTime.tryParse(indexedAt),
          missingAt: missingAt == null ? null : DateTime.tryParse(missingAt),
        ),
      );
    } on Object {
      return _unwritable();
    }
  }

  TextContentRead _unreadableRead() => const TextContentRead.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.file,
      code: FILE_ERR_OTHER,
    ),
  );

  TextContentWrite _unwritable() => const TextContentWrite.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.file,
      code: FILE_ERR_OTHER,
    ),
  );
}
