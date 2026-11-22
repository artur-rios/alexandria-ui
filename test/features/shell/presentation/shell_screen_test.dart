import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/core/startup/core_unavailable_screen.dart';
import 'package:alexandria_ui/core/theme/breakpoints.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/lifecycle/presentation/missing_files_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/library_menu.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_library_gateway.dart';
import '../../../support/shell_harness.dart';

/// The application shell (UC-38, FR-UX-01, FR-UX-02, FR-UX-11).
void main() {
  Finder panel() => find.byType(ShellNavigationPanel);

  /// Pumps the shell at [surfaceSize] over one library, Course.
  Future<ProviderContainer> pumpWithALibrary(
    WidgetTester tester, {
    required Size surfaceSize,
  }) => tester.pumpShell(
    surfaceSize: surfaceSize,
    extraOverrides: [
      libraryGatewayProvider.overrideWithValue(
        FakeLibraryGateway(
          libraries: const [
            Library(uuid: 'lib-1', name: 'Course', rootPath: '/course'),
          ],
        ),
      ),
    ],
  );

  // The three tiers, and the minimum supported window itself.
  const surfaces = <String, Size>{
    'TheMinimumWindow': Size(1024, 640),
    'ACompactWindow': Size(1100, 700),
    'AMediumWindow': Size(1280, 800),
    'AnExpandedWindow': Size(1700, 1000),
    // Wide enough for labels and short: the breakpoints are widths, so this
    // is the shape that catches a panel which clips instead of adapting.
    'AWideButShortWindow': Size(1360, 640),
  };

  group('the library tools the panel reaches (UC-37 main flow step 1)', () {
    /// Opens the bar's Library menu.
    Future<AppLocalizations> openTools(WidgetTester tester) async {
      await tester.tap(find.byType(LibraryMenu));
      await tester.pumpAndSettle();

      return AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    }

    testWidgets(
      'GivenTheShell_WhenTheToolsAreOpened_ThenTheMissingFilesReviewIsOffered',
      (tester) async {
        // UC-37 main flow step 1: "from the Library menu or from an index
        // run's outcome". This is the first of the two.
        await tester.pumpShell();

        final l10n = await openTools(tester);

        expect(find.text(l10n.missingFilesOpen), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheShell_WhenTheToolsAreOpened_ThenEveryLibraryWideAreaIsOffered',
      (tester) async {
        // The areas that belong to no single library, and so have no entry
        // in the left menu (FR-CT-20) — but must still be reachable from
        // anywhere rather than only from home.
        await tester.pumpShell();

        final l10n = await openTools(tester);

        expect(find.text(l10n.libraryMenuAdd), findsOneWidget);
        expect(find.text(l10n.collectionsOpen), findsOneWidget);
        expect(find.text(l10n.watchlistsOpen), findsOneWidget);
        expect(find.text(l10n.readingListsOpen), findsOneWidget);
        expect(find.text(l10n.deletedItemsOpen), findsOneWidget);
      },
    );

    testWidgets('GivenTheToolsAreOpen_WhenTheReviewIsChosen_ThenItOpens', (
      tester,
    ) async {
      await tester.pumpShell();

      final l10n = await openTools(tester);
      await tester.tap(find.text(l10n.missingFilesOpen));
      await tester.pumpAndSettle();

      expect(find.byType(MissingFilesScreen), findsOneWidget);
    });

    testWidgets(
      'GivenTheMinimumWindow_WhenTheBarIsRead_ThenTheToolsAreStillReachable',
      (tester) async {
        // FR-UX-02: the bar collapses rather than dropping an entry.
        await tester.pumpShell(surfaceSize: const Size(1024, 640));

        expect(find.byType(LibraryMenu), findsOneWidget);
      },
    );
  });

  group('the widest tier (FR-UX-02)', () {
    /// Where [label]'s text sits relative to its entry's icon [icon].
    Offset labelFromIcon(WidgetTester tester, String label, IconData icon) =>
        tester.getCenter(
          find.descendant(of: panel(), matching: find.text(label)),
        ) -
        tester.getCenter(
          find.descendant(of: panel(), matching: find.byIcon(icon)),
        );

    testWidgets(
      'GivenAnExpandedWindow_WhenThePanelIsDrawn_ThenLabelsSitBesideTheIcons',
      (tester) async {
        // The third tier had no behaviour of its own: 1600 looked exactly like
        // 1280. At this width the labels sit beside the icons rather than
        // under them, which is what the extra room buys.
        await pumpWithALibrary(tester, surfaceSize: const Size(1700, 1000));

        final offset = labelFromIcon(
          tester,
          'Bookmarks',
          Icons.bookmark_outline,
        );
        expect(offset.dx, greaterThan(0));
        expect(offset.dy.abs(), lessThan(4));
      },
    );

    testWidgets(
      'GivenAMediumWindow_WhenThePanelIsDrawn_ThenLabelsSitBeneathTheIcons',
      (tester) async {
        await pumpWithALibrary(tester, surfaceSize: const Size(1280, 800));

        final offset = labelFromIcon(
          tester,
          'Bookmarks',
          Icons.bookmark_outline,
        );
        expect(offset.dx.abs(), lessThan(4));
        expect(offset.dy, greaterThan(0));
      },
    );

    testWidgets(
      'GivenAnExpandedWindow_WhenThePanelIsDrawn_ThenEveryLabelIsStillRead',
      (tester) async {
        await pumpWithALibrary(tester, surfaceSize: const Size(1700, 1000));

        for (final label in ['Home', 'Bookmarks', 'Course']) {
          expect(
            find.descendant(of: panel(), matching: find.text(label)),
            findsOneWidget,
            reason: 'no entry is dropped at any tier (FR-UX-02)',
          );
        }
      },
    );
  });

  group('structure', () {
    testWidgets(
      'GivenASignedInOwner_WhenTheShellOpens_ThenItHasAPanelAndAContentArea',
      (tester) async {
        await tester.pumpShell();

        expect(find.byType(ShellNavigationPanel), findsOneWidget);
        expect(find.byType(ShellContentArea), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheShellOpens_WhenNothingHasBeenPicked_ThenTheDashboardIsShown',
      (tester) async {
        final container = await tester.pumpShell();

        expect(
          container.read(shellControllerProvider),
          const HomeDestination(),
        );
      },
    );

    testWidgets(
      'GivenTheCoreCannotBeLoaded_WhenTheApplicationStarts_ThenTheShellIsNotShown',
      (tester) async {
        // AF-04: the core-unavailable state is presented instead, with its own
        // retry, rather than the application terminating or the shell opening
        // over a core that is not there.
        await tester.pumpFailedStartup();

        expect(find.byType(ShellScreen), findsNothing);
        expect(find.byType(CoreUnavailableScreen), findsOneWidget);
      },
    );
  });

  group('navigation', () {
    testWidgets(
      'GivenTheShell_WhenADestinationIsPickedInThePanel_ThenItsAreaIsShown',
      (tester) async {
        final container = await tester.pumpShell();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );

        await tester.tap(
          find.descendant(
            of: panel(),
            matching: find.text(l10n.destinationBookmarks),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          container.read(shellControllerProvider),
          const BookmarksDestination(),
        );
        expect(
          find.descendant(
            of: find.byType(ShellContentArea),
            matching: find.text(l10n.destinationBookmarks),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'GivenEveryEntry_WhenEachIsPicked_ThenEachHeadsTheContentArea',
      (tester) async {
        await pumpWithALibrary(tester, surfaceSize: const Size(1280, 900));

        // Bookmarks first: the shell opens on home, and picking the entry
        // already shown proves nothing.
        for (final label in ['Bookmarks', 'Course', 'Home']) {
          await tester.tap(
            find.descendant(of: panel(), matching: find.text(label)),
          );
          await tester.pumpAndSettle();

          expect(
            find.descendant(
              of: find.byType(ShellContentArea),
              matching: find.text(label),
            ),
            findsOneWidget,
            reason: 'the content area should be headed by $label',
          );
        }
      },
    );

    testWidgets(
      'GivenTheShell_WhenTheOwnerUsesTheKeyboard_ThenADestinationCanBeReached',
      (tester) async {
        // FR-UX-11: the panel is the shell's primary action surface, and it is
        // reachable without a pointer.
        final container = await tester.pumpShell();

        // Tabbed until a destination takes the focus rather than a fixed
        // number of presses: the shell has grown focusable controls since
        // UC-38 — the search field is one — and counting keystrokes would
        // make this test about the tab order rather than about reachability.
        for (var press = 0; press < 15; press++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();

          if (container.read(shellControllerProvider) !=
              const HomeDestination()) {
            break;
          }
        }

        expect(
          container.read(shellControllerProvider),
          isNot(const HomeDestination()),
          reason: 'FR-UX-11: the panel is reachable without a pointer',
        );
      },
    );
  });

  group('breakpoints', () {
    for (final entry in surfaces.entries) {
      testWidgets(
        'Given${entry.key}_WhenTheShellIsLaidOut_ThenNoEntryIsDropped',
        (tester) async {
          await pumpWithALibrary(tester, surfaceSize: entry.value);

          // A label where the tier draws one, its tooltip where it does not.
          final labelled = Breakpoint.of(
            entry.value.width,
          ).showsNavigationLabels;
          for (final label in ['Home', 'Bookmarks', 'Course']) {
            expect(
              labelled
                  ? find.descendant(of: panel(), matching: find.text(label))
                  : find.byTooltip(label),
              findsOneWidget,
              reason: 'FR-UX-02: the panel collapses, it never drops $label',
            );
          }
        },
      );

      testWidgets(
        'Given${entry.key}_WhenTheShellIsLaidOut_ThenNothingIsClipped',
        (tester) async {
          await pumpWithALibrary(tester, surfaceSize: entry.value);

          // An overflowing layout throws during paint, which the tester
          // records; reaching here with nothing recorded is the assertion.
          expect(tester.takeException(), isNull);
          expect(find.byType(ShellContentArea), findsOneWidget);
        },
      );
    }

    testWidgets(
      'GivenTheMinimumWindow_WhenThePanelIsLaidOut_ThenItCollapsesToIcons',
      (tester) async {
        await tester.pumpShell(surfaceSize: Breakpoint.minimumWindowSize);

        expect(
          find.descendant(of: panel(), matching: find.text('Home')),
          findsNothing,
        );
        expect(find.byTooltip('Home'), findsOneWidget);
      },
    );

    testWidgets(
      'GivenAMediumWindow_WhenThePanelIsLaidOut_ThenItsEntriesAreLabelled',
      (tester) async {
        await tester.pumpShell(surfaceSize: const Size(1280, 800));

        expect(
          find.descendant(of: panel(), matching: find.text('Home')),
          findsOneWidget,
        );
        expect(find.byTooltip('Home'), findsNothing);
      },
    );
  });

  group('themes and languages', () {
    for (final (name, mode) in [
      ('Light', ThemeMode.light),
      ('Dark', ThemeMode.dark),
    ]) {
      testWidgets(
        'GivenThe${name}Theme_WhenTheShellOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await tester.pumpShell(themeMode: mode);

          final context = tester.element(find.byType(ShellScreen));
          expect(
            Theme.of(context).brightness,
            mode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
          expect(find.byType(ShellNavigationPanel), findsOneWidget);
        },
      );
    }

    for (final (name, locale) in [
      ('English', const Locale('en')),
      ('Portuguese', const Locale('pt', 'BR')),
    ]) {
      testWidgets(
        'Given${name}_WhenTheShellOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          await tester.pumpShell(locale: locale);

          final l10n = AppLocalizations.of(
            tester.element(find.byType(ShellScreen)),
          );

          for (final label in [
            l10n.destinationHome,
            l10n.destinationBookmarks,
          ]) {
            expect(label, isNotEmpty);
            expect(label, isNot(contains('destination')));
            expect(
              find.descendant(of: panel(), matching: find.text(label)),
              findsOneWidget,
            );
          }
          // Home and the bookmarks both have content of their own — the
          // dashboard (UC-14) and the bookmark manager (UC-28) — so what this
          // checks is that the one the shell is *not* opened on renders in the
          // owner's language too.
          await tester.tap(
            find.descendant(
              of: panel(),
              matching: find.text(l10n.destinationBookmarks),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text(l10n.bookmarkAdd), findsOneWidget);
        },
      );
    }
  });
}
