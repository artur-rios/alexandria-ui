import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_bookmarks.dart';
import '../../../support/fake_catalog_gateway.dart';

/// Which screens reach into libraries, and which must not (FR-CT-06,
/// FR-CT-16, core FR-FC-38).
///
/// A library keeps its files out of the type panels so a course does not
/// bury everything else. That is a rule about *listing*, and reading it as a
/// rule about the catalog cost the owner two things: a marked folder's files
/// could not be found by name, and a deleted one could be reached from
/// nowhere — not its panel, not the deleted-items review, and not its own
/// library, which lists only active files.
void main() {
  final indexedAt = DateTime.utc(2026, 8, 30, 9);

  FileDetails row(String name, {String? library}) => FileDetails(
    file: CatalogFile(
      uuid: 'uuid-$name',
      name: name,
      path: '/library/$name',
      type: FileType.document,
      contentHash: '',
      indexedAt: indexedAt,
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
        reason:
            'a deleted library file would be reachable from nowhere at all',
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

  test('GivenALibraryFile_WhenTheDashboardLoads_ThenItIsNotShown', () async {
    // The other direction, and the one the reach put at risk: the dashboard
    // reads the same index the search does, and a course's handouts arriving
    // on the front page is what marking the folder was meant to stop.
    final sut = build(
      files: [row('lecture.pdf', library: 'lib-1'), row('manual.pdf')],
    );

    final recent = await sut.ref.read(recentFilesProvider.future);

    expect(recent.map((row) => row.file.name), ['manual.pdf']);
  });
}
