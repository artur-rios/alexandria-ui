import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_desktop/core/startup/core_unavailable_screen.dart';
import 'package:alexandria_desktop/core/theme/breakpoints.dart';
import 'package:alexandria_desktop/features/shell/domain/shell_destination.dart';
import 'package:alexandria_desktop/features/shell/presentation/playback_bar.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/login_harness.dart';
import '../../../support/shell_harness.dart';

/// The application shell (UC-38, FR-UX-01, FR-UX-02, FR-UX-11).
void main() {
  // The three tiers, and the minimum supported window itself.
  const surfaces = <String, Size>{
    'TheMinimumWindow': Size(1024, 640),
    'ACompactWindow': Size(1100, 700),
    'AMediumWindow': Size(1280, 800),
    'AnExpandedWindow': Size(1700, 1000),
    // Wide enough for labels, short enough that ten of them do not fit: the
    // breakpoints are widths, so this is the shape that catches a panel which
    // clips instead of adapting.
    'AWideButShortWindow': Size(1360, 640),
  };

  group('structure', () {
    testWidgets(
      'GivenASignedInOwner_WhenTheShellOpens_ThenItHasAPanelContentAndAPlaybackBar',
      (tester) async {
        await tester.pumpShell();

        expect(find.byType(ShellNavigationPanel), findsOneWidget);
        expect(find.byType(ShellContentArea), findsOneWidget);
        expect(find.byType(PlaybackBar), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheShellOpens_WhenNothingHasBeenPicked_ThenTheDashboardIsShown',
      (tester) async {
        final container = await tester.pumpShell();

        expect(container.read(shellControllerProvider), ShellDestination.home);
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

    testWidgets(
      'GivenNoMediaIsPlaying_WhenTheShellOpens_ThenThePlaybackBarSaysSo',
      (tester) async {
        await tester.pumpShell();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(PlaybackBar)),
        );
        expect(find.text(l10n.playbackNothingPlaying), findsOneWidget);
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

        // The icon rather than the label: the rail's tappable region is the
        // destination, and the label sits inside a box that does not hit test
        // on its own.
        await tester.tap(find.byIcon(ShellDestination.comicBooks.icon));
        await tester.pumpAndSettle();

        expect(
          container.read(shellControllerProvider),
          ShellDestination.comicBooks,
        );
        expect(
          find.descendant(
            of: find.byType(ShellContentArea),
            matching: find.text(l10n.destinationComicBooks),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'GivenEveryDestination_WhenEachIsPicked_ThenEachHeadsTheContentArea',
      (tester) async {
        await tester.pumpShell(surfaceSize: const Size(1280, 900));
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );

        for (final destination in ShellDestination.values) {
          // Either icon: the selected destination shows its filled variant,
          // and the loop starts on one that is already selected.
          await tester.tap(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Icon &&
                  (widget.icon == destination.icon ||
                      widget.icon == destination.selectedIcon),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.descendant(
              of: find.byType(ShellContentArea),
              matching: find.text(destination.label(l10n)),
            ),
            findsOneWidget,
            reason: 'the content area should be headed by ${destination.name}',
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

        for (var press = 0; press < 3; press++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(
          container.read(shellControllerProvider),
          isNot(ShellDestination.home),
        );
      },
    );
  });

  group('breakpoints', () {
    for (final entry in surfaces.entries) {
      testWidgets(
        'Given${entry.key}_WhenTheShellIsLaidOut_ThenNoDestinationIsDropped',
        (tester) async {
          await tester.pumpShell(surfaceSize: entry.value);

          final rail = tester.widget<NavigationRail>(
            find.byType(NavigationRail),
          );
          expect(
            rail.destinations.length,
            ShellDestination.values.length,
            reason: 'FR-UX-02: the panel collapses, it never drops an entry',
          );
        },
      );

      testWidgets(
        'Given${entry.key}_WhenTheShellIsLaidOut_ThenNothingIsClipped',
        (tester) async {
          await tester.pumpShell(surfaceSize: entry.value);

          // An overflowing layout throws during paint, which the tester
          // records; reaching here with nothing recorded is the assertion.
          expect(tester.takeException(), isNull);
          expect(find.byType(PlaybackBar), findsOneWidget);
          expect(find.byType(ShellContentArea), findsOneWidget);
        },
      );
    }

    testWidgets(
      'GivenTheMinimumWindow_WhenThePanelIsLaidOut_ThenItCollapsesToIcons',
      (tester) async {
        await tester.pumpShell(surfaceSize: Breakpoint.minimumWindowSize);

        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.labelType, NavigationRailLabelType.none);
      },
    );

    testWidgets(
      'GivenAMediumWindow_WhenThePanelIsLaidOut_ThenItsEntriesAreLabelled',
      (tester) async {
        await tester.pumpShell(surfaceSize: const Size(1280, 800));

        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.labelType, NavigationRailLabelType.all);
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

          for (final destination in ShellDestination.values) {
            final label = destination.label(l10n);
            expect(label, isNotEmpty);
            expect(label, isNot(contains('destination')));
          }
          expect(find.text(l10n.playbackNothingPlaying), findsOneWidget);
          expect(find.text(l10n.shellAreaPending), findsOneWidget);
        },
      );
    }
  });
}
