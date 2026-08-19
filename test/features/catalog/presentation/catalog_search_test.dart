import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/failures/core_status.dart';
import 'package:alexandria_desktop/core/failures/failure.dart';
import 'package:alexandria_desktop/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_desktop/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_desktop/features/catalog/domain/library_type.dart';
import 'package:alexandria_desktop/features/library_sources/presentation/library_sources_screen.dart';
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
    Map<LibraryType, CatalogListing>? listings,
    Locale? locale,
  }) => tester.pumpShell(
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
  Map<LibraryType, CatalogListing> aLibrary() => {
    LibraryType.audio: CatalogListing.loaded(
      files: [
        aFile(name: 'Kind of Blue.flac'),
        aFile(uuid: 'c', name: 'Giant Steps.flac'),
      ],
    ),
    LibraryType.image: CatalogListing.loaded(
      files: [aFile(uuid: 'b', name: 'blue.png', type: LibraryType.image)],
    ),
  };

  group('the main flow', () {
    testWidgets('GivenTheShell_WhenItOpens_ThenASearchFieldIsOffered',
        (tester) async {
      await openShell(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));

      expect(find.widgetWithText(TextField, l10n.searchLabel), findsOneWidget);
    });

    testWidgets('GivenATerm_WhenItIsEntered_ThenMatchesAcrossTypesAreShown',
        (tester) async {
      await openShell(tester, listings: aLibrary());

      await search(tester, 'blue');

      expect(find.text('Kind of Blue.flac'), findsOneWidget);
      expect(find.text('blue.png'), findsOneWidget);
      expect(find.text('Giant Steps.flac'), findsNothing);
    });

    testWidgets('GivenMatchesOfTwoTypes_WhenShown_ThenTheyAreGroupedByType',
        (tester) async {
      await openShell(tester, listings: aLibrary());

      await search(tester, 'blue');

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      // The group headings are the panel's own words for the types.
      expect(find.text(l10n.destinationMusic), findsWidgets);
      expect(find.text(l10n.destinationImages), findsWidgets);
    });

    testWidgets('GivenAMatch_WhenItIsShown_ThenTheTermIsHighlighted',
        (tester) async {
      await openShell(tester, listings: aLibrary());

      await search(tester, 'blue');

      // A rich-text title is what carries the marked span; a plain Text would
      // mean the highlight was never applied.
      final titles = tester.widgetList<Text>(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.byType(Text),
        ),
      );
      expect(
        titles.any((text) => text.textSpan != null),
        isTrue,
        reason: 'the matched term should be marked in the name',
      );
    });
  });

  group('nothing matches (AF-01, FR-CT-09)', () {
    testWidgets('GivenNoMatch_WhenTheTermIsEntered_ThenTheTermIsNamed',
        (tester) async {
      await openShell(tester, listings: aLibrary());

      await search(tester, 'reggae');

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      expect(find.text(l10n.searchNoResults('reggae')), findsOneWidget);
    });
  });

  group('the term is cleared (AF-02)', () {
    testWidgets('GivenASearch_WhenTheTermIsCleared_ThenTheListingReturns',
        (tester) async {
      await openShell(tester, listings: aLibrary());
      await search(tester, 'blue');
      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      expect(find.text(l10n.searchResultsFor('blue')), findsOneWidget);

      await tester.tap(find.byTooltip(l10n.searchClear));
      await tester.pumpAndSettle();

      expect(find.text(l10n.searchResultsFor('blue')), findsNothing);
    });

    testWidgets('GivenAWhitespaceTerm_WhenItIsEntered_ThenNoSearchRuns',
        (tester) async {
      await openShell(tester, listings: aLibrary());

      await search(tester, '   ');

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      expect(find.text(l10n.searchResultsFor('   ')), findsNothing);
    });
  });

  group('part of the catalog could not be read (AF-03)', () {
    testWidgets('GivenAFailedType_WhenTheCatalogIsSearched_ThenItSaysSo',
        (tester) async {
      await openShell(
        tester,
        listings: {
          ...aLibrary(),
          LibraryType.text: const CatalogListing.failed(
            failure: Failure.disk(family: CoreStatusFamily.file, code: 6),
          ),
        },
      );

      await search(tester, 'blue');

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      // The results are a partial answer, and saying so is the difference
      // between a partial answer and a wrong one.
      expect(find.text(l10n.searchPartial), findsOneWidget);
    });

    testWidgets('GivenEveryTypeAnswers_WhenSearched_ThenNoPartialIsClaimed',
        (tester) async {
      await openShell(tester, listings: aLibrary());

      await search(tester, 'blue');

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      expect(find.text(l10n.searchPartial), findsNothing);
    });
  });

  group('the catalog is empty (AF-04)', () {
    testWidgets('GivenNothingCatalogued_WhenSearched_ThenAFolderIsOffered',
        (tester) async {
      await openShell(tester);

      await search(tester, 'blue');

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
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
    testWidgets('Given${name}_WhenNothingMatches_ThenItIsLocalized',
        (tester) async {
      await openShell(tester, listings: aLibrary(), locale: locale);

      await search(tester, 'reggae');

      final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
      expect(l10n.searchNoResults('reggae'), isNot(startsWith('search')));
      expect(find.text(l10n.searchNoResults('reggae')), findsOneWidget);
    });
  }
}
