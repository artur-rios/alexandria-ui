import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/application/login_controller.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_ui/features/auth/presentation/login_screen.dart';
import 'package:alexandria_ui/features/auth/presentation/recovery_codes_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/login_harness.dart';

/// Saving the recovery codes (UC-40, FR-AU-12, FR-AU-13, FR-AU-19).
void main() {
  const codes = ['aaaa-bbbb', 'cccc-dddd', 'eeee-ffff'];

  /// The strings the screen is rendering, in whichever language it was pumped
  /// in. Read from the widget tree rather than looked up, so a test that
  /// pumped Portuguese asserts Portuguese.
  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(RecoveryCodesScreen)));

  /// Signs up against a gateway that mints [minted], landing wherever
  /// registration leads.
  Future<ProviderContainer> signUp(
    WidgetTester tester, {
    List<String>? minted = codes,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final container = await tester.pumpSignUpScreen(
      locale: locale,
      themeMode: themeMode,
      gateway: FakeAuthGateway(
        outcome: AuthOutcome.authenticated(
          session: FakeAuthGateway.defaultSession,
          recoveryCodes: minted,
        ),
      ),
    );

    await tester.signUp();

    return container;
  }

  group('the main flow', () {
    // Steps 1 and 2: in place of the catalog, not beside it.
    testWidgets('GivenANewAccount_WhenItIsCreated_ThenTheCodesAreShown', (
      tester,
    ) async {
      await signUp(tester);

      expect(find.byType(RecoveryCodesScreen), findsOneWidget);
      expect(find.byType(ShellScreen), findsNothing);
      for (final code in codes) {
        expect(find.text(code), findsOneWidget);
      }
    });

    testWidgets('GivenTheCodes_WhenTheyAreShown_ThenItSaysThisIsTheOnlyTime', (
      tester,
    ) async {
      await signUp(tester);

      expect(
        find.text(messages(tester).recoveryCodesExplanation),
        findsOneWidget,
      );
    });

    // Steps 4 and 5.
    testWidgets('GivenTheCodes_WhenTheyAreAcknowledged_ThenTheCatalogOpens', (
      tester,
    ) async {
      await signUp(tester);

      await tester.tap(find.text(messages(tester).recoveryCodesAcknowledge));
      await tester.pumpAndSettle();

      expect(find.byType(ShellScreen), findsOneWidget);
      expect(find.byType(RecoveryCodesScreen), findsNothing);
    });

    // FR-AU-13: acknowledging drops them, and nothing kept a copy.
    testWidgets('GivenTheyAreAcknowledged_WhenTheStateIsRead_ThenTheyAreGone', (
      tester,
    ) async {
      final container = await signUp(tester);

      await tester.tap(find.text(messages(tester).recoveryCodesAcknowledge));
      await tester.pumpAndSettle();

      final state = container.read(sessionControllerProvider);
      expect((state as SessionActive).recoveryCodes, isNull);
    });
  });

  // AF-01: the acknowledgement is the only way past.
  group('a screen with no way around it', () {
    testWidgets('GivenTheCodes_WhenTheyAreShown_ThenTheCatalogIsNotReachable', (
      tester,
    ) async {
      final container = await signUp(tester);

      expect(
        catalogIsReachable(container.read(sessionControllerProvider)),
        isFalse,
      );
    });
  });

  // AF-02: onto the clipboard, and nowhere else.
  group('copying the codes', () {
    testWidgets('GivenTheCodes_WhenTheCopyIsAsked_ThenTheyReachTheClipboard', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await signUp(tester);
      await tester.tap(find.text(messages(tester).recoveryCodesCopy));
      await tester.pumpAndSettle();

      expect(copied, codes.join('\n'));
    });

    testWidgets('GivenTheCopyHappened_WhenItSettles_ThenTheOwnerIsTold', (
      tester,
    ) async {
      // Answered for here too: the notice follows the copy, so a test of the
      // notice must not depend on what a real clipboard would do.
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await signUp(tester);

      await tester.tap(find.text(messages(tester).recoveryCodesCopy));
      await tester.pumpAndSettle();

      expect(find.text(messages(tester).recoveryCodesCopied), findsOneWidget);
    });
  });

  // AF-03: the core issued none.
  group('an account created without codes', () {
    testWidgets('GivenNoCodes_WhenTheAccountIsCreated_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await signUp(tester, minted: const []);

      expect(find.text(messages(tester).recoveryCodesNone), findsOneWidget);
      expect(find.byType(ShellScreen), findsNothing);
    });

    testWidgets('GivenNoCodes_WhenTheOwnerContinues_ThenTheCatalogOpens', (
      tester,
    ) async {
      await signUp(tester, minted: const []);

      await tester.tap(find.text(messages(tester).recoveryCodesAcknowledge));
      await tester.pumpAndSettle();

      expect(find.byType(ShellScreen), findsOneWidget);
    });

    testWidgets('GivenNoCodes_WhenTheyAreShown_ThenNoCopyIsOffered', (
      tester,
    ) async {
      await signUp(tester, minted: const []);

      expect(find.text(messages(tester).recoveryCodesCopy), findsNothing);
    });
  });

  // AF-04: leaving without storing them.
  group('signing out from the prompt', () {
    testWidgets('GivenTheCodes_WhenTheOwnerSignsOut_ThenLoginIsPresented', (
      tester,
    ) async {
      final gateway = FakeAuthGateway(
        outcome: AuthOutcome.authenticated(
          session: FakeAuthGateway.defaultSession,
          recoveryCodes: codes,
        ),
      );
      final container = await tester.pumpSignUpScreen(gateway: gateway);
      await tester.signUp();

      // Nothing is told to the gateway here: registration itself is what
      // makes the account exist, and the entry screen follows from that
      // rather than from a second probe.

      await tester.tap(find.text(messages(tester).signOut));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(container.read(sessionControllerProvider), isA<SessionAbsent>());
    });
  });

  // A login mints nothing, so it must not stop here.
  group('an ordinary login', () {
    testWidgets('GivenAnExistingAccount_WhenTheOwnerLogsIn_ThenNoCodesShow', (
      tester,
    ) async {
      await tester.pumpLoginScreen();

      await tester.signIn();

      expect(find.byType(RecoveryCodesScreen), findsNothing);
      expect(find.byType(ShellScreen), findsOneWidget);
    });
  });

  group('themes and languages', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheCodesAreShown_ThenItRendersInThatBrightness',
        (tester) async {
          await signUp(tester, themeMode: themeMode);

          expect(
            Theme.of(
              tester.element(find.byType(RecoveryCodesScreen)),
            ).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheCodesAreShown_ThenNoStringRendersAsItsKey',
        (tester) async {
          await signUp(tester, locale: locale);

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
}
