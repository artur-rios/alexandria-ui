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

  @override
  Future<CollectionMembers> members({
    required String uuid,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.collectionListItems(uuid, credential);
    } on CoreCallException {
      return _unreadableMembers();
    }

    if (!CoreStatusFamily.collection.isOk(response.status)) {
      return CollectionMembers.failed(
        failure: mapCoreStatus(CoreStatusFamily.collection, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadableMembers();

    try {
      final body = jsonDecode(json) as Map<String, dynamic>;
      final kind = CollectionKind.fromWireName(body['kind'] as String?);
      if (kind == null) return _unreadableMembers();

      final items = body['items'];

      return CollectionMembers.loaded(
        kind: kind,
        members: [
          if (items is List<dynamic>)
            for (final item in items)
              if (item is Map<String, dynamic>) ?_memberFrom(item),
        ],
      );
    } on Object {
      return _unreadableMembers();
    }
  }

  @override
  Future<CollectionAdditions> addItems({
    required String uuid,
    required List<String> itemUuids,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.collectionAddItems(
        uuid,
        jsonEncode({'itemUuids': itemUuids}),
        credential,
      );
    } on CoreCallException {
      return _unaddable();
    }

    if (!CoreStatusFamily.collection.isOk(response.status)) {
      // AF-03 and AF-05: the request itself was refused, so there is nothing
      // to report per item.
      return CollectionAdditions.failed(
        failure: mapCoreStatus(CoreStatusFamily.collection, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unaddable();

    try {
      final body = jsonDecode(json) as Map<String, dynamic>;
      final items = body['items'];
      if (items is! List) return _unaddable();

      return CollectionAdditions.reported(
        items: [
          for (final item in items)
            if (item is Map<String, dynamic>)
              ItemAddition(
                itemUuid: item['itemUuid'] as String,
                added: item['added'] as bool? ?? false,
                reason: ItemRejection.fromWireName(item['reason'] as String?),
              ),
        ],
      );
    } on Object {
      return _unaddable();
    }
  }

  @override
  Future<CollectionWrite> removeItem({
    required String uuid,
    required String itemUuid,
    required String credential,
  }) => _write(() => _core.collectionRemoveItem(uuid, itemUuid, credential));

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

  /// The member [row] describes, or `null` when it carries no uuid.
  ///
  /// A file row names itself `name`; a bookmark row names itself `title`. Both
  /// are "what this is called" to the screen, which is all it shows.
  static CollectionMember? _memberFrom(Map<String, dynamic> row) {
    final uuid = row['uuid'] as String?;
    if (uuid == null) return null;

    return CollectionMember(
      uuid: uuid,
      name: (row['name'] ?? row['title']) as String? ?? uuid,
    );
  }

  CollectionMembers _unreadableMembers() => const CollectionMembers.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.collection,
      code: COLLECTION_ERR_OTHER,
    ),
  );

  CollectionAdditions _unaddable() => const CollectionAdditions.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.collection,
      code: COLLECTION_ERR_OTHER,
    ),
  );

  CollectionBrowse _unreadable() => const CollectionBrowse.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.collection,
      code: COLLECTION_ERR_OTHER,
    ),
  );
}
