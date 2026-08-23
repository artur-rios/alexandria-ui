import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/auth/application/sign_up_state.dart';
import 'package:alexandria_ui/features/auth/domain/login_validation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/test_container.dart';

void main() {
  const goodPassword = 'a decent long passphrase';

  ProviderContainer containerWith(FakeAuthGateway gateway) =>
      buildTestContainer(
        overrides: [
          ...fakeCoreOverrides(),
          authGatewayProvider.overrideWithValue(gateway),
        ],
      );

  SignUpEditing editingState(ProviderContainer container) {
    final state = container.read(signUpControllerProvider);
    expect(state, isA<SignUpEditing>());
    return state as SignUpEditing;
  }

  Future<void> submitValid(ProviderContainer container) => container
      .read(signUpControllerProvider.notifier)
      .submit(
        email: 'owner@example.com',
        password: goodPassword,
        passwordConfirmation: goodPassword,
      );

  group('the main flow', () {
    test(
      'GivenTheCoreCreatesTheAccount_WhenTheOwnerSignsUp_ThenTheSessionIsEstablished',
      () async {
        final container = containerWith(FakeAuthGateway());

        await submitValid(container);

        expect(container.read(sessionControllerProvider), isA<SessionActive>());
      },
    );

    test(
      'GivenAValidForm_WhenTheOwnerSignsUp_ThenTheCoreReceivesWhatWasTyped',
      () async {
        final gateway = FakeAuthGateway();
        final container = containerWith(gateway);

        await submitValid(container);

        expect(gateway.registrations.single, (
          email: 'owner@example.com',
          password: goodPassword,
          passwordConfirmation: goodPassword,
        ));
      },
    );

    test(
      'GivenTheCoreCreatesTheAccount_WhenTheOwnerSignsUp_ThenTheFormIsLeftClean',
      () async {
        final container = containerWith(FakeAuthGateway());

        await submitValid(container);

        expect(editingState(container).problem, isNull);
      },
    );

    // More important here than on login: a second call would either create a
    // second account or be refused as a conflict caused by the first.
    test(
      'GivenAnAttemptInFlight_WhenTheOwnerSubmitsAgain_ThenTheCoreIsCalledOnlyOnce',
      () async {
        final gateway = FakeAuthGateway()..hold();
        final container = containerWith(gateway);

        final first = submitValid(container);
        await Future<void>.delayed(Duration.zero);
        await submitValid(container);

        expect(gateway.registrations, hasLength(1));

        gateway.release();
        await first;
      },
    );

    test(
      'GivenAnAttemptInFlight_WhenTheStateIsRead_ThenItIsSubmitting',
      () async {
        final gateway = FakeAuthGateway()..hold();
        final container = containerWith(gateway);

        final attempt = submitValid(container);
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(signUpControllerProvider),
          isA<SignUpSubmitting>(),
        );

        gateway.release();
        await attempt;
      },
    );
  });

  // UC-01 AF-01 and AF-02. The assertion that matters in every one of these is
  // that the core was not called.
  group('the form rejects itself', () {
    Future<void> submit(
      ProviderContainer container, {
      String email = 'owner@example.com',
      String password = goodPassword,
      String? confirmation,
    }) => container
        .read(signUpControllerProvider.notifier)
        .submit(
          email: email,
          password: password,
          passwordConfirmation: confirmation ?? password,
        );

    test(
      'GivenAMalformedEmail_WhenTheOwnerSignsUp_ThenTheCoreIsNeverCalled',
      () async {
        final gateway = FakeAuthGateway();
        final container = containerWith(gateway);

        await submit(container, email: 'not-an-email');

        expect(gateway.registrations, isEmpty);
        expect(editingState(container).emailError, LoginFieldError.malformed);
      },
    );

    test(
      'GivenAnEmptyPassword_WhenTheOwnerSignsUp_ThenTheCoreIsNeverCalled',
      () async {
        final gateway = FakeAuthGateway();
        final container = containerWith(gateway);

        await submit(container, password: '');

        expect(gateway.registrations, isEmpty);
        expect(editingState(container).passwordError, LoginFieldError.missing);
      },
    );

    // AF-02.
    test(
      'GivenTheTwoEntriesDiffer_WhenTheOwnerSignsUp_ThenTheCoreIsNeverCalled',
      () async {
        final gateway = FakeAuthGateway();
        final container = containerWith(gateway);

        await submit(container, confirmation: 'something else entirely');

        expect(gateway.registrations, isEmpty);
      },
    );

    test(
      'GivenTheTwoEntriesDiffer_WhenTheOwnerSignsUp_ThenTheConfirmationFieldIsMarked',
      () async {
        final container = containerWith(FakeAuthGateway());

        await submit(container, confirmation: 'something else entirely');

        expect(
          editingState(container).passwordConfirmationError,
          LoginFieldError.mismatched,
        );
      },
    );

    // The mismatch belongs to the repeat field alone: marking the first as
    // wrong too would tell the owner to change the password they meant.
    test(
      'GivenTheTwoEntriesDiffer_WhenTheOwnerSignsUp_ThenTheFirstPasswordIsNotMarked',
      () async {
        final container = containerWith(FakeAuthGateway());

        await submit(container, confirmation: 'something else entirely');

        expect(editingState(container).passwordError, isNull);
      },
    );

    test(
      'GivenAnEmptyConfirmation_WhenTheOwnerSignsUp_ThenTheConfirmationIsMarkedAsMissing',
      () async {
        final container = containerWith(FakeAuthGateway());

        await submit(container, confirmation: '');

        expect(
          editingState(container).passwordConfirmationError,
          LoginFieldError.missing,
        );
      },
    );

    test(
      'GivenAnInvalidForm_WhenTheOwnerSignsUp_ThenNoSessionIsEstablished',
      () async {
        final container = containerWith(FakeAuthGateway());

        await submit(container, email: '');

        expect(container.read(sessionControllerProvider), isA<SessionAbsent>());
      },
    );

    test(
      'GivenAMarkedField_WhenAValidAttemptIsSubmitted_ThenTheMarkIsCleared',
      () async {
        final container = containerWith(FakeAuthGateway());

        await submit(container, email: 'not-an-email');
        await submitValid(container);

        expect(editingState(container).emailError, isNull);
      },
    );
  });

  group('the failures the core reports', () {
    Future<SignUpProblem?> problemFrom(Failure failure) async {
      final container = containerWith(FakeAuthGateway.failing(failure));
      await submitValid(container);
      return editingState(container).problem;
    }

    // AF-04.
    test(
      'GivenAnAccountAlreadyExists_WhenTheOwnerSignsUp_ThenThatIsReported',
      () async {
        expect(
          await problemFrom(
            const Failure.conflict(family: CoreStatusFamily.auth, code: 10),
          ),
          const SignUpProblem.accountExists(),
        );
      },
    );

    test(
      'GivenAnAccountAlreadyExists_WhenTheOwnerSignsUp_ThenNoSessionIsEstablished',
      () async {
        final container = containerWith(
          FakeAuthGateway.failing(
            const Failure.conflict(family: CoreStatusFamily.auth, code: 10),
          ),
        );

        await submitValid(container);

        expect(container.read(sessionControllerProvider), isA<SessionAbsent>());
      },
    );

    // AF-03: the core's strength policy refused the password.
    test(
      'GivenTheCoreRefusesTheCredentials_WhenTheOwnerSignsUp_ThenItIsReportedAsRejected',
      () async {
        expect(
          await problemFrom(
            const Failure.invalidInput(family: CoreStatusFamily.auth, code: 1),
          ),
          const SignUpProblem.rejected(),
        );
      },
    );

    // AF-05.
    test(
      'GivenTheCoreReportsAConfigurationFailure_WhenTheOwnerSignsUp_ThenARetryIsOffered',
      () async {
        const failure = Failure.configuration(
          family: CoreStatusFamily.auth,
          code: 8,
        );

        expect(
          await problemFrom(failure),
          const SignUpProblem.configuration(failure: failure),
        );
      },
    );

    test(
      'GivenTheCoreIsNotInitialized_WhenTheOwnerSignsUp_ThenARetryIsOffered',
      () async {
        const failure = Failure.notInitialized(
          family: CoreStatusFamily.auth,
          code: 3,
        );

        expect(
          await problemFrom(failure),
          const SignUpProblem.configuration(failure: failure),
        );
      },
    );

    test(
      'GivenAnUnrecognizedFailure_WhenTheOwnerSignsUp_ThenItIsStillReported',
      () async {
        const failure = Failure.unexpected(
          family: CoreStatusFamily.auth,
          code: 4242,
        );

        expect(
          await problemFrom(failure),
          const SignUpProblem.other(failure: failure),
        );
      },
    );
  });
}
