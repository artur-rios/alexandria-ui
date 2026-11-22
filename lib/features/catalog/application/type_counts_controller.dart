import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/catalog_gateway.dart';
import '../domain/file_type.dart';

/// Every type's item count, for the dashboard (FR-CT-01).
///
/// The core publishes no count call, so the count is still the length of the
/// listing it would return — but one listing, not one per type. Asking per
/// type meant serializing the whole catalog out of the core, across the FFI
/// boundary and through a JSON decode once for every type, and
/// again after every scan, purge and restore. The one call omits the type
/// filter, which the core reads as every type, and the tally is done here.
class TypeCountsController extends AsyncNotifier<Map<FileType, int>> {
  @override
  Future<Map<FileType, int>> build() async {
    final listing = await ref.read(catalogGatewayProvider).listFiles();

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
