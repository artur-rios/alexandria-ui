import 'package:alexandria_desktop/features/organization/domain/collection.dart';
import 'package:alexandria_desktop/features/organization/domain/collection_gateway.dart';

/// A [CollectionGateway] that never reaches the core (Testing Specification
/// §2.3).
class FakeCollectionGateway implements CollectionGateway {
  /// Creates a gateway holding [collections].
  FakeCollectionGateway({List<Collection>? collections})
    : collections = [...?collections];

  /// What a browse answers.
  final List<Collection> collections;

  /// What [browse] answers instead, when a test says so.
  CollectionBrowse? browseOutcome;

  /// What the next write answers, in order.
  ///
  /// A list rather than one outcome, so a test can have the core refuse once
  /// and accept the retry — which is the whole of AF-02: the form stays open
  /// and the owner corrects it.
  final List<CollectionWrite> writeOutcomes = [];

  /// Every collection created, in order.
  final List<({String name, CollectionKind kind})> created = [];

  /// Every rename asked for, in order.
  final List<({String uuid, String name})> renamed = [];

  /// Every collection deleted, in order.
  final List<String> deleted = [];

  /// The kind each browse was filtered by, in order.
  final List<CollectionKind?> filters = [];

  @override
  Future<CollectionBrowse> browse({
    required String credential,
    CollectionKind? kind,
  }) async {
    filters.add(kind);
    if (browseOutcome case final outcome?) return outcome;

    return CollectionBrowse.loaded(
      collections: [
        for (final collection in collections)
          if (kind == null || collection.kind == kind) collection,
      ],
    );
  }

  @override
  Future<CollectionWrite> create({
    required String name,
    required CollectionKind kind,
    required String credential,
  }) async {
    created.add((name: name, kind: kind));
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    collections.add(
      Collection(uuid: 'created-${collections.length}', name: name, kind: kind),
    );
    return const CollectionWrite.done();
  }

  @override
  Future<CollectionWrite> rename({
    required String uuid,
    required String name,
    required String credential,
  }) async {
    renamed.add((uuid: uuid, name: name));
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    final index = collections.indexWhere((c) => c.uuid == uuid);
    if (index >= 0) {
      collections[index] = collections[index].copyWith(name: name);
    }
    return const CollectionWrite.done();
  }

  @override
  Future<CollectionWrite> delete({
    required String uuid,
    required String credential,
  }) async {
    deleted.add(uuid);
    if (writeOutcomes.isNotEmpty) return writeOutcomes.removeAt(0);

    collections.removeWhere((c) => c.uuid == uuid);
    return const CollectionWrite.done();
  }
}
