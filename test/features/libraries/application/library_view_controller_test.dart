import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/domain/listing_view.dart';
import 'package:alexandria_ui/features/libraries/application/library_view_controller.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_library_gateway.dart';

/// Which folder of each library is open, and what it shows (library
/// navigation design §4).
void main() {
  const course = Library(uuid: 'lib-1', name: 'Course', rootPath: '/course');

  ({ProviderContainer ref, FakeLibraryGateway gateway}) build({
    LibraryRead? top,
  }) {
    final gateway = FakeLibraryGateway(libraries: const [course]);
    if (top != null) gateway.reads['lib-1'] = {'': top};

    final container = ProviderContainer(
      overrides: [libraryGatewayProvider.overrideWithValue(gateway)],
      // A failed read settles as the failure at once, rather than loading
      // again on a timer this test would have to wait out.
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);

    // The folder is auto-disposed without a listener, as the view keeps one.
    container.listen(libraryFolderProvider('lib-1'), (_, _) {});

    return (ref: container, gateway: gateway);
  }

  /// The course's open folder once the core has answered for [path].
  Future<LibraryFolderView> loaded(
    ProviderContainer ref, {
    String path = '',
  }) async {
    await ref.read(
      libraryTreeControllerProvider((uuid: 'lib-1', path: path)).future,
    );
    return ref.read(libraryFolderProvider('lib-1')).requireValue;
  }

  group('the open folder', () {
    test('GivenNothingOpened_WhenAFolderIsAskedFor_ThenItIsTheTop', () {
      final sut = build();

      expect(
        sut.ref.read(libraryViewControllerProvider.notifier).folderOf('lib-1'),
        '',
      );
    });

    test('GivenAFolderOpened_WhenItIsAskedFor_ThenItIsThatFolder', () {
      final sut = build();
      final controller = sut.ref.read(libraryViewControllerProvider.notifier);

      controller.openFolder('lib-1', 'class-01');

      expect(controller.folderOf('lib-1'), 'class-01');
    });

    test('GivenTwoLibraries_WhenOneOpensAFolder_ThenTheOtherStaysAtItsTop', () {
      final sut = build();
      final controller = sut.ref.read(libraryViewControllerProvider.notifier);

      controller.openFolder('lib-1', 'class-01');
      controller.openFolder('lib-2', 'films');
      controller.openFolder('lib-1', 'class-02');

      expect(controller.folderOf('lib-1'), 'class-02');
      expect(controller.folderOf('lib-2'), 'films');
      expect(controller.folderOf('lib-3'), '');
    });

    test(
      'GivenAFolderOpened_WhenTheFolderIsRead_ThenThatLevelIsAskedFor',
      () async {
        final sut = build();

        sut.ref
            .read(libraryViewControllerProvider.notifier)
            .openFolder('lib-1', 'class-01');
        await loaded(sut.ref, path: 'class-01');

        expect(sut.gateway.readsMade.last, (uuid: 'lib-1', path: 'class-01'));
      },
    );
  });

  group('what the folder shows', () {
    final top = LibraryRead.loaded(
      listing: LibraryListing(
        library: course,
        path: '',
        folders: const [
          LibraryFolder(name: 'zoology', path: 'zoology'),
          LibraryFolder(name: 'Art', path: 'Art'),
        ],
        files: [
          LibraryFile(
            file: aFile(uuid: '1', name: 'b.md'),
          ),
          LibraryFile(
            file: aFile(uuid: '2', name: 'Saga.cbz', type: FileType.comic),
          ),
          LibraryFile(
            file: aFile(uuid: '3', name: 'a.md'),
          ),
        ],
      ),
    );

    test('GivenAFolder_WhenItLoads_ThenFoldersAreAToZAndFilesByName', () async {
      final sut = build(top: top);

      final folder = await loaded(sut.ref);

      expect(folder.folders.map((each) => each.name), ['Art', 'zoology']);
      expect(folder.files.map((file) => file.name), [
        'a.md',
        'b.md',
        'Saga.cbz',
      ]);
    });

    test(
      'GivenATypeFilter_WhenTheFolderLoads_ThenOnlyThatTypeIsShown',
      () async {
        final sut = build(top: top);
        await sut.ref
            .read(libraryViewPreferencesProvider.notifier)
            .filterTo(FileType.comic);

        final folder = await loaded(sut.ref);

        expect(folder.files.map((file) => file.name), ['Saga.cbz']);
        expect(
          folder.folders,
          hasLength(2),
          reason: 'folders are not filtered',
        );
        expect(folder.filteredToNothing, isFalse);
      },
    );

    test(
      'GivenAFilterMatchingNothing_WhenTheFolderLoads_ThenItSaysSo',
      () async {
        final sut = build(top: top);
        await sut.ref
            .read(libraryViewPreferencesProvider.notifier)
            .filterTo(FileType.video);

        final folder = await loaded(sut.ref);

        expect(folder.files, isEmpty);
        expect(folder.filteredToNothing, isTrue);
        expect(folder.isEmpty, isFalse);
      },
    );

    test(
      'GivenADescendingOrder_WhenTheFolderLoads_ThenTheFilesAreReversed',
      () async {
        final sut = build(top: top);
        await sut.ref
            .read(libraryViewPreferencesProvider.notifier)
            .orderIn(SortDirection.descending);

        final folder = await loaded(sut.ref);

        expect(folder.files.map((file) => file.name), [
          'Saga.cbz',
          'b.md',
          'a.md',
        ]);
        expect(folder.folders.map((each) => each.name), [
          'Art',
          'zoology',
        ], reason: 'folders always come first, A–Z');
      },
    );

    test('GivenAnEmptyFolder_WhenItLoads_ThenItIsEmptyNotFiltered', () async {
      final sut = build(
        top: const LibraryRead.loaded(
          listing: LibraryListing(
            library: course,
            path: '',
            folders: [],
            files: [],
          ),
        ),
      );

      final folder = await loaded(sut.ref);

      expect(folder.isEmpty, isTrue);
      expect(folder.filteredToNothing, isFalse);
    });

    test(
      'GivenTheCoreFails_WhenTheFolderLoads_ThenItSurfacesAsAnError',
      () async {
        // Thrown rather than answered empty, so "we could not ask" is never
        // mistaken for "there is nothing here".
        const failure = Failure.disk(family: CoreStatusFamily.library, code: 6);
        final sut = build(top: const LibraryRead.failed(failure: failure));

        await pumpEventQueue();

        final state = sut.ref.read(libraryFolderProvider('lib-1'));
        expect(state.hasError, isTrue);
        expect(state.error, failure);
      },
    );
  });
}
