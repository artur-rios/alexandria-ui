import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../shell/domain/session_activity.dart';

/// The catalog's share of signing out (UC-03 main flow step 3, FR-AU-09).
///
/// Every catalog provider is kept for the run rather than disposed with the
/// widget that read it, which is what makes a listing instant on the way back
/// to it. That same caching is why signing out has to say so explicitly: the
/// projections would otherwise still be there for whoever signs in next, and
/// BR-05 keeps nothing of a session past its end.
///
/// Invalidation rather than a clear method on each controller: the projections
/// are derived from the core, so the honest reset is "forget this and read it
/// again", and every controller already knows how to build itself from empty.
class CatalogSessionActivity implements SessionActivity {
  /// Creates the activity over [_ref].
  const CatalogSessionActivity(this._ref);

  final Ref _ref;

  /// The catalog holds nothing unsaved: the metadata form writes through the
  /// core as it saves (UC-15), and there is no draft left behind when it
  /// closes.
  @override
  bool get holdsUnsavedChanges => false;

  /// Nothing here outlives the session — these are projections, not work.
  @override
  bool get continuesInTheCore => false;

  @override
  Future<void> end() async {
    // The catalog itself, and everything derived from it.
    _ref.invalidate(listingControllerProvider);
    _ref.invalidate(typeCountsControllerProvider);
    _ref.invalidate(recentFilesProvider);
    _ref.invalidate(catalogSearchProvider);

    // What the owner had open, and what they had typed. Both are as much a
    // trace of the session as the records themselves.
    _ref.invalidate(searchTermProvider);
    _ref.invalidate(openFileProvider);
    _ref.invalidate(fileDetailsControllerProvider);
    _ref.invalidate(musicMetadataEditorProvider);
    _ref.invalidate(videoMetadataEditorProvider);
    _ref.invalidate(fileRenameControllerProvider);
    // Read from the catalog, so it goes when the catalog does (UC-20).
    _ref.invalidate(musicLibraryProvider);
    // The bookmarks are the core's too, and just as much a trace of the
    // session as the catalog (UC-28).
    _ref.invalidate(bookmarksControllerProvider);
    _ref.invalidate(bookmarkFormProvider);
    _ref.invalidate(collectionsControllerProvider);
    _ref.invalidate(collectionsFormProvider);
    _ref.invalidate(openCollectionProvider);
    _ref.invalidate(collectionMembersControllerProvider);
    _ref.invalidate(collectionCandidatesControllerProvider);
    _ref.invalidate(collectionMembershipFormProvider);
    // The watchlists are the core's, and just as much a trace of the session
    // (UC-29).
    _ref.invalidate(watchlistsControllerProvider);
    _ref.invalidate(watchlistsFormProvider);
    _ref.invalidate(trackedVideosProvider);
    _ref.invalidate(watchProgressEditorProvider);
    _ref.invalidate(readingListsControllerProvider);
    _ref.invalidate(readingListsFormProvider);
    _ref.invalidate(trackedReadingItemsProvider);
    _ref.invalidate(readingProgressEditorProvider);
    _ref.invalidate(deletionControllerProvider);
    _ref.invalidate(openFileHoldsProvider);
    _ref.invalidate(deletedItemsControllerProvider);
    _ref.invalidate(restoreControllerProvider);
    _ref.invalidate(purgeControllerProvider);
    _ref.invalidate(missingFilesControllerProvider);

    // The layout and the per-type filters are deliberately left alone: they
    // are how the owner prefers to see their library, not a projection of it,
    // and UC-10 and UC-12 carry them across the run on purpose.
  }
}
