import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/collection.dart';
import '../domain/collection_gateway.dart';

/// The collection whose members are open, or `null` when none is (UC-27 main
/// flow step 1).
class OpenCollection extends Notifier<Collection?> {
  @override
  Collection? build() => null;

  /// Opens [collection]'s members (step 1).
  void open(Collection collection) => state = collection;

  /// Returns to the collections list.
  void close() => state = null;
}

/// The open collection's current members (UC-27 main flow step 2).
class CollectionMembersController
    extends AsyncNotifier<List<CollectionMember>> {
  @override
  Future<List<CollectionMember>> build() async {
    // Watched, so opening a different collection reads its members without
    // anything having to remember to ask.
    final collection = ref.watch(openCollectionProvider);
    if (collection == null) return const [];

    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07).
    if (credential == null) return const [];

    final members = await ref
        .read(collectionGatewayProvider)
        .members(uuid: collection.uuid, credential: credential);

    switch (members) {
      case CollectionMembersLoaded(members: final rows):
        return rows;

      // AF-05: a rejected session returns the owner to login.
      case CollectionMembersFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        return const [];

      case CollectionMembersFailed(:final failure):
        throw failure;
    }
  }

  /// Reads them again (steps 4 and 5, and AF-03's refresh).
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

/// What the members screen is reporting, if anything (UC-27).
class MembershipReport {
  /// Creates a report.
  const MembershipReport({
    this.additions = const [],
    this.alreadyPresent = const [],
    this.notFound = false,
    this.requestFailure,
  });

  /// What became of each item an addition covered (AF-04).
  final List<ReportedAddition> additions;

  /// The items that were already members, which the core was not asked about
  /// (AF-02).
  final List<String> alreadyPresent;

  /// Whether the core reported the collection or an item as gone (AF-03).
  final bool notFound;

  /// Why the request itself was refused, when it was.
  final Failure? requestFailure;

  /// Whether there is anything to say.
  bool get isEmpty =>
      additions.isEmpty &&
      alreadyPresent.isEmpty &&
      !notFound &&
      requestFailure == null;

  /// The additions that did not land.
  List<ReportedAddition> get failed => [
    for (final addition in additions)
      if (!addition.added) addition,
  ];
}

/// One item's outcome, named as the owner chose it (UC-27 AF-04).
///
/// The core answers by uuid; a report that showed uuids would be telling the
/// owner about identifiers they never saw.
class ReportedAddition {
  /// Creates an outcome.
  const ReportedAddition({
    required this.name,
    required this.added,
    this.reason,
  });

  /// What the item is called.
  final String name;

  /// Whether the core linked it.
  final bool added;

  /// Why it did not, when the core named a reason this version knows.
  final ItemRejection? reason;
}

/// Drives UC-27: adding items to a collection and taking them out again.
class CollectionMembershipForm extends Notifier<MembershipReport> {
  @override
  MembershipReport build() => const MembershipReport();

  /// Clears whatever the screen was reporting.
  void acknowledge() => state = const MembershipReport();

  /// Adds [candidates] to the open collection (main flow steps 3 and 4).
  ///
  /// One core call for the batch. The core links what it can and answers what
  /// became of each item, which is what AF-04 reports — this used to be a call
  /// per item, because the core rejected a whole batch over one bad member.
  Future<void> add(List<CollectionMember> candidates) async {
    final collection = ref.read(openCollectionProvider);
    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (collection == null || credential == null) return;

    // AF-02: an item already in the collection is reported as such, and the
    // core is not asked about it — it would link it a second time to no
    // effect.
    final present = {
      for (final member
          in ref.read(collectionMembersControllerProvider).value ??
              const <CollectionMember>[])
        member.uuid,
    };

    final alreadyPresent = <String>[];
    final toAdd = <CollectionMember>[];
    for (final candidate in candidates) {
      if (present.contains(candidate.uuid)) {
        alreadyPresent.add(candidate.name);
      } else {
        toAdd.add(candidate);
      }
    }

    if (toAdd.isEmpty) {
      state = MembershipReport(alreadyPresent: alreadyPresent);
      return;
    }

    final outcome = await ref
        .read(collectionGatewayProvider)
        .addItems(
          uuid: collection.uuid,
          itemUuids: [for (final candidate in toAdd) candidate.uuid],
          credential: credential,
        );

    switch (outcome) {
      case CollectionAdditionsReported(:final items):
        // The core answers by uuid; the report names what the owner chose.
        final names = {
          for (final candidate in toAdd) candidate.uuid: candidate.name,
        };

        state = MembershipReport(
          additions: [
            for (final item in items)
              ReportedAddition(
                name: names[item.itemUuid] ?? item.itemUuid,
                added: item.added,
                reason: item.reason,
              ),
          ],
          alreadyPresent: alreadyPresent,
        );
        await ref.read(collectionMembersControllerProvider.notifier).reload();

      // AF-05: the session is discarded, which returns the owner to login.
      case CollectionAdditionsFailed(
        failure: final UnauthorizedFailure failure,
      ):
        session.invalidate(failure);

      // AF-03: the collection is gone. Nothing was linked, and there is
      // nothing to report per item.
      case CollectionAdditionsFailed(failure: NotFoundFailure()):
        state = const MembershipReport(notFound: true);
        await ref.read(collectionMembersControllerProvider.notifier).reload();

      case CollectionAdditionsFailed(:final failure):
        state = MembershipReport(requestFailure: failure);
    }
  }

  /// Removes [member] from the open collection (steps 5 and 6).
  ///
  /// The item stays in the catalog and disappears only from this collection —
  /// that is the core's own guarantee, not something arranged here.
  Future<void> remove(CollectionMember member) async {
    final collection = ref.read(openCollectionProvider);
    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (collection == null || credential == null) return;

    final outcome = await ref
        .read(collectionGatewayProvider)
        .removeItem(
          uuid: collection.uuid,
          itemUuid: member.uuid,
          credential: credential,
        );

    switch (outcome) {
      case CollectionWriteDone():
        state = const MembershipReport();
        await ref.read(collectionMembersControllerProvider.notifier).reload();

      // AF-05.
      case CollectionWriteFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);

      // AF-03: the collection or the item is gone, so the membership is read
      // again and the screen says so.
      case CollectionWriteFailed(failure: NotFoundFailure()):
        state = const MembershipReport(notFound: true);
        await ref.read(collectionMembersControllerProvider.notifier).reload();

      case CollectionWriteFailed(:final failure):
        state = MembershipReport(requestFailure: failure);
    }
  }
}
