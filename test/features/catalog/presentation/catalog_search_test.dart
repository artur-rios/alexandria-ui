import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/failures/core_status.dart';
import 'package:alexandria_desktop/core/failures/failure.dart';
import 'package:alexandria_desktop/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_desktop/features/catalog/domain/catalog_gateway.dart'
    as gateway
    show CatalogListing;
import 'package:alexandria_desktop/features/catalog/domain/library_type.dart';
import 'package:alexandria_desktop/features/library_sources/presentation/library_sources_screen.dart';
import 'package:alexandria_desktop/features/catalog/presentation/catalog_listing.dart'
    show CatalogListing;
import 'package:alexandria_desktop/features/catalog/presentation/catalog_search_view.dart';
import 'package:alexandria_desktop/features/shell/domain/shell_destination.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/shell_harness.dart';

/// Searching the catalog (UC-11, FR-CT-06, FR-CT-09).
void main() {
  /// Signs in with [listings] bound.
  Future<ProviderContainer> openShell(
    WidgetTester tester, {
    Map<LibraryType, gateway.CatalogListing>? listings,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) => tester.pumpShell(
    themeMode: themeMode,
    locale: locale,
    extraOverrides: <Override>[
      catalogGatewayProvider.overrideWithValue(
        FakeCatalogGateway(listings: listings),
      ),
    ],
  );

  /// Types [term] into the search field.
  Future<void> search(WidgetTester tester, String term) async {
    await tester.enterText(find.byType(TextField), term);
    await tester.pumpAndSettle();
  }

  /// A library with one audio file and one image in it.
  Map<LibraryType, gateway.CatalogListing> aLibrary() => {
    LibraryType.audio: gateway.CatalogListing.loaded(
      files: [
        aFile(name: 'Kind of Blue.flac'),
        aFile(uuid: 'c', name: 'Giant Steps.flac'),
      ],
    ),
    LibraryType.image: gateway.CatalogListing.loaded(
      files: [aFile(uuid: 'b', name: 'blue.png', type: LibraryType.image)],
    ),
  };

  /// Moves to [destination] through the navigation panel.
  Future<void> goTo(WidgetTester tester, ShellDestination destination) async {
    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(destination.icon),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('leaving a search behind', () {
    testWidgets(
      'GivenASearchIsOpen_WhenAnotherAreaIsChosen_ThenTheListingIsShown',
      (tester) async {
        // Navigating is a request for that area. A search left standing would
        // leave the panel highlighting one thing and the content showing
        // another, with only the clear button to escape it.
        await openShell(tester, listings: aLibrary());
        await search(tester, 'blue');

        await goTo(tester, ShellDestination.images);

        expect(find.byType(CatalogSearchResults), findsNothing);
        expect(find.byType(CatalogListing), findsOneWidget);
      },
    );

    testWidgets(
      'GivenASearchIsOpen_WhenAnotherAreaIsChosen_ThenTheFieldIsEmpty',
      (tester) async {
        final container = await openShell(tester, listings: aLibrary());
        await search(tester, 'blue');

        await goTo(tester, ShellDestination.images);

        expect(container.read(searchTermProvider), isEmpty);
      },
    );
  });

  group('the areas a catalog search does not answer', () {
    testWidgets(
      'GivenTheBookmarksArea_WhenItOpens_ThenNoCatalogSearchIsOffered',
      (tester) async {
        // Bookmarks are not files, and the catalog search matches file names
        // (FR-CT-06). A field that silently replaced the bookmarks with file
        // results would be offering an answer to a question it cannot ask.
        await openShell(tester, listings: aLibrary());

        await goTo(tester, ShellDestination.bookmarks);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );

        expect(find.widgetWithText(TextField, l10n.searchLabel), findsNothing);
      },
    );

    testWidgets(
      'GivenAFileTypeArea_WhenItOpens_ThenTheCatalogSearchIsOffered',
      (tester) async {
        await openShell(tester, listings: aLibrary());

        await goTo(tester, ShellDestination.images);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );

        expect(
          find.widgetWithText(TextField, l10n.searchLabel),
          findsOneWidget,
        );
      },
    );
  });

  group('the main flow', () {
    testWidgets('GivenTheShell_WhenItOpens_ThenASearchFieldIsOffered', (
      tester,
    ) async {
      await openShell(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );

      expect(find.widgetWithText(TextField, l10n.searchLabel), findsOneWidget);
    });

    testWidgets('GivenATerm_WhenItIsEntered_ThenMatchesAcrossTypesAreShown', (
      tester,
    ) async {
      await openShell(tester, listings: aLibrary());

      await search(tester, 'blue');

      expect(find.text('Kind of Blue.flac'), findsOneWidget);
      expect(find.text('blue.png'), findsOneWidget);
      expect(find.text('Giant Steps.flac'), findsNothing);
    });

    testWidgets('GivenMatchesOfTwoTypes_WhenShown_ThenTheyAreGroupedByType', (
      tester,
    ) async {
      await openShell(tester, listings: aLibrary());

      await search(tester, 'blue');

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      // The group headings are the panel's own words for the types.
      expect(find.text(l10n.destinationMusic), findsWidgets);
      expect(find.text(l10n.destinationImages), findsWidgets);
    });

    testWidgets('GivenAMatch_WhenItIsShown_ThenTheTermIsHighlighted', (
      tester,
    ) async {
      await openShell(tester, listings: aLibrary());

      await search(tester, 'blue');

      // A rich-text title is what carries the marked span; a plain Text would
      // mean the highlight was never applied.
      final titles = tester.widgetList<Text>(
        find.descendant(of: find.byType(ListTile), matching: find.byType(Text)),
      );
      expect(
        titles.any((text) => text.textSpan != null),
        isTrue,
        reason: 'the matched term should be marked in the name',
      );
    });
  });

  group('nothing matches (AF-01, FR-CT-09)', () {
    testWidgets('GivenNoMatch_WhenTheTermIsEntered_ThenTheTermIsNamed', (
      tester,
    ) async {
      await openShell(tester, listings: aLibrary());

      await search(tester, 'reggae');

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.searchNoResults('reggae')), findsOneWidget);
    });
  });

  group('the term is cleared (AF-02)', () {
    testWidgets('GivenASearch_WhenTheTermIsCleared_ThenTheListingReturns', (
      tester,
    ) async {
      await openShell(tester, listings: aLibrary());
      await search(tester, 'blue');
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.searchResultsFor('blue')), findsOneWidget);

      await tester.tap(find.byTooltip(l10n.searchClear));
      await tester.pumpAndSettle();

      expect(find.text(l10n.searchResultsFor('blue')), findsNothing);
    });

    testWidgets('GivenAWhitespaceTerm_WhenItIsEntered_ThenNoSearchRuns', (
      tester,
    ) async {
      await openShell(tester, listings: aLibrary());

      await search(tester, '   ');

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.searchResultsFor('   ')), findsNothing);
    });
  });

  group('part of the catalog could not be read (AF-03)', () {
    testWidgets('GivenAFailedType_WhenTheCatalogIsSearched_ThenItSaysSo', (
      tester,
    ) async {
      await openShell(
        tester,
        listings: {
          ...aLibrary(),
          LibraryType.text: const gateway.CatalogListing.failed(
            failure: Failure.disk(family: CoreStatusFamily.file, code: 6),
          ),
        },
      );

      await search(tester, 'blue');

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      // The results are a partial answer, and saying so is the difference
      // between a partial answer and a wrong one.
      expect(find.text(l10n.searchPartial), findsOneWidget);
    });

    testWidgets('GivenEveryTypeAnswers_WhenSearched_ThenNoPartialIsClaimed', (
      tester,
    ) async {
      await openShell(tester, listings: aLibrary());

      await search(tester, 'blue');

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.searchPartial), findsNothing);
    });
  });

  group('the catalog is empty (AF-04)', () {
    testWidgets('GivenNothingCatalogued_WhenSearched_ThenAFolderIsOffered', (
      tester,
    ) async {
      await openShell(tester);

      await search(tester, 'blue');

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(find.text(l10n.catalogEmptyFirstRun), findsOneWidget);

      await tester.tap(find.text(l10n.catalogEmptyAddFolder));
      await tester.pumpAndSettle();

      expect(find.byType(LibrarySourcesScreen), findsOneWidget);
    });
  });

  for (final (name, locale) in [
    ('English', const Locale('en')),
    ('Portuguese', const Locale('pt', 'BR')),
  ]) {
    testWidgets('Given${name}_WhenNothingMatches_ThenItIsLocalized', (
      tester,
    ) async {
      await openShell(tester, listings: aLibrary(), locale: locale);

      await search(tester, 'reggae');

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      expect(l10n.searchNoResults('reggae'), isNot(startsWith('search')));
      expect(find.text(l10n.searchNoResults('reggae')), findsOneWidget);
    });
  }
  // Testing Specification 7.1: both themes are test surface, not review
  // surface. A screen that only reads correctly in one is a failing screen.
  group('both themes', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${mode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheScreenOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openShell(tester, themeMode: mode);

          expect(
            Theme.of(tester.element(find.byType(ShellScreen).first)).brightness,
            mode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }
  });
}
