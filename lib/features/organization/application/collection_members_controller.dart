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

/// What became of one item in an addition (UC-27 AF-04).
class ItemAddition {
  /// Records that [name] was added, or was not and why.
  const ItemAddition({
    required this.name,
    required this.succeeded,
    this.failure,
  });

  /// What the item is called, so the report names it rather than a uuid.
  final String name;

  /// Whether the core linked it.
  final bool succeeded;

  /// Why it did not, when it did not.
  final Failure? failure;
}

/// What the members screen is reporting, if anything (UC-27).
class MembershipReport {
  /// Creates a report.
  const MembershipReport({
    this.additions = const [],
    this.alreadyPresent = const [],
    this.notFound = false,
  });

  /// What became of each item an addition covered (AF-04).
  final List<ItemAddition> additions;

  /// The items that were already members, which the core was not asked about
  /// (AF-02).
  final List<String> alreadyPresent;

  /// Whether the core reported the collection or an item as gone (AF-03).
  final bool notFound;

  /// Whether there is anything to say.
  bool get isEmpty => additions.isEmpty && alreadyPresent.isEmpty && !notFound;

  /// The additions that did not land.
  List<ItemAddition> get failed => [
    for (final addition in additions)
      if (!addition.succeeded) addition,
  ];
}

/// Drives UC-27: adding items to a collection and taking them out again.
class CollectionMembershipForm extends Notifier<MembershipReport> {
  @override
  MembershipReport build() => const MembershipReport();

  /// Clears whatever the screen was reporting.
  void acknowledge() => state = const MembershipReport();

  /// Adds [candidates] to the open collection (main flow steps 3 and 4).
  ///
  /// One core call per item, so the report can name which landed and which did
  /// not (AF-04). The core's own call validates a whole batch before linking
  /// any of it, which would answer a single reason for the lot.
  Future<void> add(List<CollectionMember> candidates) async {
    final collection = ref.read(openCollectionProvider);
    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (collection == null || credential == null) return;

    // AF-02: an item already in the collection is reported as such, and the
    // core is not asked — it would link it a second time to no effect.
    final present = {
      for (final member
          in ref.read(collectionMembersControllerProvider).value ??
              const <CollectionMember>[])
        member.uuid,
    };

    final gateway = ref.read(collectionGatewayProvider);
    final additions = <ItemAddition>[];
    final alreadyPresent = <String>[];
    var sawNotFound = false;

    for (final candidate in candidates) {
      if (present.contains(candidate.uuid)) {
        alreadyPresent.add(candidate.name);
        continue;
      }

      final outcome = await gateway.addItem(
        uuid: collection.uuid,
        itemUuid: candidate.uuid,
        credential: credential,
      );

      switch (outcome) {
        case CollectionWriteDone():
          additions.add(ItemAddition(name: candidate.name, succeeded: true));

        // AF-05: the session is discarded, and the rest of the batch is
        // abandoned — every remaining call would be refused the same way.
        case CollectionWriteFailed(failure: final UnauthorizedFailure failure):
          session.invalidate(failure);
          return;

        case CollectionWriteFailed(failure: final NotFoundFailure failure):
          sawNotFound = true;
          additions.add(
            ItemAddition(
              name: candidate.name,
              succeeded: false,
              failure: failure,
            ),
          );

        // AF-01 as the core sees it: an item of the wrong kind. The screen
        // does not offer one, so reaching this means the owner got here
        // another way — and the core's reason is what says why.
        case CollectionWriteFailed(:final failure):
          additions.add(
            ItemAddition(
              name: candidate.name,
              succeeded: false,
              failure: failure,
            ),
          );
      }
    }

    state = MembershipReport(
      additions: additions,
      alreadyPresent: alreadyPresent,
      notFound: sawNotFound,
    );
    await ref.read(collectionMembersControllerProvider.notifier).reload();
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
        state = MembershipReport(
          additions: [
            ItemAddition(name: member.name, succeeded: false, failure: failure),
          ],
        );
    }
  }
}
