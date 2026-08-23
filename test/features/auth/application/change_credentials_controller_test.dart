import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/auth/application/change_credentials_state.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_ui/features/auth/domain/login_validation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/test_container.dart';

/// Replacing the stored e-mail and password (UC-04, FR-AU-10).
void main() {
  /// A container with [gateway] bound and a session already established.
  ProviderContainer signedIn(FakeAuthGateway gateway) {
    final container = buildTestContainer(
      overrides: [
        ...fakeCoreOverrides(),
        authGatewayProvider.overrideWithValue(gateway),
      ],
    );
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);
    return container;
  }

  group('local validation (AF-01)', () {
    test(
      'GivenAMalformedEmail_WhenTheChangeIsSubmitted_ThenTheCoreIsNeverCalled',
      () async {
        final gateway = FakeAuthGateway();
        final container = signedIn(gateway);

        await container
            .read(changeCredentialsControllerProvider.notifier)
            .submit(
              email: 'not-an-address',
              password: 'a decent long passphrase',
              passwordConfirmation: 'a decent long passphrase',
            );

        expect(gateway.credentialChanges, isEmpty);
        expect(
          container.read(changeCredentialsControllerProvider),
          isA<ChangeCredentialsEditing>().having(
            (state) => state.emailError,
            'emailError',
            LoginFieldError.malformed,
          ),
        );
      },
    );

    test(
      'GivenAnEmptyPassword_WhenTheChangeIsSubmitted_ThenTheCoreIsNeverCalled',
      () async {
        final gateway = FakeAuthGateway();
        final container = signedIn(gateway);

        await container
            .read(changeCredentialsControllerProvider.notifier)
            .submit(
              email: 'owner@example.com',
              password: '',
              passwordConfirmation: '',
            );

        expect(gateway.credentialChanges, isEmpty);
        expect(
          container.read(changeCredentialsControllerProvider),
          isA<ChangeCredentialsEditing>().having(
            (state) => state.passwordError,
            'passwordError',
            LoginFieldError.missing,
          ),
        );
      },
    );

    test(
      'GivenPasswordsThatDiffer_WhenTheChangeIsSubmitted_ThenTheCoreIsNeverCalled',
      () async {
        final gateway = FakeAuthGateway();
        final container = signedIn(gateway);

        await container
            .read(changeCredentialsControllerProvider.notifier)
            .submit(
              email: 'owner@example.com',
              password: 'a decent long passphrase',
              passwordConfirmation: 'a different passphrase',
            );

        expect(gateway.credentialChanges, isEmpty);
        expect(
          container.read(changeCredentialsControllerProvider),
          isA<ChangeCredentialsEditing>().having(
            (state) => state.passwordConfirmationError,
            'passwordConfirmationError',
            LoginFieldError.mismatched,
          ),
        );
      },
    );

    test('GivenAVerdict_WhenTheOwnerEdits_ThenItIsCleared', () async {
      final gateway = FakeAuthGateway();
      final container = signedIn(gateway);
      final controller = container.read(
        changeCredentialsControllerProvider.notifier,
      );
      await controller.submit(
        email: 'not-an-address',
        password: '',
        passwordConfirmation: '',
      );

      controller.resetProblems();

      expect(
        container.read(changeCredentialsControllerProvider),
        const ChangeCredentialsState.editing(),
      );
    });
  });

  group('the main flow', () {
    test(
      'GivenAValidForm_WhenItIsSubmitted_ThenTheCoreIsCalledWithTheSession',
      () async {
        final gateway = FakeAuthGateway();
        final container = signedIn(gateway);

        await container
            .read(changeCredentialsControllerProvider.notifier)
            .submit(
              email: 'new@example.com',
              password: 'a decent long passphrase',
              passwordConfirmation: 'a decent long passphrase',
            );

        expect(gateway.credentialChanges, hasLength(1));
        expect(gateway.credentialChanges.single.email, 'new@example.com');
        expect(
          gateway.credentialChanges.single.credential,
          FakeAuthGateway.defaultSession.credential,
          reason: 'step 4 calls the core with the active session',
        );
      },
    );

    test(
      'GivenTheCoreAccepts_WhenTheChangeSettles_ThenItIsConfirmed',
      () async {
        final container = signedIn(FakeAuthGateway());

        await container
            .read(changeCredentialsControllerProvider.notifier)
            .submit(
              email: 'new@example.com',
              password: 'a decent long passphrase',
              passwordConfirmation: 'a decent long passphrase',
            );

        expect(
          container.read(changeCredentialsControllerProvider),
          isA<ChangeCredentialsChanged>(),
        );
      },
    );

    test(
      'GivenTheCoreAccepts_WhenTheChangeSettles_ThenTheSessionSurvives',
      () async {
        // The postcondition: the existing session remains valid.
        final container = signedIn(FakeAuthGateway());
        final before = container.read(sessionControllerProvider);

        await container
            .read(changeCredentialsControllerProvider.notifier)
            .submit(
              email: 'new@example.com',
              password: 'a decent long passphrase',
              passwordConfirmation: 'a decent long passphrase',
            );

        expect(container.read(sessionControllerProvider), before);
        expect(container.read(sessionControllerProvider), isA<SessionActive>());
      },
    );

    test(
      'GivenAnAttemptInFlight_WhenItIsSubmittedAgain_ThenOnlyOneCallIsMade',
      () async {
        final gateway = FakeAuthGateway()..hold();
        final container = signedIn(gateway);
        final controller = container.read(
          changeCredentialsControllerProvider.notifier,
        );

        final first = controller.submit(
          email: 'new@example.com',
          password: 'a decent long passphrase',
          passwordConfirmation: 'a decent long passphrase',
        );
        await controller.submit(
          email: 'new@example.com',
          password: 'a decent long passphrase',
          passwordConfirmation: 'a decent long passphrase',
        );
        gateway.release();
        await first;

        expect(gateway.credentialChanges, hasLength(1));
      },
    );
  });

  group('the core refuses', () {
    test(
      'GivenTheCoreRejectsTheSession_WhenTheChangeIsSubmitted_ThenTheOwnerIsSignedOut',
      () async {
        // AF-02.
        const failure = Failure.unauthorized(
          family: CoreStatusFamily.auth,
          code: 2,
        );
        final gateway = FakeAuthGateway()
          ..changeOutcome = const CredentialChangeOutcome.failed(
            failure: failure,
          );
        final container = signedIn(gateway);

        await container
            .read(changeCredentialsControllerProvider.notifier)
            .submit(
              email: 'new@example.com',
              password: 'a decent long passphrase',
              passwordConfirmation: 'a decent long passphrase',
            );

        expect(
          container.read(sessionControllerProvider),
          const SessionState.absent(endedBecause: failure),
        );
      },
    );

    test(
      'GivenTheCoreRejectsTheNewCredentials_WhenItSettles_ThenTheReasonIsShown',
      () async {
        // AF-03: the stored credentials are left alone and the owner reads why.
        const failure = Failure.invalidInput(
          family: CoreStatusFamily.auth,
          code: 1,
        );
        final gateway = FakeAuthGateway()
          ..changeOutcome = const CredentialChangeOutcome.failed(
            failure: failure,
          );
        final container = signedIn(gateway);

        await container
            .read(changeCredentialsControllerProvider.notifier)
            .submit(
              email: 'new@example.com',
              password: 'short',
              passwordConfirmation: 'short',
            );

        expect(
          container.read(changeCredentialsControllerProvider),
          const ChangeCredentialsState.editing(problem: failure),
        );
      },
    );

    test(
      'GivenTheCoreRejectsTheNewCredentials_WhenItSettles_ThenTheSessionSurvives',
      () async {
        // AF-03 is not AF-02: a refused password must not sign the owner out.
        final gateway = FakeAuthGateway()
          ..changeOutcome = const CredentialChangeOutcome.failed(
            failure: Failure.invalidInput(
              family: CoreStatusFamily.auth,
              code: 1,
            ),
          );
        final container = signedIn(gateway);

        await container
            .read(changeCredentialsControllerProvider.notifier)
            .submit(
              email: 'new@example.com',
              password: 'short',
              passwordConfirmation: 'short',
            );

        expect(container.read(sessionControllerProvider), isA<SessionActive>());
      },
    );
  });

  test(
    'GivenNoSession_WhenAChangeIsSubmitted_ThenTheCoreIsNeverCalled',
    () async {
      // Defensive: the form is only offered inside a session.
      final gateway = FakeAuthGateway();
      final container = buildTestContainer(
        overrides: [
          ...fakeCoreOverrides(),
          authGatewayProvider.overrideWithValue(gateway),
        ],
      );

      await container
          .read(changeCredentialsControllerProvider.notifier)
          .submit(
            email: 'new@example.com',
            password: 'a decent long passphrase',
            passwordConfirmation: 'a decent long passphrase',
          );

      expect(gateway.credentialChanges, isEmpty);
    },
  );
}
