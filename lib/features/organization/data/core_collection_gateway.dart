import 'dart:convert';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../domain/collection.dart';
import '../domain/collection_gateway.dart';

/// [CollectionGateway] over the core's collection calls (UC-26, UC-27).
class CoreCollectionGateway implements CollectionGateway {
  /// Wraps [_core].
  const CoreCollectionGateway(this._core);

  final CoreClient _core;

  @override
  Future<CollectionBrowse> browse({
    required String credential,
    CollectionKind? kind,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.collectionsList(
        // An empty filter is every collection, which is what the screen opens
        // on. The kind is stated only when one was asked for: the core reads
        // an absent filter as no filter, and sending an empty one would be
        // saying something different.
        kind == null ? '' : jsonEncode({'kind': kind.wireName}),
        credential,
      );
    } on CoreCallException {
      return _unreadable();
    }

    if (!CoreStatusFamily.collection.isOk(response.status)) {
      return CollectionBrowse.failed(
        failure: mapCoreStatus(CoreStatusFamily.collection, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadable();

    try {
      final rows = jsonDecode(json) as List<dynamic>;

      return CollectionBrowse.loaded(
        collections: [
          for (final row in rows)
            if (row is Map<String, dynamic>) ?_collectionFrom(row),
        ],
      );
    } on Object {
      return _unreadable();
    }
  }

  @override
  Future<CollectionWrite> create({
    required String name,
    required CollectionKind kind,
    required String credential,
  }) => _write(
    () => _core.collectionCreate(
      jsonEncode({'name': name, 'kind': kind.wireName}),
      credential,
    ),
  );

  @override
  Future<CollectionWrite> rename({
    required String uuid,
    required String name,
    required String credential,
  }) => _write(
    () => _core.collectionRename(uuid, jsonEncode({'name': name}), credential),
  );

  @override
  Future<CollectionWrite> delete({
    required String uuid,
    required String credential,
  }) => _write(() => _core.collectionDelete(uuid, credential));

  /// Runs [call] and turns the core's status into an outcome.
  Future<CollectionWrite> _write(
    Future<CoreJsonResponse> Function() call,
  ) async {
    final CoreJsonResponse response;
    try {
      response = await call();
    } on CoreCallException {
      return const CollectionWrite.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.collection,
          code: COLLECTION_ERR_OTHER,
        ),
      );
    }

    if (!CoreStatusFamily.collection.isOk(response.status)) {
      return CollectionWrite.failed(
        failure: mapCoreStatus(CoreStatusFamily.collection, response.status),
      );
    }

    return const CollectionWrite.done();
  }

  /// The collection [row] describes, or `null` when the core answers a kind
  /// this application does not know.
  ///
  /// Dropped rather than guessed at: a collection of an unrecognized kind
  /// would accept items by a rule this version cannot state, and a core that
  /// grows a kind must not make the listing it appears in unreadable.
  static Collection? _collectionFrom(Map<String, dynamic> row) {
    final kind = CollectionKind.fromWireName(row['kind'] as String?);
    if (kind == null) return null;

    return Collection(
      uuid: row['uuid'] as String,
      name: row['name'] as String,
      kind: kind,
      itemCount: (row['itemCount'] as num?)?.toInt() ?? 0,
    );
  }

  CollectionBrowse _unreadable() => const CollectionBrowse.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.collection,
      code: COLLECTION_ERR_OTHER,
    ),
  );
}
