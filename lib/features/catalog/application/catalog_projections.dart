import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';

/// Reads every projection of the catalog again (FR-LC-09).
///
/// One list, in one place, because the callers are the writes that change what
/// the catalog holds — a scan, a soft delete, a restore, a purge — and they
/// all owe the owner the same thing afterwards: a screen that agrees with the
/// core. Each of them used to spell the list out itself, and they had drifted
/// apart. Every one of them had left [musicLibraryProvider] out except the
/// scan, so a track deleted or purged stayed in the music area for the rest of
/// the session, and playing it from there reported it as skipped because the
/// core no longer had it. That is the same defect the scan path already
/// carried a comment about having fixed once.
///
/// Bookmarks are not here: only the writes that can touch a bookmark record
/// invalidate that one, and it is theirs to add.
void invalidateCatalogProjections(Ref ref) {
  ref.invalidate(listingControllerProvider);
  ref.invalidate(typeCountsControllerProvider);
  ref.invalidate(recentFilesProvider);
  ref.invalidate(catalogSearchProvider);
  ref.invalidate(fileDetailsControllerProvider);
  // The music area builds its own view of the audio listing, so it does not
  // follow any of the above.
  ref.invalidate(musicLibraryProvider);
}
