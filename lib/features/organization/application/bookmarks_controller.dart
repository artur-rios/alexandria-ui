import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/bookmark.dart';
import '../domain/bookmark_gateway.dart';

/// The owner's bookmarks (UC-28 main flow steps 1 and 2, FR-OG-10).
///
/// An [AsyncNotifier] like the catalog listings, for the same reason: the
/// screen shows a spinner, a list, or a failure, and that is what the type
/// already is.
class BookmarksController extends AsyncNotifier<List<Bookmark>> {
  @override
  Future<List<Bookmark>> build() async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07).
    if (credential == null) return const [];

    // Watched, so choosing a collection reloads the listing without anything
    // having to remember to ask (main flow step 1).
    final collectionUuid = ref.watch(bookmarkCollectionFilterProvider);

    final listing = await ref
        .read(bookmarkGatewayProvider)
        .list(credential: credential, collectionUuid: collectionUuid);

    switch (listing) {
      case BookmarkListingLoaded(:final bookmarks):
        return bookmarks;

      // AF-06: a rejected session returns the owner to login, as everywhere.
      case BookmarkListingFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        return const [];

      case BookmarkListingFailed(:final failure):
        throw failure;
    }
  }

  /// Reads the bookmarks again (main flow step 2, AF-05).
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

/// Where the bookmark form is (UC-28).
enum BookmarkFormStage {
  /// Closed.
  closed,

  /// Open, with the owner filling it in.
  editing,

  /// The call is in flight.
  saving,
}

/// The bookmark form's state (UC-28 main flow steps 3 to 5).
class BookmarkFormState {
  /// Creates a state.
  const BookmarkFormState({
    this.uuid,
    this.url = '',
    this.title = '',
    this.collectionUuid,
    this.stage = BookmarkFormStage.closed,
    this.urlError,
    this.titleError,
    this.rejection,
  });

  /// The bookmark being edited, or `null` when one is being created.
  final String? uuid;

  /// What the owner has typed.
  final String url;

  /// And as its title.
  final String title;

  /// The collection it is filed in, carried through an update untouched.
  final String? collectionUuid;

  /// Where the form is.
  final BookmarkFormStage stage;

  /// What local validation refused (AF-01).
  final BookmarkFieldError? urlError;

  /// And for the title.
  final BookmarkFieldError? titleError;

  /// What the core refused (AF-02, AF-05).
  final Failure? rejection;

  /// Whether the form is open at all.
  bool get isOpen => stage != BookmarkFormStage.closed;

  /// Whether the call is in flight.
  bool get isSaving => stage == BookmarkFormStage.saving;

  /// Whether this is an update rather than a creation.
  bool get isEditing => uuid != null;

  /// A copy with the given changes.
  ///
  /// The errors and the rejection are cleared rather than carried whenever
  /// they are not given: each belongs to one attempt.
  BookmarkFormState copyWith({
    String? uuid,
    String? url,
    String? title,
    String? collectionUuid,
    BookmarkFormStage? stage,
    BookmarkFieldError? urlError,
    BookmarkFieldError? titleError,
    Failure? rejection,
  }) => BookmarkFormState(
    uuid: uuid ?? this.uuid,
    url: url ?? this.url,
    title: title ?? this.title,
    collectionUuid: collectionUuid ?? this.collectionUuid,
    stage: stage ?? this.stage,
    urlError: urlError,
    titleError: titleError,
    rejection: rejection,
  );
}

/// Which collection the bookmarks listing is filtered to, or `null` for all
/// of them (UC-28 main flow step 1).
class BookmarkCollectionFilter extends Notifier<String?> {
  @override
  String? build() => null;

  /// Filters to [collectionUuid], or to everything when it is `null`.
  void choose(String? collectionUuid) => state = collectionUuid;
}

/// The form that creates and updates a bookmark (UC-28).
class BookmarkForm extends Notifier<BookmarkFormState> {
  @override
  BookmarkFormState build() => const BookmarkFormState();

  /// Opens the form empty, to create one (main flow step 3).
  void create() =>
      state = const BookmarkFormState(stage: BookmarkFormStage.editing);

  /// Opens it on [bookmark], to update it (main flow step 5).
  void edit(Bookmark bookmark) => state = BookmarkFormState(
    uuid: bookmark.uuid,
    url: bookmark.url,
    title: bookmark.title,
    // Seeded so the selector opens on where the bookmark actually is, and so
    // an update that does not touch it leaves it alone.
    collectionUuid: bookmark.collectionUuid,
    stage: BookmarkFormStage.editing,
  );

  /// Files the bookmark in [collectionUuid], or nowhere when it is `null`.
  ///
  /// Only a bookmark collection is offered (AF-03): a file collection would be
  /// refused by the core, and the selector is what keeps the owner from
  /// choosing one.
  void chooseCollection(String? collectionUuid) => state = BookmarkFormState(
    uuid: state.uuid,
    url: state.url,
    title: state.title,
    collectionUuid: collectionUuid,
    stage: state.stage,
  );

  /// Records the address, dropping the mark that was on it.
  void editUrl(String url) =>
      state = state.copyWith(url: url, titleError: state.titleError);

  /// Records the title, dropping the mark that was on it.
  void editTitle(String title) =>
      state = state.copyWith(title: title, urlError: state.urlError);

  /// Closes the form without sending anything.
  void close() => state = const BookmarkFormState();

  /// Validates and sends (main flow steps 4 and 5).
  Future<void> submit() async {
    if (state.isSaving) return;

    // AF-01 / FR-OG-12: marked, and the core is not called.
    final urlError = validateBookmarkUrl(state.url);
    final titleError = validateBookmarkTitle(state.title);
    if (urlError != null || titleError != null) {
      state = state.copyWith(urlError: urlError, titleError: titleError);
      return;
    }

    state = state.copyWith(stage: BookmarkFormStage.saving);

    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (credential == null) {
      state = state.copyWith(stage: BookmarkFormStage.editing);
      return;
    }

    final gateway = ref.read(bookmarkGatewayProvider);
    final uuid = state.uuid;
    final outcome = uuid == null
        ? await gateway.create(
            url: state.url.trim(),
            title: state.title.trim(),
            credential: credential,
            collectionUuid: state.collectionUuid,
          )
        : await gateway.update(
            uuid: uuid,
            url: state.url.trim(),
            title: state.title.trim(),
            credential: credential,
            collectionUuid: state.collectionUuid,
          );

    switch (outcome) {
      case BookmarkSaved():
        // Step 2 again: the listing reads the core rather than being patched
        // here, because the core is what holds it.
        await ref.read(bookmarksControllerProvider.notifier).reload();
        // The form is finished, so it closes. What it wrote is in the listing
        // behind it, which is where the owner looks next.
        state = const BookmarkFormState();

      // AF-06: the session is discarded, which returns the owner to login.
      case BookmarkWriteFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);
        state = const BookmarkFormState();

      // AF-05: the bookmark is gone. The form closes and the listing is read
      // again, because what it was showing is no longer there.
      case BookmarkWriteFailed(failure: final NotFoundFailure failure):
        await ref.read(bookmarksControllerProvider.notifier).reload();
        state = state.copyWith(
          rejection: failure,
          stage: BookmarkFormStage.editing,
        );

      // AF-02: the core's reason is final and the form stays open with what
      // the owner wrote, so they can act on it.
      case BookmarkWriteFailed(:final failure):
        state = state.copyWith(
          rejection: failure,
          stage: BookmarkFormStage.editing,
        );
    }
  }
}
