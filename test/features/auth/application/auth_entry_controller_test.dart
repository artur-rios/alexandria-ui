import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/auth/application/auth_entry_controller.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/test_container.dart';

/// FR-AU-01 and UC-01 main flow step 1: which screen a session-less owner is
/// shown is decided from the core, not guessed.
void main() {
  ProviderContainer containerWith(AccountExistence existence) {
    final gateway = FakeAuthGateway()..existence = existence;
    return buildTestContainer(
      overrides: [
        ...fakeCoreOverrides(),
        authGatewayProvider.overrideWithValue(gateway),
      ],
    );
  }

  /// Reads the entry point after the probe has had a turn to settle.
  Future<AuthEntry> entryOf(ProviderContainer container) async {
    container.read(authEntryProvider);
    await Future<void>.delayed(Duration.zero);
    return container.read(authEntryProvider);
  }

  test(
    'GivenNothingHasBeenAsked_WhenTheEntryPointIsFirstRead_ThenItIsStillResolving',
    () {
      expect(
        containerWith(AccountExistence.absent).read(authEntryProvider),
        AuthEntry.resolving,
      );
    },
  );

  test(
    'GivenTheCoreHoldsNoAccount_WhenTheProbeSettles_ThenSignUpIsPresented',
    () async {
      expect(
        await entryOf(containerWith(AccountExistence.absent)),
        AuthEntry.signUp,
      );
    },
  );

  test(
    'GivenTheCoreHoldsAnAccount_WhenTheProbeSettles_ThenLoginIsPresented',
    () async {
      expect(
        await entryOf(containerWith(AccountExistence.present)),
        AuthEntry.login,
      );
    },
  );

  // Login is the screen that recovers on its own: its AF-03 sends the owner to
  // sign-up if the core turns out to hold nothing. Guessing the other way
  // would offer to create an account over one that already exists.
  test(
    'GivenTheCoreCannotAnswer_WhenTheProbeSettles_ThenLoginIsPresented',
    () async {
      expect(
        await entryOf(containerWith(AccountExistence.unknown)),
        AuthEntry.login,
      );
    },
  );

  // UC-01 AF-04.
  test(
    'GivenSignUpIsPresented_WhenAnAccountTurnsOutToExist_ThenLoginCanBeReached',
    () async {
      final container = containerWith(AccountExistence.absent);
      await entryOf(container);

      container.read(authEntryProvider.notifier).goToLogin();

      expect(container.read(authEntryProvider), AuthEntry.login);
    },
  );

  // UC-02 AF-03.
  test(
    'GivenLoginIsPresented_WhenNoAccountTurnsOutToExist_ThenSignUpCanBeReached',
    () async {
      final container = containerWith(AccountExistence.present);
      await entryOf(container);

      container.read(authEntryProvider.notifier).goToSignUp();

      expect(container.read(authEntryProvider), AuthEntry.signUp);
    },
  );
}
