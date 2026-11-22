import 'dart:convert';

import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/core/settings/settings_store.dart';
import 'package:alexandria_ui/core/theme/breakpoints.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/domain/music_metadata.dart';
import 'package:alexandria_ui/features/catalog/presentation/file_details_view.dart';
import 'package:alexandria_ui/features/catalog/presentation/file_tiles.dart';
import 'package:alexandria_ui/features/indexing/domain/index_gateway.dart';
import 'package:alexandria_ui/features/indexing/domain/index_run.dart';
import 'package:alexandria_ui/features/libraries/application/library_view_preferences.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/libraries/presentation/library_name_dialog.dart';
import 'package:alexandria_ui/features/libraries/presentation/library_view.dart';
import 'package:alexandria_ui/features/organization/presentation/bookmarks_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/async_state_view.dart';
import 'package:alexandria_ui/features/shell/presentation/confirmation_dialog.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:alexandria_ui/features/viewers/presentation/document_viewer_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/misc.dart';

import '../../../support/failing_settings_store.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_folder_picker.dart';
import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_gateway.dart';
import '../../../support/fake_media_player.dart';
import '../../../support/fake_playback.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/shell_harness.dart';

/// A library in the main area: its folders, its files, and what can be done
/// to it (library navigation design §4).
void main() {
  const course = Library(
    uuid: 'lib-1',
    name: 'Course',
    rootPath: '/media/course',
  );
  const films = Library(uuid: 'lib-2', name: 'Films', rootPath: '/media/films');

  /// One level of [library], holding [folders] and [files].
  LibraryRead level(
    String path, {
    Library library = course,
    List<String> folders = const [],
    List<CatalogFile> files = const [],
  }) => LibraryRead.loaded(
    listing: LibraryListing(
      library: library,
      path: path,
      folders: [
        for (final name in folders)
          LibraryFolder(name: name, path: path.isEmpty ? name : '$path/$name'),
      ],
      files: [for (final file in files) LibraryFile(file: file)],
    ),
  );

  final lecture = aFile(
    uuid: 'f-lecture',
    name: 'lecture.mp4',
    type: FileType.video,
  );
  final syllabus = aFile(
    uuid: 'f-syllabus',
    name: 'Syllabus.epub',
    type: FileType.document,
  );
  final comic = aFile(uuid: 'f-comic', name: 'Saga.cbz', type: FileType.comic);

  /// The shell over [gateway] (the course and the films by default), with
  /// the course open.
  Future<({ProviderContainer container, FakeLibraryGateway gateway})> open(
    WidgetTester tester, {
    Map<String, LibraryRead>? levels,
    FakeLibraryGateway? gateway,
    FakeCatalogGateway? catalog,
    SettingsStore? settings,
    Size surfaceSize = const Size(1440, 1000),
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    FakeFolderPicker? picker,
    List<Override> extraOverrides = const [],
  }) async {
    final theGateway =
        gateway ?? FakeLibraryGateway(libraries: const [course, films]);
    theGateway.reads['lib-1'] =
        levels ??
        {
          '': level('', folders: ['class-01'], files: [syllabus]),
          'class-01': level('class-01', files: [lecture]),
        };

    final container = await tester.pumpShell(
      surfaceSize: surfaceSize,
      settings:
          settings ??
          InMemorySettingsStore(
            rechecksAtStartup: false,
            themeMode: themeMode,
            locale: locale,
          ),
      locale: locale,
      themeMode: themeMode,
      extraOverrides: <Override>[
        libraryGatewayProvider.overrideWithValue(theGateway),
        catalogGatewayProvider.overrideWithValue(
          catalog ?? FakeCatalogGateway(),
        ),
        folderPickerProvider.overrideWithValue(picker ?? FakeFolderPicker()),
        ...extraOverrides,
      ],
    );
    await tester.goTo(const LibraryDestination('lib-1'));

    return (container: container, gateway: theGateway);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  Finder inView(Finder finder) =>
      find.descendant(of: find.byType(LibraryView), matching: finder);

  Finder inHeader(Finder finder) =>
      find.descendant(of: find.byType(LibraryHeader), matching: finder);

  Finder crumbs(Finder finder) =>
      find.descendant(of: find.byType(LibraryBreadcrumbs), matching: finder);

  /// Opens one of the toolbar's menus by the label on its button, then
  /// chooses [entry] in it.
  Future<void> choose(WidgetTester tester, String menu, String entry) async {
    await tester.tap(inView(find.text(menu)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(entry).last);
    await tester.pumpAndSettle();
  }

  group('breadcrumbs and folders', () {
    testWidgets(
      'GivenAFolder_WhenItIsOpened_ThenItsContentsAndACrumbAreShown',
      (tester) async {
        await open(tester);

        await tester.tap(inView(find.text('class-01')));
        await tester.pumpAndSettle();

        expect(inView(find.text('lecture.mp4')), findsOneWidget);
        expect(inView(find.text('Syllabus.epub')), findsNothing);
        expect(crumbs(find.text('class-01')), findsOneWidget);
      },
    );

    testWidgets('GivenAnOpenFolder_WhenTheRootCrumbIsTapped_ThenTheTopShows', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(inView(find.text('class-01')));
      await tester.pumpAndSettle();

      await tester.tap(crumbs(find.byTooltip('Course')));
      await tester.pumpAndSettle();

      expect(inView(find.text('Syllabus.epub')), findsOneWidget);
      expect(inView(find.text('lecture.mp4')), findsNothing);
      expect(crumbs(find.text('class-01')), findsNothing);
    });

    testWidgets(
      'GivenADeepFolder_WhenAMiddleCrumbIsTapped_ThenThatLevelShows',
      (tester) async {
        final opened = await open(
          tester,
          levels: {
            '': level('', folders: ['term-1']),
            'term-1': level('term-1', folders: ['week-1']),
            'term-1/week-1': level('term-1/week-1', files: [lecture]),
          },
        );
        await tester.tap(inView(find.text('term-1')));
        await tester.pumpAndSettle();
        await tester.tap(inView(find.text('week-1')));
        await tester.pumpAndSettle();

        await tester.tap(crumbs(find.widgetWithText(TextButton, 'term-1')));
        await tester.pumpAndSettle();

        expect(opened.gateway.readsMade.last, (uuid: 'lib-1', path: 'term-1'));
        expect(inView(find.text('week-1')), findsWidgets);
      },
    );

    testWidgets('GivenFoldersAndFiles_WhenShown_ThenFoldersComeFirstAToZ', (
      tester,
    ) async {
      await open(
        tester,
        levels: {
          '': level(
            '',
            folders: ['zoology', 'Art', 'biology'],
            files: [aFile(uuid: 'a', name: 'aardvark.md')],
          ),
        },
      );

      final top = [
        for (final name in ['Art', 'biology', 'zoology', 'aardvark.md'])
          tester.getTopLeft(inView(find.text(name))).dy,
      ];
      expect(top, orderedEquals([...top]..sort()));
    });
  });

  group('the toolbar', () {
    final mixed = {
      '': level(
        '',
        files: [
          syllabus,
          comic,
          aFile(uuid: 'f-other', name: 'Another.cbz', type: FileType.comic),
        ],
      ),
    };

    testWidgets('GivenMixedFiles_WhenComicIsChosen_ThenOnlyComicsAreShown', (
      tester,
    ) async {
      await open(tester, levels: mixed);

      await choose(
        tester,
        messages(tester).libraryTypeAll,
        messages(tester).destinationComicBooks,
      );

      expect(inView(find.text('Saga.cbz')), findsOneWidget);
      expect(inView(find.text('Another.cbz')), findsOneWidget);
      expect(inView(find.text('Syllabus.epub')), findsNothing);
    });

    testWidgets('GivenNameOrder_WhenDescendingIsChosen_ThenTheOrderReverses', (
      tester,
    ) async {
      await open(tester, levels: mixed);
      double top(String name) => tester.getTopLeft(inView(find.text(name))).dy;
      expect(top('Another.cbz'), lessThan(top('Saga.cbz')));

      await choose(
        tester,
        messages(tester).sortLabel,
        messages(tester).sortDescending,
      );

      expect(top('Saga.cbz'), lessThan(top('Another.cbz')));
      expect(top('Syllabus.epub'), lessThan(top('Saga.cbz')));
    });

    testWidgets('GivenTheSortMenu_WhenItOpens_ThenEveryOrderIsOffered', (
      tester,
    ) async {
      await open(tester, levels: mixed);
      final l10n = messages(tester);

      await tester.tap(inView(find.text(l10n.sortLabel)));
      await tester.pumpAndSettle();

      for (final entry in [
        l10n.sortByName,
        l10n.sortByIndexed,
        l10n.sortByAlbum,
        l10n.sortAscending,
        l10n.sortDescending,
      ]) {
        expect(find.widgetWithText(MenuItemButton, entry), findsOneWidget);
      }
    });

    testWidgets('GivenTracks_WhenSortedByAlbum_ThenTheyAreInTrackOrder', (
      tester,
    ) async {
      await open(
        tester,
        levels: {
          '': level(
            '',
            files: [
              aFile(
                uuid: 't2',
                name: 'a - second.flac',
                type: FileType.audio,
                tags: const MusicMetadata(
                  title: 'Second',
                  artist: 'Band',
                  album: 'Record',
                  track: 2,
                ),
              ),
              aFile(
                uuid: 't1',
                name: 'b - first.flac',
                type: FileType.audio,
                tags: const MusicMetadata(
                  title: 'First',
                  artist: 'Band',
                  album: 'Record',
                  track: 1,
                ),
              ),
            ],
          ),
        },
      );
      double top(String name) => tester.getTopLeft(inView(find.text(name))).dy;
      expect(top('Second'), lessThan(top('First')), reason: 'by file name');

      await choose(
        tester,
        messages(tester).sortLabel,
        messages(tester).sortByAlbum,
      );

      expect(top('First'), lessThan(top('Second')), reason: 'by track');
    });

    testWidgets(
      'GivenTheList_WhenTheGridAndThenTheListAreChosen_ThenEachIsDrawn',
      (tester) async {
        await open(tester);
        expect(inView(find.byType(FileRow)), findsOneWidget);
        expect(inView(find.byType(FileTile)), findsNothing);

        await tester.tap(find.byTooltip(messages(tester).layoutGrid));
        await tester.pumpAndSettle();

        expect(inView(find.byType(FileTile)), findsOneWidget);
        expect(inView(find.byType(FileRow)), findsNothing);
        expect(inView(find.text('class-01')), findsOneWidget);

        await tester.tap(find.byTooltip(messages(tester).layoutList));
        await tester.pumpAndSettle();

        expect(inView(find.byType(FileRow)), findsOneWidget);
      },
    );

    testWidgets(
      'GivenChoicesMade_WhenTheyAreMade_ThenTheyAreStoredUnderLibraryView',
      (tester) async {
        final settings = InMemorySettingsStore(rechecksAtStartup: false);
        await open(tester, levels: mixed, settings: settings);

        await tester.tap(find.byTooltip(messages(tester).layoutGrid));
        await tester.pumpAndSettle();
        await choose(
          tester,
          messages(tester).libraryTypeAll,
          messages(tester).destinationComicBooks,
        );
        await choose(
          tester,
          messages(tester).sortLabel,
          messages(tester).sortDescending,
        );

        expect(
          jsonDecode(
            settings.entries[LibraryViewPreferencesController.settingsKey]!,
          ),
          {
            'layout': 'grid',
            'type': 'comic',
            'sortField': 'name',
            'direction': 'descending',
          },
        );
      },
    );

    testWidgets('GivenStoredChoices_WhenALibraryOpens_ThenTheyApply', (
      tester,
    ) async {
      await open(
        tester,
        levels: mixed,
        settings: InMemorySettingsStore(
          rechecksAtStartup: false,
          values: {
            'libraryView': jsonEncode({
              'layout': 'grid',
              'type': 'comic',
              'sortField': 'name',
              'direction': 'descending',
            }),
          },
        ),
      );

      expect(inView(find.byType(FileTile)), findsNWidgets(2));
      expect(inView(find.text('Syllabus.epub')), findsNothing);
      expect(
        tester.getTopLeft(inView(find.text('Saga.cbz'))).dy,
        lessThanOrEqualTo(
          tester.getTopLeft(inView(find.text('Another.cbz'))).dy,
        ),
      );
    });

    testWidgets('GivenAChoice_WhenAnotherLibraryOpens_ThenItAppliesThereToo', (
      tester,
    ) async {
      // One choice for every library, not one per library (spec §4).
      final opened = await open(tester);
      opened.gateway.reads['lib-2'] = {
        '': level('', library: films, files: [lecture]),
      };
      await tester.tap(find.byTooltip(messages(tester).layoutGrid));
      await tester.pumpAndSettle();

      await tester.goTo(const LibraryDestination('lib-2'));

      expect(inView(find.byType(FileTile)), findsOneWidget);
    });

    testWidgets('GivenTheStoreRefuses_WhenAChoiceIsMade_ThenItStillApplies', (
      tester,
    ) async {
      await open(tester, settings: FailingSettingsStore());

      await tester.tap(find.byTooltip(messages(tester).layoutGrid));
      await tester.pumpAndSettle();

      expect(inView(find.byType(FileTile)), findsOneWidget);
      expect(find.text(messages(tester).libraryViewUnsaved), findsOneWidget);
    });
  });

  group('the open folder is remembered', () {
    testWidgets(
      'GivenFolderXOpenInLibrary1_WhenHomeThenLibrary1AreSelected_ThenXIsStillOpen',
      (tester) async {
        final opened = await open(tester);
        opened.gateway.reads['lib-2'] = {
          '': level('', library: films, files: [syllabus]),
        };
        await tester.tap(inView(find.text('class-01')));
        await tester.pumpAndSettle();

        await tester.goTo(const HomeDestination());
        await tester.goTo(const LibraryDestination('lib-1'));

        expect(inView(find.text('lecture.mp4')), findsOneWidget);
        expect(crumbs(find.text('class-01')), findsOneWidget);

        // Per library: the other one opens at its own top.
        await tester.goTo(const LibraryDestination('lib-2'));
        expect(inView(find.text('Syllabus.epub')), findsOneWidget);
      },
    );
  });

  group('files and their actions', () {
    testWidgets('GivenAFileRow_WhenTapped_ThenTheFileItselfOpens', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(inView(find.text('Syllabus.epub')));
      await tester.pumpAndSettle();

      expect(find.byType(DocumentViewerScreen), findsOneWidget);
    });

    testWidgets(
      'GivenAFileRow_WhenItsDetailsOpen_ThenRenameDeleteAndOpenAreOffered',
      (tester) async {
        final catalog = FakeCatalogGateway();
        catalog.details[syllabus.uuid] = FileDetailsOutcome.read(
          details: FileDetails(file: syllabus),
        );
        await open(tester, catalog: catalog);

        await tester.tap(
          inView(
            find.descendant(
              of: find.widgetWithText(FileRow, 'Syllabus.epub'),
              matching: find.byType(FileDetailsButton),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final l10n = messages(tester);
        expect(find.byType(FileDetailsView), findsOneWidget);
        expect(find.text(l10n.renameOpen), findsOneWidget);
        expect(find.text(l10n.deleteFile), findsOneWidget);
        expect(find.text(l10n.viewerOpen), findsOneWidget);
      },
    );

    testWidgets(
      'GivenAudioInAFolder_WhenATrackIsTapped_ThenItPlaysThroughTheFoldersAudioInShownOrder',
      (tester) async {
        final player = FakeMediaPlayer();
        final opened = await open(
          tester,
          levels: {
            '': level(
              '',
              files: [
                aFile(uuid: 't-a', name: 'a.flac', type: FileType.audio),
                syllabus,
                aFile(uuid: 't-c', name: 'c.flac', type: FileType.audio),
                aFile(uuid: 't-b', name: 'b.flac', type: FileType.audio),
              ],
            ),
          },
          extraOverrides: [
            audioPlayerProvider.overrideWithValue(player),
            playbackSourceGatewayProvider.overrideWithValue(
              FakePlaybackSourceGateway()..pathFor = (uuid) => '/music/$uuid',
            ),
            coverGatewayProvider.overrideWithValue(FakeCoverGateway()),
          ],
        );
        await choose(
          tester,
          messages(tester).sortLabel,
          messages(tester).sortDescending,
        );

        await tester.tap(inView(find.text('b.flac')));
        await tester.pumpAndSettle();

        final playing = opened.container.read(audioPlaybackControllerProvider);
        expect(playing.current?.uuid, 't-b');
        expect(playing.queue.map((file) => file.uuid), [
          't-c',
          't-b',
          't-a',
        ], reason: 'the queue is the folder\'s audio, in the order shown');
      },
    );
  });

  group('empty states', () {
    testWidgets('GivenAnEmptyFolder_WhenOpened_ThenItSaysNothingIsInIt', (
      tester,
    ) async {
      await open(
        tester,
        levels: {
          '': level('', folders: ['empty']),
          'empty': level('empty'),
        },
      );

      await tester.tap(inView(find.text('empty')));
      await tester.pumpAndSettle();

      expect(find.text(messages(tester).libraryEmptyFolder), findsOneWidget);
    });

    testWidgets('GivenAnEmptyRoot_WhenOpened_ThenItSaysToScanIt', (
      tester,
    ) async {
      await open(tester, levels: {'': level('')});

      expect(find.text(messages(tester).libraryEmptyRoot), findsOneWidget);
      expect(find.text(messages(tester).libraryEmptyFolder), findsNothing);
    });

    testWidgets(
      'GivenAFilterThatMatchesNothing_WhenApplied_ThenItSaysSoAndClearRestores',
      (tester) async {
        await open(
          tester,
          levels: {
            '': level('', files: [syllabus]),
          },
        );

        await choose(
          tester,
          messages(tester).libraryTypeAll,
          messages(tester).destinationComicBooks,
        );

        final l10n = messages(tester);
        expect(find.text(l10n.libraryNoneComicBooks), findsOneWidget);
        expect(l10n.libraryNoneComicBooks, 'No comic books in this folder.');

        await tester.tap(find.text(l10n.libraryTypeFilterClear));
        await tester.pumpAndSettle();

        expect(inView(find.text('Syllabus.epub')), findsOneWidget);
      },
    );

    testWidgets('GivenTheCoreFails_WhenTheFolderLoads_ThenAMessageAndRetry', (
      tester,
    ) async {
      final opened = await open(
        tester,
        levels: {
          '': const LibraryRead.failed(
            failure: Failure.disk(family: CoreStatusFamily.library, code: 6),
          ),
        },
      );
      expect(find.byType(ShellFailureView), findsOneWidget);

      opened.gateway.reads['lib-1'] = {
        '': level('', files: [syllabus]),
      };
      await tester.tap(find.text(messages(tester).retry));
      await tester.pumpAndSettle();

      expect(inView(find.text('Syllabus.epub')), findsOneWidget);
    });
    testWidgets('GivenAFailedLibrary_WhenAnotherIsOpened_ThenItLists', (
      tester,
    ) async {
      // One library failing must not take the others down with it.
      final opened = await open(
        tester,
        levels: {
          '': const LibraryRead.failed(
            failure: Failure.disk(family: CoreStatusFamily.library, code: 6),
          ),
        },
      );
      opened.gateway.reads['lib-2'] = {
        '': level('', library: films, files: [lecture]),
      };
      expect(find.byType(ShellFailureView), findsOneWidget);

      await tester.goTo(const LibraryDestination('lib-2'));

      expect(inView(find.text('lecture.mp4')), findsOneWidget);
      expect(find.byType(ShellFailureView), findsNothing);
    });
  });

  group('the header', () {
    testWidgets('GivenALibrary_WhenShown_ThenItsNameAndTogglesAreThere', (
      tester,
    ) async {
      await open(tester);

      final l10n = messages(tester);
      expect(inHeader(find.text('Course')), findsOneWidget);
      expect(inHeader(find.byTooltip(l10n.libraryPin)), findsOneWidget);
      expect(inHeader(find.byTooltip(l10n.libraryFavoriteAdd)), findsOneWidget);
    });

    testWidgets('GivenTheToggles_WhenPressed_ThenTheCoreIsAskedAndTheyFlip', (
      tester,
    ) async {
      final opened = await open(tester);
      final l10n = messages(tester);

      await tester.tap(inHeader(find.byTooltip(l10n.libraryPin)));
      await tester.pumpAndSettle();
      await tester.tap(inHeader(find.byTooltip(l10n.libraryFavoriteAdd)));
      await tester.pumpAndSettle();

      expect(opened.gateway.pinnedCalls, [(uuid: 'lib-1', pinned: true)]);
      expect(opened.gateway.favoriteCalls, [(uuid: 'lib-1', favorite: true)]);
      expect(inHeader(find.byTooltip(l10n.libraryUnpin)), findsOneWidget);
      expect(
        inHeader(find.byTooltip(l10n.libraryFavoriteRemove)),
        findsOneWidget,
      );
    });

    testWidgets('GivenTheCoreRefuses_WhenAToggleIsPressed_ThenItSaysSo', (
      tester,
    ) async {
      final opened = await open(tester);
      opened.gateway.writeOutcomes.add(
        const LibraryWrite.failed(
          failure: Failure.disk(family: CoreStatusFamily.library, code: 6),
        ),
      );
      final l10n = messages(tester);

      await tester.tap(inHeader(find.byTooltip(l10n.libraryFavoriteAdd)));
      await tester.pumpAndSettle();

      expect(find.text(l10n.libraryChangeNotSaved), findsOneWidget);
      expect(inHeader(find.byTooltip(l10n.libraryFavoriteAdd)), findsOneWidget);
    });

    testWidgets('GivenTheMenu_WhenOpened_ThenRenameScanMoveAndRemoveAreThere', (
      tester,
    ) async {
      await open(tester);
      final l10n = messages(tester);

      await tester.tap(inHeader(find.byTooltip(l10n.libraryActions)));
      await tester.pumpAndSettle();

      for (final entry in [
        l10n.libraryRenameEntry,
        l10n.libraryScan,
        l10n.libraryMove,
        l10n.libraryRemove,
      ]) {
        expect(find.widgetWithText(MenuItemButton, entry), findsOneWidget);
      }
    });

    testWidgets('GivenTheMenu_WhenRenameIsChosen_ThenTheNameDialogOpens', (
      tester,
    ) async {
      final opened = await open(tester);
      final l10n = messages(tester);
      await tester.tap(inHeader(find.byTooltip(l10n.libraryActions)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.libraryRenameEntry));
      await tester.pumpAndSettle();
      expect(find.byType(LibraryNameDialog), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(LibraryNameDialog),
          matching: find.byType(TextField),
        ),
        'Lectures',
      );
      await tester.tap(find.widgetWithText(FilledButton, l10n.renameSubmit));
      await tester.pumpAndSettle();

      expect(opened.gateway.renamedCalls, [(uuid: 'lib-1', name: 'Lectures')]);
      expect(inHeader(find.text('Lectures')), findsOneWidget);
    });

    testWidgets('GivenTheMenu_WhenScanAgainIsChosen_ThenTheLibraryIsScanned', (
      tester,
    ) async {
      final index = FakeIndexGateway();
      await open(
        tester,
        extraOverrides: [indexGatewayProvider.overrideWithValue(index)],
      );
      final l10n = messages(tester);
      await tester.tap(inHeader(find.byTooltip(l10n.libraryActions)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.libraryScan));
      await tester.pumpAndSettle();

      expect(index.libraryStarts.map((start) => start.uuid), ['lib-1']);
    });

    testWidgets('GivenTheMenu_WhenMoveIsChosen_ThenTheLibraryIsPointedThere', (
      tester,
    ) async {
      final opened = await open(
        tester,
        picker: FakeFolderPicker(path: '/media/moved'),
      );
      final l10n = messages(tester);
      await tester.tap(inHeader(find.byTooltip(l10n.libraryActions)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.libraryMove));
      await tester.pumpAndSettle();

      expect(opened.gateway.moved, [(uuid: 'lib-1', rootPath: '/media/moved')]);
    });

    testWidgets('GivenTheMenu_WhenRemoveIsConfirmed_ThenTheShellGoesHome', (
      tester,
    ) async {
      final opened = await open(tester);
      final l10n = messages(tester);
      await tester.tap(inHeader(find.byTooltip(l10n.libraryActions)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.libraryRemove));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmationDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, l10n.libraryRemove));
      await tester.pumpAndSettle();

      expect(opened.gateway.removed, ['lib-1']);
      expect(
        opened.container.read(shellControllerProvider),
        const HomeDestination(),
      );
    });

    testWidgets('GivenTheHeader_WhenRemoveIsRefused_ThenTheShellSaysWhy', (
      tester,
    ) async {
      // The Manage libraries dialog says its refusals inside itself; the
      // header, with no dialog over it, still says them on the shell.
      const conflict = Failure.conflict(
        family: CoreStatusFamily.library,
        code: LIBRARY_ERR_CONFLICT,
      );
      await open(
        tester,
        gateway: FakeLibraryGateway(libraries: const [course, films])
          ..writeOutcomes.add(const LibraryWrite.failed(failure: conflict)),
      );
      final l10n = messages(tester);
      await tester.tap(inHeader(find.byTooltip(l10n.libraryActions)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.libraryRemove));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l10n.libraryRemove));
      await tester.pumpAndSettle();

      final said = find.widgetWithText(SnackBar, l10n.libraryRemoveRunning);
      expect(
        find.descendant(of: find.byType(ShellScreen), matching: said),
        findsOneWidget,
      );
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('GivenAPausedRun_WhenTheLibraryIsShown_ThenItsStatusIsShown', (
      tester,
    ) async {
      await open(
        tester,
        extraOverrides: [
          indexGatewayProvider.overrideWithValue(
            FakeIndexGateway()
              ..activeRunsOutcome = const ActiveRunsOutcome.read(
                runs: [
                  IndexRun(
                    runId: 'r1',
                    root: '/media/course',
                    libraryUuid: 'lib-1',
                    status: IndexRunStatus.paused,
                  ),
                ],
              ),
          ),
          runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
        ],
      );

      expect(
        inHeader(find.text(messages(tester).libraryRunPaused)),
        findsOneWidget,
      );
    });

    testWidgets(
      'GivenTheKeyboard_WhenThePinAndTheMenuAreActivated_ThenTheyWork',
      (tester) async {
        final opened = await open(tester);
        final l10n = messages(tester);

        // Tab until the Pin toggle has the focus, as a keyboard owner would.
        final pin = inHeader(find.byTooltip(l10n.libraryPin));
        await tabUntilFocused(tester, pin);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(opened.gateway.pinnedCalls, [(uuid: 'lib-1', pinned: true)]);

        // On to the menu button, opened with Space; then down to Rename.
        final menu = inHeader(find.byTooltip(l10n.libraryActions));
        await tabUntilFocused(tester, menu);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(find.text(l10n.libraryRenameEntry), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryNameDialog), findsOneWidget);
      },
    );
  });

  group('size', () {
    testWidgets(
      'GivenFiveHundredFilesAtTheMinimumWindow_WhenShown_ThenNothingOverflowsAndOnlyVisibleRowsAreBuilt',
      (tester) async {
        await open(
          tester,
          surfaceSize: Breakpoint.minimumWindowSize,
          levels: {
            '': level(
              '',
              folders: ['a-folder'],
              files: [
                for (var index = 0; index < 500; index++)
                  aFile(
                    uuid: 'clip-$index',
                    name: 'Clip $index.mp4',
                    type: FileType.video,
                  ),
              ],
            ),
          },
        );

        expect(tester.takeException(), isNull);
        expect(inView(find.byType(FileRow)), findsWidgets);
        expect(
          tester.widgetList(inView(find.byType(FileRow))).length,
          lessThan(100),
          reason: 'a folder that built all 500 rows would defeat FR-CT-10',
        );
      },
    );
  });

  group('the areas that are not a library', () {
    testWidgets('GivenBookmarks_WhenSelected_ThenNoLibraryIsShown', (
      tester,
    ) async {
      await open(tester);

      await tester.goTo(const BookmarksDestination());

      expect(find.byType(LibraryView), findsNothing);
      expect(find.byType(BookmarksView), findsOneWidget);
    });
  });

  for (final (name, locale) in [
    ('English', const Locale('en')),
    ('Portuguese', const Locale('pt', 'BR')),
  ]) {
    testWidgets('Given${name}_WhenALibraryIsShown_ThenItIsLocalized', (
      tester,
    ) async {
      await open(
        tester,
        locale: locale,
        levels: {
          '': level('', files: [syllabus]),
        },
      );
      final l10n = messages(tester);

      for (final label in [
        l10n.libraryEmptyFolder,
        l10n.libraryTypeAll,
        l10n.sortLabel,
        l10n.libraryNoneComicBooks,
        l10n.libraryTypeFilterClear,
        l10n.libraryActions,
        l10n.libraryViewUnsaved,
      ]) {
        expect(label, isNot(startsWith('library')));
      }
      expect(inView(find.text(l10n.libraryTypeAll)), findsOneWidget);
      expect(inHeader(find.byTooltip(l10n.libraryActions)), findsOneWidget);
    });
  }

  group('both themes', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${mode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenALibraryIsShown_ThenItRendersInThatBrightness',
        (tester) async {
          await open(tester, themeMode: mode);

          expect(
            Theme.of(tester.element(find.byType(LibraryView))).brightness,
            mode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }
  });
}

/// Presses Tab until [target] holds the primary focus.
Future<void> tabUntilFocused(WidgetTester tester, Finder target) async {
  for (var press = 0; press < 60; press++) {
    if (_hasFocus(tester, target)) return;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
  }
  fail('Tab never reached $target');
}

bool _hasFocus(WidgetTester tester, Finder target) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  final element = tester.element(target);
  if (element == focused) return true;
  // The focus node sits below the tooltip's element, inside the button.
  var found = false;
  void visit(Element child) {
    if (child == focused) found = true;
    if (!found) child.visitChildElements(visit);
  }

  element.visitChildElements(visit);
  return found;
}
