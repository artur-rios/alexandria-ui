import 'package:alexandria_desktop/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/shell_harness.dart';

/// What the application resolves when the owner has expressed no preference,
/// and what it does when the system changes underneath one
/// (UC-39 AF-01, AF-03).
///
/// Separate from the dialog's own tests because none of this goes through the
/// dialog: it is what the application does before the owner has opened it, and
/// what it does while they are not looking.
void main() {
  group('following the system theme (AF-01)', () {
    testWidgets(
      'GivenTheSystemTheme_WhenTheSystemTurnsDark_ThenTheShellFollowsIt',
      (tester) async {
        // The default is ThemeMode.system, so no preference is set here.
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        await tester.pumpShell(themeMode: ThemeMode.system);
        expect(
          Theme.of(tester.element(find.byType(ShellScreen))).brightness,
          Brightness.light,
        );

        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pumpAndSettle();

        expect(
          Theme.of(tester.element(find.byType(ShellScreen))).brightness,
          Brightness.dark,
          reason: 'AF-01: the change is followed immediately',
        );
      },
    );

    testWidgets('GivenAChosenTheme_WhenTheSystemChanges_ThenTheChoiceIsKept', (
      tester,
    ) async {
      // The other half of AF-01: following the system is what "system"
      // means, and it must not leak into a theme the owner picked outright.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      // The owner chose light outright, and the system then turns dark.
      await tester.pumpShell(themeMode: ThemeMode.light);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();

      expect(
        Theme.of(tester.element(find.byType(ShellScreen))).brightness,
        Brightness.light,
        reason: 'a chosen theme is a choice, not a starting point',
      );
    });
  });

  group('resolving the language with no preference (AF-03)', () {
    testWidgets(
      'GivenNoChosenLanguage_WhenTheSystemIsPortuguese_ThenPortugueseIsUsed',
      (tester) async {
        tester.platformDispatcher.localesTestValue = const [Locale('pt', 'BR')];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);

        await tester.pumpShell();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );
        expect(l10n.localeName, startsWith('pt'));
      },
    );

    testWidgets(
      'GivenNoChosenLanguage_WhenTheSystemIsEnglish_ThenEnglishIsUsed',
      (tester) async {
        tester.platformDispatcher.localesTestValue = const [Locale('en', 'GB')];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);

        await tester.pumpShell();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );
        expect(l10n.localeName, startsWith('en'));
      },
    );

    testWidgets(
      'GivenNoChosenLanguage_WhenTheSystemIsNeither_ThenEnglishIsUsed',
      (tester) async {
        // AF-03's tail: an unsupported system language falls back to English
        // rather than to whichever catalog happens to be first.
        tester.platformDispatcher.localesTestValue = const [Locale('ja')];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);

        await tester.pumpShell();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );
        expect(l10n.localeName, startsWith('en'));
      },
    );

    testWidgets(
      'GivenAChosenLanguage_WhenTheSystemIsTheOther_ThenTheChoiceWins',
      (tester) async {
        tester.platformDispatcher.localesTestValue = const [Locale('ja')];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);

        await tester.pumpShell(locale: const Locale('pt', 'BR'));

        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellScreen)),
        );
        expect(l10n.localeName, startsWith('pt'));
      },
    );
  });
}
