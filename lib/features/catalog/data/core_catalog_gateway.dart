import 'dart:convert';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../domain/catalog_file.dart';
import '../domain/catalog_gateway.dart';
import '../domain/library_type.dart';

/// [CatalogGateway] over the generated bindings (IR-03, UC-09).
class CoreCatalogGateway implements CatalogGateway {
  /// Creates a gateway over [core].
  const CoreCatalogGateway(this._core);

  final CoreClient _core;

  @override
  Future<CatalogListing> listFiles({
    required LibraryType type,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.filesList(
        // The filter the core's own HTTP route takes. `state: active` is
        // explicit rather than left to the default: UC-09 step 3 asks for
        // active records, and a default that changed would silently start
        // listing deleted ones.
        jsonEncode({'type': type.wireName, 'state': 'active'}),
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

    return CatalogFile(
      uuid: row['uuid'] as String,
      name: row['name'] as String,
      path: row['path'] as String? ?? '',
      type: type,
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
