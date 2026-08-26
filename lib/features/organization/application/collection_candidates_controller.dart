import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../catalog/domain/catalog_gateway.dart';
import '../../catalog/domain/library_type.dart';
import '../domain/collection.dart';
import '../domain/bookmark_gateway.dart';
import '../domain/collection_gateway.dart';

/// What the open collection could accept (UC-27 main flow step 3).
///
/// Files for a file collection, bookmarks for a bookmark collection, and
/// nothing else. That is AF-01 answered before it can happen: an item of the
/// wrong kind is never offered, so the owner cannot pick one by accident, and
/// the core's refusal is left as the backstop for reaching it another way.
class CollectionCandidatesController
    extends AsyncNotifier<List<CollectionMember>> {
  @override
  Future<List<CollectionMember>> build() async {
    final collection = ref.watch(openCollectionProvider);
    if (collection == null) return const [];

    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07).
    if (credential == null) return const [];

    return switch (collection.kind) {
      CollectionKind.file => _files(credential),
      CollectionKind.bookmark => _bookmarks(credential),
    };
  }

  /// Every active file, across every type.
  ///
  /// A call per type, because the core lists by type and publishes nothing
  /// that answers "every file at once" — the same shape and the same cost as
  /// the deleted view's assembly, and for the same reason.
  Future<List<CollectionMember>> _files(String credential) async {
    final catalog = ref.read(catalogGatewayProvider);
    final candidates = <CollectionMember>[];

    for (final type in LibraryType.values) {
      final listing = await catalog.listFiles(
        type: type,
        credential: credential,
      );

      // A type the core will not answer is skipped rather than taking the
      // others down with it (UC-09 AF-02).
      if (listing case CatalogListingLoaded(:final files)) {
        candidates.addAll(
          files.map(
            (row) => CollectionMember(uuid: row.file.uuid, name: row.file.name),
          ),
        );
      }
    }

    candidates.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return candidates;
  }

  Future<List<CollectionMember>> _bookmarks(String credential) async {
    final listing = await ref
        .read(bookmarkGatewayProvider)
        .list(credential: credential);

    if (listing case BookmarkListingLoaded(:final bookmarks)) {
      return [
        for (final bookmark in bookmarks)
          CollectionMember(uuid: bookmark.uuid, name: bookmark.title),
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return const [];
  }
}
