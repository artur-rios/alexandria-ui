import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../catalog/domain/catalog_gateway.dart';
import '../../catalog/domain/file_details.dart';
import '../../catalog/domain/file_type.dart';

/// The files the core reports as missing on disk (UC-37 main flow step 2).
///
/// Missing is a marking on an active record, not a lifecycle state of its own,
/// so this is the active listing of every type filtered to what carries the
/// marking. The core is what decides which those are — nothing here infers it
/// from the filesystem (BR-16, FR-LC-08).
///
/// Published as `List<FileDetails>`, not just the files: each row is the
/// record the listing read, so nothing that shows one has to read it again.
class MissingFilesController extends AsyncNotifier<List<FileDetails>> {
  @override
  Future<List<FileDetails>> build() async {
    final catalog = ref.read(catalogGatewayProvider);
    final missing = <FileDetails>[];

    for (final type in FileType.values) {
      final listing = await catalog.listFiles(type: type);

      switch (listing) {
        case CatalogListingLoaded(:final files):
          missing.addAll(files.where((row) => row.file.isMissing));

        // One type the core will not answer must not take the others down
        // with it.
        case CatalogListingFailed():
          continue;
      }
    }

    // Longest missing first, which is the order a review reads in. A record
    // the core answered without a timestamp sorts last: it is the one this
    // cannot place.
    missing.sort((a, b) {
      final left = a.file.missingAt;
      final right = b.file.missingAt;
      if (left == null) return right == null ? 0 : 1;
      if (right == null) return -1;

      return left.compareTo(right);
    });

    return missing;
  }

  /// Reads them again (step 5: what a re-scan found leaves the review).
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

/// Whether [path] sits under a folder the owner still has registered (AF-03).
///
/// A prefix comparison over the separator, so `/books` does not claim
/// `/books-archive/x.epub`. Case-insensitive, because a Windows path that
/// differs only in case is the same folder.
bool isUnderRegisteredFolder(String path, Iterable<String> roots) {
  final target = path.replaceAll(r'\', '/').toLowerCase();

  for (final root in roots) {
    var normalized = root.replaceAll(r'\', '/').toLowerCase();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (normalized.isEmpty) continue;

    if (target == normalized || target.startsWith('$normalized/')) return true;
  }

  return false;
}
