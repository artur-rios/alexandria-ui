import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:alexandria_ui/features/viewers/application/comic_viewer_controller.dart';
import 'package:alexandria_ui/features/viewers/domain/file_viewer.dart';
import 'package:alexandria_ui/features/viewers/presentation/comic_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_comic_gateway.dart';
import '../../../support/fake_document_gateway.dart';
import '../../../support/shell_harness.dart';

/// Reading a comic book (UC-23, FR-VW-03, FR-VW-07, FR-VW-08).
void main() {
  const uuid = 'c1b2a390-4d5e-4f60-8a71-9b2c3d4e5f60';

  /// Signs in, opens the comic listing, and opens the one file in it.
  Future<
    ({
      ProviderContainer container,
      FakeComicGateway comics,
      FakeReadingPositionStore positions,
    })
  >
  open(
    WidgetTester tester, {
    FakeComicGateway? comics,
    FakeReadingPositionStore? positions,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    bool openIt = true,
  }) async {
    final file = aFile(
      uuid: uuid,
      name: 'Watchmen 01.cbz',
      path: '/home/owner/comics/Watchmen 01.cbz',
      type: FileType.comic,
    );
    final catalog = FakeCatalogGateway(
      listings: {
        FileType.comic: loadedDetails([file]),
      },
    );
    catalog.details[uuid] = FileDetailsOutcome.read(
      details: FileDetails(file: file, metadata: const {}),
    );

    final archive = comics ?? FakeComicGateway();
    final store = positions ?? FakeReadingPositionStore();

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(catalog),
        comicGatewayProvider.overrideWithValue(archive),
        readingPositionsProvider.overrideWithValue(store),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(ShellDestination.comicBooks.icon),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watchmen 01.cbz').first);
    await tester.pumpAndSettle();

    if (openIt) {
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      await tester.tap(find.text(l10n.viewerOpen));
      await tester.pumpAndSettle();
    }

    return (container: container, comics: archive, positions: store);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  group('the main flow', () {
    testWidgets('GivenAComic_WhenItsDetailsOpen_ThenReadingIsOffered', (
      tester,
    ) async {
      await open(tester, openIt: false);

      expect(find.text(messages(tester).viewerOpen), findsOneWidget);
    });

    // Step 2: pages come from the archive without it being extracted, which
    // is the core's own call rather than a temporary directory here.
    testWidgets('GivenAComic_WhenItIsOpened_ThenItsFirstPageIsRead', (
      tester,
    ) async {
      final opened = await open(tester);

      expect(opened.comics.requested, [1]);
      expect(find.byType(Image), findsWidgets);
    });

    // Step 3.
    testWidgets('GivenAPage_WhenTheOwnerTurnsIt_ThenTheNextPageIsRead', (
      tester,
    ) async {
      final opened = await open(tester);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(opened.comics.requested, [1, 2]);
      expect(find.text(messages(tester).comicPageOf(2, 3)), findsOneWidget);
    });

    testWidgets('GivenTheFirstPage_WhenItIsShown_ThenTurningBackIsNotOffered', (
      tester,
    ) async {
      await open(tester);

      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_left),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('GivenTheLastPage_WhenItIsShown_ThenTurningOnIsNotOffered', (
      tester,
    ) async {
      final opened = await open(tester, comics: FakeComicGateway(pageCount: 1));

      expect(opened.comics.requested, [1]);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_right),
            )
            .onPressed,
        isNull,
      );
    });

    // FR-VW-03's fit controls.
    testWidgets('GivenTheFitIsChanged_WhenItIs_ThenThePageFollows', (
      tester,
    ) async {
      final opened = await open(tester);

      await tester.tap(find.byIcon(Icons.width_normal_outlined));
      await tester.pumpAndSettle();

      expect(
        opened.container.read(comicViewerControllerProvider).fit,
        ComicFit.width,
      );
    });

    // Step 4: the page position is remembered.
    testWidgets('GivenAPageIsRead_WhenItIs_ThenThePositionIsRemembered', (
      tester,
    ) async {
      final opened = await open(tester);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(opened.positions.recorded.last.uuid, uuid);
      expect(opened.positions.recorded.last.position, 2);
    });

    testWidgets(
      'GivenARememberedPage_WhenTheComicIsOpened_ThenItResumesThere',
      (tester) async {
        final opened = await open(
          tester,
          positions: FakeReadingPositionStore({uuid: 3}),
        );

        expect(opened.comics.requested, [3]);
        expect(find.text(messages(tester).comicPageOf(3, 3)), findsOneWidget);
      },
    );

    // Step 5: nothing was extracted, so nothing is left behind.
    testWidgets('GivenAnOpenComic_WhenItIsClosed_ThenNothingIsRetained', (
      tester,
    ) async {
      final opened = await open(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(ComicViewerScreen), findsNothing);
      expect(
        opened.container.read(comicViewerControllerProvider).bytes,
        isNull,
      );
    });
  });

  // AF-01, AF-02, AF-03: the archive itself.
  group('an archive that cannot be read', () {
    testWidgets('GivenTheFileIsGone_WhenItIsOpened_ThenItIsReportedAsMissing', (
      tester,
    ) async {
      await open(
        tester,
        comics: FakeComicGateway()
          ..archiveFailure = ViewerFailure.missingOnDisk,
      );

      expect(find.text(messages(tester).viewerFileMissing), findsOneWidget);
      expect(find.text(messages(tester).detailsRescan), findsOneWidget);
    });

    testWidgets('GivenACorruptArchive_WhenItIsOpened_ThenItIsReported', (
      tester,
    ) async {
      await open(
        tester,
        comics: FakeComicGateway()..archiveFailure = ViewerFailure.unreadable,
      );

      expect(find.text(messages(tester).viewerUnreadable), findsOneWidget);
    });

    // AF-03: the file is named, so the owner knows which one has a format
    // nothing bundled decodes.
    testWidgets('GivenAnUnsupportedFormat_WhenItIsOpened_ThenTheFileIsNamed', (
      tester,
    ) async {
      await open(
        tester,
        comics: FakeComicGateway()
          ..archiveFailure = ViewerFailure.unsupportedFormat,
      );

      expect(
        find.text(messages(tester).viewerUnsupportedFormat('Watchmen 01.cbz')),
        findsOneWidget,
      );
    });

    testWidgets('GivenAnUnsupportedFormat_WhenClosed_ThenOtherActionsRemain', (
      tester,
    ) async {
      await open(
        tester,
        comics: FakeComicGateway()
          ..archiveFailure = ViewerFailure.unsupportedFormat,
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text(messages(tester).renameOpen), findsOneWidget);
    });
  });

  // AF-04: an individual page cannot be decoded.
  group('a page that will not decode', () {
    testWidgets('GivenABadPage_WhenTheOwnerReachesIt_ThenItIsSteppedOver', (
      tester,
    ) async {
      final comics = FakeComicGateway()..undecodable.add(2);
      final opened = await open(tester, comics: comics);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(opened.comics.requested, [1, 2, 3]);
      expect(find.text(messages(tester).comicPageOf(3, 3)), findsOneWidget);
    });

    testWidgets('GivenABadPage_WhenItIsSteppedOver_ThenTheGapIsMarked', (
      tester,
    ) async {
      final comics = FakeComicGateway()..undecodable.add(2);
      await open(tester, comics: comics);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(
        find.text(messages(tester).comicPagesSkipped('2')),
        findsOneWidget,
      );
    });

    // Running out of archive mid-gap: the page on screen has to stay on
    // screen.
    testWidgets(
        'GivenEveryPageAheadIsBad_WhenPagingOn_ThenTheLastGoodOneStays', (
      tester,
    ) async {
      // The viewer used to end this run holding the stage open with no image
      // and the number of a page that never decoded — a blank frame with
      // working controls and nothing to say why.
      final comics = FakeComicGateway()..undecodable.addAll([2, 3]);
      final opened = await open(tester, comics: comics);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(opened.comics.requested, [1, 2, 3]);
      expect(find.text(messages(tester).comicPageOf(1, 3)), findsOneWidget);
      // The image itself, because the number alone was right in one of the
      // ways this was broken and the frame was still empty.
      expect(find.byType(Image), findsWidgets);
      expect(
        find.text(messages(tester).comicPagesSkipped('2, 3')),
        findsOneWidget,
      );
    });

    // Paging backwards over a gap steps backwards, not forwards.
    testWidgets('GivenABadPage_WhenPagingBack_ThenItStepsBackPastIt', (
      tester,
    ) async {
      final comics = FakeComicGateway()..undecodable.add(2);
      final opened = await open(
        tester,
        comics: comics,
        positions: FakeReadingPositionStore({uuid: 3}),
      );

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(opened.comics.requested, [3, 2, 1]);
      expect(find.text(messages(tester).comicPageOf(1, 3)), findsOneWidget);
    });
  });

  group('themes and languages', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheViewerOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await open(tester, themeMode: themeMode);

          expect(
            Theme.of(tester.element(find.byType(ComicViewerScreen))).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheViewerOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          final comics = FakeComicGateway()..undecodable.add(2);
          await open(tester, locale: locale, comics: comics);

          await tester.tap(find.byIcon(Icons.chevron_right));
          await tester.pumpAndSettle();

          expect(
            find.textContaining(RegExp('comic[A-Z]'), findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });
}
