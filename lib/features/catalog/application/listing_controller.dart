import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/catalog_file.dart';
import '../domain/catalog_gateway.dart';
import '../domain/library_type.dart';

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
    return _load(libraryTypeFor(destination));
  }

  Future<List<CatalogFile>> _load(LibraryType? type) async {
    // Home is the dashboard (UC-14) and bookmarks are not files (UC-28), so
    // there is nothing for this to fetch.
    if (type == null) return const [];

    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    // No session, no catalog call (FR-AU-07).
    if (credential == null) return const [];

    final listing = await ref
        .read(catalogGatewayProvider)
        .listFiles(type: type, credential: credential);

    switch (listing) {
      case CatalogListingLoaded(:final files):
        return files;

      // AF-04: the core rejected the session. Discarding it returns the owner
      // to login; the failure is still thrown so the listing does not read as
      // an empty library on the way out.
      case CatalogListingFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);
        throw failure;

      // AF-02: thrown rather than returned empty, so the shell's
      // AsyncStateView renders the failure and its retry — and so "we could
      // not ask" is never mistaken for "there is nothing here".
      case CatalogListingFailed(:final failure):
        throw failure;
    }
  }

  /// Loads the current type again (AF-02's retry).
  Future<void> reload() async {
    final type = libraryTypeFor(ref.read(shellControllerProvider));

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load(type));
  }
}

/// Every type's item count, for the navigation panel (FR-CT-01).
///
/// One query per type, because the core publishes no count call — the count is
/// the length of the listing it would return. Kept apart from the listing so
/// the panel's numbers do not disappear while a listing reloads.
class TypeCountsController extends AsyncNotifier<Map<LibraryType, int>> {
  @override
  Future<Map<LibraryType, int>> build() async {
    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (credential == null) return const {};

    final gateway = ref.read(catalogGatewayProvider);
    final counts = <LibraryType, int>{};

    for (final type in LibraryType.values) {
      final listing = await gateway.listFiles(
        type: type,
        credential: credential,
      );

      // A type that fails is left out rather than counted as zero: a zero the
      // owner reads as "nothing here" would be a lie about a query that never
      // answered. The panel shows no number for it.
      if (listing case CatalogListingLoaded(:final files)) {
        counts[type] = files.length;
      }
    }

    return counts;
  }

  /// Counts every type again — after an index run, for instance.
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}
