import 'dart:convert';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../../catalog/data/file_view_parser.dart';
import '../../catalog/domain/music_metadata.dart';
import '../domain/library.dart';
import '../domain/library_gateway.dart';

/// [LibraryGateway] over the core's library calls (libraries design).
class CoreLibraryGateway implements LibraryGateway {
  /// Wraps [_core].
  const CoreLibraryGateway(this._core);

  final CoreClient _core;

  @override
  Future<LibraryBrowse> browse({required String credential}) async {
    final CoreJsonResponse response;
    try {
      response = await _core.librariesList(credential);
    } on CoreCallException {
      return _unreadableBrowse();
    }

    if (!CoreStatusFamily.library.isOk(response.status)) {
      return LibraryBrowse.failed(
        failure: mapCoreStatus(CoreStatusFamily.library, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadableBrowse();

    try {
      final rows = jsonDecode(json) as List<dynamic>;

      return LibraryBrowse.loaded(
        libraries: [
          for (final row in rows) _libraryFrom(row as Map<String, dynamic>),
        ],
      );
    } on Object {
      // Broad by intent, as on every payload path in the sibling gateways: a
      // malformed document surfaces as FormatException and a wrongly-typed
      // field as TypeError.
      return _unreadableBrowse();
    }
  }

  @override
  Future<LibraryRead> read({
    required String uuid,
    required String path,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.libraryBrowse(uuid, path, credential);
    } on CoreCallException {
      return _unreadableRead();
    }

    if (!CoreStatusFamily.library.isOk(response.status)) {
      return LibraryRead.failed(
        failure: mapCoreStatus(CoreStatusFamily.library, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadableRead();

    try {
      final body = jsonDecode(json) as Map<String, dynamic>;

      return LibraryRead.loaded(
        listing: LibraryListing(
          library: _libraryFrom(body['library'] as Map<String, dynamic>),
          path: body['path'] as String? ?? '',
          folders: [
            for (final row in body['folders'] as List<dynamic>)
              LibraryFolder(
                name: (row as Map<String, dynamic>)['name'] as String,
                path: row['path'] as String,
              ),
          ],
          // A row this application cannot read is dropped rather than
          // failing the whole level: one unreadable file should cost that
          // file, not the folder it is in.
          files: [
            for (final row in body['files'] as List<dynamic>)
              ?_fileFrom(row as Map<String, dynamic>),
          ],
        ),
      );
    } on Object {
      return _unreadableRead();
    }
  }

  @override
  Future<LibraryWrite> register({
    required String name,
    required String rootPath,
    required String credential,
  }) => _write(
    () => _core.libraryRegister(
      jsonEncode({'name': name, 'rootPath': rootPath}),
      credential,
    ),
  );

  @override
  Future<LibraryWrite> move({
    required String uuid,
    required String rootPath,
    required String credential,
  }) => _write(
    () => _core.libraryMove(
      uuid,
      jsonEncode({'rootPath': rootPath}),
      credential,
    ),
  );

  @override
  Future<LibraryWrite> remove({
    required String uuid,
    required String credential,
  }) => _write(() => _core.libraryRemove(uuid, credential));

  Future<LibraryWrite> _write(Future<CoreJsonResponse> Function() call) async {
    final CoreJsonResponse response;
    try {
      response = await call();
    } on CoreCallException {
      return const LibraryWrite.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.library,
          code: LIBRARY_ERR_OTHER,
        ),
      );
    }

    if (!CoreStatusFamily.library.isOk(response.status)) {
      return LibraryWrite.failed(
        failure: mapCoreStatus(CoreStatusFamily.library, response.status),
      );
    }

    return const LibraryWrite.done();
  }

  Library _libraryFrom(Map<String, dynamic> row) => Library(
    uuid: row['uuid'] as String,
    name: row['name'] as String,
    rootPath: row['rootPath'] as String,
  );

  /// One file, or `null` when its record cannot be read.
  ///
  /// `row` is a whole `FileView`; the file's own columns are nested under
  /// `file`, which is what `fileFromFileView` reads. Handing it the outer
  /// map instead finds no `fileType`, answers `null`, and — since an
  /// unreadable row is dropped — makes every file in the folder vanish while
  /// the folders beside them still appear.
  LibraryFile? _fileFrom(Map<String, dynamic> row) {
    final nested = row['file'];
    if (nested is! Map<String, dynamic>) return null;

    final file = fileFromFileView(nested);
    if (file == null) return null;

    final tags = metadataFromFileView(row['metadata']);

    return LibraryFile(
      file: file,
      metadata: tags.isEmpty ? null : MusicMetadata.fromDetails(tags),
    );
  }

  LibraryBrowse _unreadableBrowse() => const LibraryBrowse.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.library,
      code: LIBRARY_ERR_OTHER,
    ),
  );

  LibraryRead _unreadableRead() => const LibraryRead.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.library,
      code: LIBRARY_ERR_OTHER,
    ),
  );
}
