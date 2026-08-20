import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/reading_list.dart';
import '../domain/reading_list_gateway.dart';

/// The owner's reading lists and everything they track (UC-31, UC-32 step 2).
class ReadingListsController extends AsyncNotifier<List<ReadingList>> {
  @override
  Future<List<ReadingList>> build() async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07).
    if (credential == null) return const [];

    final browse = await ref
        .read(readingListGatewayProvider)
        .browse(credential: credential);

    switch (browse) {
      case ReadingListBrowseLoaded(:final readingLists):
        return readingLists;

      // AF-06: a rejected session returns the owner to login.
      case ReadingListBrowseFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        return const [];

      case ReadingListBrowseFailed(:final failure):
        throw failure;
    }
  }

  /// Reads them again (AF-04's refresh).
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

/// What the reading-lists screen is reporting, if anything.
enum ReadingListNotice {
  /// Nothing.
  none,

  /// The item is already in that reading list (UC-31 AF-03).
  alreadyTracked,

  /// The core has no such reading list or item (AF-04).
  notFound,

  /// The core refused for a reason of its own.
  refused,
}

/// The reading-lists screen's own state, beside the lists themselves (UC-31).
class ReadingListsState {
  /// Creates a state.
  const ReadingListsState({
    this.name = '',
    this.nameError,
    this.isCreating = false,
    this.notice = ReadingListNotice.none,
    this.refusal,
  });

  /// The name being typed into the create field.
  final String name;

  /// What local validation refused (AF-01).
  final ReadingListNameError? nameError;

  /// Whether a create is in flight.
  final bool isCreating;

  /// What the screen is reporting.
  final ReadingListNotice notice;

  /// The core's own reason, when it gave one.
  final Failure? refusal;

  /// A copy with the given changes.
  ReadingListsState copyWith({
    String? name,
    ReadingListNameError? nameError,
    bool? isCreating,
    ReadingListNotice notice = ReadingListNotice.none,
    Failure? refusal,
  }) => ReadingListsState(
    name: name ?? this.name,
    nameError: nameError,
    isCreating: isCreating ?? this.isCreating,
    notice: notice,
    refusal: refusal,
  );
}

/// Drives UC-31: creating reading lists and choosing what they track.
class ReadingListsForm extends Notifier<ReadingListsState> {
  @override
  ReadingListsState build() => const ReadingListsState();

  /// Records the name being typed, dropping the mark that was on it.
  void editName(String name) => state = state.copyWith(name: name);

  /// Clears whatever the screen was reporting.
  void acknowledge() => state = state.copyWith();

  /// Creates a reading list (main flow steps 1 and 2).
  Future<void> create() async {
    if (state.isCreating) return;

    // AF-01: marked, and the core is not called.
    final nameError = validateReadingListName(state.name);
    if (nameError != null) {
      state = state.copyWith(nameError: nameError);
      return;
    }

    state = state.copyWith(isCreating: true);

    await _call(
      (gateway, credential) =>
          gateway.create(name: state.name.trim(), credential: credential),
      onDone: () => state = const ReadingListsState(),
      onFailure: (notice, failure) => state = state.copyWith(
        isCreating: false,
        notice: notice,
        refusal: failure,
      ),
    );
  }

  /// Adds [itemUuid] to [readingListUuid] (main flow steps 3 and 4).
  ///
  /// AF-03 is answered before the call where the screen already knows the
  /// answer.
  Future<void> addItem({
    required String readingListUuid,
    required String itemUuid,
  }) async {
    final lists = ref.read(readingListsControllerProvider).value ?? const [];
    final target = lists
        .where((list) => list.uuid == readingListUuid)
        .firstOrNull;

    if (target != null && target.tracks(itemUuid)) {
      state = state.copyWith(notice: ReadingListNotice.alreadyTracked);
      return;
    }

    await _call(
      (gateway, credential) => gateway.addItem(
        uuid: readingListUuid,
        itemUuid: itemUuid,
        credential: credential,
      ),
    );
  }

  /// Removes it again (main flow step 5).
  Future<void> removeItem({
    required String readingListUuid,
    required String itemUuid,
  }) => _call(
    (gateway, credential) => gateway.removeItem(
      uuid: readingListUuid,
      itemUuid: itemUuid,
      credential: credential,
    ),
  );

  /// Deletes a reading list (main flow step 6).
  ///
  /// The confirmation is the screen's: it has to say that the books and comics
  /// are preserved before this is reached.
  Future<void> delete(String readingListUuid) => _call(
    (gateway, credential) =>
        gateway.delete(uuid: readingListUuid, credential: credential),
  );

  /// Runs [call] and turns its answer into what the screen shows.
  Future<void> _call(
    Future<ReadingListWrite> Function(ReadingListGateway, String credential)
    call, {
    void Function()? onDone,
    void Function(ReadingListNotice, Failure?)? onFailure,
  }) async {
    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (credential == null) return;

    final outcome = await call(
      ref.read(readingListGatewayProvider),
      credential,
    );

    switch (outcome) {
      case ReadingListWriteDone():
        // The screen reads the core again rather than being patched here.
        await ref.read(readingListsControllerProvider.notifier).reload();
        (onDone ?? () => state = state.copyWith())();

      // AF-06: the session is discarded, which returns the owner to login.
      case ReadingListWriteFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);

      // AF-04: the list or the item is gone, so the screen says so and reads
      // the core again.
      case ReadingListWriteFailed(failure: final NotFoundFailure failure):
        await ref.read(readingListsControllerProvider.notifier).reload();
        (onFailure ??
            (notice, failure) => state = state.copyWith(
              notice: notice,
              refusal: failure,
            ))(ReadingListNotice.notFound, failure);

      case ReadingListWriteFailed(:final failure):
        (onFailure ??
            (notice, failure) => state = state.copyWith(
              notice: notice,
              refusal: failure,
            ))(ReadingListNotice.refused, failure);
    }
  }
}
