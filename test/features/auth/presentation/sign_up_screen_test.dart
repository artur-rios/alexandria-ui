import 'package:alexandria_desktop/core/failures/core_rejection.dart';
import 'package:alexandria_desktop/core/failures/core_status.dart';
import 'package:alexandria_desktop/core/failures/failure.dart';
import 'package:alexandria_desktop/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_desktop/core/theme/breakpoints.dart';
import 'package:alexandria_desktop/features/auth/presentation/login_screen.dart';
import 'package:alexandria_desktop/features/auth/presentation/recovery_codes_screen.dart';
import 'package:alexandria_desktop/features/auth/presentation/sign_up_screen.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/login_harness.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt'));

  // FR-AU-01, main flow steps 1 and 2.
  group('which screen the owner lands on', () {
    testWidgets(
      'GivenTheCoreHoldsNoAccount_WhenTheApplicationIsReady_ThenSignUpIsShown',
      (tester) async {
        await tester.pumpSignUpScreen();

        expect(find.byType(SignUpScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
      },
    );

    testWidgets(
      'GivenTheCoreHoldsAnAccount_WhenTheApplicationIsReady_ThenLoginIsShown',
      (tester) async {
        await tester.pumpLoginScreen();

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(SignUpScreen), findsNothing);
      },
    );

    // The password cannot be recovered, so the owner is told before choosing
    // one rather than after.
    testWidgets('GivenTheSignUpScreen_WhenItOpens_ThenTheStakesAreStated', (
      tester,
    ) async {
      await tester.pumpSignUpScreen();

      expect(find.text(en.signUpIntro), findsOneWidget);
    });
  });

  group('the main flow', () {
    testWidgets(
      'GivenAValidForm_WhenTheOwnerSignsUp_ThenTheSignUpScreenIsReplaced',
      (tester) async {
        await tester.pumpSignUpScreen();

        await tester.signUp();

        expect(find.byType(SignUpScreen), findsNothing);
      },
    );

    testWidgets('GivenAValidForm_WhenTheOwnerSignsUp_ThenTheCoreIsCalledOnce', (
      tester,
    ) async {
      final gateway = FakeAuthGateway();
      await tester.pumpSignUpScreen(gateway: gateway);

      await tester.signUp();

      expect(gateway.registrations, hasLength(1));
    });

    testWidgets(
      'GivenAnAttemptInFlight_WhenTheFormIsRead_ThenAProgressIndicatorReplacesTheAction',
      (tester) async {
        final gateway = FakeAuthGateway()..hold();
        await tester.pumpSignUpScreen(gateway: gateway);

        await tester.enterRegistration();
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text(en.signUpSubmit), findsNothing);

        gateway.release();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'GivenAnAttemptInFlight_WhenTheOwnerTriesTheActionAgain_ThenTheAccountIsCreatedOnlyOnce',
      (tester) async {
        final gateway = FakeAuthGateway()..hold();
        await tester.pumpSignUpScreen(gateway: gateway);

        await tester.enterRegistration();
        await tester.tap(find.byType(FilledButton));
        await tester.pump();
        await tester.tap(find.byType(FilledButton), warnIfMissed: false);
        await tester.pump();

        expect(gateway.registrations, hasLength(1));

        gateway.release();
        await tester.pumpAndSettle();
      },
    );
  });

  // UC-01 AF-01.
  group('AF-01 — the address or password is unusable', () {
    testWidgets(
      'GivenAMalformedEmail_WhenTheOwnerSignsUp_ThenTheFieldIsMarkedAndTheCoreIsNotCalled',
      (tester) async {
        final gateway = FakeAuthGateway();
        await tester.pumpSignUpScreen(gateway: gateway);

        await tester.signUp(email: 'not-an-email');

        expect(find.text(en.loginEmailMalformed), findsOneWidget);
        expect(gateway.registrations, isEmpty);
      },
    );

    testWidgets(
      'GivenAnEmptyPassword_WhenTheOwnerSignsUp_ThenTheFieldIsMarkedAndTheCoreIsNotCalled',
      (tester) async {
        final gateway = FakeAuthGateway();
        await tester.pumpSignUpScreen(gateway: gateway);

        await tester.signUp(password: '');

        expect(find.text(en.loginPasswordMissing), findsOneWidget);
        expect(gateway.registrations, isEmpty);
      },
    );
  });

  // UC-01 AF-02.
  group('AF-02 — the two entries differ', () {
    testWidgets(
      'GivenEntriesThatDiffer_WhenTheOwnerSignsUp_ThenTheCoreIsNotCalled',
      (tester) async {
        final gateway = FakeAuthGateway();
        await tester.pumpSignUpScreen(gateway: gateway);

        await tester.signUp(passwordConfirmation: 'something else');

        expect(gateway.registrations, isEmpty);
      },
    );

    testWidgets(
      'GivenEntriesThatDiffer_WhenTheOwnerSignsUp_ThenTheConfirmationFieldIsMarked',
      (tester) async {
        await tester.pumpSignUpScreen();

        await tester.signUp(passwordConfirmation: 'something else');

        expect(find.text(en.signUpPasswordMismatch), findsOneWidget);
      },
    );

    testWidgets(
      'GivenAnEmptyRepeat_WhenTheOwnerSignsUp_ThenTheFieldIsMarkedAsMissing',
      (tester) async {
        await tester.pumpSignUpScreen();

        await tester.signUp(passwordConfirmation: '');

        expect(find.text(en.signUpPasswordConfirmationMissing), findsOneWidget);
      },
    );
  });

  // UC-01 AF-03.
  group('AF-03 — the core refuses the credentials', () {
    Future<void> pumpRefused(WidgetTester tester) => tester.pumpSignUpScreen(
      gateway: FakeAuthGateway.failing(
        const Failure.invalidInput(family: CoreStatusFamily.auth, code: 1),
      ),
    );

    testWidgets(
      'GivenTheCoreRefusesTheCredentials_WhenTheOwnerSignsUp_ThenTheRefusalIsShown',
      (tester) async {
        await pumpRefused(tester);

        await tester.signUp();

        expect(find.text(en.signUpRejected), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheCoreRefusesTheCredentials_WhenTheOwnerSignsUp_ThenTheOwnerStaysOnTheScreen',
      (tester) async {
        await pumpRefused(tester);

        await tester.signUp();

        expect(find.byType(SignUpScreen), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheCoreRefusesTheCredentials_WhenTheOwnerSignsUp_ThenBothPasswordFieldsAreCleared',
      (tester) async {
        await pumpRefused(tester);

        await tester.signUp();

        expect(tester.passwordField.controller?.text, isEmpty);
        expect(tester.passwordConfirmationField.controller?.text, isEmpty);
      },
    );

    // The address survives: it was not what the core objected to, and making
    // the owner retype it would be a second annoyance for a first mistake.
    testWidgets(
      'GivenTheCoreRefusesTheCredentials_WhenTheOwnerSignsUp_ThenTheAddressIsKept',
      (tester) async {
        await pumpRefused(tester);

        await tester.signUp();

        expect(tester.emailField.controller?.text, 'owner@example.com');
      },
    );
  });

  // UC-01 AF-03, with the reason the core now names (core issue #101). This is
  // the difference between "try something else" and being told what to change.
  group('AF-03 — the rule the core named', () {
    Future<void> pumpRefusedWith(
      WidgetTester tester,
      String code, {
      Map<String, String> params = const {},
    }) => tester.pumpSignUpScreen(
      gateway: FakeAuthGateway.failing(
        Failure.rejected(
          family: CoreStatusFamily.auth,
          code: 1,
          rejection: CoreRejection(code: code, params: params),
        ),
      ),
    );

    testWidgets(
      'GivenThePasswordIsTooShort_WhenTheOwnerSignsUp_ThenTheBoundIsStated',
      (tester) async {
        await pumpRefusedWith(
          tester,
          'password_too_short',
          params: const {'min': '12'},
        );

        await tester.signUp();

        expect(find.text(en.rejectionPasswordTooShort('12')), findsOneWidget);
      },
    );

    // The bound is the core's, so a different one reads differently rather
    // than being hardcoded here.
    testWidgets(
      'GivenTheCoreRaisesItsMinimum_WhenTheOwnerSignsUp_ThenTheNewBoundIsStated',
      (tester) async {
        await pumpRefusedWith(
          tester,
          'password_too_short',
          params: const {'min': '16'},
        );

        await tester.signUp();

        expect(find.text(en.rejectionPasswordTooShort('16')), findsOneWidget);
      },
    );

    testWidgets(
      'GivenThePasswordIsTooCommon_WhenTheOwnerSignsUp_ThenThatIsStated',
      (tester) async {
        await pumpRefusedWith(tester, 'password_too_common');

        await tester.signUp();

        expect(find.text(en.rejectionPasswordTooCommon), findsOneWidget);
      },
    );

    testWidgets(
      'GivenThePasswordContainsTheAddress_WhenTheOwnerSignsUp_ThenThatIsStated',
      (tester) async {
        await pumpRefusedWith(tester, 'password_contains_email');

        await tester.signUp();

        expect(find.text(en.rejectionPasswordContainsEmail), findsOneWidget);
      },
    );

    // A rule this version has not caught up with still reads as a sentence,
    // never as a code or a blank.
    testWidgets(
      'GivenACodeThisVersionDoesNotKnow_WhenTheOwnerSignsUp_ThenAReadableMessageIsStillShown',
      (tester) async {
        await pumpRefusedWith(tester, 'password_needs_a_haiku');

        await tester.signUp();

        expect(find.text(en.failureInvalidInput), findsOneWidget);
        expect(find.text('password_needs_a_haiku'), findsNothing);
      },
    );

    testWidgets(
      'GivenThePortugueseCatalog_WhenARuleIsNamed_ThenItIsTranslated',
      (tester) async {
        await tester.pumpSignUpScreen(
          locale: const Locale('pt', 'BR'),
          gateway: FakeAuthGateway.failing(
            const Failure.rejected(
              family: CoreStatusFamily.auth,
              code: 1,
              rejection: CoreRejection(
                code: 'password_too_short',
                params: {'min': '12'},
              ),
            ),
          ),
        );

        await tester.signUp();

        expect(find.text(pt.rejectionPasswordTooShort('12')), findsOneWidget);
      },
    );
  });

  // UC-01 step 7. What used to be AF-06 — the account created but the
  // confirmation message undeliverable — cannot happen: the core sends no
  // message, and dropped confirmation entirely on 2026-08-18. Signing up
  // opens a session and hands the owner their recovery codes (UC-40), which
  // is the one thing between here and the library.
  group('a successful sign-up', () {
    testWidgets(
      'GivenValidCredentials_WhenTheOwnerSignsUp_ThenTheRecoveryCodesAreShown',
      (tester) async {
        await tester.pumpSignUpScreen();

        await tester.signUp();

        expect(find.byType(RecoveryCodesScreen), findsOneWidget);
        expect(find.byType(ShellScreen), findsNothing);
      },
    );
  });

  // UC-01 AF-04.
  group('AF-04 — an account already exists', () {
    Future<void> pumpConflict(WidgetTester tester) => tester.pumpSignUpScreen(
      gateway: FakeAuthGateway.failing(
        const Failure.conflict(family: CoreStatusFamily.auth, code: 10),
      ),
    );

    testWidgets(
      'GivenAnAccountAlreadyExists_WhenTheOwnerSignsUp_ThenThatIsExplained',
      (tester) async {
        await pumpConflict(tester);

        await tester.signUp();

        expect(find.text(en.signUpAccountExists), findsOneWidget);
      },
    );

    testWidgets(
      'GivenAnAccountAlreadyExists_WhenTheOwnerFollowsTheAction_ThenTheLoginScreenIsShown',
      (tester) async {
        await pumpConflict(tester);

        await tester.signUp();
        await tester.tap(
          find.widgetWithText(OutlinedButton, en.signUpGoToLogin),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );

    // Offered rather than done: switching the screen out from under someone
    // mid-typing loses what they typed with no explanation.
    testWidgets(
      'GivenAnAccountAlreadyExists_WhenTheOwnerHasNotActed_ThenTheyAreStillOnSignUp',
      (tester) async {
        await pumpConflict(tester);

        await tester.signUp();

        expect(find.byType(SignUpScreen), findsOneWidget);
      },
    );
  });

  // UC-01 AF-05.
  group('AF-05 — the core cannot create an account', () {
    Future<void> pumpMisconfigured(WidgetTester tester) =>
        tester.pumpSignUpScreen(
          gateway: FakeAuthGateway.failing(
            const Failure.configuration(family: CoreStatusFamily.auth, code: 8),
          ),
        );

    testWidgets(
      'GivenTheCoreIsMisconfigured_WhenTheOwnerSignsUp_ThenAReadableMessageIsShown',
      (tester) async {
        await pumpMisconfigured(tester);

        await tester.signUp();

        expect(find.text(en.failureConfiguration), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheCoreIsMisconfigured_WhenTheOwnerSignsUp_ThenARetryIsOffered',
      (tester) async {
        await pumpMisconfigured(tester);

        await tester.signUp();

        expect(find.widgetWithText(OutlinedButton, en.retry), findsOneWidget);
      },
    );

    // FR-UX-09: no failure state ever ends in a raw status code.
    testWidgets(
      'GivenTheCoreIsMisconfigured_WhenTheOwnerSignsUp_ThenNoStatusCodeIsOnScreen',
      (tester) async {
        await pumpMisconfigured(tester);

        await tester.signUp();

        expect(find.text('8'), findsNothing);
      },
    );
  });

  // UC-02 AF-03, which could only state the condition until UC-01 existed.
  testWidgets(
    'GivenLoginReportsNoAccount_WhenTheOwnerFollowsTheAction_ThenSignUpIsShown',
    (tester) async {
      await tester.pumpLoginScreen(
        gateway: FakeAuthGateway.failing(
          const Failure.configuration(family: CoreStatusFamily.auth, code: 8),
        ),
      );

      await tester.signIn();
      await tester.tap(find.widgetWithText(OutlinedButton, en.loginGoToSignUp));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpScreen), findsOneWidget);
    },
  );

  // Testing Specification §7.1.
  group('the screen surface', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenSignUpIsShown_ThenTheFormAndItsActionAreVisible',
        (tester) async {
          await tester.pumpSignUpScreen(themeMode: themeMode);

          expect(find.byType(TextField), findsNWidgets(3));
          expect(find.text(en.signUpSubmit), findsOneWidget);
        },
      );
    }

    testWidgets(
      'GivenTheEnglishCatalog_WhenSignUpIsShown_ThenNoKeyRendersAsItsIdentifier',
      (tester) async {
        await tester.pumpSignUpScreen(locale: const Locale('en'));

        expect(find.text(en.signUpTitle), findsOneWidget);
        expect(find.text('signUpTitle'), findsNothing);
      },
    );

    testWidgets(
      'GivenThePortugueseCatalog_WhenSignUpIsShown_ThenItIsTranslated',
      (tester) async {
        await tester.pumpSignUpScreen(locale: const Locale('pt', 'BR'));

        expect(find.text(pt.signUpTitle), findsOneWidget);
        expect(find.text(en.signUpTitle), findsNothing);
      },
    );

    testWidgets(
      'GivenThePortugueseCatalog_WhenTheEntriesDiffer_ThenTheMismatchIsTranslated',
      (tester) async {
        await tester.pumpSignUpScreen(locale: const Locale('pt', 'BR'));

        await tester.signUp(passwordConfirmation: 'outra coisa');

        expect(find.text(pt.signUpPasswordMismatch), findsOneWidget);
      },
    );

    for (final size in [
      Breakpoint.minimumWindowSize,
      const Size(Breakpoint.mediumMinWidth, 800),
      const Size(Breakpoint.expandedMinWidth, 900),
    ]) {
      testWidgets(
        'GivenAWindowOf${size.width.toInt()}Pixels_WhenSignUpIsShown_ThenNothingOverflows',
        (tester) async {
          await tester.pumpSignUpScreen(surfaceSize: size);

          expect(tester.takeException(), isNull);
          expect(find.text(en.signUpSubmit), findsOneWidget);
        },
      );
    }

    // NFR-07: the form is a field taller than login, so the minimum window is
    // where a control would first become unreachable.
    testWidgets('GivenTheMinimumWindow_WhenTheActionIsTapped_ThenItResponds', (
      tester,
    ) async {
      final gateway = FakeAuthGateway();
      await tester.pumpSignUpScreen(
        gateway: gateway,
        surfaceSize: Breakpoint.minimumWindowSize,
      );

      await tester.signUp();

      expect(gateway.registrations, hasLength(1));
    });

    // FR-UX-11.
    testWidgets(
      'GivenSignUpOpens_WhenTheOwnerTypesWithoutClicking_ThenTheTextReachesTheEmailField',
      (tester) async {
        await tester.pumpSignUpScreen();

        tester.testTextInput.enterText('owner@example.com');
        await tester.pump();

        expect(tester.emailField.controller?.text, 'owner@example.com');
      },
    );

    testWidgets(
      'GivenTheFormIsFilled_WhenEnterIsPressedInTheRepeatField_ThenTheAttemptIsMade',
      (tester) async {
        final gateway = FakeAuthGateway();
        await tester.pumpSignUpScreen(gateway: gateway);

        await tester.enterRegistration();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(gateway.registrations, hasLength(1));
      },
    );
  });
}
