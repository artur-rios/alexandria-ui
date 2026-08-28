import 'dart:convert';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../domain/catalog_gateway.dart';
import '../domain/file_details.dart';
import '../domain/library_type.dart';
import '../domain/listing_view.dart';
import '../domain/music_metadata.dart';
import '../domain/video_metadata.dart';
import 'file_view_parser.dart';

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
          for (final row in rows) ?_detailsFrom(row as Map<String, dynamic>),
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
      final details = _detailsFrom(jsonDecode(json) as Map<String, dynamic>);
      if (details == null) return _unreadableDetails();

      return FileDetailsOutcome.read(details: details);
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
          metadataFromFileView(body['metadata']),
        ),
      );
    } on Object {
      return _unreadableEdit();
    }
  }

  @override
  Future<VideoMetadataEditOutcome> editVideoMetadata({
    required String uuid,
    required VideoMetadata metadata,
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
      return const VideoMetadataEditOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.file,
          code: FILE_ERR_OTHER,
        ),
      );
    }

    // AF-02, AF-04 and AF-05 all arrive here and are told apart by the status
    // the mapper reads: a value the core refused, a record it does not have,
    // and a rejected session.
    if (!CoreStatusFamily.file.isOk(response.status)) {
      return VideoMetadataEditOutcome.failed(
        failure: mapCoreStatus(CoreStatusFamily.file, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadableVideoEdit();

    try {
      final body = jsonDecode(json) as Map<String, dynamic>;

      return VideoMetadataEditOutcome.saved(
        metadata: VideoMetadata.fromDetails(
          metadataFromFileView(body['metadata']),
        ),
      );
    } on Object {
      return _unreadableVideoEdit();
    }
  }

  @override
  Future<FileRenameOutcome> renameFile({
    required String uuid,
    required String name,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.fileRename(uuid, name, credential);
    } on CoreCallException {
      return _unreadableRename();
    }

    // AF-02, AF-03 and AF-05 are told apart by the status the mapper reads: a
    // disk that refused the rename, a record the core does not have, and a
    // rejected session.
    if (!CoreStatusFamily.file.isOk(response.status)) {
      return FileRenameOutcome.failed(
        failure: mapCoreStatus(CoreStatusFamily.file, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadableRename();

    try {
      final file = fileFromFileView(jsonDecode(json) as Map<String, dynamic>);
      if (file == null) return _unreadableRename();

      return FileRenameOutcome.renamed(file: file);
    } on Object {
      return _unreadableRename();
    }
  }

  FileRenameOutcome _unreadableRename() => const FileRenameOutcome.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.file,
      code: FILE_ERR_OTHER,
    ),
  );

  VideoMetadataEditOutcome _unreadableVideoEdit() =>
      const VideoMetadataEditOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.file,
          code: FILE_ERR_OTHER,
        ),
      );

  MetadataEditOutcome _unreadableEdit() => const MetadataEditOutcome.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.file,
      code: FILE_ERR_OTHER,
    ),
  );

  FileDetailsOutcome _unreadableDetails() => const FileDetailsOutcome.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.file,
      code: FILE_ERR_OTHER,
    ),
  );

  /// The [FileDetails] record [body] describes, or `null` when its file is
  /// one of a type this application does not know.
  ///
  /// One parse for both the single-file call and each row of the listing:
  /// the core answers the same `FileView` shape for both, so there is one
  /// place that reads it rather than a second copy that could drift from the
  /// first.
  FileDetails? _detailsFrom(Map<String, dynamic> body) {
    final file = fileFromFileView(body['file'] as Map<String, dynamic>);
    if (file == null) return null;

    return FileDetails(
      file: file,
      metadata: metadataFromFileView(body['metadata']),
      width: body['width'] as int?,
      height: body['height'] as int?,
      // The core names a comic's page count separately from a document's,
      // because a FileView carries both fields and they are never both
      // answered for one file. Either is "how many pages" to a reader.
      pageCount: body['pageCount'] as int? ?? body['comicPageCount'] as int?,
      durationSeconds: (body['durationSeconds'] as num?)?.toDouble(),
      isDeleted: (body['file'] as Map<String, dynamic>)['state'] == 'deleted',
    );
  }

  CatalogListing _unreadable() => const CatalogListing.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.file,
      code: FILE_ERR_OTHER,
    ),
  );

  @override
  Future<FileThumbnailOutcome> fileThumbnail({
    required String uuid,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.fileThumbnail(uuid, credential);
    } on CoreCallException {
      return _unreadableThumbnail();
    }

    // `InvalidInput` (a file with no embedded picture) is told apart from
    // anything else here only by the `Failure` it carries — the caller reads
    // every member of `.failed` the same way, the designed jacket, so no
    // narrower status check belongs here.
    if (!CoreStatusFamily.playback.isOk(response.status)) {
      return FileThumbnailOutcome.failed(
        failure: mapCoreStatus(CoreStatusFamily.playback, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadableThumbnail();

    try {
      final body = jsonDecode(json) as Map<String, dynamic>;
      final encoded = body['bytesBase64'] as String?;
      if (encoded == null) return _unreadableThumbnail();

      return FileThumbnailOutcome.read(bytes: base64Decode(encoded));
    } on Object {
      return _unreadableThumbnail();
    }
  }

  FileThumbnailOutcome _unreadableThumbnail() =>
      const FileThumbnailOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.playback,
          code: PLAYBACK_ERR_OTHER,
        ),
      );
}
