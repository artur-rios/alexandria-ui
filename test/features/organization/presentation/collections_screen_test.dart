import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/organization/domain/collection.dart';
import 'package:alexandria_ui/features/organization/domain/collection_gateway.dart';
import 'package:alexandria_ui/features/organization/presentation/collections_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/confirmation_dialog.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/library_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_collection_gateway.dart';
import '../../../support/shell_harness.dart';

/// Managing collections (UC-26, FR-OG-01 … FR-OG-03, FR-OG-06).
void main() {
  const films = Collection(
    uuid: 'c-1',
    name: 'Films',
    kind: CollectionKind.file,
    itemCount: 3,
  );

  const reading = Collection(
    uuid: 'c-2',
    name: 'Reading',
    kind: CollectionKind.bookmark,
  );

  /// Signs in and opens the collections screen (main flow step 1).
  Future<({ProviderContainer container, FakeCollectionGateway gateway})>
  openCollections(
    WidgetTester tester, {
    List<Collection> collections = const [films],
    CollectionBrowse? browse,
    List<CollectionWrite> writeOutcomes = const [],
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    bool openScreen = true,
  }) async {
    final gateway = FakeCollectionGateway(collections: collections)
      ..browseOutcome = browse
      ..writeOutcomes.addAll(writeOutcomes);

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        collectionGatewayProvider.overrideWithValue(gateway),
        // A file in the catalog, so the dashboard is not the first-run block
        // — which is where the screen is reached from.
        catalogGatewayProvider.overrideWithValue(
          FakeCatalogGateway(
            listings: {
              LibraryType.document: loadedDetails([aFile()]),
            },
          ),
        ),
      ],
    );

    if (openScreen) {
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      await tester.openLibraryTool(l10n.collectionsOpen);
      await tester.pumpAndSettle();
    }

    return (container: container, gateway: gateway);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// The screen's own name field.
  ///
  /// Scoped: the shell behind the dialog has a search field of its own, and it
  /// comes first in the tree.
  Finder nameField() => find.descendant(
    of: find.byType(CollectionsScreen),
    matching: find.byType(TextField),
  );

  /// [finder], but only inside the screen.
  ///
  /// The dashboard behind the dialog carries a delete icon of its own — the
  /// deleted-items entry — so an unscoped icon finder matches twice.
  Finder inScreen(Finder finder) =>
      find.descendant(of: find.byType(CollectionsScreen), matching: finder);

  Future<void> typeName(WidgetTester tester, String name) async {
    await tester.enterText(nameField(), name);
    await tester.pump();
  }

  group('the main flow', () {
    // Step 1. Reached from the menu bar's Library menu, so it is available
    // from every area rather than from the dashboard alone.
    testWidgets(
      'GivenTheShell_WhenTheToolsAreOpened_ThenCollectionsAreReachable',
      (tester) async {
        await openCollections(tester, openScreen: false);

        await tester.tap(find.byType(LibraryMenu));
        await tester.pumpAndSettle();

        expect(find.text(messages(tester).collectionsOpen), findsOneWidget);
      },
    );

    testWidgets('GivenCollections_WhenTheScreenOpens_ThenTheyAreListed', (
      tester,
    ) async {
      await openCollections(tester, collections: const [films, reading]);

      expect(find.text('Films'), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
    });

    // FR-OG-06: the count is the core's, shown beside each collection.
    testWidgets('GivenACollectionWithItems_WhenListed_ThenTheCountIsShown', (
      tester,
    ) async {
      await openCollections(tester);

      expect(
        find.text(messages(tester).collectionItemCount(3)),
        findsOneWidget,
      );
    });

    testWidgets('GivenNoCollections_WhenTheScreenOpens_ThenItSaysSo', (
      tester,
    ) async {
      await openCollections(tester, collections: const []);

      expect(find.text(messages(tester).collectionsNone), findsOneWidget);
    });

    // Steps 2 to 4: a name and a kind.
    testWidgets('GivenANameAndAKind_WhenCreateIsAsked_ThenTheCoreIsCalled', (
      tester,
    ) async {
      final opened = await openCollections(tester, collections: const []);

      await typeName(tester, 'Sci-fi');
      // Scoped: the navigation panel behind the dialog has a Bookmarks
      // destination with the same label.
      await tester.tap(
        inScreen(find.text(messages(tester).collectionKindBookmark)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(messages(tester).collectionCreate));
      await tester.pumpAndSettle();

      expect(opened.gateway.created, [
        (name: 'Sci-fi', kind: CollectionKind.bookmark),
      ]);
    });

    testWidgets('GivenNoKindChosen_WhenCreateIsAsked_ThenItIsAFileCollection', (
      tester,
    ) async {
      final opened = await openCollections(tester, collections: const []);

      await typeName(tester, 'Sci-fi');
      await tester.tap(find.text(messages(tester).collectionCreate));
      await tester.pumpAndSettle();

      expect(opened.gateway.created.single.kind, CollectionKind.file);
    });

    // Step 5.
    testWidgets('GivenACollection_WhenItIsRenamed_ThenTheCoreIsCalled', (
      tester,
    ) async {
      final opened = await openCollections(tester);

      await tester.tap(inScreen(find.byIcon(Icons.edit_outlined)));
      await tester.pumpAndSettle();
      await typeName(tester, 'Cinema');
      await tester.tap(find.text(messages(tester).collectionRenameSave));
      await tester.pumpAndSettle();

      expect(opened.gateway.renamed, [(uuid: 'c-1', name: 'Cinema')]);
    });

    testWidgets('GivenARenameIsOpen_WhenTheFieldIsSeeded_ThenItHoldsTheName', (
      tester,
    ) async {
      await openCollections(tester);

      await tester.tap(inScreen(find.byIcon(Icons.edit_outlined)));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(nameField()).controller?.text, 'Films');
    });

    // Step 6: the confirmation says the items are kept.
    testWidgets('GivenACollection_WhenItIsDeleted_ThenTheOwnerIsAskedFirst', (
      tester,
    ) async {
      final opened = await openCollections(tester);

      await tester.tap(inScreen(find.byIcon(Icons.delete_outline)));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmationDialog), findsOneWidget);
      expect(
        find.text(messages(tester).collectionDeleteMessage('Films')),
        findsOneWidget,
      );
      expect(opened.gateway.deleted, isEmpty);
    });

    testWidgets('GivenTheConfirmation_WhenItIsAccepted_ThenItIsDeleted', (
      tester,
    ) async {
      final opened = await openCollections(tester);

      await tester.tap(inScreen(find.byIcon(Icons.delete_outline)));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmationDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(opened.gateway.deleted, ['c-1']);
      expect(find.text('Films'), findsNothing);
    });
  });

  // AF-01: the name is blank after trimming.
  group('a name the screen refuses', () {
    testWidgets('GivenABlankName_WhenCreateIsAsked_ThenTheCoreIsNotCalled', (
      tester,
    ) async {
      final opened = await openCollections(tester, collections: const []);

      await typeName(tester, '   ');
      await tester.tap(find.text(messages(tester).collectionCreate));
      await tester.pumpAndSettle();

      expect(opened.gateway.created, isEmpty);
      expect(find.text(messages(tester).collectionNameEmpty), findsOneWidget);
    });

    testWidgets('GivenABlankRename_WhenSaveIsAsked_ThenTheCoreIsNotCalled', (
      tester,
    ) async {
      final opened = await openCollections(tester);

      await tester.tap(inScreen(find.byIcon(Icons.edit_outlined)));
      await tester.pumpAndSettle();
      await typeName(tester, '  ');
      await tester.tap(find.text(messages(tester).collectionRenameSave));
      await tester.pumpAndSettle();

      expect(opened.gateway.renamed, isEmpty);
      expect(find.text(messages(tester).collectionNameEmpty), findsOneWidget);
    });
  });

  // AF-02: the core rejects the name, and the form stays open.
  group('a name the core refuses', () {
    testWidgets('GivenTheCoreRefuses_WhenItAnswers_ThenTheFormStaysOpen', (
      tester,
    ) async {
      await openCollections(
        tester,
        collections: const [],
        writeOutcomes: const [
          CollectionWrite.failed(
            failure: Failure.invalidInput(
              family: CoreStatusFamily.collection,
              code: COLLECTION_ERR_INVALID_INPUT,
            ),
          ),
        ],
      );

      await typeName(tester, 'Sci-fi');
      await tester.tap(find.text(messages(tester).collectionCreate));
      await tester.pumpAndSettle();

      expect(find.text(messages(tester).failureInvalidInput), findsOneWidget);
      expect(find.text(messages(tester).collectionCreate), findsOneWidget);
    });
  });

  // AF-03: the owner cancels a deletion.
  group('a deletion the owner changes their mind about', () {
    testWidgets('GivenTheConfirmation_WhenItIsCancelled_ThenNothingChanges', (
      tester,
    ) async {
      final opened = await openCollections(tester);

      await tester.tap(inScreen(find.byIcon(Icons.delete_outline)));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmationDialog),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(opened.gateway.deleted, isEmpty);
      expect(find.text('Films'), findsOneWidget);
    });
  });

  // AF-04: the core reports the collection as not found.
  group('a collection the core no longer has', () {
    testWidgets('GivenItIsGone_WhenItIsDeleted_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await openCollections(
        tester,
        writeOutcomes: const [
          CollectionWrite.failed(
            failure: Failure.notFound(
              family: CoreStatusFamily.collection,
              code: COLLECTION_ERR_NOT_FOUND,
            ),
          ),
        ],
      );

      await tester.tap(inScreen(find.byIcon(Icons.delete_outline)));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmationDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(messages(tester).collectionNotFound), findsOneWidget);
    });
  });

  // AF-05: the core rejects the call as unauthorized.
  group('a session the core rejects', () {
    testWidgets(
      'GivenTheCoreRejectsTheSession_WhenBrowsing_ThenTheOwnerSignsOut',
      (tester) async {
        final opened = await openCollections(
          tester,
          browse: const CollectionBrowse.failed(
            failure: Failure.unauthorized(
              family: CoreStatusFamily.collection,
              code: COLLECTION_ERR_UNAUTHORIZED,
            ),
          ),
          openScreen: false,
        );

        // Read rather than opened: the collections load lazily, so this is the
        // browse the screen would have triggered.
        await opened.container.read(collectionsControllerProvider.future);

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
          await openCollections(tester, themeMode: themeMode);

          expect(
            Theme.of(tester.element(find.byType(CollectionsScreen))).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheScreenOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openCollections(
            tester,
            locale: locale,
            collections: const [films, reading],
          );

          await typeName(tester, '  ');
          await tester.tap(find.text(messages(tester).collectionCreate));
          await tester.pumpAndSettle();

          expect(
            find.textContaining(
              RegExp('collections?[A-Z]'),
              findRichText: true,
            ),
            findsNothing,
          );
        },
      );
    }
  });
}
