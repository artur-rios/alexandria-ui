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

/// One member of a collection, as the members screen lists it (UC-27).
///
/// A projection over the two things a collection can hold: the screen shows a
/// name and removes by uuid, and which table the row came from is the
/// collection's `kind`, not something each row has to restate.
@freezed
abstract class CollectionMember with _$CollectionMember {
  /// Creates a member.
  const factory CollectionMember({required String uuid, required String name}) =
      _CollectionMember;
}

/// What listing a collection's members produced (UC-27 main flow step 2).
@freezed
sealed class CollectionMembers with _$CollectionMembers {
  /// The core answered, possibly with nothing.
  const factory CollectionMembers.loaded({
    required CollectionKind kind,
    required List<CollectionMember> members,
  }) = CollectionMembersLoaded;

  /// The core could not answer (AF-03, AF-05).
  const factory CollectionMembers.failed({required Failure failure}) =
      CollectionMembersFailed;
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

  /// The current members of the collection [uuid] identifies (FR-OG-06).
  Future<CollectionMembers> members({
    required String uuid,
    required String credential,
  });

  /// Adds [itemUuid] to the collection [uuid] identifies (FR-OG-04).
  ///
  /// One item per call, deliberately. The core's own call takes a list and
  /// validates every uuid before linking any, so a batch containing one bad
  /// item links nothing and answers a single reason — which cannot satisfy
  /// UC-27 AF-04's "report exactly which succeeded and which did not". One
  /// call per item is what makes that answerable.
  Future<CollectionWrite> addItem({
    required String uuid,
    required String itemUuid,
    required String credential,
  });

  /// Removes [itemUuid] from the collection [uuid] identifies (FR-OG-05).
  ///
  /// The item stays in the catalog; only the link goes.
  Future<CollectionWrite> removeItem({
    required String uuid,
    required String itemUuid,
    required String credential,
  });
}
