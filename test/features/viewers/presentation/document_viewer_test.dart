import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/viewers/domain/document_gateway.dart';
import 'package:alexandria_ui/features/viewers/domain/viewer_registry.dart';
import 'package:alexandria_ui/features/viewers/presentation/document_viewer_screen.dart';
import 'package:alexandria_ui/features/viewers/presentation/viewer_failure_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_document_gateway.dart';
import '../../../support/shell_harness.dart';

/// Reading a PDF or an e-book (UC-22, FR-VW-01, FR-VW-02, FR-VW-07, FR-VW-08).
void main() {
  const uuid = 'd3f1a920-6c48-4b7e-9a25-8f4c1e0b7d63';

  FileDetails aBook({bool isDeleted = false}) => FileDetails(
    file: aFile(
      uuid: uuid,
      name: 'Solaris.epub',
      path: '/home/owner/books/Solaris.epub',
      type: LibraryType.document,
    ),
    metadata: const {},
    isDeleted: isDeleted,
  );

  /// Signs in, opens the books listing, and opens the one file in it.
  Future<({ProviderContainer container, FakeDocumentGateway documents})> open(
    WidgetTester tester, {
    DocumentOutcome? outcome,
    FakeReadingPositionStore? positions,
    ViewerRegistry? registry,
    ShellDestination destination = ShellDestination.books,
    LibraryType type = LibraryType.document,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    bool openIt = true,
  }) async {
    final details = aBook();
    final catalog = FakeCatalogGateway(
      listings: {
        type: CatalogListing.loaded(files: [details.file]),
      },
    );
    catalog.details[uuid] = FileDetailsOutcome.read(details: details);

    final documents = FakeDocumentGateway(outcome: outcome);

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(catalog),
        documentGatewayProvider.overrideWithValue(documents),
        readingPositionsProvider.overrideWithValue(
          positions ?? FakeReadingPositionStore(),
        ),
        if (registry != null)
          viewerRegistryProvider.overrideWithValue(registry),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(destination.icon),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Solaris.epub').first);
    await tester.pumpAndSettle();

    if (openIt) {
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      await tester.tap(find.text(l10n.viewerOpen));
      await tester.pumpAndSettle();
    }

    return (container: container, documents: documents);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  group('the registry', () {
    // FR-VW-01 / main flow step 2.
    testWidgets(
      'GivenARegisteredType_WhenItsDetailsOpen_ThenOpeningIsOffered',
      (tester) async {
        await open(tester, openIt: false);

        expect(find.text(messages(tester).viewerOpen), findsOneWidget);
      },
    );

    // AF-04 / FR-VW-08: the type has no viewer, and every other action stays.
    testWidgets('GivenAnUnregisteredType_WhenItsDetailsOpen_ThenItSaysSo', (
      tester,
    ) async {
      await open(tester, registry: ViewerRegistry.empty, openIt: false);

      expect(find.text(messages(tester).viewerOpen), findsNothing);
      expect(find.text(messages(tester).detailsNoViewer), findsOneWidget);
      // The other actions are still there.
      expect(find.text(messages(tester).renameOpen), findsOneWidget);
    });
  });

  group('the main flow', () {
    // Step 3: the bytes are read when the file is opened, and not before
    // (FR-VW-07).
    testWidgets('GivenADocument_WhenItsDetailsOpen_ThenNothingIsReadYet', (
      tester,
    ) async {
      final opened = await open(tester, openIt: false);

      expect(opened.documents.opened, isEmpty);
    });

    testWidgets('GivenADocument_WhenItIsOpened_ThenItsPathIsRead', (
      tester,
    ) async {
      final opened = await open(tester);

      expect(opened.documents.opened, ['/home/owner/books/Solaris.epub']);
    });

    // Step 4: chapter navigation.
    testWidgets('GivenAnEbook_WhenItIsOpened_ThenItsFirstChapterIsShown', (
      tester,
    ) async {
      await open(tester);

      expect(
        find.textContaining('The first chapter.', findRichText: true),
        findsOneWidget,
      );
      expect(find.text(messages(tester).viewerChapterOf(1, 2)), findsOneWidget);
    });

    testWidgets('GivenAnEbook_WhenTheOwnerMovesOn_ThenTheNextChapterIsShown', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('The second chapter.', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('GivenTheFirstChapter_WhenItIsShown_ThenBackIsNotOffered', (
      tester,
    ) async {
      await open(tester);

      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_left),
            )
            .onPressed,
        isNull,
      );
    });

    // Step 5 / FR-VW-02: the position is remembered.
    testWidgets('GivenTheOwnerMovesOn_WhenTheyDo_ThenThePositionIsRemembered', (
      tester,
    ) async {
      final positions = FakeReadingPositionStore();
      await open(tester, positions: positions);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(positions.recorded, hasLength(1));
      expect(positions.recorded.single.uuid, uuid);
      expect(positions.recorded.single.position, 1);
    });

    testWidgets('GivenARememberedPosition_WhenItIsOpened_ThenItResumesThere', (
      tester,
    ) async {
      await open(tester, positions: FakeReadingPositionStore({uuid: 1}));

      expect(
        find.textContaining('The second chapter.', findRichText: true),
        findsOneWidget,
      );
    });

    // Step 6: nothing is retained (FR-VW-07).
    testWidgets('GivenAnOpenDocument_WhenItIsClosed_ThenNothingIsRetained', (
      tester,
    ) async {
      final opened = await open(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(DocumentViewerScreen), findsNothing);
      expect(
        opened.container.read(documentViewerControllerProvider).document,
        isNull,
      );
    });
  });

  // AF-01, AF-02, AF-03.
  group('a document that cannot be presented', () {
    testWidgets('GivenTheFileIsGone_WhenItIsOpened_ThenItIsReportedAsMissing', (
      tester,
    ) async {
      await open(tester, outcome: FakeDocumentGateway.missing);

      expect(find.text(messages(tester).viewerFileMissing), findsOneWidget);
    });

    testWidgets('GivenTheFileIsGone_WhenItIsReported_ThenARescanIsOffered', (
      tester,
    ) async {
      await open(tester, outcome: FakeDocumentGateway.missing);

      expect(find.text(messages(tester).detailsRescan), findsOneWidget);
    });

    testWidgets('GivenDamagedBytes_WhenOpened_ThenItIsReportedAsUnreadable', (
      tester,
    ) async {
      await open(tester, outcome: FakeDocumentGateway.unreadable);

      expect(find.text(messages(tester).viewerUnreadable), findsOneWidget);
    });

    // Indexing again will not repair a damaged file.
    testWidgets('GivenDamagedBytes_WhenReported_ThenNoRescanIsOffered', (
      tester,
    ) async {
      await open(tester, outcome: FakeDocumentGateway.unreadable);

      expect(find.text(messages(tester).detailsRescan), findsNothing);
    });

    testWidgets('GivenAnEncryptedDocument_WhenOpened_ThenItIsReported', (
      tester,
    ) async {
      await open(tester, outcome: FakeDocumentGateway.encrypted);

      expect(find.text(messages(tester).viewerEncrypted), findsOneWidget);
    });

    // AF-03: no password is prompted for, so there is nowhere to type one.
    testWidgets('GivenAnEncryptedDocument_WhenReported_ThenNoPasswordIsAsked', (
      tester,
    ) async {
      await open(tester, outcome: FakeDocumentGateway.encrypted);

      expect(
        find.descendant(
          of: find.byType(ViewerFailureView),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
    });

    // The viewer is left, and the file's other actions are where they were.
    testWidgets('GivenAFailure_WhenTheViewerIsClosed_ThenTheDetailsAreBack', (
      tester,
    ) async {
      await open(tester, outcome: FakeDocumentGateway.unreadable);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text(messages(tester).renameOpen), findsOneWidget);
    });
  });

  group('themes and languages', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheViewerOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await open(tester, themeMode: themeMode);

          expect(
            Theme.of(
              tester.element(find.byType(DocumentViewerScreen)),
            ).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheViewerOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          await open(
            tester,
            locale: locale,
            outcome: FakeDocumentGateway.encrypted,
          );

          expect(
            find.textContaining(RegExp('viewer[A-Z]'), findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });
}
