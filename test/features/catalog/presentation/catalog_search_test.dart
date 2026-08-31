import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart'
    as gateway
    show CatalogListing;
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/library_sources/presentation/library_sources_screen.dart';
import 'package:alexandria_ui/features/catalog/presentation/catalog_listing.dart'
    show CatalogListing;
import 'package:alexandria_ui/features/catalog/presentation/catalog_search_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_library_gateway.dart';
import '../../../support/shell_harness.dart';

/// Searching the catalog (UC-11, FR-CT-06, FR-CT-09).
void main() {
  /// Signs in with [listings] bound.
  Future<ProviderContainer> openShell(
    WidgetTester tester, {
    Map<FileType, gateway.CatalogListing>? listings,
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

  /// The active locale's strings, read off the shell that is already open.
  AppLocalizations localizations(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// Opens the shell over [gateway] and searches for [term].
  ///
  /// Takes a whole gateway rather than [openShell]'s `listings` map, because
  /// the audio-result tests need [FakeCatalogGateway.addAudio]'s paired
  /// listing-and-details entry, not just a listing.
  Future<void> searchFor(
    WidgetTester tester, {
    required String term,
    required FakeCatalogGateway gateway,
  }) async {
    await tester.pumpShell(
      extraOverrides: [catalogGatewayProvider.overrideWithValue(gateway)],
    );
    await search(tester, term);
  }

  /// A library with one audio file and one image in it.
  Map<FileType, gateway.CatalogListing> aLibrary() => {
    FileType.audio: loadedDetails([
      aFile(name: 'Kind of Blue.flac'),
      aFile(uuid: 'c', name: 'Giant Steps.flac'),
    ]),
    FileType.image: loadedDetails([
      aFile(uuid: 'b', name: 'blue.png', type: FileType.image),
    ]),
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
      final l10n = localizations(tester);

      await search(tester, 'blue');

      // The audio match still matches on its name on disk (FR-CT-06), but
      // carries no title tag, so FR-CT-13 shows the word for that rather than
      // the name — matching by disk name and showing it are different rules.
      expect(find.text(l10n.musicUnknownTitle), findsOneWidget);
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
          FileType.text: const gateway.CatalogListing.failed(
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

  group('audio results (FR-CT-13)', () {
    testWidgets(
      'GivenAnAudioMatch_WhenTheResultsAreShown_ThenItReadsItsMetadataTitle',
      (tester) async {
        // The rule follows the file type, not the screen: if the results
        // showed names on disk, every file name the music area removes would
        // come back the moment anyone searched.
        //
        // The search itself still matches on the name on disk (FR-CT-06 does
        // not read metadata), so the term has to appear there for the file to
        // be found at all — "AIR" in the disk name is what makes this a match,
        // and "Airbag" in the title is what the row is asserted to show for it.
        await searchFor(
          tester,
          term: 'air',
          gateway: FakeCatalogGateway()
            ..addAudio(
              uuid: '1',
              name: 'AIR-DISKNAME-01.flac',
              title: 'Airbag',
              artist: 'Radiohead',
            ),
        );

        expect(find.textContaining('Airbag'), findsOneWidget);
        expect(find.textContaining('DISKNAME'), findsNothing);
      },
    );

    testWidgets(
      'GivenAnAudioMatch_WhenTheResultsAreShown_ThenItReadsItsArtist',
      (tester) async {
        // Two tracks can share a title — a remix, a live take, a duplicate
        // rip — and the artist is what tells them apart in a result list
        // that no longer shows the file name.
        await searchFor(
          tester,
          term: 'air',
          gateway: FakeCatalogGateway()
            ..addAudio(
              uuid: '1',
              name: 'AIR-DISKNAME-01.flac',
              title: 'Airbag',
              artist: 'Radiohead',
            ),
        );

        expect(find.textContaining('Radiohead'), findsOneWidget);
        // Neither the file name nor the path it lives at is shown alongside
        // the artist — FR-CT-13 is not satisfied by moving the leak from the
        // title to the subtitle.
        expect(find.textContaining('DISKNAME'), findsNothing);
        expect(find.textContaining('/home/owner'), findsNothing);
      },
    );

    testWidgets(
      'GivenAnUntaggedAudioMatch_WhenTheResultsAreShown_ThenItReadsUnknownTitle',
      (tester) async {
        await searchFor(
          tester,
          term: 'disk',
          gateway: FakeCatalogGateway()
            ..addAudio(uuid: '1', name: 'DISKNAME-01.flac'),
        );
        final l10n = localizations(tester);

        expect(find.textContaining(l10n.musicUnknownTitle), findsOneWidget);
        expect(find.textContaining('DISKNAME'), findsNothing);
      },
    );

    testWidgets(
      'GivenAnUntaggedAudioMatch_WhenTheResultsAreShown_ThenItReadsUnknownArtist',
      (tester) async {
        await searchFor(
          tester,
          term: 'disk',
          gateway: FakeCatalogGateway()
            ..addAudio(uuid: '1', name: 'DISKNAME-01.flac'),
        );
        final l10n = localizations(tester);

        expect(find.textContaining(l10n.musicUnknownArtist), findsOneWidget);
        expect(find.textContaining('DISKNAME'), findsNothing);
        expect(find.textContaining('/home/owner'), findsNothing);
      },
    );

    testWidgets(
      'GivenANonAudioMatch_WhenTheResultsAreShown_ThenItStillReadsItsFileName',
      (tester) async {
        // Only audio has a metadata name to show instead. A document's name
        // on disk is what it is called.
        await searchFor(
          tester,
          term: 'notes',
          gateway: FakeCatalogGateway()
            ..addDocument(uuid: '2', name: 'notes.pdf'),
        );

        // Exact rather than containing: the subtitle shows the file's path,
        // which also contains "notes.pdf" as its tail, and a containing match
        // would pass even if the title itself were never checked.
        expect(find.text('notes.pdf'), findsOneWidget);
      },
    );
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
  group('a hit that lives in a library', () {
    // A library keeps its files out of the type panels, so a result found
    // here and then missing from its panel reads as a bug. The row says why
    // (FR-CT-16).
    Future<void> searchInLibrary(
      WidgetTester tester, {
      String? libraryUuid = 'lib-1',
      List<Library> libraries = const [
        Library(uuid: 'lib-1', name: 'Rust course', rootPath: '/courses/rust'),
      ],
    }) async {
      // Named `catalog` rather than `gateway`: this file imports the domain
      // listing under that prefix, and a local of the same name hides it.
      final catalog = FakeCatalogGateway(
        listings: {
          FileType.document: gateway.CatalogListing.loaded(
            files: [
              FileDetails(
                file: aFile(name: 'lecture-01.pdf'),
                libraryUuid: libraryUuid,
              ),
            ],
          ),
        },
      );

      await tester.pumpShell(
        extraOverrides: [
          catalogGatewayProvider.overrideWithValue(catalog),
          libraryGatewayProvider.overrideWithValue(
            FakeLibraryGateway(libraries: libraries),
          ),
        ],
      );
      await search(tester, 'lecture');
    }

    testWidgets('GivenAHitInALibrary_WhenItIsListed_ThenItNamesTheLibrary', (
      tester,
    ) async {
      await searchInLibrary(tester);

      expect(
        find.text(localizations(tester).searchInLibrary('Rust course')),
        findsOneWidget,
      );
    });

    testWidgets('GivenAHitOutsideEveryLibrary_WhenItIsListed_ThenItIsNotTagged', (
      tester,
    ) async {
      // The half that makes the test above mean something: a row that tagged
      // everything would pass it.
      await searchInLibrary(tester, libraryUuid: null);

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets(
      'GivenTheLibrariesAreNotReadYet_WhenAHitIsListed_ThenItStillSaysItIsInOne',
      (tester) async {
        // The name is looked up, not carried on the row — so the tag has to
        // work before the lookup answers. Saying "in a library" is the part
        // that explains the panel the file is missing from.
        await searchInLibrary(tester, libraries: const []);

        expect(
          find.text(localizations(tester).searchInALibrary),
          findsOneWidget,
        );
      },
    );
  });

}
