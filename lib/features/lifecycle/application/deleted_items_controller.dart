import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../catalog/domain/catalog_gateway.dart';
import '../../catalog/domain/library_type.dart';
import '../../catalog/domain/listing_view.dart';
import '../../organization/domain/bookmark_gateway.dart';
import '../domain/deleted_record.dart';
import '../domain/retention.dart';
import '../domain/lifecycle_gateway.dart';

/// Everything the core holds as deleted (UC-34 main flow steps 2 and 3).
///
/// Every file type is asked, plus the bookmarks: the core publishes a listing
/// per type and no call that answers "everything deleted" at once, so this is
/// that call, assembled here. The cost is one call per type and one for the
/// bookmarks, paid when the view opens.
class DeletedItemsController extends AsyncNotifier<List<DeletedRecord>> {
  @override
  Future<List<DeletedRecord>> build() async {
    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    // No session, no call (FR-AU-07).
    if (credential == null) return const [];

    final catalog = ref.read(catalogGatewayProvider);
    final records = <DeletedRecord>[];

    for (final type in LibraryType.values) {
      final listing = await catalog.listFiles(
        type: type,
        credential: credential,
        lifecycle: LifecycleFilter.deleted,
      );

      switch (listing) {
        case CatalogListingLoaded(:final files):
          records.addAll(files.map(DeletedRecord.ofFile));

        // AF-05: a rejected session returns the owner to login.
        case CatalogListingFailed(failure: final UnauthorizedFailure failure):
          session.invalidate(failure);
          return const [];

        // One type the core will not answer must not take the others down
        // with it, the same way a listing's does not (UC-09 AF-02).
        case CatalogListingFailed():
          continue;
      }
    }

    final bookmarks = await ref
        .read(bookmarkGatewayProvider)
        .list(credential: credential, deleted: true);

    switch (bookmarks) {
      case BookmarkListingLoaded(bookmarks: final rows):
        records.addAll(rows.map(DeletedRecord.ofBookmark));

      case BookmarkListingFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);
        return const [];

      case BookmarkListingFailed():
        break;
    }

    // Most recently deleted first, which is the order an owner looking for
    // something they just deleted reads in. A record the core answered
    // without a timestamp sorts last rather than first: it is the one this
    // cannot place.
    records.sort((a, b) {
      final left = a.deletedAt;
      final right = b.deletedAt;
      if (left == null) return right == null ? 0 : 1;
      if (right == null) return -1;

      return right.compareTo(left);
    });

    return records;
  }

  /// Reads them again (AF-03's refresh, and step 6's).
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

/// The retention window the core enforces (UC-34, FR-LC-03).
///
/// Read once per session and held: it is configuration, not state, and a call
/// per row would ask the same question of the same process repeatedly.
class RetentionWindowController extends AsyncNotifier<int?> {
  @override
  Future<int?> build() async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07).
    if (credential == null) return null;

    final window = await ref
        .read(retentionGatewayProvider)
        .window(credential: credential);

    return switch (window) {
      RetentionWindowLoaded(:final days) => days,
      // The view still lists what is deleted and still restores; it simply
      // shows no countdown. That is the honest outcome — the alternative is
      // the assumption this call exists to remove.
      RetentionWindowFailed() => null,
    };
  }
}

/// What the deleted view is reporting, if anything (UC-34).
enum RestoreNotice {
  /// Nothing.
  none,

  /// The core has no such record, or it is past its retention window (AF-03).
  notFound,

  /// The core refused for a reason of its own.
  refused,
}

/// Drives UC-34's restore (main flow steps 4 to 6).
class RestoreController
    extends Notifier<({RestoreNotice notice, Failure? refusal})> {
  @override
  ({RestoreNotice notice, Failure? refusal}) build() =>
      (notice: RestoreNotice.none, refusal: null);

  /// Clears whatever the view was reporting.
  void acknowledge() => state = (notice: RestoreNotice.none, refusal: null);

  /// Restores [record] (steps 4 to 6).
  Future<void> restore(DeletedRecord record) async {
    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (credential == null) return;

    final gateway = ref.read(lifecycleGatewayProvider);
    final outcome = switch (record.kind) {
      DeletedRecordKind.file => await gateway.restoreFile(
        uuid: record.uuid,
        credential: credential,
      ),
      DeletedRecordKind.bookmark => await gateway.restoreBookmark(
        uuid: record.uuid,
        credential: credential,
      ),
    };

    switch (outcome) {
      case LifecycleWriteDone():
        state = (notice: RestoreNotice.none, refusal: null);
        // Step 6: the record leaves this view and returns to the default
        // listings, both by reading the core again (FR-LC-09). AF-04 needs
        // nothing more — a file whose bytes went missing since the deletion
        // comes back marked missing, because that marking is the core's.
        await _refresh();

      // AF-05: the session is discarded, which returns the owner to login.
      case LifecycleWriteFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);

      // AF-03, and AF-02 as the core reports it: a record past its retention
      // window is answered as not found.
      case LifecycleWriteFailed(failure: final NotFoundFailure failure):
        state = (notice: RestoreNotice.notFound, refusal: failure);
        await _refresh();

      case LifecycleWriteFailed(:final failure):
        state = (notice: RestoreNotice.refused, refusal: failure);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(listingControllerProvider);
    // The details view offers the restore too (UC-13 AF-02), and a record that
    // came back has to stop reading as deleted in the dialog that restored it.
    ref.invalidate(fileDetailsControllerProvider);
    ref.invalidate(typeCountsControllerProvider);
    ref.invalidate(recentFilesProvider);
    ref.invalidate(catalogSearchProvider);
    ref.invalidate(bookmarksControllerProvider);

    await ref.read(deletedItemsControllerProvider.notifier).reload();
  }
}
