import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/core/failures/core_rejection.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_ui/features/auth/presentation/change_credentials_dialog.dart';
import 'package:alexandria_ui/features/auth/presentation/login_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/preferences_dialog.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/login_harness.dart';
import '../../../support/shell_harness.dart';

/// The credential-change form (UC-04, FR-AU-10, FR-AU-11).
void main() {
  /// The panel's preferences action.
  ///
  /// Not `find.byType(PreferencesButton)`: the shell now builds its
  /// preferences action as a `RailAction` inline, matching how the
  /// destinations beside it present at each breakpoint.
  Finder preferencesActionInShell() => find.descendant(
    of: find.byType(ShellNavigationPanel),
    matching: find.byIcon(Icons.settings_outlined),
  );

  /// Signs in, opens preferences, and opens the credential-change form.
  Future<void> openForm(
    WidgetTester tester, {
    FakeAuthGateway? gateway,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpShell(
      gateway: gateway,
      locale: locale,
      themeMode: themeMode,
    );
    await tester.tap(preferencesActionInShell());
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(PreferencesDialog)),
    );
    await tester.tap(find.text(l10n.changeCredentialsOpen));
    await tester.pumpAndSettle();
  }

  /// Fills the three fields and presses the form's primary action.
  Future<void> submitForm(
    WidgetTester tester, {
    String email = 'new@example.com',
    String password = 'a decent long passphrase',
    String? confirmation,
  }) async {
    final fields = find.descendant(
      of: find.byType(ChangeCredentialsDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), password);
    await tester.enterText(fields.at(2), confirmation ?? password);
    await tester.pump();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ChangeCredentialsDialog)),
    );
    await tester.tap(find.text(l10n.changeCredentialsSubmit));
    await tester.pumpAndSettle();
  }

  group('reachability (main flow step 1)', () {
    testWidgets(
      'GivenASignedInOwner_WhenPreferencesOpen_ThenTheChangeIsOffered',
      (tester) async {
        await tester.pumpShell();
        await tester.tap(preferencesActionInShell());
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PreferencesDialog)),
        );

        expect(find.text(l10n.changeCredentialsOpen), findsOneWidget);
      },
    );

    testWidgets(
      'GivenNoSession_WhenPreferencesOpen_ThenTheChangeIsNotOffered',
      (tester) async {
        // The core requires a session to change credentials that already
        // exist, and preferences are reachable without one (UC-39).
        await tester.pumpLoginScreen();
        await tester.tap(find.byType(PreferencesButton));
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PreferencesDialog)),
        );

        expect(find.text(l10n.changeCredentialsOpen), findsNothing);
      },
    );

    testWidgets('GivenPreferences_WhenTheChangeIsChosen_ThenTheFormOpens', (
      tester,
    ) async {
      await openForm(tester);

      expect(find.byType(ChangeCredentialsDialog), findsOneWidget);
    });
  });

  group('the main flow', () {
    testWidgets('GivenAValidForm_WhenItIsSubmitted_ThenTheCoreIsCalledOnce', (
      tester,
    ) async {
      final gateway = FakeAuthGateway();
      await openForm(tester, gateway: gateway);

      await submitForm(tester);

      expect(gateway.credentialChanges, hasLength(1));
      expect(gateway.credentialChanges.single.email, 'new@example.com');
    });

    testWidgets('GivenTheCoreAccepts_WhenItSettles_ThenTheChangeIsConfirmed', (
      tester,
    ) async {
      await openForm(tester);

      await submitForm(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ChangeCredentialsDialog)),
      );
      expect(find.text(l10n.changeCredentialsDone), findsOneWidget);
    });

    testWidgets('GivenTheCoreAccepts_WhenItSettles_ThenThePlaintextIsCleared', (
      tester,
    ) async {
      // FR-AU-11: the plaintext lives no longer than the call needs it.
      await openForm(tester);

      await submitForm(tester);

      expect(
        find.descendant(
          of: find.byType(ChangeCredentialsDialog),
          matching: find.byType(TextField),
        ),
        findsNothing,
        reason: 'the confirmed form replaces the fields entirely',
      );
    });

    testWidgets('GivenTheCoreAccepts_WhenItSettles_ThenTheOwnerStaysSignedIn', (
      tester,
    ) async {
      final container = await tester.pumpShell();
      await tester.tap(preferencesActionInShell());
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(PreferencesDialog)),
      );
      await tester.tap(find.text(l10n.changeCredentialsOpen));
      await tester.pumpAndSettle();

      await submitForm(tester);

      expect(find.byType(LoginScreen), findsNothing);
      expect(container.read(sessionControllerProvider), isA<SessionActive>());
    });
  });

  group('local validation (AF-01)', () {
    testWidgets(
      'GivenAMalformedEmail_WhenItIsSubmitted_ThenTheFieldIsMarkedAndNoCallIsMade',
      (tester) async {
        final gateway = FakeAuthGateway();
        await openForm(tester, gateway: gateway);

        await submitForm(tester, email: 'not-an-address');

        final l10n = AppLocalizations.of(
          tester.element(find.byType(ChangeCredentialsDialog)),
        );
        expect(find.text(l10n.loginEmailMalformed), findsOneWidget);
        expect(gateway.credentialChanges, isEmpty);
      },
    );

    testWidgets(
      'GivenPasswordsThatDiffer_WhenItIsSubmitted_ThenTheRepeatIsMarked',
      (tester) async {
        final gateway = FakeAuthGateway();
        await openForm(tester, gateway: gateway);

        await submitForm(tester, confirmation: 'a different passphrase');

        final l10n = AppLocalizations.of(
          tester.element(find.byType(ChangeCredentialsDialog)),
        );
        expect(find.text(l10n.signUpPasswordMismatch), findsOneWidget);
        expect(gateway.credentialChanges, isEmpty);
      },
    );
  });

  group('the core refuses', () {
    testWidgets(
      'GivenTheCoreRejectsTheSession_WhenItSettles_ThenTheOwnerReturnsToLogin',
      (tester) async {
        // AF-02.
        final gateway = FakeAuthGateway()
          ..changeOutcome = const CredentialChangeOutcome.failed(
            failure: Failure.unauthorized(
              family: CoreStatusFamily.auth,
              code: 2,
            ),
          );
        await openForm(tester, gateway: gateway);

        await submitForm(tester);

        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheCoreRejectsTheNewCredentials_WhenItSettles_ThenTheReasonIsShown',
      (tester) async {
        // AF-03.
        final gateway = FakeAuthGateway()
          ..changeOutcome = const CredentialChangeOutcome.failed(
            failure: Failure.invalidInput(
              family: CoreStatusFamily.auth,
              code: 1,
            ),
          );
        await openForm(tester, gateway: gateway);

        await submitForm(tester);

        final l10n = AppLocalizations.of(
          tester.element(find.byType(ChangeCredentialsDialog)),
        );
        expect(find.text(l10n.changeCredentialsRejected), findsOneWidget);
        expect(find.byType(ChangeCredentialsDialog), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheCoreNamesTheRule_WhenItRefuses_ThenTheOwnerReadsWhichRule',
      (tester) async {
        final gateway = FakeAuthGateway()
          ..changeOutcome = const CredentialChangeOutcome.failed(
            failure: Failure.rejected(
              family: CoreStatusFamily.auth,
              code: 1,
              rejection: CoreRejection(
                code: 'password_too_short',
                params: {'min': '12'},
              ),
            ),
          );
        await openForm(tester, gateway: gateway);

        await submitForm(tester, password: 'short', confirmation: 'short');

        final l10n = AppLocalizations.of(
          tester.element(find.byType(ChangeCredentialsDialog)),
        );
        expect(find.text(l10n.changeCredentialsRejected), findsNothing);
        expect(find.text(l10n.rejectionPasswordTooShort('12')), findsOneWidget);
      },
    );
  });

  group('themes, languages, and the keyboard', () {
    testWidgets('GivenTheForm_WhenItOpens_ThenTheFirstFieldTakesFocus', (
      tester,
    ) async {
      // FR-UX-11: usable from the keyboard alone.
      await openForm(tester);

      final first = tester.widget<TextField>(
        find
            .descendant(
              of: find.byType(ChangeCredentialsDialog),
              matching: find.byType(TextField),
            )
            .first,
      );
      expect(first.autofocus, isTrue);
    });

    for (final (name, mode) in [
      ('Light', ThemeMode.light),
      ('Dark', ThemeMode.dark),
    ]) {
      testWidgets(
        'GivenThe${name}Theme_WhenTheFormOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openForm(tester, themeMode: mode);

          expect(
            Theme.of(
              tester.element(find.byType(ChangeCredentialsDialog)),
            ).brightness,
            mode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final (name, locale) in [
      ('English', const Locale('en')),
      ('Portuguese', const Locale('pt', 'BR')),
    ]) {
      testWidgets('Given${name}_WhenTheFormOpens_ThenNoStringRendersAsItsKey', (
        tester,
      ) async {
        await openForm(tester, locale: locale);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ChangeCredentialsDialog)),
        );

        for (final label in [
          l10n.changeCredentialsTitle,
          l10n.changeCredentialsIntro,
          l10n.changeCredentialsSubmit,
        ]) {
          expect(label, isNotEmpty);
          expect(label, isNot(startsWith('changeCredentials')));
          expect(find.text(label), findsWidgets);
        }
      });
    }
  });
}
