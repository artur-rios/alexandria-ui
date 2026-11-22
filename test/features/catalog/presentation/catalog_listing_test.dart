import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/domain/music_metadata.dart';
// Prefixed: the widget and the domain's listing union share a name, and this
// test speaks about both.
import 'package:alexandria_ui/features/catalog/presentation/catalog_listing.dart'
    as widgets;
import 'package:alexandria_ui/features/libraries/presentation/libraries_view.dart';
import 'package:alexandria_ui/features/organization/presentation/bookmarks_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/async_state_view.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_folder_picker.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/shell_harness.dart';

/// Browsing the library by type (UC-09, FR-CT-01, FR-CT-02, FR-CT-10).
void main() {
  /// Signs in and selects [destination].
  Future<ProviderContainer> openListing(
    WidgetTester tester, {
    Map<FileType, CatalogListing>? listings,
    ShellDestination destination = const TypeDestination(FileType.video),
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
        // The empty catalog offers to add a library; cancelling the picker it
        // opens keeps a test that presses it off the platform channel.
        folderPickerProvider.overrideWithValue(FakeFolderPicker()),
      ],
    );

    await tester.goTo(destination);

    return container;
  }

  group('the main flow', () {
    testWidgets('GivenATypeWithFiles_WhenItIsSelected_ThenItsFilesAreListed', (
      tester,
    ) async {
      await openListing(
        tester,
        listings: {
          FileType.video: loadedDetails([
            aFile(type: FileType.video, name: 'Deep Blue Sea.mp4'),
            aFile(uuid: 'b', type: FileType.video, name: 'Blue Planet.mp4'),
          ]),
        },
      );

      expect(find.text('Deep Blue Sea.mp4'), findsOneWidget);
      expect(find.text('Blue Planet.mp4'), findsOneWidget);
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

        // The content area's offer, not the left menu's entry beside it.

        await tester.tap(
          find.descendant(
            of: find.byType(ShellContentArea),

            matching: find.text(l10n.libraryAdd),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LibrariesView), findsOneWidget);
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

      await tester.openTypeListing(FileType.image);

      expect(find.text('a.png'), findsOneWidget);
      expect(find.byType(ShellFailureView), findsNothing);
    });
  });

  group('the areas that are not listings', () {
    testWidgets('GivenBookmarks_WhenSelected_ThenNoFileListingIsShown', (
      tester,
    ) async {
      // Bookmarks are not files, so the listing this use case built is not
      // what that destination shows — UC-28's bookmark manager is.
      await openListing(tester, destination: const BookmarksDestination());

      expect(find.byType(widgets.CatalogListing), findsNothing);
      expect(find.byType(BookmarksView), findsOneWidget);
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

  group('the Music panel', () {
    Map<FileType, CatalogListing> twoTracks() => {
      FileType.audio: loadedDetails([
        aFile(
          uuid: 't2',
          name: '02 - b.flac',
          type: FileType.audio,
          tags: const MusicMetadata(
            title: 'Second',
            artist: 'Band',
            album: 'Record',
            track: 2,
          ),
          durationSeconds: 125,
        ),
        aFile(
          uuid: 't1',
          name: '01 - a.flac',
          type: FileType.audio,
          tags: const MusicMetadata(
            title: 'First',
            artist: 'Band',
            album: 'Record',
            track: 1,
          ),
          durationSeconds: 245,
        ),
      ]),
    };

    testWidgets('GivenTheMusicPanel_WhenOpened_ThenItIsSortedByAlbum', (
      tester,
    ) async {
      await openListing(
        tester,
        listings: twoTracks(),
        destination: const TypeDestination(FileType.audio),
      );

      expect(
        tester.getTopLeft(find.text('First')).dy,
        lessThan(tester.getTopLeft(find.text('Second')).dy),
        reason: 'track 1 is listed after track 2',
      );
    });
  });
}
