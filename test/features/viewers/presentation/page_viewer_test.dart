import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/editing/presentation/text_editor_screen.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:alexandria_ui/features/viewers/domain/page_content.dart';
import 'package:alexandria_ui/features/viewers/presentation/page_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_page_gateway.dart';
import '../../../support/fake_text_content_gateway.dart';
import '../../../support/shell_harness.dart';
import '../../../support/file_row.dart';

/// Reading a saved page, or a Markdown file rendered (UC-25, FR-VW-05,
/// FR-VW-06, FR-VW-07).
void main() {
  const uuid = 'p1a2b3c4-5d6e-4f70-8912-a3b4c5d6e7f8';

  /// Signs in, opens the listing for [type], and opens the one file in it.
  Future<({ProviderContainer container, FakePageGateway pages})> open(
    WidgetTester tester, {
    PageOutcome? outcome,
    FileType type = FileType.html,
    ShellDestination destination = ShellDestination.pages,
    String name = 'Article.html',
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    bool openIt = true,
  }) async {
    final file = aFile(
      uuid: uuid,
      name: name,
      path: '/home/owner/pages/$name',
      type: type,
    );
    final catalog = FakeCatalogGateway(
      listings: {
        type: loadedDetails([file]),
      },
    );
    catalog.details[uuid] = FileDetailsOutcome.read(
      details: FileDetails(file: file, metadata: const {}),
    );

    final pages = FakePageGateway(outcome: outcome);

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(catalog),
        pageGatewayProvider.overrideWithValue(pages),
        textContentGatewayProvider.overrideWithValue(FakeTextContentGateway()),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(destination.icon),
      ),
    );
    await tester.pumpAndSettle();
    // The row opens the file itself now, so a test that wants it open taps
    // the row, and one that wants the details taps the button beside it —
    // where the Open action still is, for a file that cannot just be opened.
    if (openIt) {
      await tester.tap(find.text(name).first);
      await tester.pumpAndSettle();
    } else {
      await openDetailsOf(tester, name);
    }

    return (container: container, pages: pages);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  group('the main flow', () {
    testWidgets('GivenASavedPage_WhenItsDetailsOpen_ThenReadingIsOffered', (
      tester,
    ) async {
      await open(tester, openIt: false);

      expect(find.text(messages(tester).viewerOpen), findsOneWidget);
    });

    // Step 2: the bytes are read when the page is opened.
    testWidgets('GivenASavedPage_WhenItIsOpened_ThenItsPathIsRead', (
      tester,
    ) async {
      final opened = await open(tester);

      expect(opened.pages.paths, ['/home/owner/pages/Article.html']);
    });

    // Step 3: rendered as widgets.
    testWidgets('GivenASavedPage_WhenItIsOpened_ThenItsContentIsRendered', (
      tester,
    ) async {
      await open(tester);

      expect(
        find.textContaining('A saved article.', findRichText: true),
        findsOneWidget,
      );
    });

    // FR-VW-06: a Markdown file is rendered rather than edited.
    testWidgets('GivenAMarkdownFile_WhenItIsOpened_ThenItIsRendered', (
      tester,
    ) async {
      await open(
        tester,
        type: FileType.text,
        destination: ShellDestination.notes,
        name: 'Notes.md',
        outcome: FakePageGateway.markdown,
      );

      expect(
        find.textContaining('Rendered heading', findRichText: true),
        findsOneWidget,
      );
    });

    // Step 4: a Markdown file may be switched into the editor.
    testWidgets('GivenAMarkdownFile_WhenItIsRead_ThenTheEditorIsOffered', (
      tester,
    ) async {
      await open(
        tester,
        type: FileType.text,
        destination: ShellDestination.notes,
        name: 'Notes.md',
        outcome: FakePageGateway.markdown,
      );

      expect(find.text(messages(tester).editorOpen), findsWidgets);
    });

    testWidgets('GivenTheOffer_WhenItIsTaken_ThenTheEditorOpens', (
      tester,
    ) async {
      await open(
        tester,
        type: FileType.text,
        destination: ShellDestination.notes,
        name: 'Notes.md',
        outcome: FakePageGateway.markdown,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(PageViewerScreen),
          matching: find.text(messages(tester).editorOpen),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextEditorScreen), findsOneWidget);
      expect(find.byType(PageViewerScreen), findsNothing);
    });

    // An HTML page is not something this application edits (BR-06).
    testWidgets('GivenAnHtmlPage_WhenItIsRead_ThenTheEditorIsNotOffered', (
      tester,
    ) async {
      await open(tester);

      expect(
        find.descendant(
          of: find.byType(PageViewerScreen),
          matching: find.text(messages(tester).editorOpen),
        ),
        findsNothing,
      );
    });

    testWidgets('GivenAnOpenPage_WhenItIsClosed_ThenNothingIsRetained', (
      tester,
    ) async {
      final opened = await open(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(PageViewerScreen), findsNothing);
      expect(
        opened.container.read(pageViewerControllerProvider).content,
        isNull,
      );
    });
  });

  // AF-01: the file is absent from disk.
  group('a page that is not there', () {
    testWidgets('GivenTheFileIsGone_WhenItIsOpened_ThenItIsReportedAsMissing', (
      tester,
    ) async {
      await open(tester, outcome: FakePageGateway.missing);

      expect(find.text(messages(tester).viewerFileMissing), findsOneWidget);
      expect(find.text(messages(tester).detailsRescan), findsOneWidget);
    });
  });

  // AF-02: the page references assets that are absent.
  group('assets the page could not load', () {
    testWidgets('GivenMissingAssets_WhenThePageIsRead_ThenTheyAreNamed', (
      tester,
    ) async {
      await open(
        tester,
        outcome: const PageRead(
          content: PageContent(
            html: '<p>A saved article.</p>',
            missingAssets: ['photo.png', 'site.css'],
          ),
        ),
      );

      expect(
        find.text(messages(tester).pageMissingAssets('photo.png, site.css')),
        findsOneWidget,
      );
    });

    // The page renders without them.
    testWidgets('GivenMissingAssets_WhenThePageIsRead_ThenItStillRenders', (
      tester,
    ) async {
      await open(
        tester,
        outcome: const PageRead(
          content: PageContent(
            html: '<p>A saved article.</p>',
            missingAssets: ['photo.png'],
          ),
        ),
      );

      expect(
        find.textContaining('A saved article.', findRichText: true),
        findsOneWidget,
      );
    });
  });

  // AF-03: the page contains script.
  group('script in the page', () {
    testWidgets('GivenAPageWithScript_WhenItIsRead_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await open(
        tester,
        outcome: const PageRead(
          content: PageContent(
            html: '<p>A saved article.</p>',
            hasScript: true,
          ),
        ),
      );

      expect(find.text(messages(tester).pageScriptsNotRun), findsOneWidget);
    });

    testWidgets('GivenAPageWithoutScript_WhenItIsRead_ThenNothingIsSaid', (
      tester,
    ) async {
      await open(tester);

      expect(find.text(messages(tester).pageScriptsNotRun), findsNothing);
    });
  });

  // AF-04: the markup is malformed.
  group('markup that does not parse', () {
    testWidgets('GivenMalformedMarkup_WhenItIsRead_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await open(
        tester,
        outcome: const PageRead(
          content: PageContent(
            html: '<p>A saved article.</p>',
            isMalformed: true,
          ),
        ),
      );

      expect(find.text(messages(tester).pageMalformed), findsOneWidget);
    });

    // What could be parsed is still drawn.
    testWidgets('GivenMalformedMarkup_WhenItIsRead_ThenWhatItCanIsRendered', (
      tester,
    ) async {
      await open(
        tester,
        outcome: const PageRead(
          content: PageContent(
            html: '<p>A saved article.</p>',
            isMalformed: true,
          ),
        ),
      );

      expect(
        find.textContaining('A saved article.', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group("the page's own look (main flow step 3)", () {
    testWidgets('GivenStyledMarkup_WhenItIsShown_ThenTheStylingIsDrawn', (
      tester,
    ) async {
      // The gateway folds a page's stylesheets onto its elements
      // (`page_styles.dart`); this is the other half of that — the renderer
      // reading them. Asserted on the painted text rather than on the markup,
      // because an attribute nobody draws is not styling.
      await open(
        tester,
        outcome: const PageRead(
          content: PageContent(
            html: '<p style="color: #ff0000; font-style: italic">Words</p>',
          ),
        ),
      );

      final text = tester.widget<RichText>(
        find
            .descendant(
              of: find.byType(PageViewerScreen),
              matching: find.byType(RichText),
            )
            .first,
      );
      expect(text.text.style?.color, const Color(0xFFFF0000));
      expect(text.text.style?.fontStyle, FontStyle.italic);
    });

    testWidgets('GivenAnEmbeddedFrame_WhenThePageIsShown_ThenItDoesNotFail', (
      tester,
    ) async {
      // An `<iframe>` used to be given a web view, and `webview_flutter` has
      // no Linux or Windows implementation: building one raised
      // `LateInitializationError` and left an error box in the middle of the
      // article. A saved page with an embedded video or map is ordinary, so
      // this is ordinary too — the frame becomes a link to where it pointed.
      await open(
        tester,
        outcome: const PageRead(
          content: PageContent(
            html:
                '<p>Before</p>'
                '<iframe src="https://example.com/embed" width="560" '
                'height="315"></iframe>'
                '<p>After</p>',
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
      expect(
        find.textContaining('After', findRichText: true),
        findsOneWidget,
        reason: 'the rest of the page draws around the embed',
      );
      expect(
        find.textContaining('example.com/embed', findRichText: true),
        findsOneWidget,
        reason: 'the frame is shown as where it pointed',
      );
    });
  });

  group('themes and languages', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheViewerOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await open(tester, themeMode: themeMode);

          expect(
            Theme.of(tester.element(find.byType(PageViewerScreen))).brightness,
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
            outcome: const PageRead(
              content: PageContent(
                html: '<p>A saved article.</p>',
                hasScript: true,
                isMalformed: true,
                missingAssets: ['photo.png'],
              ),
            ),
          );

          expect(
            find.textContaining(RegExp('page[A-Z]'), findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });
}
