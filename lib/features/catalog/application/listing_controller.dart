import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/catalog_file.dart';
import '../domain/catalog_gateway.dart';
import '../domain/file_type.dart';
import '../domain/listing_view.dart';

/// The files of the type the owner has selected (UC-09, FR-CT-02).
///
/// It watches the shell's destination rather than taking the type as an
/// argument, so selecting a type in the panel *is* what loads its listing —
/// main flow steps 2 and 3 are one movement, and nothing has to remember to
/// ask.
///
/// While a new type loads, `AsyncValue` keeps the previous value alongside its
/// loading flag, which is what leaves the last listing on screen instead of
/// blanking it (AF-02's "leaves the previous listing intact").
class ListingController extends AsyncNotifier<List<CatalogFile>> {
  @override
  Future<List<CatalogFile>> build() {
    final destination = ref.watch(shellControllerProvider);
    final type = fileTypeFor(destination);

    // Watched, so changing a filter or a sort reloads the listing without
    // anything having to remember to ask for it (UC-12 main flow steps 2
    // and 4).
    final view = type == null
        ? ListingView.initial
        : ref.watch(listingViewControllerProvider).forType(type);

    return _load(type, view);
  }

  Future<List<CatalogFile>> _load(FileType? type, ListingView view) async {
    // Home is the dashboard (UC-14) and bookmarks are not files (UC-28), so
    // there is nothing for this to fetch.
    if (type == null) return const [];

    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    // No session, no catalog call (FR-AU-07).
    if (credential == null) return const [];

    final listing = await ref
        .read(catalogGatewayProvider)
        .listFiles(
          type: type,
          credential: credential,
          lifecycle: view.lifecycle,
        );

    switch (listing) {
      // Ordered here rather than by the core, which publishes no sort on a
      // listing (main flow step 4). Only the file is wanted here — the
      // metadata each row now carries belongs to the callers that read it.
      case CatalogListingLoaded(:final files):
        return sortFiles([for (final row in files) row.file], view);

      // AF-04: the core rejected the session. Discarding it returns the owner
      // to login; the failure is still thrown so the listing does not read as
      // an empty library on the way out.
      case CatalogListingFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);
        throw failure;

      // UC-09 AF-02: thrown rather than returned empty, so the shell's
      // AsyncStateView renders the failure and its retry — and so "we could
      // not ask" is never mistaken for "there is nothing here".
      //
      // UC-12 AF-04 is the same failure read differently: the core refusing a
      // filter is invalid input, and the view reverts rather than the listing
      // simply reporting an error it cannot act on.
      case CatalogListingFailed(failure: final InvalidInputFailure failure):
        await ref
            .read(listingViewControllerProvider.notifier)
            .revert(type, failure);
        throw failure;

      case CatalogListingFailed(:final failure):
        throw failure;
    }
  }

  /// Loads the current type again (UC-09 AF-02's retry).
  Future<void> reload() async {
    final type = fileTypeFor(ref.read(shellControllerProvider));
    final view = type == null
        ? ListingView.initial
        : ref.read(listingViewControllerProvider).forType(type);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load(type, view));
  }
}

/// Every type's item count, for the navigation panel (FR-CT-01).
///
/// The core publishes no count call, so the count is still the length of the
/// listing it would return — but one listing, not one per type. Asking per
/// type meant serializing the whole catalog out of the core, across the FFI
/// boundary and through a JSON decode once for every type in the panel, and
/// again after every scan, purge and restore. The one call omits the type
/// filter, which the core reads as every type, and the tally is done here.
///
/// Kept apart from the listing so the panel's numbers do not disappear while
/// a listing reloads.
class TypeCountsController extends AsyncNotifier<Map<FileType, int>> {
  @override
  Future<Map<FileType, int>> build() async {
    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (credential == null) return const {};

    final listing = await ref
        .read(catalogGatewayProvider)
        .listFiles(credential: credential);

    switch (listing) {
      // Every type starts at zero and is counted up, so a type with no files
      // is a real zero rather than a gap. The distinction the panel draws is
      // between a zero and *no number at all*, and no number is what a
      // failure below produces.
      case CatalogListingLoaded(:final files):
        final counts = <FileType, int>{
          for (final type in FileType.values) type: 0,
        };
        for (final row in files) {
          counts[row.file.type] = (counts[row.file.type] ?? 0) + 1;
        }
        return counts;

      // The core rejected the session, as in [ListingController]: discarding
      // it returns the owner to login, and the failure is still thrown so the
      // panel does not read as an empty catalog on the way out.
      case CatalogListingFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);
        throw failure;

      // Thrown rather than answered as an empty map, so the dashboard's
      // counts section renders its failure and the retry beside it — which
      // was unreachable while this returned. A zero the owner reads as
      // "nothing here" would be a lie about a query that never answered, and
      // an empty map is that lie told for every type at once.
      //
      // One call means this is all-or-nothing where it used to be able to
      // lose a single type. That is the honest shape: one call is all there
      // is to fail.
      case CatalogListingFailed(:final failure):
        throw failure;
    }
  }

  /// Counts every type again — after an index run, for instance.
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}
