import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/core/theme/breakpoints.dart';
import 'package:alexandria_ui/features/auth/presentation/change_credentials_dialog.dart';
import 'package:alexandria_ui/features/auth/presentation/login_screen.dart';
import 'package:alexandria_ui/features/auth/presentation/recovery_codes_section.dart';
import 'package:alexandria_ui/features/lifecycle/presentation/missing_files_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/library_menu.dart';
import 'package:alexandria_ui/features/shell/presentation/preferences_dialog.dart';
import 'package:alexandria_ui/features/shell/presentation/settings_menu.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_menu_bar.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/shell_harness.dart';

/// The shell's menu bar (UC-37 main flow step 1, UC-39, FR-UX-01, FR-UX-02).
void main() {
  AppLocalizations localizations(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// Opens the Library menu.
  Future<void> openLibrary(WidgetTester tester) async {
    await tester.tap(find.byType(LibraryMenu));
    await tester.pumpAndSettle();
  }

  group('placement (FR-UX-01)', () {
    testWidgets(
      'GivenASignedInOwner_WhenTheShellOpens_ThenTheMenuBarIsShown',
      (tester) async {
        await tester.pumpShell();

        expect(find.byType(ShellMenuBar), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheShell_WhenTheMenuBarIsShown_ThenTheRailCarriesNoLibraryMenu',
      (tester) async {
        // The rail is destinations and nothing else: a second entry point
        // would be two controls claiming to be one.
        await tester.pumpShell();

        expect(
          find.descendant(
            of: find.byType(ShellNavigationPanel),
            matching: find.byType(LibraryMenu),
          ),
          findsNothing,
        );
      },
    );
  });

  group('the library menu (UC-37 main flow step 1)', () {
    testWidgets(
      'GivenTheMenuBar_WhenTheLibraryMenuIsOpened_ThenEveryLibraryWideAreaIsOffered',
      (tester) async {
        await tester.pumpShell();
        final l10n = localizations(tester);

        await openLibrary(tester);

        for (final label in [
          l10n.librarySourcesOpen,
          l10n.collectionsOpen,
          l10n.watchlistsOpen,
          l10n.readingListsOpen,
          l10n.deletedItemsOpen,
          l10n.missingFilesOpen,
        ]) {
          expect(find.text(label), findsOneWidget, reason: label);
        }
      },
    );

    testWidgets(
      'GivenTheLibraryMenu_WhenAnEntryIsChosen_ThenItsScreenOpens',
      (tester) async {
        await tester.pumpShell();
        final l10n = localizations(tester);

        await openLibrary(tester);
        await tester.tap(find.text(l10n.missingFilesOpen));
        await tester.pumpAndSettle();

        expect(find.byType(MissingFilesScreen), findsOneWidget);
      },
    );
  });

  group('across the breakpoints (FR-UX-02)', () {
    testWidgets(
      'GivenACompactWindow_WhenTheMenuBarIsShown_ThenTheLibraryMenuIsIconOnly',
      (tester) async {
        await tester.pumpShell(surfaceSize: Breakpoint.minimumWindowSize);
        final l10n = localizations(tester);

        expect(
          find.descendant(
            of: find.byType(LibraryMenu),
            matching: find.text(l10n.libraryToolsLabel),
          ),
          findsNothing,
        );
        expect(find.byIcon(Icons.widgets_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'GivenACompactWindow_WhenTheLibraryMenuIsOpened_ThenEveryEntryIsStillReachable',
      (tester) async {
        // Collapsed, not clipped: the trigger loses its label and the menu
        // behind it loses nothing.
        await tester.pumpShell(surfaceSize: Breakpoint.minimumWindowSize);
        final l10n = localizations(tester);

        await openLibrary(tester);

        expect(find.text(l10n.missingFilesOpen), findsOneWidget);
      },
    );

    testWidgets(
      'GivenAMediumWindow_WhenTheMenuBarIsShown_ThenTheLibraryMenuIsLabelled',
      (tester) async {
        await tester.pumpShell(surfaceSize: const Size(1280, 800));
        final l10n = localizations(tester);

        expect(
          find.descendant(
            of: find.byType(LibraryMenu),
            matching: find.text(l10n.libraryToolsLabel),
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('the settings menu (UC-39 main flow step 1)', () {
    testWidgets(
      'GivenTheMenuBar_WhenTheSettingsMenuIsOpened_ThenPreferencesAreOffered',
      (tester) async {
        await tester.pumpShell();
        final l10n = localizations(tester);

        await tester.tap(find.byType(SettingsMenu));
        await tester.pumpAndSettle();

        expect(find.text(l10n.preferencesLabel), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheSettingsMenu_WhenPreferencesAreChosen_ThenTheDialogOpens',
      (tester) async {
        await tester.pumpShell();
        final l10n = localizations(tester);

        await tester.tap(find.byType(SettingsMenu));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.preferencesLabel));
        await tester.pumpAndSettle();

        expect(find.byType(PreferencesDialog), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheShell_WhenTheRailIsShown_ThenItCarriesNoActionsBesideDestinations',
      (tester) async {
        // The rail is destinations and nothing else once the bar carries the
        // two actions that used to sit under it.
        await tester.pumpShell();

        expect(
          find.descendant(
            of: find.byType(ShellNavigationPanel),
            matching: find.byIcon(Icons.settings_outlined),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'GivenTheSettingsMenu_WhenCredentialsAreChosen_ThenTheCredentialsDialogOpens',
      (tester) async {
        await tester.pumpShell();
        final l10n = localizations(tester);

        await tester.openSettingsMenuEntry(l10n.changeCredentialsOpen);

        expect(find.byType(ChangeCredentialsDialog), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheCredentialsDialog_WhenItIsOpen_ThenTheRecoveryCodesAreOffered',
      (tester) async {
        // UC-42 beside UC-04: both are things an owner does to an account they
        // still have access to, and neither is a preference.
        await tester.pumpShell();
        final l10n = localizations(tester);

        await tester.openSettingsMenuEntry(l10n.changeCredentialsOpen);

        expect(find.byType(RecoveryCodesSection), findsOneWidget);
      },
    );

    testWidgets(
      'GivenPreferences_WhenTheyAreOpen_ThenNoAccountActionIsOffered',
      (tester) async {
        // The dialog is theme and language: an account action inside it is
        // what made signing out three levels deep.
        await tester.pumpShell();
        final l10n = localizations(tester);

        await tester.openSettingsMenuEntry(l10n.preferencesLabel);

        expect(find.text(l10n.changeCredentialsOpen), findsNothing);
        expect(find.byType(RecoveryCodesSection), findsNothing);
      },
    );

    testWidgets(
      'GivenTheSettingsMenu_WhenItIsOpened_ThenSigningOutIsOffered',
      (tester) async {
        await tester.pumpShell();
        final l10n = localizations(tester);

        await tester.tap(find.byType(SettingsMenu));
        await tester.pumpAndSettle();

        expect(find.text(l10n.signOut), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheSettingsMenu_WhenSigningOutIsChosen_ThenTheLoginScreenReturns',
      (tester) async {
        await tester.pumpShell();
        final l10n = localizations(tester);

        await tester.openSettingsMenuEntry(l10n.signOut);

        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );
  });
}
