import 'dart:convert';

import 'package:alexandria_desktop/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_desktop/core/failures/failure.dart';
import 'package:alexandria_desktop/features/auth/data/core_auth_gateway.dart';
import 'package:alexandria_desktop/features/auth/domain/auth_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_core_client.dart';

void main() {
  final establishedAt = DateTime.utc(2026, 8, 12, 9, 30);

  CoreAuthGateway buildGateway(FakeCoreClient core) =>
      CoreAuthGateway(core, now: () => establishedAt);

  Future<AuthOutcome> logInWith(FakeCoreClient core) => buildGateway(
    core,
  ).logIn(email: 'owner@example.com', password: 'correct horse');

  /// The failure a login attempt produced, or a failed expectation if it
  /// authenticated instead.
  Failure failureOf(AuthOutcome outcome) {
    expect(outcome, isA<FailedOutcome>());
    return (outcome as FailedOutcome).failure;
  }

  group('the happy path', () {
    test(
      'GivenCredentialsTheCoreAccepts_WhenTheOwnerLogsIn_ThenASessionIsReturned',
      () async {
        final outcome = await logInWith(FakeCoreClient());

        expect(outcome, isA<AuthenticatedOutcome>());
      },
    );

    test(
      'GivenCredentialsTheCoreAccepts_WhenTheOwnerLogsIn_ThenTheSessionCarriesTheCoresSessionId',
      () async {
        final outcome = await logInWith(FakeCoreClient());

        expect(
          (outcome as AuthenticatedOutcome).session.credential,
          '6f1c9d02-1f3b-4f3a-9a7e-0b1d2c3e4f50',
        );
      },
    );

    test(
      'GivenCredentialsTheCoreAccepts_WhenTheOwnerLogsIn_ThenTheSessionCarriesTheAddressTyped',
      () async {
        final outcome = await logInWith(FakeCoreClient());

        expect(
          (outcome as AuthenticatedOutcome).session.email,
          'owner@example.com',
        );
      },
    );

    test(
      'GivenCredentialsTheCoreAccepts_WhenTheOwnerLogsIn_ThenTheSessionIsStampedWithTheInjectedClock',
      () async {
        final outcome = await logInWith(FakeCoreClient());

        expect(
          (outcome as AuthenticatedOutcome).session.establishedAt,
          establishedAt,
        );
      },
    );

    test(
      'GivenAnAddressPaddedWithSpaces_WhenTheOwnerLogsIn_ThenTheCoreReceivesItTrimmed',
      () async {
        final core = FakeCoreClient();

        await buildGateway(core).logIn(
          email: '  owner@example.com  ',
          password: 'correct horse',
        );

        expect(
          jsonDecode(core.authLocalLoginBodies.single),
          containsPair('email', 'owner@example.com'),
        );
      },
    );

    test(
      'GivenAPassword_WhenTheOwnerLogsIn_ThenTheCoreReceivesItUnchanged',
      () async {
        final core = FakeCoreClient();

        await logInWith(core);

        expect(
          jsonDecode(core.authLocalLoginBodies.single),
          containsPair('password', 'correct horse'),
        );
      },
    );
  });

  group('the failures the core reports', () {
    // UC-02 AF-02. The core answers the same code for an unknown address and a
    // wrong password, which is what makes the requirement that the message not
    // distinguish them hold structurally rather than by convention.
    test(
      'GivenTheCoreRejectsTheCredentials_WhenTheOwnerLogsIn_ThenItIsUnauthorized',
      () async {
        final outcome = await logInWith(
          FakeCoreClient(
            authLocalLoginResult: (
              status: AUTH_ERR_UNAUTHORIZED,
              json: null,
            ),
          ),
        );

        expect(failureOf(outcome), isA<UnauthorizedFailure>());
      },
    );

    // UC-02 AF-03. The core returns a config error when local credentials have
    // never been set — see the `ok_or_else` in the core's login command.
    test(
      'GivenNoAccountHasBeenSetUp_WhenTheOwnerLogsIn_ThenItIsAConfigurationFailure',
      () async {
        final outcome = await logInWith(
          FakeCoreClient(
            authLocalLoginResult: (status: AUTH_ERR_CONFIG, json: null),
          ),
        );

        expect(failureOf(outcome), isA<ConfigurationFailure>());
      },
    );

    // UC-02 AF-05.
    test(
      'GivenTheCoreIsNotInitialized_WhenTheOwnerLogsIn_ThenItIsANotInitializedFailure',
      () async {
        final outcome = await logInWith(
          FakeCoreClient(
            authLocalLoginResult: (
              status: AUTH_ERR_NOT_INITIALIZED,
              json: null,
            ),
          ),
        );

        expect(failureOf(outcome), isA<NotInitializedFailure>());
      },
    );

    test(
      'GivenTheCoreRejectsTheBody_WhenTheOwnerLogsIn_ThenItIsAnInvalidInputFailure',
      () async {
        final outcome = await logInWith(
          FakeCoreClient(
            authLocalLoginResult: (status: AUTH_ERR_INVALID_INPUT, json: null),
          ),
        );

        expect(failureOf(outcome), isA<InvalidInputFailure>());
      },
    );

    test(
      'GivenTheCoreReportsAnInvalidState_WhenTheOwnerLogsIn_ThenItIsAnInvalidStateFailure',
      () async {
        final outcome = await logInWith(
          FakeCoreClient(
            authLocalLoginResult: (status: AUTH_ERR_INVALID_STATE, json: null),
          ),
        );

        expect(failureOf(outcome), isA<InvalidStateFailure>());
      },
    );

    // Keeps the mapping total: a core that grows a code this version has not
    // caught up with still produces a readable message (IR-08).
    test(
      'GivenAStatusCodeThisVersionDoesNotKnow_WhenTheOwnerLogsIn_ThenItIsUnexpected',
      () async {
        final outcome = await logInWith(
          FakeCoreClient(authLocalLoginResult: (status: 4242, json: null)),
        );

        expect(failureOf(outcome), isA<UnexpectedFailure>());
      },
    );

    test(
      'GivenTheCallCannotBeMadeAtAll_WhenTheOwnerLogsIn_ThenItIsUnexpectedRatherThanThrowing',
      () async {
        final outcome = await logInWith(
          FakeCoreClient(failOnAuthLocalLogin: true),
        );

        expect(failureOf(outcome), isA<UnexpectedFailure>());
      },
    );
  });

  group('payloads that cannot be trusted', () {
    test(
      'GivenSuccessWithNoPayload_WhenTheOwnerLogsIn_ThenNoSessionIsEstablished',
      () async {
        final outcome = await logInWith(
          FakeCoreClient(authLocalLoginResult: (status: AUTH_OK, json: null)),
        );

        expect(failureOf(outcome), isA<UnexpectedFailure>());
      },
    );

    test(
      'GivenSuccessWithAMalformedPayload_WhenTheOwnerLogsIn_ThenNoSessionIsEstablished',
      () async {
        final outcome = await logInWith(
          FakeCoreClient(
            authLocalLoginResult: (status: AUTH_OK, json: 'not json at all'),
          ),
        );

        expect(failureOf(outcome), isA<UnexpectedFailure>());
      },
    );

    test(
      'GivenSuccessWithNoSessionId_WhenTheOwnerLogsIn_ThenNoSessionIsEstablished',
      () async {
        final outcome = await logInWith(
          FakeCoreClient(
            authLocalLoginResult: (status: AUTH_OK, json: '{"success":true}'),
          ),
        );

        expect(failureOf(outcome), isA<UnexpectedFailure>());
      },
    );

    // A success status whose payload says otherwise is a contradiction, and
    // trusting the status alone would establish a session the core does not
    // believe in.
    test(
      'GivenASuccessStatusButSuccessFalse_WhenTheOwnerLogsIn_ThenNoSessionIsEstablished',
      () async {
        final outcome = await logInWith(
          FakeCoreClient(
            authLocalLoginResult: (
              status: AUTH_OK,
              json: '{"success":false,"sessionId":"6f1c9d02"}',
            ),
          ),
        );

        expect(failureOf(outcome), isA<UnexpectedFailure>());
      },
    );
  });

  // FR-AU-12: the field is absent from the core's payload today and defaults to
  // confirmed, but the branch that locks the catalog is implemented and works
  // the moment the core publishes it (System Requirements §5.4).
  group('the confirmation state', () {
    test(
      'GivenTheCoreDoesNotReportConfirmationState_WhenTheOwnerLogsIn_ThenTheSessionIsConfirmed',
      () async {
        final outcome = await logInWith(FakeCoreClient());

        expect(
          (outcome as AuthenticatedOutcome).session.emailConfirmed,
          isTrue,
        );
      },
    );

    test(
      'GivenTheCoreReportsAnUnconfirmedEmail_WhenTheOwnerLogsIn_ThenTheSessionIsUnconfirmed',
      () async {
        final outcome = await logInWith(
          FakeCoreClient(
            authLocalLoginResult: (
              status: AUTH_OK,
              json:
                  '{"success":true,"sessionId":"6f1c9d02",'
                  '"emailConfirmed":false}',
            ),
          ),
        );

        expect(
          (outcome as AuthenticatedOutcome).session.emailConfirmed,
          isFalse,
        );
      },
    );
  });
}
