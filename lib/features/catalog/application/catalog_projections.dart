import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';

/// Reads every projection of the catalog again (FR-LC-09).
///
/// One list, in one place, because the callers are the writes that change what
/// the catalog holds — a scan, a soft delete, a restore, a purge — and they
/// all owe the owner the same thing afterwards: a screen that agrees with the
/// core. Each of them used to spell the list out itself, and they had drifted
/// apart, leaving one screen or another showing what the core no longer
/// had.
///
/// Bookmarks are not here: only the writes that can touch a bookmark record
/// invalidate that one, and it is theirs to add.
void invalidateCatalogProjections(Ref ref) {
  ref.invalidate(listingControllerProvider);
  ref.invalidate(typeCountsControllerProvider);
  ref.invalidate(recentFilesProvider);
  ref.invalidate(catalogSearchProvider);
  ref.invalidate(fileDetailsControllerProvider);
}
