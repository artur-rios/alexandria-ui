import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
// Prefixed: the widget and the domain's listing union share a name, and this
// test speaks about both.
import 'package:alexandria_ui/features/catalog/presentation/catalog_listing.dart'
    as widgets;
import 'package:alexandria_ui/features/catalog/domain/view_layout.dart';
import 'package:alexandria_ui/features/catalog/presentation/file_details_view.dart';
import 'package:alexandria_ui/features/library_sources/presentation/library_sources_screen.dart';
import 'package:alexandria_ui/features/organization/presentation/bookmarks_view.dart';
import 'package:alexandria_ui/features/playback/presentation/music_library_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/viewers/presentation/document_viewer_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/async_state_view.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/shell_harness.dart';

/// Browsing the library by type (UC-09, FR-CT-01, FR-CT-02, FR-CT-10).
void main() {
  /// Signs in and selects [destination].
  Future<ProviderContainer> openListing(
    WidgetTester tester, {
    Map<FileType, CatalogListing>? listings,
    ShellDestination destination = ShellDestination.videos,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final container = await tester.pumpShell(
      themeMode: themeMode,
      locale: locale,
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(
          FakeCatalogGateway(listings: listings),
        ),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(destination.icon),
      ),
    );
    await tester.pumpAndSettle();

    return container;
  }

  group('opening a file (UC-13 main flow step 1)', () {
    /// One document, listed under Documents.
    Map<FileType, CatalogListing> aDocument({bool missing = false}) => {
      FileType.document: loadedDetails([
        aFile(
          uuid: 'doc-1',
          name: 'Solaris.epub',
          type: FileType.document,
          missingAt: missing ? DateTime(2026) : null,
        ),
      ]),
    };

    testWidgets('GivenARow_WhenItIsTapped_ThenTheFileItselfOpens', (
      tester,
    ) async {
      // It used to open a dialog about the file, with an Open button inside
      // it: two clicks and a modal to read something the owner had already
      // pointed at.
      await openListing(
        tester,
        listings: aDocument(),
        destination: ShellDestination.books,
      );

      await tester.tap(find.text('Solaris.epub'));
      await tester.pumpAndSettle();

      expect(find.byType(DocumentViewerScreen), findsOneWidget);
      expect(find.byType(FileDetailsView), findsNothing);
    });

    testWidgets('GivenARow_WhenItsDetailsButtonIsPressed_ThenTheDetailsOpen', (
      tester,
    ) async {
      // Renaming, metadata, collections and deletion all live in the details,
      // so the way in is on every row rather than behind a gesture.
      await openListing(
        tester,
        listings: aDocument(),
        destination: ShellDestination.books,
      );

      await tester.tap(find.byType(FileDetailsButton));
      await tester.pumpAndSettle();

      expect(find.byType(FileDetailsView), findsOneWidget);
      expect(find.byType(DocumentViewerScreen), findsNothing);
    });

    testWidgets('GivenAMissingFile_WhenItsRowIsTapped_ThenTheDetailsOpen', (
      tester,
    ) async {
      // A file the last refresh could not find has nothing to open. The
      // details are where that is explained and where the rescan is (UC-37),
      // so that is where the tap goes rather than into a reader that would
      // only fail.
      await openListing(
        tester,
        listings: aDocument(missing: true),
        destination: ShellDestination.books,
      );

      await tester.tap(find.text('Solaris.epub'));
      await tester.pumpAndSettle();

      expect(find.byType(FileDetailsView), findsOneWidget);
      expect(find.byType(DocumentViewerScreen), findsNothing);
    });

    testWidgets('GivenTheGrid_WhenATileIsTapped_ThenTheFileItselfOpens', (
      tester,
    ) async {
      // The tile is the row in another shape; it opens what the row opens.
      final container = await openListing(
        tester,
        listings: aDocument(),
        destination: ShellDestination.books,
      );
      await container
          .read(layoutControllerProvider.notifier)
          .choose(FileType.document, ViewLayout.grid);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Solaris.epub'));
      await tester.pumpAndSettle();

      expect(find.byType(DocumentViewerScreen), findsOneWidget);
    });
  });

  group('the main flow', () {
    testWidgets('GivenATypeWithFiles_WhenItIsSelected_ThenItsFilesAreListed', (
      tester,
    ) async {
      await openListing(
        tester,
        listings: {
          FileType.video: loadedDetails([
            aFile(type: FileType.video, name: 'Kind of Blue.mp4'),
            aFile(uuid: 'b', type: FileType.video, name: 'Blue Train.mp4'),
          ]),
        },
      );

      expect(find.text('Kind of Blue.mp4'), findsOneWidget);
      expect(find.text('Blue Train.mp4'), findsOneWidget);
    });

    testWidgets('GivenALargeListing_WhenItIsShown_ThenRowsAreBuiltOnDemand', (
      tester,
    ) async {
      // FR-CT-10: the scroll cost must not grow with the library. A builder
      // materializes only what fits, which is what this asserts.
      await openListing(
        tester,
        listings: {
          FileType.video: loadedDetails([
            for (var index = 0; index < 500; index++)
              aFile(
                uuid: '$index',
                type: FileType.video,
                name: 'Clip $index.mp4',
              ),
          ]),
        },
      );

      expect(find.byType(ListTile), findsWidgets);
      expect(
        tester.widgetList(find.byType(ListTile)).length,
        lessThan(100),
        reason: 'a listing that built all 500 rows would defeat FR-CT-10',
      );
    });

    testWidgets('GivenAMissingFile_WhenItIsListed_ThenItIsMarked', (
      tester,
    ) async {
      await openListing(
        tester,
        listings: {
          FileType.video: loadedDetails([
            aFile(type: FileType.video, missingAt: DateTime.utc(2026, 8, 19)),
          ]),
        },
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.catalogFileMissing), findsOneWidget);
    });
  });

  group('the type is empty (AF-01)', () {
    testWidgets('GivenAnEmptyTypeInAStockedLibrary_WhenSelected_ThenItSaysSo', (
      tester,
    ) async {
      await openListing(
        tester,
        listings: {
          FileType.image: loadedDetails([aFile()]),
        },
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.catalogEmptyTitle), findsOneWidget);
      expect(find.byType(ShellFailureView), findsNothing);
    });

    testWidgets(
      'GivenAnEmptyCatalog_WhenATypeIsSelected_ThenAddingAFolderIsOffered',
      (tester) async {
        await openListing(tester);

        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );
        expect(find.text(l10n.catalogEmptyFirstRun), findsOneWidget);

        await tester.tap(find.text(l10n.catalogEmptyAddFolder));
        await tester.pumpAndSettle();

        expect(find.byType(LibrarySourcesScreen), findsOneWidget);
      },
    );
  });

  group('the core fails (AF-02)', () {
    testWidgets('GivenTheCoreFails_WhenATypeIsSelected_ThenAMessageAndRetry', (
      tester,
    ) async {
      await openListing(
        tester,
        listings: {
          FileType.video: const CatalogListing.failed(
            failure: Failure.disk(family: CoreStatusFamily.file, code: 6),
          ),
        },
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.byType(ShellFailureView), findsOneWidget);
      expect(find.text(l10n.retry), findsOneWidget);
      expect(find.textContaining('6'), findsNothing);
    });

    testWidgets('GivenAFailedType_WhenAnotherIsSelected_ThenItLists', (
      tester,
    ) async {
      await openListing(
        tester,
        listings: {
          FileType.video: const CatalogListing.failed(
            failure: Failure.disk(family: CoreStatusFamily.file, code: 6),
          ),
          FileType.image: loadedDetails([
            aFile(type: FileType.image, name: 'a.png'),
          ]),
        },
      );
      expect(find.byType(ShellFailureView), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(ShellNavigationPanel),
          matching: find.byIcon(ShellDestination.images.icon),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('a.png'), findsOneWidget);
      expect(find.byType(ShellFailureView), findsNothing);
    });
  });

  group('the panel counts (FR-CT-01)', () {
    testWidgets('GivenTypesWithFiles_WhenTheShellOpens_ThenCountsAreShown', (
      tester,
    ) async {
      await openListing(
        tester,
        listings: {
          FileType.video: loadedDetails([
            aFile(type: FileType.video),
            aFile(uuid: 'b', type: FileType.video),
          ]),
        },
      );

      expect(find.widgetWithText(Badge, '2'), findsOneWidget);
    });
  });

  group('the areas that are not listings', () {
    testWidgets('GivenBookmarks_WhenSelected_ThenNoFileListingIsShown', (
      tester,
    ) async {
      // Bookmarks are not files, so the listing this use case built is not
      // what that destination shows — UC-28's bookmark manager is.
      await openListing(tester, destination: ShellDestination.bookmarks);

      expect(find.byType(widgets.CatalogListing), findsNothing);
      expect(find.byType(BookmarksView), findsOneWidget);
    });

    testWidgets('GivenMusic_WhenSelected_ThenNoFileListingIsShown', (
      tester,
    ) async {
      // UC-46's whole point: a listing of file names is the one thing a
      // music library must never be (FR-CT-13).
      await openListing(tester, destination: ShellDestination.music);

      expect(find.byType(widgets.CatalogListing), findsNothing);
      expect(find.byType(MusicLibraryView), findsOneWidget);
    });
  });

  for (final (name, locale) in [
    ('English', const Locale('en')),
    ('Portuguese', const Locale('pt', 'BR')),
  ]) {
    testWidgets('Given${name}_WhenAnEmptyTypeIsShown_ThenItIsLocalized', (
      tester,
    ) async {
      await openListing(
        tester,
        locale: locale,
        listings: {
          FileType.image: loadedDetails([aFile()]),
        },
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(l10n.catalogEmptyTitle, isNot(startsWith('catalog')));
      expect(find.text(l10n.catalogEmptyTitle), findsOneWidget);
    });
  }
  // Testing Specification 7.1: both themes are test surface, not review
  // surface. A screen that only reads correctly in one is a failing screen.
  group('both themes', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${mode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheScreenOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openListing(tester, themeMode: mode);

          expect(
            Theme.of(tester.element(find.byType(ShellScreen).first)).brightness,
            mode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }
  });
}
