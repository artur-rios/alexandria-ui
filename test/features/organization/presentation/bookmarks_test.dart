import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/organization/domain/bookmark.dart';
import 'package:alexandria_ui/features/organization/domain/bookmark_gateway.dart';
import 'package:alexandria_ui/features/organization/presentation/bookmarks_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_bookmarks.dart';
import '../../../support/keyboard.dart';
import '../../../support/shell_harness.dart';

/// Managing bookmarks (UC-28, FR-OG-08 … FR-OG-12).
void main() {
  const article = Bookmark(
    uuid: 'bm-1',
    url: 'https://example.com/article',
    title: 'An article',
  );

  /// Signs in and opens the bookmarks area.
  Future<
    ({
      ProviderContainer container,
      FakeBookmarkGateway gateway,
      FakeBrowserLauncher browser,
    })
  >
  openBookmarks(
    WidgetTester tester, {
    List<Bookmark> bookmarks = const [article],
    BookmarkListing? listing,
    List<BookmarkWrite> writeOutcomes = const [],
    bool browserOpens = true,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final gateway = FakeBookmarkGateway(bookmarks: bookmarks)
      ..listing = listing
      ..writeOutcomes.addAll(writeOutcomes);
    final browser = FakeBrowserLauncher(opens: browserOpens);

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        bookmarkGatewayProvider.overrideWithValue(gateway),
        browserLauncherProvider.overrideWithValue(browser),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(ShellDestination.bookmarks.icon),
      ),
    );
    await tester.pumpAndSettle();

    return (container: container, gateway: gateway, browser: browser);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// Fills the open form.
  Future<void> fill(WidgetTester tester, {String? title, String? url}) async {
    if (title != null) {
      await tester.enterText(
        find.ancestor(
          of: find.text(messages(tester).bookmarkTitleLabel),
          matching: find.byType(TextField),
        ),
        title,
      );
    }
    if (url != null) {
      await tester.enterText(
        find.ancestor(
          of: find.text(messages(tester).bookmarkUrlLabel),
          matching: find.byType(TextField),
        ),
        url,
      );
    }
    await tester.pump();
  }

  Future<void> openForm(WidgetTester tester) async {
    await tester.tap(find.text(messages(tester).bookmarkAdd));
    await tester.pumpAndSettle();
  }

  /// The form's own fields. Scoped, because the shell above it carries the
  /// catalog search.
  final formFields = find.descendant(
    of: find.byType(BookmarksView),
    matching: find.byType(TextField),
  );

  Future<void> submit(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(FilledButton, label));
    await tester.pumpAndSettle();
  }

  testWidgets('GivenTheTitleField_WhenReturnIsPressed_ThenTheBookmarkIsSaved', (
    tester,
  ) async {
    // FR-UX-11: Return submits from any field, not only from the last one
    // — the address field always did, and the title beside it did not.
    final opened = await openBookmarks(tester);
    await openForm(tester);
    await fill(tester, title: 'Flutter', url: 'https://flutter.dev');

    await tester.pressReturnIn(formFields.first);

    expect(opened.gateway.writes, hasLength(1));
    expect(opened.gateway.writes.single.title, 'Flutter');
  });

  group('the main flow', () {
    // Steps 1 and 2.
    testWidgets('GivenBookmarks_WhenTheAreaIsOpened_ThenTheyAreListed', (
      tester,
    ) async {
      final opened = await openBookmarks(tester);

      expect(find.text('An article'), findsOneWidget);
      expect(find.text('https://example.com/article'), findsOneWidget);
      // FR-OG-10: unfiltered, which is what the area opens on.
      expect(opened.gateway.filters, [null]);
    });

    testWidgets('GivenNoBookmarks_WhenTheAreaIsOpened_ThenItSaysSo', (
      tester,
    ) async {
      await openBookmarks(tester, bookmarks: const []);

      expect(find.text(messages(tester).bookmarksNone), findsOneWidget);
    });

    // Steps 3 and 4.
    testWidgets('GivenTheForm_WhenABookmarkIsCreated_ThenItGoesToTheCore', (
      tester,
    ) async {
      final opened = await openBookmarks(tester, bookmarks: const []);

      await openForm(tester);
      await fill(tester, title: 'Solaris', url: 'https://example.com/solaris');
      await submit(tester, messages(tester).bookmarkCreate);

      expect(opened.gateway.writes, hasLength(1));
      expect(opened.gateway.writes.single.uuid, isNull);
      expect(opened.gateway.writes.single.title, 'Solaris');
      expect(opened.gateway.writes.single.url, 'https://example.com/solaris');
    });

    testWidgets('GivenACreatedBookmark_WhenItIsStored_ThenTheListingShowsIt', (
      tester,
    ) async {
      await openBookmarks(tester, bookmarks: const []);

      await openForm(tester);
      await fill(tester, title: 'Solaris', url: 'https://example.com/solaris');
      await submit(tester, messages(tester).bookmarkCreate);

      expect(find.text('Solaris'), findsOneWidget);
      expect(formFields, findsNothing);
    });

    // Step 5.
    testWidgets('GivenABookmark_WhenItIsEdited_ThenTheChangeGoesToTheCore', (
      tester,
    ) async {
      final opened = await openBookmarks(tester);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await fill(tester, title: 'A better title');
      await submit(tester, messages(tester).bookmarkSave);

      expect(opened.gateway.writes.single.uuid, 'bm-1');
      expect(opened.gateway.writes.single.title, 'A better title');
    });

    testWidgets('GivenTheEditForm_WhenItOpens_ThenItHoldsTheCurrentValues', (
      tester,
    ) async {
      await openBookmarks(tester);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('An article'), findsWidgets);
      expect(find.text('https://example.com/article'), findsWidgets);
    });

    // A bookmark already filed keeps its collection through an update, since
    // this application cannot offer one to change it to.
    testWidgets('GivenAFiledBookmark_WhenItIsEdited_ThenItStaysFiled', (
      tester,
    ) async {
      final opened = await openBookmarks(
        tester,
        bookmarks: const [
          Bookmark(
            uuid: 'bm-2',
            url: 'https://example.com/filed',
            title: 'Filed',
            collectionUuid: 'collection-1',
          ),
        ],
      );

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await fill(tester, title: 'Still filed');
      await submit(tester, messages(tester).bookmarkSave);

      expect(opened.gateway.writes.single.collection, 'collection-1');
    });

    // Step 6.
    testWidgets('GivenABookmark_WhenItIsOpened_ThenTheBrowserGetsTheUrl', (
      tester,
    ) async {
      final opened = await openBookmarks(tester);

      await tester.tap(find.text('An article'));
      await tester.pumpAndSettle();

      expect(opened.browser.opened, ['https://example.com/article']);
    });
  });

  // AF-01: the URL does not parse, or the title is blank.
  group('a bookmark the form refuses', () {
    testWidgets('GivenABlankTitle_WhenSubmitted_ThenTheCoreIsNotCalled', (
      tester,
    ) async {
      final opened = await openBookmarks(tester, bookmarks: const []);

      await openForm(tester);
      await fill(tester, url: 'https://example.com');
      await submit(tester, messages(tester).bookmarkCreate);

      expect(opened.gateway.writes, isEmpty);
      expect(find.text(messages(tester).bookmarkFieldEmpty), findsOneWidget);
    });

    testWidgets('GivenAnAddressThatIsNotOne_WhenSubmitted_ThenItIsMarked', (
      tester,
    ) async {
      final opened = await openBookmarks(tester, bookmarks: const []);

      await openForm(tester);
      await fill(tester, title: 'Something', url: 'not an address');
      await submit(tester, messages(tester).bookmarkCreate);

      expect(opened.gateway.writes, isEmpty);
      expect(find.text(messages(tester).bookmarkUrlUnopenable), findsOneWidget);
    });

    testWidgets('GivenAMarkedField_WhenItIsEditedAgain_ThenTheMarkIsDropped', (
      tester,
    ) async {
      await openBookmarks(tester, bookmarks: const []);

      await openForm(tester);
      await fill(tester, title: 'Something', url: 'not an address');
      await submit(tester, messages(tester).bookmarkCreate);
      await fill(tester, url: 'https://example.com');

      expect(find.text(messages(tester).bookmarkUrlUnopenable), findsNothing);
    });
  });

  // AF-02: the core rejects the bookmark.
  group('a bookmark the core refuses', () {
    const rejection = BookmarkWrite.failed(
      failure: Failure.invalidInput(
        family: CoreStatusFamily.bookmark,
        code: BOOKMARK_ERR_INVALID_INPUT,
      ),
    );

    testWidgets('GivenTheCoreRefuses_WhenItAnswers_ThenTheFormStaysOpen', (
      tester,
    ) async {
      await openBookmarks(
        tester,
        bookmarks: const [],
        writeOutcomes: const [rejection],
      );

      await openForm(tester);
      await fill(tester, title: 'Solaris', url: 'https://example.com/solaris');
      await submit(tester, messages(tester).bookmarkCreate);

      expect(formFields, findsWidgets);
      expect(find.text('Solaris'), findsWidgets);
    });

    testWidgets('GivenTheCoreRefusesOnce_WhenTheOwnerRetries_ThenItIsSent', (
      tester,
    ) async {
      final opened = await openBookmarks(
        tester,
        bookmarks: const [],
        writeOutcomes: const [rejection],
      );

      await openForm(tester);
      await fill(tester, title: 'Solaris', url: 'https://example.com/solaris');
      await submit(tester, messages(tester).bookmarkCreate);
      await submit(tester, messages(tester).bookmarkCreate);

      expect(opened.gateway.writes, hasLength(2));
      expect(formFields, findsNothing);
    });
  });

  // AF-04: no default browser can be launched.
  group('a browser that will not open', () {
    testWidgets('GivenNoBrowser_WhenABookmarkIsOpened_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await openBookmarks(tester, browserOpens: false);

      await tester.tap(find.text('An article'));
      await tester.pumpAndSettle();

      expect(find.text(messages(tester).bookmarkNoBrowser), findsOneWidget);
    });

    // The only useful thing left: the owner takes the address elsewhere.
    testWidgets(
      'GivenNoBrowser_WhenTheOwnerCopies_ThenTheUrlIsOnTheClipboard',
      (tester) async {
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied =
                  (call.arguments as Map<Object?, Object?>)['text'] as String?;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );

        await openBookmarks(tester, browserOpens: false);

        await tester.tap(find.text('An article'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(messages(tester).bookmarkCopyUrl));
        await tester.pumpAndSettle();

        expect(copied, 'https://example.com/article');
      },
    );
  });

  // AF-06: the core rejects the call as unauthorized.
  group('a session the core rejects', () {
    testWidgets(
      'GivenTheCoreRejectsTheSession_WhenListing_ThenTheOwnerSignsOut',
      (tester) async {
        final opened = await openBookmarks(
          tester,
          listing: const BookmarkListing.failed(
            failure: Failure.unauthorized(
              family: CoreStatusFamily.bookmark,
              code: BOOKMARK_ERR_UNAUTHORIZED,
            ),
          ),
        );

        expect(
          opened.container.read(sessionControllerProvider),
          isA<SessionAbsent>(),
        );
      },
    );
  });

  group('themes and languages', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenBookmarksOpen_ThenTheyRenderInThatBrightness',
        (tester) async {
          await openBookmarks(tester, themeMode: themeMode);

          expect(
            Theme.of(tester.element(find.byType(BookmarksView))).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenBookmarksOpen_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openBookmarks(tester, locale: locale, bookmarks: const []);

          await openForm(tester);
          await submit(tester, messages(tester).bookmarkCreate);

          expect(
            find.textContaining(RegExp('bookmark[A-Z]'), findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });
}
