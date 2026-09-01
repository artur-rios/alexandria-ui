import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
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
import '../../../support/keyboard.dart';
import '../../../support/shell_harness.dart';

/// Tracking reading progress (UC-32, FR-TR-12 … FR-TR-14).
void main() {
  const bookUuid = 'b1a2b3c4-5d6e-4f70-8912-a3b4c5d6e7f8';
  const comicUuid = 'c1a2b3c4-5d6e-4f70-8912-a3b4c5d6e7f8';

  const bookProgress = ReadingProgress(
    readingListUuid: 'rl-1',
    itemUuid: bookUuid,
    targetKind: ReadingTargetKind.document,
    state: ReadingState.pending,
  );

  const comicProgress = ReadingProgress(
    readingListUuid: 'rl-1',
    itemUuid: comicUuid,
    targetKind: ReadingTargetKind.comic,
    state: ReadingState.reading,
    currentIssue: 3,
    totalIssues: 12,
  );

  final book = aFile(
    uuid: bookUuid,
    name: 'Solaris.epub',
    type: FileType.document,
  );
  final comic = aFile(
    uuid: comicUuid,
    name: 'Sandman.cbz',
    type: FileType.comic,
  );

  /// Signs in and opens the reading-lists screen with [items] in one list.
  Future<({ProviderContainer container, FakeReadingListGateway gateway})>
  openLists(
    WidgetTester tester, {
    List<ReadingProgress> items = const [bookProgress],
    List<ReadingList>? readingLists,
    List<ReadingListWrite> writeOutcomes = const [],
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    bool openScreen = true,
  }) async {
    final catalog = FakeCatalogGateway(
      listings: {
        FileType.document: loadedDetails([book]),
        FileType.comic: loadedDetails([comic]),
      },
    );
    for (final file in [book, comic]) {
      catalog.details[file.uuid] = FileDetailsOutcome.read(
        details: FileDetails(file: file, metadata: const {}),
      );
    }

    final gateway = FakeReadingListGateway(
      readingLists:
          readingLists ??
          [ReadingList(uuid: 'rl-1', name: 'Shelf', items: items)],
    )..writeOutcomes.addAll(writeOutcomes);

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(catalog),
        readingListGatewayProvider.overrideWithValue(gateway),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(ShellDestination.books.icon),
      ),
    );
    await tester.pumpAndSettle();

    if (openScreen) {
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      await tester.tap(find.text(l10n.readingListsOpen));
      await tester.pumpAndSettle();

      // Main flow step 1: the list is opened, which is what shows its items.
      await tester.tap(find.text('Shelf'));
      await tester.pumpAndSettle();
    }

    return (container: container, gateway: gateway);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// [finder], but only inside the reading-lists screen.
  ///
  /// The catalog listing it opens over carries the same file names, so an
  /// unscoped finder matches twice.
  Finder inScreen(Finder finder) =>
      find.descendant(of: find.byType(ReadingListsScreen), matching: finder);

  /// Opens the editor on the item named [name] (main flow step 3).
  Future<void> openEditor(WidgetTester tester, String name) async {
    await tester.tap(inScreen(find.text(name)));
    await tester.pumpAndSettle();
  }

  Future<void> typeIssue(
    WidgetTester tester,
    String label,
    String value,
  ) async {
    await tester.enterText(
      find.ancestor(of: find.text(label), matching: find.byType(TextField)),
      value,
    );
    await tester.pump();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text(messages(tester).readProgressSave));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'GivenAnIssueField_WhenReturnIsPressed_ThenTheProgressIsSaved',
    (tester) async {
      // FR-UX-11: Return saves, from either of the two counters.
      final opened = await openLists(tester, items: const [comicProgress]);
      await openEditor(tester, 'Sandman.cbz');
      await typeIssue(tester, messages(tester).readCurrentIssueLabel, '7');

      await tester.pressReturnIn(
        find.ancestor(
          of: find.text(messages(tester).readCurrentIssueLabel),
          matching: find.byType(TextField),
        ),
      );

      expect(opened.gateway.progressUpdates, hasLength(1));
      expect(opened.gateway.progressUpdates.single.currentIssue, 7);
    },
  );

  group('the main flow', () {
    // Step 2: the core's progress is what the screen presents.
    testWidgets('GivenTrackedItems_WhenTheListOpens_ThenTheirStateIsShown', (
      tester,
    ) async {
      await openLists(tester, items: const [bookProgress, comicProgress]);

      expect(inScreen(find.text('Solaris.epub')), findsOneWidget);
      expect(find.text(messages(tester).readStatePending), findsWidgets);
      expect(
        find.text(
          '${messages(tester).readStateReading} · '
          '${messages(tester).readIssueOf(3, 12)}',
        ),
        findsOneWidget,
      );
    });

    // Steps 3, 5 and 6.
    testWidgets('GivenABook_WhenAStateIsChosen_ThenItGoesToTheCore', (
      tester,
    ) async {
      final opened = await openLists(tester);

      await openEditor(tester, 'Solaris.epub');
      await tester.tap(find.text(messages(tester).readStateRead));
      await tester.pumpAndSettle();
      await save(tester);

      expect(opened.gateway.progressUpdates, [
        (
          list: 'rl-1',
          item: bookUuid,
          state: ReadingState.read,
          currentIssue: null,
          totalIssues: null,
        ),
      ]);
    });

    // Step 4: a comic in a series carries its issue and its total.
    testWidgets('GivenAComic_WhenAnIssueIsSet_ThenItGoesToTheCore', (
      tester,
    ) async {
      final opened = await openLists(tester, items: const [comicProgress]);

      await openEditor(tester, 'Sandman.cbz');
      await typeIssue(tester, messages(tester).readCurrentIssueLabel, '7');
      await typeIssue(tester, messages(tester).readTotalIssuesLabel, '12');
      await save(tester);

      expect(opened.gateway.progressUpdates, [
        (
          list: 'rl-1',
          item: comicUuid,
          state: ReadingState.reading,
          currentIssue: 7,
          totalIssues: 12,
        ),
      ]);
    });

    // Step 6: the editor closes over what the core answered.
    testWidgets('GivenTheCoreAccepts_WhenItAnswers_ThenTheEditorCloses', (
      tester,
    ) async {
      await openLists(tester);

      await openEditor(tester, 'Solaris.epub');
      await save(tester);

      expect(find.text(messages(tester).readProgressSave), findsNothing);
    });
  });

  // AF-01: a standalone book has no issue fields.
  group('an item that is not a series', () {
    testWidgets('GivenABook_WhenItsEditorOpens_ThenNoIssueFieldIsShown', (
      tester,
    ) async {
      await openLists(tester);

      await openEditor(tester, 'Solaris.epub');

      expect(find.text(messages(tester).readCurrentIssueLabel), findsNothing);
      expect(find.text(messages(tester).readTotalIssuesLabel), findsNothing);
    });

    testWidgets('GivenAComic_WhenItsEditorOpens_ThenIssueFieldsAreShown', (
      tester,
    ) async {
      await openLists(tester, items: const [comicProgress]);

      await openEditor(tester, 'Sandman.cbz');

      expect(find.text(messages(tester).readCurrentIssueLabel), findsOneWidget);
    });
  });

  // AF-02: the issue is not a positive whole number, or is past the total.
  group('an issue the screen refuses', () {
    for (final (value, message) in [
      ('seven', 'readIssueNotANumber'),
      ('0', 'readIssueNotPositive'),
    ]) {
      testWidgets(
        'Given${value == '0' ? 'Zero' : 'Words'}_WhenSaveIsAsked_ThenTheCoreIsNotCalled',
        (tester) async {
          final opened = await openLists(tester, items: const [comicProgress]);

          await openEditor(tester, 'Sandman.cbz');
          await typeIssue(
            tester,
            messages(tester).readCurrentIssueLabel,
            value,
          );
          await save(tester);

          expect(opened.gateway.progressUpdates, isEmpty);
          expect(
            find.text(switch (message) {
              'readIssueNotANumber' => messages(tester).readIssueNotANumber,
              _ => messages(tester).readIssueNotPositive,
            }),
            findsOneWidget,
          );
        },
      );
    }

    testWidgets('GivenAnIssuePastTheTotal_WhenSaveIsAsked_ThenItIsMarked', (
      tester,
    ) async {
      final opened = await openLists(tester, items: const [comicProgress]);

      await openEditor(tester, 'Sandman.cbz');
      await typeIssue(tester, messages(tester).readTotalIssuesLabel, '5');
      await typeIssue(tester, messages(tester).readCurrentIssueLabel, '9');
      await save(tester);

      expect(opened.gateway.progressUpdates, isEmpty);
      expect(find.text(messages(tester).readIssueBeyondTotal), findsOneWidget);
    });
  });

  // AF-03: the core rejects the state as invalid.
  group('a state the core rejects', () {
    testWidgets('GivenTheCoreRefuses_WhenItAnswers_ThenTheReasonIsShown', (
      tester,
    ) async {
      await openLists(
        tester,
        writeOutcomes: const [
          ReadingListWrite.failed(
            failure: Failure.invalidState(
              family: CoreStatusFamily.readingList,
              code: READING_LIST_ERR_INVALID_STATE,
            ),
          ),
        ],
      );

      await openEditor(tester, 'Solaris.epub');
      await tester.tap(find.text(messages(tester).readStateRead));
      await tester.pumpAndSettle();
      await save(tester);

      // The stored progress is unchanged, so the editor stays open over it.
      expect(find.text(messages(tester).readProgressSave), findsOneWidget);
      expect(find.text(messages(tester).readStatePending), findsWidgets);
    });
  });

  // AF-04: the core reports the reading list or item as not found.
  group('an item the core no longer has', () {
    testWidgets('GivenItIsGone_WhenProgressIsSaved_ThenTheScreenIsReadAgain', (
      tester,
    ) async {
      final opened = await openLists(
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

      await openEditor(tester, 'Solaris.epub');
      await save(tester);

      expect(opened.gateway.progressUpdates, hasLength(1));
      expect(find.text(messages(tester).readProgressSave), findsOneWidget);
    });
  });

  // AF-05: the same item is in several reading lists.
  group('an item tracked in two lists', () {
    testWidgets('GivenTwoLists_WhenOneIsSet_ThenOnlyThatOneIsSent', (
      tester,
    ) async {
      final opened = await openLists(
        tester,
        readingLists: const [
          ReadingList(uuid: 'rl-1', name: 'Shelf', items: [bookProgress]),
          ReadingList(
            uuid: 'rl-2',
            name: 'Someday',
            items: [
              ReadingProgress(
                readingListUuid: 'rl-2',
                itemUuid: bookUuid,
                targetKind: ReadingTargetKind.document,
                state: ReadingState.pending,
              ),
            ],
          ),
        ],
      );

      await openEditor(tester, 'Solaris.epub');
      await tester.tap(find.text(messages(tester).readStateRead));
      await tester.pumpAndSettle();
      await save(tester);

      expect(opened.gateway.progressUpdates.single.list, 'rl-1');
    });
  });

  // AF-06: the core rejects the call as unauthorized.
  group('a session the core rejects', () {
    testWidgets(
      'GivenTheCoreRejectsTheSession_WhenProgressIsSaved_ThenTheOwnerSignsOut',
      (tester) async {
        final opened = await openLists(
          tester,
          writeOutcomes: const [
            ReadingListWrite.failed(
              failure: Failure.unauthorized(
                family: CoreStatusFamily.readingList,
                code: READING_LIST_ERR_UNAUTHORIZED,
              ),
            ),
          ],
        );

        await openEditor(tester, 'Solaris.epub');
        await save(tester);

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
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheEditorOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openLists(tester, themeMode: themeMode);
          await openEditor(tester, 'Solaris.epub');

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
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheEditorOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openLists(tester, locale: locale, items: const [comicProgress]);
          await openEditor(tester, 'Sandman.cbz');
          await typeIssue(tester, messages(tester).readCurrentIssueLabel, 'x');
          await save(tester);

          expect(
            find.textContaining(
              RegExp('read(ing)?(Issue|State|Progress)[A-Z]'),
              findRichText: true,
            ),
            findsNothing,
          );
        },
      );
    }
  });
}
