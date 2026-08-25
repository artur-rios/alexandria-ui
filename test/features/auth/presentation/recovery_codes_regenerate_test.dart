import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_ui/features/auth/presentation/login_screen.dart';
import 'package:alexandria_ui/features/auth/presentation/recovery_codes_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/confirmation_dialog.dart';
import 'package:alexandria_ui/features/shell/presentation/preferences_dialog.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/shell_harness.dart';

/// Regenerating the recovery codes (UC-42, FR-AU-14, FR-AU-17, FR-AU-19).
void main() {
  const newCodes = ['new-aaaa', 'new-bbbb'];

  /// Signs in and opens preferences from the Settings menu, where the
  /// section lives (step 1).
  Future<({ProviderContainer container, FakeAuthGateway gateway})>
  openPreferences(
    WidgetTester tester, {
    AccountOutcome? account,
    RegenerateOutcome? regenerate,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final gateway = FakeAuthGateway();
    if (account != null) gateway.accountOutcome = account;
    if (regenerate != null) gateway.regenerateOutcome = regenerate;

    final container = await tester.pumpShell(
      gateway: gateway,
      locale: locale,
      themeMode: themeMode,
    );

    await tester.openSettingsMenuEntry(
      AppLocalizations.of(tester.element(find.byType(ShellScreen)))
          .preferencesLabel,
    );

    return (container: container, gateway: gateway);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// Presses the action and answers the confirmation.
  Future<void> regenerate(WidgetTester tester, {bool confirm = true}) async {
    await tester.tap(find.text(messages(tester).recoveryCodesRegenerate));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(ConfirmationDialog),
        matching: confirm ? find.byType(FilledButton) : find.byType(TextButton),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the main flow', () {
    // Step 1: the count comes from the core.
    testWidgets('GivenTheCoreReportsACount_WhenPreferencesOpen_ThenItIsShown', (
      tester,
    ) async {
      await openPreferences(tester);

      expect(
        find.text(messages(tester).recoveryCodesRemaining(7)),
        findsOneWidget,
      );
    });

    // Steps 2 and 3: the confirmation says what the owner is giving up.
    testWidgets('GivenTheAction_WhenItIsPressed_ThenTheOwnerIsAskedFirst', (
      tester,
    ) async {
      final opened = await openPreferences(tester);

      await tester.tap(find.text(messages(tester).recoveryCodesRegenerate));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmationDialog), findsOneWidget);
      expect(
        find.text(messages(tester).recoveryCodesRegenerateMessage),
        findsOneWidget,
      );
      expect(opened.gateway.regenerations, 0);
    });

    // Steps 4 and 5: the new set is shown under UC-40's rules.
    testWidgets('GivenItIsConfirmed_WhenTheCoreAnswers_ThenTheNewSetIsShown', (
      tester,
    ) async {
      final opened = await openPreferences(tester);

      await regenerate(tester);

      expect(opened.gateway.regenerations, 1);
      expect(find.byType(RecoveryCodesScreen), findsOneWidget);
      for (final code in newCodes) {
        expect(find.text(code), findsOneWidget);
      }
    });

    testWidgets('GivenTheNewSet_WhenItIsAcknowledged_ThenTheCatalogReturns', (
      tester,
    ) async {
      await openPreferences(tester);
      await regenerate(tester);

      await tester.tap(
        find.text(
          AppLocalizations.of(
            tester.element(find.byType(RecoveryCodesScreen)),
          ).recoveryCodesAcknowledge,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShellScreen), findsOneWidget);
      expect(find.byType(RecoveryCodesScreen), findsNothing);
    });
  });

  // AF-01: declining changes nothing, and the existing codes keep working.
  group('a regeneration the owner changes their mind about', () {
    testWidgets('GivenTheConfirmation_WhenItIsDeclined_ThenNothingChanges', (
      tester,
    ) async {
      final opened = await openPreferences(tester);

      await regenerate(tester, confirm: false);

      expect(opened.gateway.regenerations, 0);
      expect(find.byType(RecoveryCodesScreen), findsNothing);
    });
  });

  // AF-02: the core refused, and it replaced nothing.
  group('a regeneration the core refuses', () {
    testWidgets('GivenTheCoreRefuses_WhenItAnswers_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await openPreferences(
        tester,
        regenerate: const RegenerateOutcome.failed(
          failure: Failure.invalidInput(family: CoreStatusFamily.auth, code: 1),
        ),
      );

      await regenerate(tester);
      // The preferences dialog closes on the way through, so the notice is
      // read from the section when it is opened again.
      await tester.openSettingsMenuEntry(messages(tester).preferencesLabel);

      expect(find.byType(RecoveryCodesScreen), findsNothing);
      expect(find.text(messages(tester).failureInvalidInput), findsOneWidget);
    });
  });

  // AF-03: the core did not report a count. The action stays — hiding it
  // behind a number the core would not give helps nobody.
  group('a core that will not say how many remain', () {
    testWidgets('GivenNoCount_WhenPreferencesOpen_ThenTheActionIsStillThere', (
      tester,
    ) async {
      await openPreferences(
        tester,
        account: const AccountOutcome.read(
          account: AccountSummary(email: 'owner@example.com'),
        ),
      );

      expect(
        find.text(messages(tester).recoveryCodesRegenerate),
        findsOneWidget,
      );
      // No count is stated when the core gave none — neither a number nor
      // the "none left" sentence, which would be a zero this never read.
      expect(
        find.text(messages(tester).recoveryCodesRemaining(7)),
        findsNothing,
      );
      expect(find.text(messages(tester).recoveryCodesNoneLeft), findsNothing);
    });

    testWidgets('GivenTheReadFailed_WhenPreferencesOpen_ThenTheActionRemains', (
      tester,
    ) async {
      await openPreferences(
        tester,
        account: const AccountOutcome.failed(
          failure: Failure.unexpected(family: CoreStatusFamily.auth, code: 9),
        ),
      );

      expect(
        find.text(messages(tester).recoveryCodesRegenerate),
        findsOneWidget,
      );
    });
  });

  // Zero left is worth its own sentence: the account cannot be recovered.
  group('an account with no codes left', () {
    testWidgets('GivenNoneRemain_WhenPreferencesOpen_ThenItSaysSoPlainly', (
      tester,
    ) async {
      await openPreferences(
        tester,
        account: const AccountOutcome.read(
          account: AccountSummary(
            email: 'owner@example.com',
            recoveryCodesRemaining: 0,
          ),
        ),
      );

      expect(find.text(messages(tester).recoveryCodesNoneLeft), findsOneWidget);
    });
  });

  // AF-04: the core rejects the call as unauthorized.
  group('a session the core rejects', () {
    testWidgets(
      'GivenTheCoreRejectsTheSession_WhenRegenerating_ThenTheOwnerSignsOut',
      (tester) async {
        final opened = await openPreferences(
          tester,
          regenerate: const RegenerateOutcome.failed(
            failure: Failure.unauthorized(
              family: CoreStatusFamily.auth,
              code: 2,
            ),
          ),
        );

        await regenerate(tester);

        expect(
          opened.container.read(sessionControllerProvider),
          isA<SessionAbsent>(),
        );
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );
  });

  group('themes and languages', () {
    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheSectionIsShown_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openPreferences(tester, locale: locale);

          expect(
            find.textContaining(
              RegExp('recoveryCodes[A-Z]'),
              findRichText: true,
            ),
            findsNothing,
          );
        },
      );
    }
  });
  // Testing Specification 7.1: both themes are test surface, not review
  // surface. A screen that only reads correctly in one is a failing screen.
  group('both themes', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${mode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheScreenOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openPreferences(tester, themeMode: mode);

          expect(
            Theme.of(
              tester.element(find.byType(PreferencesDialog).first),
            ).brightness,
            mode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }
  });
}
