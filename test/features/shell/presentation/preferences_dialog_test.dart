import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/shell/presentation/preferences_dialog.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alexandria_ui/core/settings/settings_store.dart';
import 'package:alexandria_ui/core/theme/breakpoints.dart';

import '../../../support/login_harness.dart';
import '../../../support/shell_harness.dart';
import '../../../support/in_memory_settings_store.dart';

/// The preferences dialog (UC-39, FR-UX-04, FR-UX-05, FR-UX-11, FR-UX-12).
void main() {
  /// Opens preferences from the shell's Settings menu.
  Future<void> openFromShell(
    WidgetTester tester, {
    ThemeMode? themeMode,
    SettingsStore? settings,
    Size? surfaceSize,
  }) async {
    await tester.pumpShell(
      themeMode: themeMode ?? ThemeMode.light,
      settings: settings,
      surfaceSize: surfaceSize ?? const Size(1280, 800),
    );
    await tester.openSettingsMenuEntry(
      AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      ).preferencesLabel,
    );
  }

  group('reachability (main flow step 1)', () {
    testWidgets(
      'GivenASignedInOwner_WhenTheShellIsShown_ThenPreferencesCanBeOpened',
      (tester) async {
        await openFromShell(tester);

        expect(find.byType(PreferencesDialog), findsOneWidget);
      },
    );

    testWidgets(
      'GivenNoSession_WhenTheLoginScreenIsShown_ThenPreferencesCanBeOpened',
      (tester) async {
        // "Reachable with or without a session" is the requirement, and the
        // login screen is where an owner without one is.
        await tester.pumpLoginScreen();

        await tester.tap(find.byType(PreferencesButton));
        await tester.pumpAndSettle();

        expect(find.byType(PreferencesDialog), findsOneWidget);
      },
    );

    testWidgets(
      'GivenNoSession_WhenPreferencesOpen_ThenOnlyTheThemeAndLanguageAreOffered',
      (tester) async {
        // What an owner standing on the login screen can actually act on
        // (UC-39 AF-05). The theme and the language change the screen in
        // front of them; the rest are settings for a library they have not
        // opened.
        await tester.pumpLoginScreen();
        await tester.tap(find.byType(PreferencesButton));
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PreferencesDialog)),
        );

        expect(find.text(l10n.preferencesThemeLabel), findsOneWidget);
        expect(find.text(l10n.preferencesLanguageLabel), findsOneWidget);
        expect(find.text(l10n.startupRecheckLabel), findsNothing);
      },
    );

    testWidgets('GivenASession_WhenPreferencesOpen_ThenEveryChoiceIsOffered', (
      tester,
    ) async {
      // The other half, and what stops the gate above from being a switch
      // nobody ever turns back on.
      await openFromShell(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(PreferencesDialog)),
      );

      expect(find.text(l10n.preferencesThemeLabel), findsOneWidget);
      expect(find.text(l10n.preferencesLanguageLabel), findsOneWidget);
      expect(find.text(l10n.startupRecheckLabel), findsOneWidget);
    });

    testWidgets(
      'GivenAFirstLaunch_WhenTheSignUpScreenIsShown_ThenPreferencesCanBeOpened',
      (tester) async {
        // The first screen a fresh installation shows, and so the owner's
        // first chance to pick a language they can read.
        await tester.pumpSignUpScreen();

        await tester.tap(find.byType(PreferencesButton));
        await tester.pumpAndSettle();

        expect(find.byType(PreferencesDialog), findsOneWidget);
      },
    );
  });

  group('choosing a theme', () {
    testWidgets(
      'GivenTheLightTheme_WhenDarkIsChosen_ThenItAppliesWithoutRestarting',
      (tester) async {
        await openFromShell(tester);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PreferencesDialog)),
        );

        await tester.tap(find.text(l10n.preferencesThemeDark));
        await tester.pumpAndSettle();

        expect(
          Theme.of(tester.element(find.byType(ShellScreen))).brightness,
          Brightness.dark,
        );
      },
    );

    testWidgets(
      'GivenDarkIsChosen_WhenTheDialogIsClosed_ThenTheShellStaysDark',
      (tester) async {
        await openFromShell(tester);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PreferencesDialog)),
        );

        await tester.tap(find.text(l10n.preferencesThemeDark));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.preferencesClose));
        await tester.pumpAndSettle();

        expect(find.byType(PreferencesDialog), findsNothing);
        expect(
          Theme.of(tester.element(find.byType(ShellScreen))).brightness,
          Brightness.dark,
        );
      },
    );
  });

  group('choosing a language', () {
    testWidgets(
      'GivenEnglish_WhenPortugueseIsChosen_ThenTheInterfaceChangesImmediately',
      (tester) async {
        await openFromShell(tester);
        final english = AppLocalizations.of(
          tester.element(find.byType(PreferencesDialog)),
        );
        // Scoped to the dialog: the panel's own preferences action carries
        // the same word as its visible label now, and an unscoped finder
        // would match both.
        expect(
          find.descendant(
            of: find.byType(PreferencesDialog),
            matching: find.text(english.preferencesTitle),
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('Português (Brasil)'));
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(PreferencesDialog)),
        );
        expect(l10n.localeName, startsWith('pt'));
        expect(
          find.descendant(
            of: find.byType(PreferencesDialog),
            matching: find.text(l10n.preferencesTitle),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'GivenBothLanguages_WhenTheyAreOffered_ThenEachNamesItselfInItsOwnWords',
      (tester) async {
        // An owner who has landed in the language they cannot read finds their
        // own by the word they recognize.
        await openFromShell(tester);

        expect(find.text('English'), findsOneWidget);
        expect(find.text('Português (Brasil)'), findsOneWidget);
      },
    );
  });

  group('the minimum window (NFR-07)', () {
    testWidgets(
      'GivenTheMinimumWindow_WhenPreferencesOpen_ThenTheLastOptionIsReachable',
      (tester) async {
        // NFR-07: the dialog has to stay usable at the minimum supported
        // window. The start-up re-check switch sits at the bottom of it, so
        // this is the test that would catch the day scrolling stops being
        // enough.
        await openFromShell(tester, surfaceSize: Breakpoint.minimumWindowSize);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PreferencesDialog)),
        );

        final recheck = find.widgetWithText(
          SwitchListTile,
          l10n.startupRecheckLabel,
        );
        await tester.scrollUntilVisible(
          recheck,
          200,
          scrollable: find
              .descendant(
                of: find.byType(PreferencesDialog),
                matching: find.byType(Scrollable),
              )
              .first,
        );

        await tester.tap(recheck);
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(PreferencesDialog)),
        );
        expect(
          container.read(preferencesControllerProvider).rechecksAtStartup,
          isFalse,
        );
      },
    );
  });

  group('a store that cannot be written (AF-02)', () {
    testWidgets(
      'GivenTheStoreRefusesAWrite_WhenAThemeIsChosen_ThenTheOwnerIsTold',
      (tester) async {
        await tester.pumpShellWithFailingSettings();
        await tester.openSettingsMenuEntry(
          AppLocalizations.of(
            tester.element(find.byType(ShellScreen)),
          ).preferencesLabel,
        );
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PreferencesDialog)),
        );

        await tester.tap(find.text(l10n.preferencesThemeDark));
        await tester.pumpAndSettle();

        expect(find.text(l10n.preferencesUnsaved), findsOneWidget);
        expect(
          Theme.of(tester.element(find.byType(PreferencesDialog))).brightness,
          Brightness.dark,
          reason: 'AF-02: the choice applies for this session either way',
        );
      },
    );

    testWidgets('GivenAWorkingStore_WhenAThemeIsChosen_ThenNoNoticeIsShown', (
      tester,
    ) async {
      await openFromShell(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(PreferencesDialog)),
      );

      await tester.tap(find.text(l10n.preferencesThemeDark));
      await tester.pumpAndSettle();

      expect(find.text(l10n.preferencesUnsaved), findsNothing);
    });
  });

  group('the rest of the application is undisturbed (AF-04)', () {
    testWidgets(
      'GivenAChosenDestination_WhenTheThemeChanges_ThenTheOwnerStaysThere',
      (tester) async {
        // AF-04 names playback and an index run, neither of which exists yet
        // (UC-19, UC-06). The property they share with what does exist
        // is that a preference change is not a reset, and the shell's
        // destination is the state available to prove it on.
        final container = await tester.pumpShell();
        await tester.openSettingsMenuEntry(
          AppLocalizations.of(
            tester.element(find.byType(ShellScreen)),
          ).preferencesLabel,
        );
        final before = container.read(shellControllerProvider);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PreferencesDialog)),
        );

        await tester.tap(find.text(l10n.preferencesThemeDark));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Português (Brasil)'));
        await tester.pumpAndSettle();

        expect(container.read(shellControllerProvider), before);
      },
    );
  });

  group('keyboard and themes', () {
    testWidgets(
      'GivenTheDialog_WhenItOpens_ThenItsPrimaryActionIsReachableFromTheKeyboard',
      (tester) async {
        await openFromShell(tester);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(find.byType(PreferencesDialog), findsNothing);
      },
    );

    for (final (name, mode) in [
      ('Light', ThemeMode.light),
      ('Dark', ThemeMode.dark),
    ]) {
      testWidgets(
        'GivenThe${name}Theme_WhenPreferencesOpen_ThenItRendersInThatBrightness',
        (tester) async {
          await openFromShell(tester, themeMode: mode);

          expect(
            Theme.of(tester.element(find.byType(PreferencesDialog))).brightness,
            mode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final (name, locale) in [
      ('English', const Locale('en')),
      ('Portuguese', const Locale('pt', 'BR')),
    ]) {
      testWidgets(
        'Given${name}_WhenPreferencesOpen_ThenNoStringRendersAsItsKey',
        (tester) async {
          await tester.pumpShell(locale: locale);
          await tester.openSettingsMenuEntry(
            AppLocalizations.of(
              tester.element(find.byType(ShellScreen)),
            ).preferencesLabel,
          );
          final l10n = AppLocalizations.of(
            tester.element(find.byType(PreferencesDialog)),
          );

          for (final label in [
            l10n.preferencesTitle,
            l10n.preferencesThemeLabel,
            l10n.preferencesThemeSystem,
            l10n.preferencesThemeLight,
            l10n.preferencesThemeDark,
            l10n.preferencesLanguageLabel,
            l10n.preferencesClose,
          ]) {
            expect(label, isNotEmpty);
            expect(label, isNot(startsWith('preferences')));
            expect(find.text(label), findsWidgets);
          }
        },
      );
    }
  });

  group('the startup re-check (FR-LB-21)', () {
    testWidgets(
      'GivenPreferences_WhenTheyOpen_ThenTheStartupRecheckIsOfferedAndOn',
      (tester) async {
        // On by default: a library that has fallen behind is the normal state
        // after the application has been closed for a while.
        await openFromShell(tester);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PreferencesDialog)),
        );

        expect(find.text(l10n.startupRecheckLabel), findsOneWidget);
        expect(
          tester
              .widget<SwitchListTile>(
                find.widgetWithText(SwitchListTile, l10n.startupRecheckLabel),
              )
              .value,
          isTrue,
        );
      },
    );

    testWidgets(
      'GivenPreferences_WhenTheRecheckIsTurnedOff_ThenItIsAppliedAndStored',
      (tester) async {
        final store = InMemorySettingsStore();
        await openFromShell(tester, settings: store);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(PreferencesDialog)),
        );

        // The group sits below the theme, language and animation groups, so
        // it is off the default surface until scrolled into view. Named
        // rather than found by type, so the test stays about this switch
        // whatever other `SwitchListTile` the dialog gains.
        final recheck = find.widgetWithText(
          SwitchListTile,
          AppLocalizations.of(
            tester.element(find.byType(PreferencesDialog)),
          ).startupRecheckLabel,
        );
        await tester.ensureVisible(recheck);
        await tester.tap(recheck);
        await tester.pumpAndSettle();

        expect(
          container.read(preferencesControllerProvider).rechecksAtStartup,
          isFalse,
        );
        expect(store.rechecksAtStartup, isFalse);
      },
    );

    testWidgets(
      'GivenTheStoreRefusesAWrite_WhenTheRecheckIsTurnedOff_ThenTheOwnerIsTold',
      (tester) async {
        // UC-39 AF-02: the choice applies for the session either way; what
        // the owner must not get is the silent belief that it was remembered.
        await tester.pumpShellWithFailingSettings();
        await tester.openSettingsMenuEntry(
          AppLocalizations.of(
            tester.element(find.byType(ShellScreen)),
          ).preferencesLabel,
        );

        final l10n = AppLocalizations.of(
          tester.element(find.byType(PreferencesDialog)),
        );
        final recheck = find.widgetWithText(
          SwitchListTile,
          l10n.startupRecheckLabel,
        );
        await tester.ensureVisible(recheck);
        await tester.tap(recheck);
        await tester.pumpAndSettle();

        expect(find.text(l10n.preferencesUnsaved), findsOneWidget);
      },
    );
  });
}
