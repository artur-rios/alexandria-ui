import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import 'collection.dart';

part 'collection_gateway.freezed.dart';

/// What listing the collections produced (UC-26 main flow step 1).
@freezed
sealed class CollectionBrowse with _$CollectionBrowse {
  /// The core answered, possibly with nothing.
  const factory CollectionBrowse.loaded({
    required List<Collection> collections,
  }) = CollectionBrowseLoaded;

  /// The core could not answer (AF-05, and anything unexpected).
  const factory CollectionBrowse.failed({required Failure failure}) =
      CollectionBrowseFailed;
}

/// What creating, renaming, or deleting a collection produced (UC-26 main flow
/// steps 4 to 6).
@freezed
sealed class CollectionWrite with _$CollectionWrite {
  /// The core applied it.
  ///
  /// The record the core echoes is not carried: the screen reads the
  /// collections again afterwards, so the echo has nothing left to tell it —
  /// and reading again is what keeps the item counts right.
  const factory CollectionWrite.done() = CollectionWriteDone;

  /// The core refused (AF-02, AF-04, AF-05).
  const factory CollectionWrite.failed({required Failure failure}) =
      CollectionWriteFailed;
}

/// The core's collection operations (FR-OG-01 … FR-OG-03, FR-OG-06).
abstract interface class CollectionGateway {
  /// Every collection, or those of [kind] (FR-OG-06).
  ///
  /// The read that makes the rest reachable: every other operation addresses a
  /// uuid, and this is where those uuids come from.
  Future<CollectionBrowse> browse({
    required String credential,
    CollectionKind? kind,
  });

  /// Creates a collection of [kind] (FR-OG-01).
  Future<CollectionWrite> create({
    required String name,
    required CollectionKind kind,
    required String credential,
  });

  /// Renames the collection [uuid] identifies (FR-OG-02).
  Future<CollectionWrite> rename({
    required String uuid,
    required String name,
    required String credential,
  });

  /// Deletes the collection [uuid] identifies (FR-OG-03).
  ///
  /// The items it held are unlinked and stay in the catalog, which is what the
  /// confirmation has to say before this is reached.
  Future<CollectionWrite> delete({
    required String uuid,
    required String credential,
  });
}
