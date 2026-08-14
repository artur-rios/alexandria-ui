import 'package:alexandria_desktop/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_desktop/features/auth/domain/session.dart';
import 'package:alexandria_desktop/features/auth/presentation/catalog_locked_screen.dart';
import 'package:alexandria_desktop/features/auth/presentation/login_screen.dart';
import 'package:alexandria_desktop/features/auth/presentation/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/login_harness.dart';

/// The theme and layout of the screens an owner meets before the catalog
/// (Testing Specification §3, §7.1).
///
/// These assert what the other widget suites cannot: that the screen *looks*
/// right in both themes. They deliberately do not assert text — `flutter test`
/// loads no real font, so every string renders as a box, and what the strings
/// say is covered by `login_screen_test.dart` and `sign_up_screen_test.dart`
/// in both languages. What a golden catches is a color that changed, a control
/// that moved, a field that resized, and a dark theme that stopped being dark.
///
/// Regenerate with `flutter test --update-goldens`, and **look at the images in
/// the pull request**. §7.1 is explicit that a golden updated without being
/// looked at is worse than no golden.
void main() {
  /// One fixed size for every golden, so a change in the image is a change in
  /// the screen rather than in the window it was captured at.
  const surface = Size(1280, 800);

  /// An unconfirmed session, which is what stands the catalog lock up.
  final unconfirmed = FakeAuthGateway(
    outcome: AuthOutcome.authenticated(
      session: Session(
        credential: 'a-real-looking-session-id',
        establishedAt: DateTime.utc(2026, 8, 12, 9, 30),
        emailConfirmed: false,
        email: 'owner@example.com',
      ),
    ),
  );

  for (final (name, mode) in [
    ('Light', ThemeMode.light),
    ('Dark', ThemeMode.dark),
  ]) {
    testWidgets('GivenThe${name}Theme_WhenLoginIsShown_ThenItMatchesItsGolden', (
      tester,
    ) async {
      await tester.pumpLoginScreen(themeMode: mode, surfaceSize: surface);

      await expectLater(
        find.byType(LoginScreen),
        matchesGoldenFile('goldens/login_${mode.name}.png'),
      );
    });

    testWidgets(
      'GivenThe${name}Theme_WhenSignUpIsShown_ThenItMatchesItsGolden',
      (tester) async {
        await tester.pumpSignUpScreen(themeMode: mode, surfaceSize: surface);

        await expectLater(
          find.byType(SignUpScreen),
          matchesGoldenFile('goldens/sign_up_${mode.name}.png'),
        );
      },
    );

    testWidgets(
      'GivenThe${name}Theme_WhenTheCatalogIsLocked_ThenItMatchesItsGolden',
      (tester) async {
        await tester.pumpSignUpScreen(
          gateway: unconfirmed,
          themeMode: mode,
          surfaceSize: surface,
        );
        await tester.signUp();

        await expectLater(
          find.byType(CatalogLockedScreen),
          matchesGoldenFile('goldens/catalog_locked_${mode.name}.png'),
        );
      },
    );
  }
}
