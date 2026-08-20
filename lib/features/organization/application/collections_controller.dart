import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/collection.dart';
import '../domain/collection_gateway.dart';

/// The owner's collections (UC-26 main flow step 1).
class CollectionsController extends AsyncNotifier<List<Collection>> {
  @override
  Future<List<Collection>> build() async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07).
    if (credential == null) return const [];

    final browse = await ref
        .read(collectionGatewayProvider)
        .browse(credential: credential);

    switch (browse) {
      case CollectionBrowseLoaded(:final collections):
        return collections;

      // AF-05: a rejected session returns the owner to login.
      case CollectionBrowseFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        return const [];

      case CollectionBrowseFailed(:final failure):
        throw failure;
    }
  }

  /// Reads them again (AF-04's refresh, and every write's).
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

/// What the collections screen is reporting, if anything (UC-26).
enum CollectionNotice {
  /// Nothing.
  none,

  /// The core has no such collection (AF-04).
  notFound,

  /// The core refused for a reason of its own (AF-02).
  refused,
}

/// The collections screen's own state, beside the collections themselves.
class CollectionsState {
  /// Creates a state.
  const CollectionsState({
    this.name = '',
    this.kind = CollectionKind.file,
    this.nameError,
    this.isWriting = false,
    this.renaming,
    this.notice = CollectionNotice.none,
    this.refusal,
  });

  /// The name being typed into the create field.
  final String name;

  /// The kind the new collection will hold (main flow step 2).
  final CollectionKind kind;

  /// What local validation refused (AF-01).
  final CollectionNameError? nameError;

  /// Whether a write is in flight.
  final bool isWriting;

  /// The collection being renamed, or `null` when none is (step 5).
  final String? renaming;

  /// What the screen is reporting.
  final CollectionNotice notice;

  /// The core's own reason, when it gave one.
  final Failure? refusal;

  /// A copy with the given changes.
  ///
  /// The mark and the notice are cleared rather than carried whenever they are
  /// not given: each belongs to one attempt.
  CollectionsState copyWith({
    String? name,
    CollectionKind? kind,
    CollectionNameError? nameError,
    bool? isWriting,
    String? renaming,
    CollectionNotice notice = CollectionNotice.none,
    Failure? refusal,
  }) => CollectionsState(
    name: name ?? this.name,
    kind: kind ?? this.kind,
    nameError: nameError,
    isWriting: isWriting ?? this.isWriting,
    renaming: renaming,
    notice: notice,
    refusal: refusal,
  );
}

/// Drives UC-26: creating, renaming, and deleting collections.
class CollectionsForm extends Notifier<CollectionsState> {
  @override
  CollectionsState build() => const CollectionsState();

  /// Records the name being typed, dropping the mark that was on it.
  void editName(String name) =>
      state = state.copyWith(name: name, renaming: state.renaming);

  /// Chooses what a new collection will hold (step 2).
  void chooseKind(CollectionKind kind) =>
      state = state.copyWith(kind: kind, renaming: state.renaming);

  /// Opens [collection] for renaming, seeding the field with its name (step 5).
  void startRenaming(Collection collection) =>
      state = state.copyWith(name: collection.name, renaming: collection.uuid);

  /// Closes the rename without sending it.
  void cancelRenaming() => state = const CollectionsState();

  /// Clears whatever the screen was reporting.
  void acknowledge() => state = state.copyWith(renaming: state.renaming);

  /// Creates a collection (main flow steps 2 to 4).
  Future<void> create() async {
    if (state.isWriting) return;

    // AF-01: marked, and the core is not called.
    final nameError = validateCollectionName(state.name);
    if (nameError != null) {
      state = state.copyWith(nameError: nameError, renaming: state.renaming);
      return;
    }

    final kind = state.kind;
    await _call(
      (gateway, credential) => gateway.create(
        name: state.name.trim(),
        kind: kind,
        credential: credential,
      ),
    );
  }

  /// Renames the collection being renamed (step 5).
  Future<void> renameSubmitted() async {
    final uuid = state.renaming;
    if (uuid == null || state.isWriting) return;

    // AF-01 again: the same rule, on the same field.
    final nameError = validateCollectionName(state.name);
    if (nameError != null) {
      state = state.copyWith(nameError: nameError, renaming: uuid);
      return;
    }

    await _call(
      (gateway, credential) => gateway.rename(
        uuid: uuid,
        name: state.name.trim(),
        credential: credential,
      ),
    );
  }

  /// Deletes a collection (step 6).
  ///
  /// The confirmation is the screen's: it has to say that the contained items
  /// are preserved before this is reached (FR-OG-03, BR-07).
  Future<void> delete(String uuid) => _call(
    (gateway, credential) => gateway.delete(uuid: uuid, credential: credential),
  );

  /// Runs [call] and turns its answer into what the screen shows.
  Future<void> _call(
    Future<CollectionWrite> Function(CollectionGateway, String credential) call,
  ) async {
    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (credential == null) return;

    state = state.copyWith(isWriting: true, renaming: state.renaming);

    final outcome = await call(ref.read(collectionGatewayProvider), credential);

    switch (outcome) {
      case CollectionWriteDone():
        // The screen reads the core again rather than being patched here,
        // which is also what keeps the item counts right.
        await ref.read(collectionsControllerProvider.notifier).reload();
        state = const CollectionsState();

      // AF-05: the session is discarded, which returns the owner to login.
      case CollectionWriteFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);

      // AF-04: the collection is gone, so the screen says so and reads the
      // core again.
      case CollectionWriteFailed(failure: final NotFoundFailure failure):
        await ref.read(collectionsControllerProvider.notifier).reload();
        state = state.copyWith(
          isWriting: false,
          renaming: state.renaming,
          notice: CollectionNotice.notFound,
          refusal: failure,
        );

      // AF-02: the core refused the name. The form stays open with what the
      // owner typed, because correcting it is the next thing they do.
      case CollectionWriteFailed(:final failure):
        state = state.copyWith(
          isWriting: false,
          renaming: state.renaming,
          notice: CollectionNotice.refused,
          refusal: failure,
        );
    }
  }
}
