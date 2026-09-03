import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/core/theme/breakpoints.dart';
import 'package:alexandria_ui/features/auth/presentation/login_screen.dart';
import 'package:alexandria_ui/core/startup/core_unavailable_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/keyboard.dart';
import '../../../support/login_harness.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt'));

  group('the form', () {
    testWidgets(
      'GivenNoSession_WhenTheApplicationIsReady_ThenTheLoginScreenIsShown',
      (tester) async {
        await tester.pumpLoginScreen();

        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );

    testWidgets('GivenTheLoginScreen_WhenItOpens_ThenNoFailureIsShown', (
      tester,
    ) async {
      await tester.pumpLoginScreen();

      expect(find.text(en.loginRejected), findsNothing);
      expect(find.text(en.loginNoAccount), findsNothing);
    });

    testWidgets(
      'GivenValidCredentials_WhenTheOwnerSignsIn_ThenTheLoginScreenIsReplaced',
      (tester) async {
        await tester.pumpLoginScreen();

        await tester.signIn();

        expect(find.byType(LoginScreen), findsNothing);
      },
    );

    testWidgets(
      'GivenAnAttemptInFlight_WhenTheFormIsRead_ThenAProgressIndicatorReplacesTheAction',
      (tester) async {
        final gateway = FakeAuthGateway()..hold();
        await tester.pumpLoginScreen(gateway: gateway);

        await tester.enterCredentials();
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text(en.loginSubmit), findsNothing);

        gateway.release();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'GivenAnAttemptInFlight_WhenTheOwnerTriesTheActionAgain_ThenTheCoreIsCalledOnlyOnce',
      (tester) async {
        final gateway = FakeAuthGateway()..hold();
        await tester.pumpLoginScreen(gateway: gateway);

        await tester.enterCredentials();
        await tester.tap(find.byType(FilledButton));
        await tester.pump();
        await tester.tap(find.byType(FilledButton), warnIfMissed: false);
        await tester.pump();

        expect(gateway.calls, hasLength(1));

        gateway.release();
        await tester.pumpAndSettle();
      },
    );
  });

  group('the keyboard (FR-UX-11)', () {
    testWidgets(
      'GivenTheEmailField_WhenReturnIsPressed_ThenTheFormIsSubmitted',
      (tester) async {
        // The complaint this answers: Return moved the focus instead of
        // signing in. That is Tab's job, and the field was configured to do
        // it because `TextInputAction.next` is written for a soft keyboard
        // this application never shows.
        final gateway = FakeAuthGateway();
        await tester.pumpLoginScreen(gateway: gateway);
        await tester.enterCredentials();

        await tester.pressReturnIn(find.byType(TextField).first);

        expect(gateway.calls, hasLength(1));
      },
    );

    // The password field's own case is `the screen surface`'s
    // `GivenCredentialsTyped_WhenEnterIsPressedInThePasswordField...`, which
    // predates this group: that field always submitted, and is why the
    // difference between the two was so easy to miss.

    testWidgets(
      'GivenTheEmailField_WhenTabIsPressed_ThenTheFocusMovesToThePassword',
      (tester) async {
        // Moving between fields is what Tab is for, and it still does it.
        await tester.pumpLoginScreen();
        await tester.tap(find.byType(TextField).first);
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        final password = tester.widget<EditableText>(
          find.descendant(
            of: find.byType(TextField).last,
            matching: find.byType(EditableText),
          ),
        );
        expect(password.focusNode.hasFocus, isTrue);
      },
    );

    testWidgets(
      'GivenAnEmptyForm_WhenReturnIsPressed_ThenItIsRefusedRatherThanIgnored',
      (tester) async {
        // Submitting from a field the owner has not filled is still
        // submitting: the form says what is missing, which is the answer
        // they need, rather than silently doing nothing.
        final gateway = FakeAuthGateway();
        await tester.pumpLoginScreen(gateway: gateway);

        await tester.pressReturnIn(find.byType(TextField).first);

        expect(gateway.calls, isEmpty);
        expect(find.text(en.loginEmailMissing), findsOneWidget);
      },
    );
  });

  group('what a refusal leaves behind (AF-01, AF-02)', () {
    testWidgets('GivenAMarkedField_WhenTheOwnerTypesInIt_ThenTheMarkGoesAway', (
      tester,
    ) async {
      // The owner's own report: submitting with something missing marked
      // the field, and filling it in left the mark exactly where it was.
      // A form that goes on saying "required" about a field with a value
      // in it is arguing with the person using it.
      await tester.pumpLoginScreen();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.text(en.loginEmailMissing), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'owner@x.com');
      await tester.pump();

      expect(find.text(en.loginEmailMissing), findsNothing);
    });

    testWidgets(
      'GivenARefusal_WhenTheOwnerTypesAgain_ThenTheNoticeGoesWithIt',
      (tester) async {
        // The refusal is about the credentials that were sent, and the
        // owner is replacing them. The next attempt says whatever is still
        // true.
        await tester.pumpLoginScreen(
          gateway: FakeAuthGateway.failing(
            const Failure.unauthorized(family: CoreStatusFamily.auth, code: 2),
          ),
        );
        await tester.signIn();
        expect(find.text(en.loginRejected), findsOneWidget);

        await tester.enterText(find.byType(TextField).last, 'another try');
        await tester.pump();

        expect(find.text(en.loginRejected), findsNothing);
      },
    );

    testWidgets(
      'GivenAnUnmarkedForm_WhenTheOwnerTypes_ThenNothingIsDisturbed',
      (tester) async {
        // Typing into a clean form must not be a state change: this runs on
        // every keystroke.
        await tester.pumpLoginScreen();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(LoginScreen)),
        );
        final before = container.read(loginControllerProvider);

        await tester.enterText(find.byType(TextField).first, 'owner@x.com');
        await tester.pump();

        expect(
          identical(container.read(loginControllerProvider), before),
          isTrue,
        );
      },
    );
  });

  // UC-02 AF-01.
  group('AF-01 — the form rejects itself', () {
    testWidgets(
      'GivenAMalformedEmail_WhenTheOwnerSignsIn_ThenTheFieldIsMarkedAndTheCoreIsNotCalled',
      (tester) async {
        final gateway = FakeAuthGateway();
        await tester.pumpLoginScreen(gateway: gateway);

        await tester.signIn(email: 'not-an-email');

        expect(find.text(en.loginEmailMalformed), findsOneWidget);
        expect(gateway.calls, isEmpty);
      },
    );

    testWidgets(
      'GivenAnEmptyPassword_WhenTheOwnerSignsIn_ThenTheFieldIsMarkedAndTheCoreIsNotCalled',
      (tester) async {
        final gateway = FakeAuthGateway();
        await tester.pumpLoginScreen(gateway: gateway);

        await tester.signIn(password: '');

        expect(find.text(en.loginPasswordMissing), findsOneWidget);
        expect(gateway.calls, isEmpty);
      },
    );

    testWidgets('GivenAnEmptyEmail_WhenTheOwnerSignsIn_ThenTheFieldIsMarked', (
      tester,
    ) async {
      await tester.pumpLoginScreen();

      await tester.signIn(email: '');

      expect(find.text(en.loginEmailMissing), findsOneWidget);
    });
  });

  // UC-02 AF-02.
  group('AF-02 — the core rejects the credentials', () {
    Future<void> pumpRejected(WidgetTester tester) => tester.pumpLoginScreen(
      gateway: FakeAuthGateway.failing(
        const Failure.unauthorized(family: CoreStatusFamily.auth, code: 2),
      ),
    );

    testWidgets(
      'GivenTheCoreRejectsTheCredentials_WhenTheOwnerSignsIn_ThenTheRefusalIsShown',
      (tester) async {
        await pumpRejected(tester);

        await tester.signIn();

        expect(find.text(en.loginRejected), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheCoreRejectsTheCredentials_WhenTheOwnerSignsIn_ThenTheOwnerStaysOnTheScreen',
      (tester) async {
        await pumpRejected(tester);

        await tester.signIn();

        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheCoreRejectsTheCredentials_WhenTheOwnerSignsIn_ThenThePasswordIsCleared',
      (tester) async {
        await pumpRejected(tester);

        await tester.signIn();

        expect(tester.passwordField.controller?.text, isEmpty);
      },
    );

    // The message must not reveal whether the address is registered, so it can
    // say nothing that names the address or the password specifically.
    testWidgets(
      'GivenTheCoreRejectsTheCredentials_WhenTheMessageIsRead_ThenItDoesNotNameTheAddress',
      (tester) async {
        await pumpRejected(tester);

        await tester.signIn();

        expect(en.loginRejected, isNot(contains('owner@example.com')));
        expect(find.text(en.loginEmailMalformed), findsNothing);
      },
    );
  });

  // UC-02 AF-03.
  testWidgets(
    'GivenNoAccountHasBeenSetUp_WhenTheOwnerSignsIn_ThenThatIsExplained',
    (tester) async {
      await tester.pumpLoginScreen(
        gateway: FakeAuthGateway.failing(
          const Failure.configuration(family: CoreStatusFamily.auth, code: 8),
        ),
      );

      await tester.signIn();

      expect(find.text(en.loginNoAccount), findsOneWidget);
    },
  );

  // UC-02 AF-04.
  group('AF-04 — a later call is rejected', () {
    testWidgets(
      'GivenASessionDiscardedByRejection_WhenTheOwnerReturns_ThenTheReasonIsStated',
      (tester) async {
        const rejection = Failure.unauthorized(
          family: CoreStatusFamily.file,
          code: 2,
        );
        final container = await tester.pumpLoginScreen();

        await tester.signIn();
        container
            .read(sessionControllerProvider.notifier)
            .invalidate(rejection);
        await tester.pumpAndSettle();

        expect(find.text(en.loginSessionEndedTitle), findsOneWidget);
      },
    );

    testWidgets(
      'GivenASessionDiscardedByRejection_WhenTheOwnerReturns_ThenTheLoginScreenIsShown',
      (tester) async {
        final container = await tester.pumpLoginScreen();

        await tester.signIn();
        container
            .read(sessionControllerProvider.notifier)
            .invalidate(
              const Failure.unauthorized(
                family: CoreStatusFamily.file,
                code: 2,
              ),
            );
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );
  });

  // UC-02 AF-05.
  group('AF-05 — the core is not ready', () {
    Future<void> pumpNotReady(WidgetTester tester) => tester.pumpLoginScreen(
      gateway: FakeAuthGateway.failing(
        const Failure.notInitialized(family: CoreStatusFamily.auth, code: 3),
      ),
    );

    testWidgets(
      'GivenTheCoreIsNotReady_WhenTheOwnerSignsIn_ThenAReadableMessageIsShown',
      (tester) async {
        await pumpNotReady(tester);

        await tester.signIn();

        expect(find.text(en.failureNotInitialized), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheCoreIsNotReady_WhenTheOwnerSignsIn_ThenARetryIsOffered',
      (tester) async {
        await pumpNotReady(tester);

        await tester.signIn();

        expect(find.widgetWithText(OutlinedButton, en.retry), findsOneWidget);
      },
    );

    // FR-UX-09: no failure state ever ends in a raw status code.
    testWidgets(
      'GivenTheCoreIsNotReady_WhenTheOwnerSignsIn_ThenNoStatusCodeIsOnScreen',
      (tester) async {
        await pumpNotReady(tester);

        await tester.signIn();

        expect(find.text('3'), findsNothing);
      },
    );
  });

  // What used to be AF-06 — an authenticated owner held out of the catalog
  // until their e-mail was confirmed — has no state behind it any more: the
  // core dropped confirmation on 2026-08-18. Signing in reaches the shell,
  // and that is the whole of it.
  group('a successful sign-in', () {
    testWidgets('GivenAnAccount_WhenTheOwnerSignsIn_ThenTheCatalogIsReached', (
      tester,
    ) async {
      await tester.pumpLoginScreen();

      await tester.signIn();

      expect(find.byType(ShellScreen), findsOneWidget);
    });
  });

  // Testing Specification §7.1: both themes, both languages, every breakpoint
  // including the minimum, and the primary action reachable from the keyboard.
  group('the screen surface', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheScreenIsShown_ThenTheFormAndItsActionAreVisible',
        (tester) async {
          await tester.pumpLoginScreen(themeMode: themeMode);

          expect(find.byType(TextField), findsNWidgets(2));
          expect(find.text(en.loginSubmit), findsOneWidget);
        },
      );
    }

    testWidgets(
      'GivenTheEnglishCatalog_WhenTheScreenIsShown_ThenNoKeyRendersAsItsIdentifier',
      (tester) async {
        await tester.pumpLoginScreen(locale: const Locale('en'));

        expect(find.text(en.loginTitle), findsOneWidget);
        expect(find.text('loginTitle'), findsNothing);
      },
    );

    testWidgets(
      'GivenThePortugueseCatalog_WhenTheScreenIsShown_ThenItIsTranslated',
      (tester) async {
        await tester.pumpLoginScreen(locale: const Locale('pt', 'BR'));

        expect(find.text(pt.loginTitle), findsOneWidget);
        expect(find.text(en.loginTitle), findsNothing);
      },
    );

    testWidgets(
      'GivenThePortugueseCatalog_WhenAnAttemptIsRefused_ThenTheRefusalIsTranslated',
      (tester) async {
        await tester.pumpLoginScreen(
          locale: const Locale('pt', 'BR'),
          gateway: FakeAuthGateway.failing(
            const Failure.unauthorized(family: CoreStatusFamily.auth, code: 2),
          ),
        );

        await tester.signIn();

        expect(find.text(pt.loginRejected), findsOneWidget);
      },
    );

    for (final size in [
      Breakpoint.minimumWindowSize,
      const Size(Breakpoint.mediumMinWidth, 800),
      const Size(Breakpoint.expandedMinWidth, 900),
    ]) {
      testWidgets(
        'GivenAWindowOf${size.width.toInt()}Pixels_WhenTheScreenIsShown_ThenNothingOverflows',
        (tester) async {
          await tester.pumpLoginScreen(surfaceSize: size);

          expect(tester.takeException(), isNull);
          expect(find.text(en.loginSubmit), findsOneWidget);
        },
      );
    }

    // NFR-07: at the minimum supported window the action must still be
    // reachable, not merely present in the tree.
    testWidgets('GivenTheMinimumWindow_WhenTheActionIsTapped_ThenItResponds', (
      tester,
    ) async {
      final gateway = FakeAuthGateway();
      await tester.pumpLoginScreen(
        gateway: gateway,
        surfaceSize: Breakpoint.minimumWindowSize,
      );

      await tester.signIn();

      expect(gateway.calls, hasLength(1));
    });

    // FR-UX-11: the screen is usable without a pointer. The first field takes
    // focus on open, and Enter in the password field submits.
    testWidgets(
      'GivenTheScreenOpens_WhenTheOwnerTypesWithoutClicking_ThenTheTextReachesTheEmailField',
      (tester) async {
        await tester.pumpLoginScreen();

        // Sent to whatever holds focus rather than to a field this test
        // picked, which is what makes it a test of the autofocus.
        tester.testTextInput.enterText('owner@example.com');
        await tester.pump();

        expect(tester.emailField.controller?.text, 'owner@example.com');
      },
    );

    testWidgets(
      'GivenCredentialsTyped_WhenEnterIsPressedInThePasswordField_ThenTheAttemptIsMade',
      (tester) async {
        final gateway = FakeAuthGateway();
        await tester.pumpLoginScreen(gateway: gateway);

        await tester.enterCredentials();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(gateway.calls, hasLength(1));
      },
    );
  });

  // The startup failure state is the foundation's, and logging in must not
  // have displaced it.
  testWidgets(
    'GivenTheCoreFailedToLoad_WhenTheApplicationStarts_ThenTheCoreUnavailableScreenStillWins',
    (tester) async {
      await tester.pumpFailedStartup();

      expect(find.byType(CoreUnavailableScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    },
  );
}
