import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/organization/domain/collection.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_bookmarks.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_library_gateway.dart';

/// Every file belongs to a library (core 0.6.0), so every screen that lists
/// files lists library files: a library's folders, the dashboard, the deleted
/// and missing reviews, and the collection picker. Before 0.6 a library kept its
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

    // The library the files are in, its root holding them.
    const library = Library(uuid: 'lib-1', name: 'Course', rootPath: '/');
    final libraries = FakeLibraryGateway(libraries: const [library]);
    libraries.reads['lib-1'] = {
      '': LibraryRead.loaded(
        listing: LibraryListing(
          library: library,
          path: '',
          folders: const [],
          files: [for (final each in files) LibraryFile(file: each.file)],
        ),
      ),
    };

    final container = ProviderContainer(
      overrides: [
        catalogGatewayProvider.overrideWithValue(gateway),
        libraryGatewayProvider.overrideWithValue(libraries),
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

  test('GivenAFileInALibrary_WhenItsFolderIsShown_ThenItIsListed', () async {
    // Where a library's files are browsed now: its folders, in the main area.
    final sut = build(files: [row('lecture.pdf', library: 'lib-1')]);
    sut.ref.listen(libraryFolderProvider('lib-1'), (_, _) {});

    await sut.ref.read(
      libraryTreeControllerProvider((uuid: 'lib-1', path: '')).future,
    );
    final listed = sut.ref.read(libraryFolderProvider('lib-1')).requireValue;

    expect(listed.files.map((file) => file.name), ['lecture.pdf']);
  });
}
