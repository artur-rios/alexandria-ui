import 'dart:convert';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../domain/catalog_file.dart';
import '../domain/catalog_gateway.dart';
import '../domain/file_details.dart';
import '../domain/library_type.dart';
import '../domain/listing_view.dart';
import '../domain/music_metadata.dart';

/// [CatalogGateway] over the generated bindings (IR-03, UC-09).
class CoreCatalogGateway implements CatalogGateway {
  /// Creates a gateway over [core].
  const CoreCatalogGateway(this._core);

  final CoreClient _core;

  @override
  Future<CatalogListing> listFiles({
    required LibraryType type,
    required String credential,
    LifecycleFilter lifecycle = LifecycleFilter.active,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.filesList(
        // The filter the core's own HTTP route takes. The state is always
        // stated rather than left to the core's default: a default that
        // changed would silently start listing deleted records.
        jsonEncode({'type': type.wireName, 'state': lifecycle.wireName}),
        credential,
      );
    } on CoreCallException {
      return const CatalogListing.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.file,
          code: FILE_ERR_OTHER,
        ),
      );
    }

    if (!CoreStatusFamily.file.isOk(response.status)) {
      return CatalogListing.failed(
        failure: mapCoreStatus(CoreStatusFamily.file, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadable();

    try {
      final rows = jsonDecode(json) as List<dynamic>;
      return CatalogListing.loaded(
        files: [
          for (final row in rows) ?_fileFrom(row as Map<String, dynamic>),
        ],
      );
    } on Object {
      // Broad by intent, as on every payload path: a malformed document
      // surfaces as FormatException and a wrongly-typed field as TypeError.
      return _unreadable();
    }
  }

  @override
  Future<FileDetailsOutcome> fileDetails({
    required String uuid,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.fileByUuid(uuid, credential);
    } on CoreCallException {
      return const FileDetailsOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.file,
          code: FILE_ERR_OTHER,
        ),
      );
    }

    // AF-01 and AF-05 both arrive here and are told apart by the status: a
    // record the core does not have is not found, and a rejected session is
    // unauthorized. The mapper draws that line, not this method.
    if (!CoreStatusFamily.file.isOk(response.status)) {
      return FileDetailsOutcome.failed(
        failure: mapCoreStatus(CoreStatusFamily.file, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadableDetails();

    try {
      final body = jsonDecode(json) as Map<String, dynamic>;
      final file = _fileFrom(body['file'] as Map<String, dynamic>);
      if (file == null) return _unreadableDetails();

      return FileDetailsOutcome.read(
        details: FileDetails(
          file: file,
          metadata: _metadataFrom(body['metadata']),
          width: body['width'] as int?,
          height: body['height'] as int?,
          // The core names a comic's page count separately from a document's,
          // because a FileView carries both fields and they are never both
          // answered for one file. Either is "how many pages" to a reader.
          pageCount:
              body['pageCount'] as int? ?? body['comicPageCount'] as int?,
          durationSeconds: (body['durationSeconds'] as num?)?.toDouble(),
          isDeleted:
              (body['file'] as Map<String, dynamic>)['state'] == 'deleted',
        ),
      );
    } on Object {
      return _unreadableDetails();
    }
  }

  @override
  Future<MetadataEditOutcome> editMusicMetadata({
    required String uuid,
    required MusicMetadata metadata,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.fileEditMetadata(
        uuid,
        jsonEncode(metadata.toPatch()),
        credential,
      );
    } on CoreCallException {
      return const MetadataEditOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.file,
          code: FILE_ERR_OTHER,
        ),
      );
    }

    // AF-02, AF-03 and AF-05 all arrive here and are told apart by the status
    // the mapper reads: an invalid value, a record the core does not have, and
    // a rejected session are three different answers to the same call.
    if (!CoreStatusFamily.file.isOk(response.status)) {
      return MetadataEditOutcome.failed(
        failure: mapCoreStatus(CoreStatusFamily.file, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadableEdit();

    try {
      final body = jsonDecode(json) as Map<String, dynamic>;

      return MetadataEditOutcome.saved(
        metadata: MusicMetadata.fromDetails(
          _metadataFrom(body['metadata']),
        ),
      );
    } on Object {
      return _unreadableEdit();
    }
  }

  MetadataEditOutcome _unreadableEdit() => const MetadataEditOutcome.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.file,
      code: FILE_ERR_OTHER,
    ),
  );

  /// The metadata object as labelled fields.
  ///
  /// Read generically rather than per subtype: this screen displays what the
  /// core sent, and a core that grows a field should show it rather than have
  /// it silently dropped by a model that predates it. The typed shape belongs
  /// to the use cases that edit metadata (UC-15, UC-16).
  Map<String, String> _metadataFrom(Object? metadata) {
    if (metadata is! Map<String, dynamic>) return const {};

    return {
      for (final entry in metadata.entries)
        // The tag serde adds to name the variant is not a field the owner
        // reads: the file's type already says which shape this is.
        if (entry.key != 'type' && entry.value != null)
          entry.key: '${entry.value}',
    };
  }

  FileDetailsOutcome _unreadableDetails() => const FileDetailsOutcome.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.file,
      code: FILE_ERR_OTHER,
    ),
  );

  /// The file [row] describes, or `null` when its type is one this
  /// application does not know.
  ///
  /// Dropping it rather than guessing: a file of an unrecognized type belongs
  /// in no listing, and a core that grows a type must not make the listing it
  /// appears in unreadable.
  CatalogFile? _fileFrom(Map<String, dynamic> row) {
    final type = LibraryType.fromWire(row['fileType'] as String?);
    if (type == null) return null;

    final missingAt = row['missingAt'] as String?;
    final indexedAt = row['indexedAt'] as String?;

    return CatalogFile(
      uuid: row['uuid'] as String,
      name: row['name'] as String,
      path: row['path'] as String? ?? '',
      type: type,
      indexedAt: indexedAt == null ? null : DateTime.tryParse(indexedAt),
      missingAt: missingAt == null ? null : DateTime.tryParse(missingAt),
    );
  }

  CatalogListing _unreadable() => const CatalogListing.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.file,
      code: FILE_ERR_OTHER,
    ),
  );
}
