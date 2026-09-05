import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/organization/domain/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_bookmarks.dart';
import '../../../support/fake_catalog_gateway.dart';

/// Which screens reach into libraries, and which must not (FR-CT-06,
/// FR-CT-16, core FR-FC-38).
///
/// A library keeps its files out of the type panels so a course does not
/// bury everything else. That is a rule about *listing* — the libraries
/// design scopes it to "the queries that browse by type" and names search,
/// playlists, watchlists, reading lists and collections as things it does
/// not apply to. Reading it as a rule about the catalog has cost the owner
/// four things so far, and each was found separately: a marked folder's files
/// could not be found by name; a deleted one could be reached from nowhere —
/// not its panel, not the review, and not its own library, which lists only
/// active files; a missing one appeared in no review at all; and one could
/// not be filed into a collection, because the picker is the only place that
/// offers it.
///
/// Hence one file naming every screen on both sides of the rule, rather than
/// a reach asserted wherever it happens to be remembered.
void main() {
  final indexedAt = DateTime.utc(2026, 8, 30, 9);

  FileDetails row(String name, {String? library, DateTime? missingAt}) =>
      FileDetails(
        file: CatalogFile(
          uuid: 'uuid-$name',
          name: name,
          path: '/library/$name',
          type: FileType.document,
          contentHash: '',
          indexedAt: indexedAt,
          missingAt: missingAt,
        ),
        libraryUuid: library,
      );

  ({ProviderContainer ref, FakeCatalogGateway gateway}) build({
    List<FileDetails> files = const [],
    List<FileDetails> deleted = const [],
  }) {
    final gateway = FakeCatalogGateway()
      ..listings[FileType.document] = CatalogListing.loaded(files: files)
      ..deleted[FileType.document] = CatalogListing.loaded(files: deleted);

    final container = ProviderContainer(
      overrides: [
        catalogGatewayProvider.overrideWithValue(gateway),
        // The review lists deleted bookmarks beside deleted files; this test
        // is about the files.
        bookmarkGatewayProvider.overrideWithValue(FakeBookmarkGateway()),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);

    return (ref: container, gateway: gateway);
  }

  test('GivenTheSearchIndex_WhenItLoads_ThenItReachesIntoLibraries', () async {
    final sut = build();

    await sut.ref.read(catalogSearchProvider.future);

    expect(
      sut.gateway.libraryReaches.every((reached) => reached),
      isTrue,
      reason:
          'the search asked for the type-panel listing, so a library file '
          'could never be found by name',
    );
  });

  test(
    'GivenTheDeletedItemsReview_WhenItLoads_ThenItReachesIntoLibraries',
    () async {
      final sut = build();

      await sut.ref.read(deletedItemsControllerProvider.future);

      expect(
        sut.gateway.libraryReaches.every((reached) => reached),
        isTrue,
        reason: 'a deleted library file would be reachable from nowhere at all',
      );
    },
  );

  test(
    'GivenADeletedLibraryFile_WhenTheReviewLoads_ThenItCanBeOfferedBack',
    () async {
      final sut = build(deleted: [row('syllabus.pdf', library: 'lib-1')]);

      final records = await sut.ref.read(deletedItemsControllerProvider.future);

      expect(records.map((record) => record.name), contains('syllabus.pdf'));
    },
  );

  test(
    'GivenTheMissingFilesReview_WhenItLoads_ThenItReachesIntoLibraries',
    () async {
      final sut = build();

      await sut.ref.read(missingFilesControllerProvider.future);

      expect(
        sut.gateway.libraryReaches.every((reached) => reached),
        isTrue,
        reason:
            'the review listed every missing file in the catalog except the '
            'ones inside a library',
      );
    },
  );

  test(
    'GivenAMissingLibraryFile_WhenTheReviewLoads_ThenItIsListed',
    () async {
      // The one screen that offers anything to do about a missing file. Its
      // library tree still shows it — missing is a marking on an active
      // record, not a state — but the tree is not where the remedy is.
      final sut = build(
        files: [
          row('lecture.mp4', library: 'lib-1', missingAt: indexedAt),
          row('manual.pdf', missingAt: indexedAt),
        ],
      );

      final missing = await sut.ref.read(missingFilesControllerProvider.future);

      expect(missing.map((row) => row.file.name), [
        'lecture.mp4',
        'manual.pdf',
      ]);
    },
  );

  test(
    'GivenTheCollectionPicker_WhenItLoads_ThenItReachesIntoLibraries',
    () async {
      // The libraries design names collections among the things the exclusion
      // does not apply to. Watchlists, reading lists and playlists honour that
      // already, because they are reached through the file's own details
      // dialog, which a library tree opens — this picker is the only way to
      // file something into a collection, so its exclusion was the whole of
      // the refusal.
      final sut = build(files: [row('lecture.pdf', library: 'lib-1')]);
      sut.ref
          .read(openCollectionProvider.notifier)
          .open(
            const Collection(
              uuid: 'col-1',
              name: 'Course',
              kind: CollectionKind.file,
            ),
          );

      final candidates = await sut.ref.read(
        collectionCandidatesControllerProvider.future,
      );

      expect(
        sut.gateway.libraryReaches.every((reached) => reached),
        isTrue,
        reason: 'a library file could not be put into a collection at all',
      );
      expect(candidates.map((member) => member.name), ['lecture.pdf']);
    },
  );

  test('GivenALibraryFile_WhenTheDashboardLoads_ThenItIsNotShown', () async {
    // The other direction, and the one the reach put at risk: the dashboard
    // reads the same index the search does, and a course's handouts arriving
    // on the front page is what marking the folder was meant to stop.
    final sut = build(
      files: [
        row('lecture.pdf', library: 'lib-1'),
        row('manual.pdf'),
      ],
    );

    final recent = await sut.ref.read(recentFilesProvider.future);

    expect(recent.map((row) => row.file.name), ['manual.pdf']);
  });
}
