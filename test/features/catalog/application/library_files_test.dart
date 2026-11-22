import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/organization/domain/collection.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_bookmarks.dart';
import '../../../support/fake_catalog_gateway.dart';

/// Every file belongs to a library (core 0.6.0), so every screen that lists
/// files lists library files: the type panels, the dashboard, the deleted and
/// missing reviews, and the collection picker. Before 0.6 a library kept its
/// files out of the type panels and the dashboard; one file pins that the
/// exclusion is gone everywhere it used to be.
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

    return (ref: container, gateway: gateway);
  }

  test(
    'GivenADeletedLibraryFile_WhenTheReviewLoads_ThenItCanBeOfferedBack',
    () async {
      final sut = build(deleted: [row('syllabus.pdf', library: 'lib-1')]);

      final records = await sut.ref.read(deletedItemsControllerProvider.future);

      expect(records.map((record) => record.name), contains('syllabus.pdf'));
    },
  );

  test('GivenAMissingLibraryFile_WhenTheReviewLoads_ThenItIsListed', () async {
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

    expect(missing.map((row) => row.file.name), ['lecture.mp4', 'manual.pdf']);
  });

  test(
    'GivenALibraryFile_WhenTheCollectionPickerLoads_ThenItIsOffered',
    () async {
      // The libraries design names collections among the things the exclusion
      // does not apply to. Watchlists and reading lists honour that
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

      expect(candidates.map((member) => member.name), ['lecture.pdf']);
    },
  );

  test(
    'GivenARecentLibraryFile_WhenTheDashboardLoads_ThenItIsAmongRecentFiles',
    () async {
      final sut = build(files: [row('lecture.pdf', library: 'lib-1')]);

      final recent = await sut.ref.read(recentFilesProvider.future);

      expect(recent.map((file) => file.name), ['lecture.pdf']);
    },
  );

  test('GivenAFileInALibrary_WhenItsTypePanelLists_ThenItIsListed', () async {
    final sut = build(files: [row('lecture.pdf', library: 'lib-1')]);
    sut.ref.listen(listingControllerProvider, (_, _) {});
    sut.ref.read(shellControllerProvider.notifier).go(ShellDestination.books);

    final listed = await sut.ref.read(listingControllerProvider.future);

    expect(listed.map((file) => file.name), ['lecture.pdf']);
  });

  test('GivenAFileInALibrary_WhenTypeCountsAreRead_ThenItIsCounted', () async {
    final sut = build(files: [row('lecture.pdf', library: 'lib-1')]);
    sut.ref.listen(typeCountsControllerProvider, (_, _) {});

    final counts = await sut.ref.read(typeCountsControllerProvider.future);

    expect(counts[FileType.document], 1);
  });
}
