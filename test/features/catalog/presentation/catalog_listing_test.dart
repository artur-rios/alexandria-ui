import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/failures/core_status.dart';
import 'package:alexandria_desktop/core/failures/failure.dart';
import 'package:alexandria_desktop/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_desktop/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_desktop/features/catalog/domain/library_type.dart';
import 'package:alexandria_desktop/features/library_sources/presentation/library_sources_screen.dart';
import 'package:alexandria_desktop/features/shell/domain/shell_destination.dart';
import 'package:alexandria_desktop/features/shell/presentation/async_state_view.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_screen.dart';
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
    Map<LibraryType, CatalogListing>? listings,
    ShellDestination destination = ShellDestination.music,
    Locale? locale,
  }) async {
    final container = await tester.pumpShell(
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

  group('the main flow', () {
    testWidgets('GivenATypeWithFiles_WhenItIsSelected_ThenItsFilesAreListed',
        (tester) async {
      await openListing(
        tester,
        listings: {
          LibraryType.audio: CatalogListing.loaded(
            files: [aFile(), aFile(uuid: 'b', name: 'Blue Train.flac')],
          ),
        },
      );

      expect(find.text('Kind of Blue.flac'), findsOneWidget);
      expect(find.text('Blue Train.flac'), findsOneWidget);
    });

    testWidgets('GivenALargeListing_WhenItIsShown_ThenRowsAreBuiltOnDemand',
        (tester) async {
      // FR-CT-10: the scroll cost must not grow with the library. A builder
      // materializes only what fits, which is what this asserts.
      await openListing(
        tester,
        listings: {
          LibraryType.audio: CatalogListing.loaded(
            files: [
              for (var index = 0; index < 500; index++)
                aFile(uuid: '$index', name: 'Track $index.flac'),
            ],
          ),
        },
      );

      expect(find.byType(ListTile), findsWidgets);
      expect(
        tester.widgetList(find.byType(ListTile)).length,
        lessThan(100),
        reason: 'a listing that built all 500 rows would defeat FR-CT-10',
      );
    });

    testWidgets('GivenAMissingFile_WhenItIsListed_ThenItIsMarked',
        (tester) async {
      await openListing(
        tester,
        listings: {
          LibraryType.audio: CatalogListing.loaded(
            files: [aFile(missingAt: DateTime.utc(2026, 8, 19))],
          ),
        },
      );

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      expect(find.text(l10n.catalogFileMissing), findsOneWidget);
    });
  });

  group('the type is empty (AF-01)', () {
    testWidgets(
      'GivenAnEmptyTypeInAStockedLibrary_WhenSelected_ThenItSaysSo',
      (tester) async {
        await openListing(
          tester,
          listings: {
            LibraryType.image: CatalogListing.loaded(files: [aFile()]),
          },
        );

        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );
        expect(find.text(l10n.catalogEmptyTitle), findsOneWidget);
        expect(find.byType(ShellFailureView), findsNothing);
      },
    );

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
    testWidgets('GivenTheCoreFails_WhenATypeIsSelected_ThenAMessageAndRetry',
        (tester) async {
      await openListing(
        tester,
        listings: {
          LibraryType.audio: const CatalogListing.failed(
            failure: Failure.disk(family: CoreStatusFamily.file, code: 6),
          ),
        },
      );

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      expect(find.byType(ShellFailureView), findsOneWidget);
      expect(find.text(l10n.retry), findsOneWidget);
      expect(find.textContaining('6'), findsNothing);
    });

    testWidgets('GivenAFailedType_WhenAnotherIsSelected_ThenItLists',
        (tester) async {
      await openListing(
        tester,
        listings: {
          LibraryType.audio: const CatalogListing.failed(
            failure: Failure.disk(family: CoreStatusFamily.file, code: 6),
          ),
          LibraryType.image: CatalogListing.loaded(
            files: [aFile(type: LibraryType.image, name: 'a.png')],
          ),
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
    testWidgets('GivenTypesWithFiles_WhenTheShellOpens_ThenCountsAreShown',
        (tester) async {
      await openListing(
        tester,
        listings: {
          LibraryType.audio: CatalogListing.loaded(
            files: [aFile(), aFile(uuid: 'b')],
          ),
        },
      );

      expect(find.widgetWithText(Badge, '2'), findsOneWidget);
    });
  });

  group('the seams that are not listings', () {
    testWidgets('GivenBookmarks_WhenSelected_ThenTheAreaIsStillPending',
        (tester) async {
      // Bookmarks are not files; UC-28 fills this.
      await openListing(tester, destination: ShellDestination.bookmarks);

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      expect(find.text(l10n.shellAreaPending), findsOneWidget);
    });
  });

  for (final (name, locale) in [
    ('English', const Locale('en')),
    ('Portuguese', const Locale('pt', 'BR')),
  ]) {
    testWidgets('Given${name}_WhenAnEmptyTypeIsShown_ThenItIsLocalized',
        (tester) async {
      await openListing(
        tester,
        locale: locale,
        listings: {
          LibraryType.image: CatalogListing.loaded(files: [aFile()]),
        },
      );

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      expect(l10n.catalogEmptyTitle, isNot(startsWith('catalog')));
      expect(find.text(l10n.catalogEmptyTitle), findsOneWidget);
    });
  }
}
