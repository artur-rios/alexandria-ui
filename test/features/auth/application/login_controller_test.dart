import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/auth/application/login_controller.dart';
import 'package:alexandria_ui/features/auth/application/login_state.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_ui/features/auth/domain/login_validation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/test_container.dart';

void main() {
  /// A container whose only outward dependency is [gateway].
  ///
  /// The startup providers are faked too, because the real gateway provider
  /// reads the loaded core — overriding it here is what keeps this a unit test
  /// with no native library in sight.
  ProviderContainer containerWith(FakeAuthGateway gateway) {
    final container = buildTestContainer(
      overrides: [
        ...fakeCoreOverrides(),
        authGatewayProvider.overrideWithValue(gateway),
      ],
    );
    // No startup ever runs over this container, so it is honest about never
    // having a core to re-check against: a successful login's own unawaited
    // call to `begin()` (FR-LB-21) would otherwise reach for one that was
    // never loaded, over a scenario this suite has nothing to do with.
    container
        .read(preferencesControllerProvider.notifier)
        .setRechecksAtStartup(false);
    return container;
  }

  LoginState stateOf(ProviderContainer container) =>
      container.read(loginControllerProvider);

  LoginEditing editingState(ProviderContainer container) {
    final state = stateOf(container);
    expect(state, isA<LoginEditing>());
    return state as LoginEditing;
  }

  Future<void> submitValid(ProviderContainer container) => container
      .read(loginControllerProvider.notifier)
      .submit(email: 'owner@example.com', password: 'correct horse');

  group('the main flow', () {
    test(
      'GivenTheCoreAcceptsTheCredentials_WhenTheOwnerSubmits_ThenTheSessionIsEstablished',
      () async {
        final container = containerWith(FakeAuthGateway());

        await submitValid(container);

        expect(container.read(sessionControllerProvider), isA<SessionActive>());
      },
    );

    test(
      'GivenTheCoreAcceptsTheCredentials_WhenTheOwnerSubmits_ThenTheFormIsLeftClean',
      () async {
        final container = containerWith(FakeAuthGateway());

        await submitValid(container);

        expect(editingState(container).problem, isNull);
      },
    );

    test(
      'GivenAValidForm_WhenTheOwnerSubmits_ThenTheCoreIsCalledWithWhatWasTyped',
      () async {
        final gateway = FakeAuthGateway();
        final container = containerWith(gateway);

        await submitValid(container);

        expect(gateway.calls.single, (
          email: 'owner@example.com',
          password: 'correct horse',
        ));
      },
    );

    test(
      'GivenAnAttemptInFlight_WhenTheStateIsRead_ThenItIsSubmitting',
      () async {
        final gateway = FakeAuthGateway()..hold();
        final container = containerWith(gateway);

        final attempt = submitValid(container);
        await Future<void>.delayed(Duration.zero);

        expect(stateOf(container), isA<LoginSubmitting>());

        gateway.release();
        await attempt;
      },
    );

    // NFR-10 and a plain double-click: a second attempt must not start while
    // the first is still in flight.
    test(
      'GivenAnAttemptInFlight_WhenTheOwnerSubmitsAgain_ThenTheCoreIsCalledOnlyOnce',
      () async {
        final gateway = FakeAuthGateway()..hold();
        final container = containerWith(gateway);

        final first = submitValid(container);
        await Future<void>.delayed(Duration.zero);
        await submitValid(container);

        expect(gateway.calls, hasLength(1));

        gateway.release();
        await first;
      },
    );
  });

  // UC-02 AF-01. The assertion that matters in every one of these is that the
  // core was not called.
  group('AF-01 — the form is not submittable', () {
    test(
      'GivenAMalformedEmail_WhenTheOwnerSubmits_ThenTheCoreIsNeverCalled',
      () async {
        final gateway = FakeAuthGateway();
        final container = containerWith(gateway);

        await container
            .read(loginControllerProvider.notifier)
            .submit(email: 'not-an-email', password: 'correct horse');

        expect(gateway.calls, isEmpty);
      },
    );

    test(
      'GivenAMalformedEmail_WhenTheOwnerSubmits_ThenTheEmailFieldIsMarked',
      () async {
        final container = containerWith(FakeAuthGateway());

        await container
            .read(loginControllerProvider.notifier)
            .submit(email: 'not-an-email', password: 'correct horse');

        expect(editingState(container).emailError, LoginFieldError.malformed);
      },
    );

    test(
      'GivenAnEmptyPassword_WhenTheOwnerSubmits_ThenTheCoreIsNeverCalled',
      () async {
        final gateway = FakeAuthGateway();
        final container = containerWith(gateway);

        await container
            .read(loginControllerProvider.notifier)
            .submit(email: 'owner@example.com', password: '');

        expect(gateway.calls, isEmpty);
      },
    );

    test(
      'GivenAnEmptyPassword_WhenTheOwnerSubmits_ThenThePasswordFieldIsMarked',
      () async {
        final container = containerWith(FakeAuthGateway());

        await container
            .read(loginControllerProvider.notifier)
            .submit(email: 'owner@example.com', password: '');

        expect(editingState(container).passwordError, LoginFieldError.missing);
      },
    );

    test(
      'GivenBothFieldsEmpty_WhenTheOwnerSubmits_ThenBothAreMarked',
      () async {
        final container = containerWith(FakeAuthGateway());

        await container
            .read(loginControllerProvider.notifier)
            .submit(email: '', password: '');

        final state = editingState(container);
        expect(
          (state.emailError, state.passwordError),
          (LoginFieldError.missing, LoginFieldError.missing),
        );
      },
    );

    test(
      'GivenAnInvalidForm_WhenTheOwnerSubmits_ThenNoSessionIsEstablished',
      () async {
        final container = containerWith(FakeAuthGateway());

        await container
            .read(loginControllerProvider.notifier)
            .submit(email: '', password: '');

        expect(container.read(sessionControllerProvider), isA<SessionAbsent>());
      },
    );

    test(
      'GivenAMarkedField_WhenAValidAttemptIsSubmitted_ThenTheMarkIsCleared',
      () async {
        final container = containerWith(FakeAuthGateway());
        final controller = container.read(loginControllerProvider.notifier);

        await controller.submit(email: '', password: '');
        await submitValid(container);

        expect(editingState(container).emailError, isNull);
      },
    );
  });

  group('the failures the core reports', () {
    Future<LoginProblem?> problemFrom(Failure failure) async {
      final container = containerWith(FakeAuthGateway.failing(failure));
      await submitValid(container);
      return editingState(container).problem;
    }

    // AF-02.
    test(
      'GivenTheCoreRejectsTheCredentials_WhenTheOwnerSubmits_ThenTheAttemptIsRejected',
      () async {
        expect(
          await problemFrom(
            const Failure.unauthorized(family: CoreStatusFamily.auth, code: 2),
          ),
          const LoginProblem.rejected(),
        );
      },
    );

    test(
      'GivenTheCoreRejectsTheCredentials_WhenTheOwnerSubmits_ThenNoSessionIsEstablished',
      () async {
        final container = containerWith(
          FakeAuthGateway.failing(
            const Failure.unauthorized(family: CoreStatusFamily.auth, code: 2),
          ),
        );

        await submitValid(container);

        expect(container.read(sessionControllerProvider), isA<SessionAbsent>());
      },
    );

    // AF-03. The core answers a configuration failure when local credentials
    // have never been set.
    test(
      'GivenNoAccountExists_WhenTheOwnerSubmits_ThenItIsReportedAsNoAccount',
      () async {
        expect(
          await problemFrom(
            const Failure.configuration(family: CoreStatusFamily.auth, code: 8),
          ),
          const LoginProblem.noAccount(),
        );
      },
    );

    // AF-05.
    test(
      'GivenTheCoreIsNotInitialized_WhenTheOwnerSubmits_ThenItIsReportedAsNotReady',
      () async {
        const failure = Failure.notInitialized(
          family: CoreStatusFamily.auth,
          code: 3,
        );

        expect(
          await problemFrom(failure),
          const LoginProblem.coreNotReady(failure: failure),
        );
      },
    );

    test(
      'GivenAnUnrecognizedFailure_WhenTheOwnerSubmits_ThenItIsStillReported',
      () async {
        const failure = Failure.unexpected(
          family: CoreStatusFamily.auth,
          code: 4242,
        );

        expect(
          await problemFrom(failure),
          const LoginProblem.other(failure: failure),
        );
      },
    );

    test(
      'GivenARefusedAttempt_WhenTheOwnerSubmitsAgainSuccessfully_ThenTheProblemIsCleared',
      () async {
        final gateway = FakeAuthGateway.failing(
          const Failure.unauthorized(family: CoreStatusFamily.auth, code: 2),
        );
        final container = containerWith(gateway);

        await submitValid(container);
        gateway.outcome = AuthOutcome.authenticated(
          session: FakeAuthGateway.defaultSession,
        );
        await submitValid(container);

        expect(editingState(container).problem, isNull);
      },
    );
  });

  // FR-AU-07. The core dropped e-mail confirmation on 2026-08-18, so a
  // session is the whole of the question now; the branch that used to lock a
  // confirmed-but-unverified owner out has nothing left to read.
  group('the catalog lock', () {
    test('GivenASession_WhenTheLockIsChecked_ThenTheCatalogIsReachable', () {
      expect(
        catalogIsReachable(
          SessionState.active(session: FakeAuthGateway.defaultSession),
        ),
        isTrue,
      );
    });

    test('GivenNoSession_WhenTheLockIsChecked_ThenTheCatalogIsLocked', () {
      expect(catalogIsReachable(const SessionState.absent()), isFalse);
    });
  });
}
