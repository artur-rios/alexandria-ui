import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/domain/music_metadata.dart';
import 'package:alexandria_ui/features/catalog/domain/view_layout.dart';
import 'package:alexandria_ui/features/catalog/presentation/file_details_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/viewers/presentation/document_viewer_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_folder_picker.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/shell_harness.dart';

/// The rows and tiles a file is drawn with (UC-13, FR-CT-03, FR-CT-10).
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
        destination: const TypeDestination(FileType.document),
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
        destination: const TypeDestination(FileType.document),
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
        destination: const TypeDestination(FileType.document),
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
        destination: const TypeDestination(FileType.document),
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

  group('the rows (FR-CT-10)', () {
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

    testWidgets(
      'GivenTheMusicPanel_WhenListed_ThenRowsShowTitleBylineDuration',
      (tester) async {
        await openListing(
          tester,
          listings: twoTracks(),
          destination: const TypeDestination(FileType.audio),
        );

        expect(find.text('First'), findsOneWidget);
        expect(find.text('01 - a.flac'), findsNothing);
        expect(find.text('Band · Record'), findsNWidgets(2));
        expect(find.text('4:05'), findsOneWidget);
      },
    );
  });
}
