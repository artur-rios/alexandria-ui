import 'package:alexandria_ui/core/failures/core_rejection.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_ui/features/auth/presentation/login_screen.dart';
import 'package:alexandria_ui/features/auth/presentation/recovery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/keyboard.dart';
import '../../../support/login_harness.dart';

/// Recovering access with a recovery code (UC-41, FR-AU-15, FR-AU-16,
/// FR-AU-18, FR-AU-19).
void main() {
  const code = 'aaaa-bbbb';
  const password = 'a decent long passphrase';

  /// A refusal carrying the core's own reason code.
  Failure refusalNamed(String reason) => Failure.rejected(
    family: CoreStatusFamily.auth,
    code: 1,
    rejection: CoreRejection(code: reason),
  );

  /// Opens the recovery screen from the login screen (main flow step 1).
  Future<FakeAuthGateway> openRecovery(
    WidgetTester tester, {
    RecoveryOutcome? outcome,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final gateway = FakeAuthGateway();
    if (outcome != null) gateway.recoveryOutcome = outcome;

    await tester.pumpLoginScreen(
      gateway: gateway,
      locale: locale,
      themeMode: themeMode,
    );

    final l10n = AppLocalizations.of(tester.element(find.byType(LoginScreen)));
    await tester.tap(find.text(l10n.recoveryOpen));
    await tester.pumpAndSettle();

    return gateway;
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(RecoveryScreen)));

  /// Fills the form in and submits it.
  Future<void> redeem(
    WidgetTester tester, {
    String enteredCode = code,
    String newPassword = password,
    String? confirmation,
  }) async {
    final l10n = messages(tester);

    await tester.enterText(
      find.ancestor(
        of: find.text(l10n.recoveryCodeLabel),
        matching: find.byType(TextField),
      ),
      enteredCode,
    );
    await tester.enterText(
      find.ancestor(
        of: find.text(l10n.recoveryNewPassword),
        matching: find.byType(TextField),
      ),
      newPassword,
    );
    await tester.enterText(
      find.ancestor(
        of: find.text(l10n.recoveryConfirmPassword),
        matching: find.byType(TextField),
      ),
      confirmation ?? newPassword,
    );
    await tester.pump();

    await tester.tap(find.text(l10n.recoverySubmit));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'GivenTheCodeField_WhenReturnIsPressed_ThenTheCodeIsRedeemed',
    (tester) async {
      // FR-UX-11: Return submits from any field of the form.
      final gateway = await openRecovery(tester);
      final l10n = messages(tester);
      await tester.enterText(
        find.ancestor(
          of: find.text(l10n.recoveryCodeLabel),
          matching: find.byType(TextField),
        ),
        code,
      );
      await tester.enterText(
        find.ancestor(
          of: find.text(l10n.recoveryNewPassword),
          matching: find.byType(TextField),
        ),
        password,
      );
      await tester.enterText(
        find.ancestor(
          of: find.text(l10n.recoveryConfirmPassword),
          matching: find.byType(TextField),
        ),
        password,
      );
      await tester.pump();

      await tester.pressReturnIn(
        find.ancestor(
          of: find.text(l10n.recoveryCodeLabel),
          matching: find.byType(TextField),
        ),
      );

      expect(gateway.redemptions, hasLength(1));
    },
  );

  testWidgets(
    'GivenAMarkedField_WhenTheOwnerTypesInIt_ThenTheMarkGoesAway',
    (tester) async {
      // AF-01, as on every other form: what the last attempt marked stops
      // being true at the first keystroke.
      await openRecovery(tester);
      final l10n = messages(tester);
      await tester.tap(find.text(l10n.recoverySubmit));
      await tester.pumpAndSettle();
      expect(find.text(l10n.recoveryCodeMissing), findsOneWidget);

      await tester.enterText(
        find.ancestor(
          of: find.text(l10n.recoveryCodeLabel),
          matching: find.byType(TextField),
        ),
        code,
      );
      await tester.pump();

      expect(find.text(l10n.recoveryCodeMissing), findsNothing);
    },
  );

  group('the main flow', () {
    // Step 1: reachable from login, and only from there.
    testWidgets('GivenTheLoginScreen_WhenRecoveryIsAsked_ThenTheScreenOpens', (
      tester,
    ) async {
      await openRecovery(tester);

      expect(find.byType(RecoveryScreen), findsOneWidget);
    });

    // Steps 3 to 5.
    testWidgets('GivenACodeAndAPassword_WhenSubmitted_ThenTheCoreIsCalled', (
      tester,
    ) async {
      final gateway = await openRecovery(tester);

      await redeem(tester);

      expect(gateway.redemptions, [
        (code: code, newPassword: password, passwordConfirmation: password),
      ]);
    });

    // Step 6.
    testWidgets('GivenTheCoreAccepts_WhenItAnswers_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await openRecovery(tester);

      await redeem(tester);

      expect(find.text(messages(tester).recoveryDone), findsOneWidget);
    });

    testWidgets('GivenTheRecoveryFinished_WhenItIsClosed_ThenLoginIsShown', (
      tester,
    ) async {
      await openRecovery(tester);
      await redeem(tester);

      await tester.tap(find.text(messages(tester).recoveryBackToLogin));
      await tester.pumpAndSettle();

      expect(find.byType(RecoveryScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  // AF-01: nothing reaches the core that could not succeed — reaching it
  // could spend a code.
  group('input the screen refuses', () {
    testWidgets('GivenABlankCode_WhenSubmitted_ThenTheCoreIsNotCalled', (
      tester,
    ) async {
      final gateway = await openRecovery(tester);

      await redeem(tester, enteredCode: '   ');

      expect(gateway.redemptions, isEmpty);
      expect(find.text(messages(tester).recoveryCodeMissing), findsOneWidget);
    });

    testWidgets('GivenAnEmptyPassword_WhenSubmitted_ThenTheCoreIsNotCalled', (
      tester,
    ) async {
      final gateway = await openRecovery(tester);

      await redeem(tester, newPassword: '');

      expect(gateway.redemptions, isEmpty);
      expect(
        find.text(messages(tester).recoveryPasswordMissing),
        findsOneWidget,
      );
    });

    testWidgets('GivenMismatchedEntries_WhenSubmitted_ThenTheCoreIsNotCalled', (
      tester,
    ) async {
      final gateway = await openRecovery(tester);

      await redeem(tester, confirmation: 'something else entirely');

      expect(gateway.redemptions, isEmpty);
      expect(
        find.text(messages(tester).signUpPasswordMismatch),
        findsOneWidget,
      );
    });
  });

  // AF-02 and AF-03: told apart, because a mistyped code and a spent one call
  // for different things (FR-AU-16).
  group('a code the core refuses', () {
    testWidgets('GivenAnUnknownCode_WhenTheCoreAnswers_ThenItSaysSo', (
      tester,
    ) async {
      await openRecovery(
        tester,
        outcome: RecoveryOutcome.failed(
          failure: refusalNamed('recovery_code_unknown'),
        ),
      );

      await redeem(tester);

      expect(find.text(messages(tester).recoveryCodeUnknown), findsOneWidget);
      expect(find.text(messages(tester).recoveryCodeUsed), findsNothing);
    });

    testWidgets('GivenASpentCode_WhenTheCoreAnswers_ThenItSaysSoInstead', (
      tester,
    ) async {
      await openRecovery(
        tester,
        outcome: RecoveryOutcome.failed(
          failure: refusalNamed('recovery_code_used'),
        ),
      );

      await redeem(tester);

      expect(find.text(messages(tester).recoveryCodeUsed), findsOneWidget);
      expect(find.text(messages(tester).recoveryCodeUnknown), findsNothing);
    });

    testWidgets('GivenARefusal_WhenTheCoreAnswers_ThenTheFormStaysOpen', (
      tester,
    ) async {
      await openRecovery(
        tester,
        outcome: RecoveryOutcome.failed(
          failure: refusalNamed('recovery_code_unknown'),
        ),
      );

      await redeem(tester);

      expect(find.text(messages(tester).recoverySubmit), findsOneWidget);
      expect(find.text(messages(tester).recoveryDone), findsNothing);
    });
  });

  // AF-04: the core rejects the new password. Its rule, its reason, its
  // wording — and the code is not spent.
  group('a password the core refuses', () {
    testWidgets(
      'GivenThePasswordIsRefused_WhenItAnswers_ThenTheReasonIsShown',
      (tester) async {
        await openRecovery(
          tester,
          outcome: const RecoveryOutcome.failed(
            failure: Failure.rejected(
              family: CoreStatusFamily.auth,
              code: 1,
              rejection: CoreRejection(
                code: 'password_too_short',
                params: {'min': '12'},
              ),
            ),
          ),
        );

        await redeem(tester);

        expect(
          find.text(messages(tester).rejectionPasswordTooShort('12')),
          findsOneWidget,
        );
      },
    );

    testWidgets('GivenARefusalWithNoReason_WhenItAnswers_ThenItStillReads', (
      tester,
    ) async {
      await openRecovery(
        tester,
        outcome: const RecoveryOutcome.failed(
          failure: Failure.invalidInput(family: CoreStatusFamily.auth, code: 1),
        ),
      );

      await redeem(tester);

      expect(find.text(messages(tester).recoveryRefused), findsOneWidget);
    });
  });

  // AF-06: no account to recover. Reported as an ordinary refusal — an answer
  // that distinguished it would tell a stranger whether an account exists.
  group('an installation with no account', () {
    testWidgets('GivenNoAccount_WhenACodeIsRedeemed_ThenNothingIsRevealed', (
      tester,
    ) async {
      await openRecovery(
        tester,
        outcome: const RecoveryOutcome.failed(
          failure: Failure.notFound(family: CoreStatusFamily.auth, code: 4),
        ),
      );

      await redeem(tester);

      expect(find.text(messages(tester).recoveryRefused), findsOneWidget);
    });
  });

  group('themes and languages', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheScreenOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openRecovery(tester, themeMode: themeMode);

          expect(
            Theme.of(tester.element(find.byType(RecoveryScreen))).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenACodeIsRefused_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openRecovery(
            tester,
            locale: locale,
            outcome: RecoveryOutcome.failed(
              failure: refusalNamed('recovery_code_used'),
            ),
          );

          await redeem(tester);

          expect(
            find.textContaining(RegExp('recovery[A-Z]'), findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });
}
