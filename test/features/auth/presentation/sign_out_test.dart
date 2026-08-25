import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/auth/presentation/auth_notice.dart';
import 'package:alexandria_ui/features/auth/presentation/login_screen.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/shell/domain/session_activity.dart';
import 'package:alexandria_ui/features/shell/presentation/confirmation_dialog.dart';
import 'package:alexandria_ui/features/shell/presentation/preferences_dialog.dart';
import 'package:alexandria_ui/features/shell/presentation/settings_menu.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_session_activity.dart';
import '../../../support/login_harness.dart';
import '../../../support/shell_harness.dart';

/// Signing out (UC-03, FR-AU-09).
void main() {
  /// Signs in and opens the Settings menu, where sign-out lives.
  Future<ProviderContainer> openSettings(
    WidgetTester tester, {
    List<SessionActivity> activities = const [],
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    List<Override> extraOverrides = const [],
  }) async {
    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      extraOverrides: <Override>[
        sessionActivitiesProvider.overrideWithValue(activities),
        ...extraOverrides,
      ],
    );

    await tester.tap(find.byType(SettingsMenu));
    await tester.pumpAndSettle();

    return container;
  }

  /// Chooses the sign-out entry.
  Future<void> pressSignOut(WidgetTester tester) async {
    final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));

    await tester.tap(find.text(l10n.signOut).last);
    await tester.pumpAndSettle();
  }

  group('the main flow', () {
    // Reached without a session: preferences are open (UC-39), but signing
    // out is offered only through the shell's Settings menu, which does not
    // exist without a session to sign out of.
    testWidgets(
      'GivenNoSession_WhenPreferencesAreOpen_ThenSigningOutIsNotOffered',
      (tester) async {
        await tester.pumpLoginScreen();
        await tester.tap(find.byType(PreferencesButton));
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(PreferencesDialog)),
        );
        expect(find.text(l10n.signOut), findsNothing);
      },
    );

    testWidgets(
      'GivenASignedInOwner_WhenTheySignOut_ThenTheLoginScreenIsShown',
      (tester) async {
        await openSettings(tester);

        await pressSignOut(tester);

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(ShellScreen), findsNothing);
      },
    );

    testWidgets(
      'GivenASignedInOwner_WhenTheySignOut_ThenTheSessionIsDiscarded',
      (tester) async {
        final container = await openSettings(tester);

        await pressSignOut(tester);

        expect(container.read(sessionControllerProvider), isA<SessionAbsent>());
      },
    );

    testWidgets(
      'GivenAnActivityIsRunning_WhenTheOwnerSignsOut_ThenItIsWoundDown',
      (tester) async {
        final playback = FakeSessionActivity();
        await openSettings(tester, activities: [playback]);
        // Signing in wound down whatever the previous session left; what is
        // asserted here is what signing out adds to that.
        playback.endCount = 0;

        await pressSignOut(tester);

        expect(playback.endCount, 1);
      },
    );

    // Main flow step 3: the catalog projections are kept for the run, so
    // signing out has to say they go — otherwise the next owner to sign in
    // would be handed the previous session's listing (BR-05).
    testWidgets(
      'GivenACatalogAlreadyRead_WhenTheOwnerSignsOutAndBackIn_ThenItIsReadAgain',
      (tester) async {
        final gateway = FakeCatalogGateway();

        // The real activities, not a fake: this is the assertion that the
        // registered set actually discards what it claims to.
        await tester.pumpShell(
          extraOverrides: <Override>[
            catalogGatewayProvider.overrideWithValue(gateway),
          ],
        );

        await tester.tap(
          find.descendant(
            of: find.byType(ShellNavigationPanel),
            matching: find.byIcon(Icons.library_music_outlined),
          ),
        );
        await tester.pumpAndSettle();

        final readWhileSignedIn = gateway.requested
            .where((type) => type == LibraryType.audio)
            .length;
        expect(readWhileSignedIn, greaterThan(0));

        await tester.tap(find.byType(SettingsMenu));
        await tester.pumpAndSettle();
        await pressSignOut(tester);

        // Signing back in lands on the same area, and the listing there has to
        // be read from the core again rather than served from what the
        // previous session left behind.
        await tester.signIn();
        await tester.pumpAndSettle();

        expect(
          gateway.requested.where((type) => type == LibraryType.audio).length,
          greaterThan(readWhileSignedIn),
        );
      },
    );
  });

  // AF-01: an editor holds unsaved changes.
  group('unsaved changes', () {
    testWidgets(
      'GivenUnsavedChanges_WhenTheOwnerSignsOut_ThenTheyAreWarnedFirst',
      (tester) async {
        await openSettings(
          tester,
          activities: [FakeSessionActivity(holdsUnsavedChanges: true)],
        );

        await pressSignOut(tester);

        expect(find.byType(ConfirmationDialog), findsOneWidget);
      },
    );

    testWidgets('GivenTheWarning_WhenTheOwnerCancels_ThenTheSessionSurvives', (
      tester,
    ) async {
      final activity = FakeSessionActivity(holdsUnsavedChanges: true);
      final container = await openSettings(tester, activities: [activity]);
      activity.endCount = 0;

      await pressSignOut(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmationDialog),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(sessionControllerProvider), isA<SessionActive>());
      expect(activity.endCount, 0);
      expect(find.byType(ShellScreen), findsOneWidget);
    });

    testWidgets('GivenTheWarning_WhenTheOwnerConfirms_ThenTheyAreSignedOut', (
      tester,
    ) async {
      await openSettings(
        tester,
        activities: [FakeSessionActivity(holdsUnsavedChanges: true)],
      );

      await pressSignOut(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmationDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets(
      'GivenNothingUnsaved_WhenTheOwnerSignsOut_ThenNoWarningIsShown',
      (tester) async {
        await openSettings(tester, activities: [FakeSessionActivity()]);

        await pressSignOut(tester);

        expect(find.byType(ConfirmationDialog), findsNothing);
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );
  });

  // AF-02: an index run is in flight.
  group('a scan still running', () {
    testWidgets(
      'GivenARunInFlight_WhenTheOwnerSignsOut_ThenTheLoginScreenSaysItContinues',
      (tester) async {
        await openSettings(
          tester,
          activities: [FakeSessionActivity(continuesInTheCore: true)],
        );

        await pressSignOut(tester);

        final l10n = AppLocalizations.of(
          tester.element(find.byType(LoginScreen)),
        );
        expect(find.text(l10n.signOutIndexRunContinues), findsOneWidget);
      },
    );

    // Nothing went wrong, so it is not drawn as a refusal.
    testWidgets(
      'GivenTheNotice_WhenItIsShown_ThenItReadsAsInformationNotAFailure',
      (tester) async {
        await openSettings(
          tester,
          activities: [FakeSessionActivity(continuesInTheCore: true)],
        );

        await pressSignOut(tester);

        expect(
          tester.widget<AuthNotice>(find.byType(AuthNotice)).tone,
          AuthNoticeTone.information,
        );
      },
    );

    testWidgets(
      'GivenNothingRunning_WhenTheOwnerSignsOut_ThenNoSuchNoticeIsShown',
      (tester) async {
        await openSettings(tester);

        await pressSignOut(tester);

        expect(find.byType(AuthNotice), findsNothing);
      },
    );

    testWidgets('GivenTheNotice_WhenTheOwnerSignsInAgain_ThenItIsGone', (
      tester,
    ) async {
      await openSettings(
        tester,
        activities: [FakeSessionActivity(continuesInTheCore: true)],
      );

      await pressSignOut(tester);
      await tester.signIn();

      expect(find.byType(ShellScreen), findsOneWidget);
      expect(find.byType(AuthNotice), findsNothing);
    });
  });

  group('themes and languages', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheWarningIsShown_ThenItRendersInThatBrightness',
        (tester) async {
          await openSettings(
            tester,
            themeMode: themeMode,
            activities: [FakeSessionActivity(holdsUnsavedChanges: true)],
          );

          await pressSignOut(tester);

          final context = tester.element(find.byType(ConfirmationDialog));
          expect(
            Theme.of(context).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenSignOutIsOffered_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openSettings(
            tester,
            locale: locale,
            activities: [FakeSessionActivity(continuesInTheCore: true)],
          );

          expect(
            find.textContaining('signOut', findRichText: true),
            findsNothing,
          );

          await pressSignOut(tester);

          expect(
            find.textContaining('signOut', findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });
}
