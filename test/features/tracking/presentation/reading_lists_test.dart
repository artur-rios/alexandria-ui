import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/confirmation_dialog.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:alexandria_ui/features/tracking/domain/reading_list.dart';
import 'package:alexandria_ui/features/tracking/domain/reading_list_gateway.dart';
import 'package:alexandria_ui/features/tracking/presentation/reading_lists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_reading_list_gateway.dart';
import '../../../support/shell_harness.dart';

/// Managing reading lists (UC-31, FR-TR-08 … FR-TR-11).
void main() {
  const bookUuid = 'b1a2b3c4-5d6e-4f70-8912-a3b4c5d6e7f8';

  const shelf = ReadingList(uuid: 'rl-1', name: 'Shelf');

  final book = aFile(
    uuid: bookUuid,
    name: 'Solaris.epub',
    type: LibraryType.document,
  );

  /// Signs in, opens the books area, and opens the reading-lists screen.
  Future<({ProviderContainer container, FakeReadingListGateway gateway})>
  openLists(
    WidgetTester tester, {
    List<ReadingList> readingLists = const [shelf],
    ReadingListBrowse? browse,
    List<ReadingListWrite> writeOutcomes = const [],
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    bool openScreen = true,
    bool reachArea = true,
  }) async {
    final catalog = FakeCatalogGateway(
      listings: {
        LibraryType.document: CatalogListing.loaded(files: [book]),
      },
    );
    catalog.details[bookUuid] = FileDetailsOutcome.read(
      details: FileDetails(file: book, metadata: const {}),
    );

    final gateway = FakeReadingListGateway(readingLists: readingLists)
      ..browseOutcome = browse
      ..writeOutcomes.addAll(writeOutcomes);

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(catalog),
        readingListGatewayProvider.overrideWithValue(gateway),
      ],
    );

    // A rejected session has already returned the owner to login by now, so
    // there is no panel to navigate — the sign-out is the outcome under test.
    if (reachArea) {
      await tester.tap(
        find.descendant(
          of: find.byType(ShellNavigationPanel),
          matching: find.byIcon(ShellDestination.books.icon),
        ),
      );
      await tester.pumpAndSettle();
    }

    if (openScreen) {
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      await tester.tap(find.text(l10n.readingListsOpen));
      await tester.pumpAndSettle();
    }

    return (container: container, gateway: gateway);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  Future<void> typeName(WidgetTester tester, String name) async {
    await tester.enterText(
      find.ancestor(
        of: find.text(messages(tester).readingListNameLabel),
        matching: find.byType(TextField),
      ),
      name,
    );
    await tester.pump();
  }

  group('the main flow', () {
    // Step 1.
    testWidgets(
      'GivenTheBooksArea_WhenItIsShown_ThenReadingListsAreReachable',
      (tester) async {
        await openLists(tester, openScreen: false);

        expect(find.text(messages(tester).readingListsOpen), findsOneWidget);
      },
    );

    testWidgets('GivenReadingLists_WhenTheScreenOpens_ThenTheyAreListed', (
      tester,
    ) async {
      await openLists(tester);

      expect(find.text('Shelf'), findsOneWidget);
    });

    testWidgets('GivenNoReadingLists_WhenTheScreenOpens_ThenItSaysSo', (
      tester,
    ) async {
      await openLists(tester, readingLists: const []);

      expect(find.text(messages(tester).readingListsNone), findsOneWidget);
    });

    // Step 2.
    testWidgets('GivenAName_WhenACreateIsAsked_ThenItGoesToTheCore', (
      tester,
    ) async {
      final opened = await openLists(tester, readingLists: const []);

      await typeName(tester, 'To read');
      await tester.tap(find.text(messages(tester).readingListCreate));
      await tester.pumpAndSettle();

      expect(opened.gateway.created, ['To read']);
      expect(find.text('To read'), findsOneWidget);
    });

    // Steps 3 and 4, from the item's detail view.
    testWidgets('GivenABook_WhenItIsAddedToAList_ThenTheCoreIsCalled', (
      tester,
    ) async {
      final opened = await openLists(tester, openScreen: false);

      await tester.tap(find.text('Solaris.epub').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(messages(tester).readingListAddTo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shelf').last);
      await tester.pumpAndSettle();

      expect(opened.gateway.added, [(list: 'rl-1', item: bookUuid)]);
    });

    // AF-02: neither a book document nor a comic.
    testWidgets(
      'GivenAnAudioFile_WhenItsDetailsOpen_ThenTrackingIsNotOffered',
      (tester) async {
        final catalog = FakeCatalogGateway(
          listings: {
            LibraryType.audio: CatalogListing.loaded(files: [aFile()]),
          },
        );

        await tester.pumpShell(
          surfaceSize: const Size(1440, 1000),
          extraOverrides: <Override>[
            catalogGatewayProvider.overrideWithValue(catalog),
            readingListGatewayProvider.overrideWithValue(
              FakeReadingListGateway(),
            ),
          ],
        );
        await tester.tap(
          find.descendant(
            of: find.byType(ShellNavigationPanel),
            matching: find.byIcon(ShellDestination.music.icon),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kind of Blue.flac').first);
        await tester.pumpAndSettle();

        expect(find.text(messages(tester).readingListAddTo), findsNothing);
      },
    );

    // Step 5.
    testWidgets('GivenATrackedItem_WhenItIsRemoved_ThenTheCoreIsCalled', (
      tester,
    ) async {
      final opened = await openLists(
        tester,
        readingLists: const [
          ReadingList(
            uuid: 'rl-1',
            name: 'Shelf',
            items: [
              ReadingProgress(
                readingListUuid: 'rl-1',
                itemUuid: bookUuid,
                targetKind: ReadingTargetKind.document,
                state: ReadingState.pending,
              ),
            ],
          ),
        ],
      );

      await tester.tap(find.text('Shelf'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();

      expect(opened.gateway.removed, [(list: 'rl-1', item: bookUuid)]);
    });

    // Step 6: the confirmation says the books and comics are kept.
    testWidgets('GivenAList_WhenItIsDeleted_ThenTheOwnerIsAskedFirst', (
      tester,
    ) async {
      final opened = await openLists(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmationDialog), findsOneWidget);
      expect(
        find.text(messages(tester).readingListDeleteMessage('Shelf')),
        findsOneWidget,
      );
      expect(opened.gateway.deleted, isEmpty);
    });

    testWidgets('GivenTheConfirmation_WhenItIsAccepted_ThenItIsDeleted', (
      tester,
    ) async {
      final opened = await openLists(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmationDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(opened.gateway.deleted, ['rl-1']);
      expect(find.text('Shelf'), findsNothing);
    });
  });

  // AF-01: the name is blank after trimming.
  group('a name the screen refuses', () {
    testWidgets('GivenABlankName_WhenCreateIsAsked_ThenTheCoreIsNotCalled', (
      tester,
    ) async {
      final opened = await openLists(tester, readingLists: const []);

      await typeName(tester, '   ');
      await tester.tap(find.text(messages(tester).readingListCreate));
      await tester.pumpAndSettle();

      expect(opened.gateway.created, isEmpty);
      expect(find.text(messages(tester).readingListNameEmpty), findsOneWidget);
    });
  });

  // AF-03: the item is already in that reading list.
  group('an item already tracked', () {
    const alreadyTracking = ReadingList(
      uuid: 'rl-1',
      name: 'Shelf',
      items: [
        ReadingProgress(
          readingListUuid: 'rl-1',
          itemUuid: bookUuid,
          targetKind: ReadingTargetKind.document,
          state: ReadingState.reading,
        ),
      ],
    );

    testWidgets('GivenItIsAlreadyTracked_WhenAddedAgain_ThenNothingIsSent', (
      tester,
    ) async {
      final opened = await openLists(
        tester,
        readingLists: const [alreadyTracking],
        openScreen: false,
      );

      await tester.tap(find.text('Solaris.epub').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(messages(tester).readingListAddTo));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(messages(tester).readingListAlreadyIn('Shelf')),
      );
      await tester.pumpAndSettle();

      expect(opened.gateway.added, isEmpty);
    });
  });

  // AF-04: the core reports the list or item as not found.
  group('a reading list the core no longer has', () {
    testWidgets('GivenTheListIsGone_WhenItIsDeleted_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await openLists(
        tester,
        writeOutcomes: const [
          ReadingListWrite.failed(
            failure: Failure.notFound(
              family: CoreStatusFamily.readingList,
              code: READING_LIST_ERR_NOT_FOUND,
            ),
          ),
        ],
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmationDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(messages(tester).readingListNotFound), findsOneWidget);
    });
  });

  // AF-05: the owner cancels a deletion.
  group('a deletion the owner changes their mind about', () {
    testWidgets('GivenTheConfirmation_WhenItIsCancelled_ThenNothingChanges', (
      tester,
    ) async {
      final opened = await openLists(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmationDialog),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(opened.gateway.deleted, isEmpty);
      expect(find.text('Shelf'), findsOneWidget);
    });
  });

  // AF-06: the core rejects the call as unauthorized.
  group('a session the core rejects', () {
    testWidgets(
      'GivenTheCoreRejectsTheSession_WhenBrowsing_ThenTheOwnerSignsOut',
      (tester) async {
        final opened = await openLists(
          tester,
          browse: const ReadingListBrowse.failed(
            failure: Failure.unauthorized(
              family: CoreStatusFamily.readingList,
              code: READING_LIST_ERR_UNAUTHORIZED,
            ),
          ),
          openScreen: false,
          reachArea: false,
        );

        // Read rather than opened: the lists load lazily, so this is the browse
        // the screen would have triggered.
        await opened.container.read(readingListsControllerProvider.future);

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
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheScreenOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openLists(tester, themeMode: themeMode);

          expect(
            Theme.of(
              tester.element(find.byType(ReadingListsScreen)),
            ).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheScreenOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openLists(tester, locale: locale, readingLists: const []);

          await typeName(tester, '  ');
          await tester.tap(find.text(messages(tester).readingListCreate));
          await tester.pumpAndSettle();

          expect(
            find.textContaining(
              RegExp('read(ing)?(List|State)[A-Z]'),
              findRichText: true,
            ),
            findsNothing,
          );
        },
      );
    }
  });
}
