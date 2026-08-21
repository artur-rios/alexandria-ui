import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_desktop/features/organization/domain/bookmark.dart';
import 'package:alexandria_desktop/features/organization/domain/collection.dart';
import 'package:alexandria_desktop/features/shell/domain/shell_destination.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_bookmarks.dart';
import '../../../support/fake_collection_gateway.dart';
import '../../../support/shell_harness.dart';

/// Filing a bookmark into a collection, and filtering by one (UC-28 main flow
/// steps 1, 3 and 5, AF-03).
///
/// The half of UC-28 that shipped unimplemented: nothing could enumerate the
/// owner's collections, so the field had nothing to offer. The core's UC-46
/// listing is what made it buildable.
void main() {
  const reading = Collection(
    uuid: 'c-2',
    name: 'Reading',
    kind: CollectionKind.bookmark,
  );

  const films = Collection(
    uuid: 'c-1',
    name: 'Films',
    kind: CollectionKind.file,
  );

  const filed = Bookmark(
    uuid: 'bm-1',
    url: 'https://example.org/a',
    title: 'A saved page',
    collectionUuid: 'c-2',
  );

  /// Signs in and opens the bookmarks area.
  Future<({FakeBookmarkGateway bookmarks, FakeCollectionGateway collections})>
  openBookmarks(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
    List<Bookmark> bookmarks = const [filed],
    List<Collection> collections = const [reading, films],
    Locale? locale,
  }) async {
    final bookmarkGateway = FakeBookmarkGateway(bookmarks: bookmarks);
    final collectionGateway = FakeCollectionGateway(collections: collections);

    await tester.pumpShell(
      themeMode: themeMode,
      locale: locale,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        bookmarkGatewayProvider.overrideWithValue(bookmarkGateway),
        collectionGatewayProvider.overrideWithValue(collectionGateway),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(ShellDestination.bookmarks.icon),
      ),
    );
    await tester.pumpAndSettle();

    return (bookmarks: bookmarkGateway, collections: collectionGateway);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// Chooses [name] in the dropdown [finder] opens.
  Future<void> choose(WidgetTester tester, Finder finder, String name) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  group('filing a bookmark', () {
    // AF-03: only a bookmark collection is offered. A file collection would
    // be refused by the core, and not offering one is what keeps the owner
    // from meeting that refusal.
    testWidgets('GivenBothKinds_WhenTheFormOpens_ThenOnlyBookmarkOnesShow', (
      tester,
    ) async {
      await openBookmarks(tester);

      await tester.tap(find.text(messages(tester).bookmarkAdd));
      await tester.pumpAndSettle();
      await tester.tap(find.text(messages(tester).bookmarkCollectionNone).last);
      await tester.pumpAndSettle();

      expect(find.text('Reading'), findsWidgets);
      expect(find.text('Films'), findsNothing);
    });

    // Step 3.
    testWidgets('GivenACollectionIsChosen_WhenSaved_ThenItReachesTheCore', (
      tester,
    ) async {
      final opened = await openBookmarks(tester, bookmarks: const []);

      await tester.tap(find.text(messages(tester).bookmarkAdd));
      await tester.pumpAndSettle();
      // Scoped to the form: the shell behind it has a search field, and it
      // comes first in the tree.
      final fields = find.descendant(
        of: find.byType(Card),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.first, 'A page');
      await tester.enterText(fields.at(1), 'https://example.org/b');
      await choose(
        tester,
        find.text(messages(tester).bookmarkCollectionNone).last,
        'Reading',
      );
      await tester.tap(find.text(messages(tester).bookmarkCreate).last);
      await tester.pumpAndSettle();

      expect(opened.bookmarks.writes.single.collection, 'c-2');
    });

    // Step 5: an update that does not touch the field leaves the bookmark
    // where it was.
    testWidgets('GivenAFiledBookmark_WhenItIsEdited_ThenItStaysFiled', (
      tester,
    ) async {
      final opened = await openBookmarks(tester);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text(messages(tester).bookmarkSave).last);
      await tester.pumpAndSettle();

      expect(opened.bookmarks.writes.single.collection, 'c-2');
    });

    testWidgets('GivenAFiledBookmark_WhenItIsUnfiled_ThenTheCoreIsToldSo', (
      tester,
    ) async {
      final opened = await openBookmarks(tester);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await choose(
        tester,
        find.text('Reading').last,
        messages(tester).bookmarkCollectionNone,
      );
      await tester.tap(find.text(messages(tester).bookmarkSave).last);
      await tester.pumpAndSettle();

      expect(opened.bookmarks.writes.single.collection, isNull);
    });
  });

  // Main flow step 1: the listing opens on everything and narrows on request.
  group('filtering the listing', () {
    testWidgets('GivenTheArea_WhenItOpens_ThenEveryBookmarkIsListed', (
      tester,
    ) async {
      final opened = await openBookmarks(tester);

      expect(opened.bookmarks.filters, [null]);
      expect(find.text('A saved page'), findsOneWidget);
    });

    testWidgets('GivenACollectionIsChosen_WhenItSettles_ThenTheCoreFilters', (
      tester,
    ) async {
      final opened = await openBookmarks(tester);

      await choose(
        tester,
        find.text(messages(tester).bookmarkFilterAll).last,
        'Reading',
      );

      expect(opened.bookmarks.filters.last, 'c-2');
    });

    testWidgets('GivenAFilter_WhenAllIsChosenAgain_ThenTheFilterIsDropped', (
      tester,
    ) async {
      final opened = await openBookmarks(tester);

      await choose(
        tester,
        find.text(messages(tester).bookmarkFilterAll).last,
        'Reading',
      );
      await choose(
        tester,
        find.text('Reading').last,
        messages(tester).bookmarkFilterAll,
      );

      expect(opened.bookmarks.filters.last, isNull);
    });
  });

  // The collections listing is asked for bookmark collections and nothing
  // else — the filter is the core's, not a client-side sieve.
  group('what the core is asked for', () {
    testWidgets('GivenTheArea_WhenItOpens_ThenOnlyBookmarkKindIsRequested', (
      tester,
    ) async {
      final opened = await openBookmarks(tester);

      expect(opened.collections.filters, contains(CollectionKind.bookmark));
      expect(opened.collections.filters, isNot(contains(null)));
    });
  });

  group('languages', () {
    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheAreaOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openBookmarks(tester, locale: locale);

          expect(
            find.textContaining(
              RegExp('bookmark(Collection|Filter)[A-Z]'),
              findRichText: true,
            ),
            findsNothing,
          );
        },
      );
    }
  });
  // Testing Specification 7.1: both themes are test surface, not review
  // surface. A screen that only reads correctly in one is a failing screen.
  group('both themes', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${mode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheScreenOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openBookmarks(tester, themeMode: mode);

          expect(
            Theme.of(tester.element(find.byType(ShellScreen).first)).brightness,
            mode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }
  });
}
