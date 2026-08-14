import 'dart:convert';

import 'package:alexandria_desktop/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_desktop/core/failures/failure.dart';
import 'package:alexandria_desktop/features/auth/data/core_auth_gateway.dart';
import 'package:alexandria_desktop/features/auth/domain/auth_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_core_client.dart';

void main() {
  final establishedAt = DateTime.utc(2026, 8, 13, 11, 0);

  CoreAuthGateway buildGateway(FakeCoreClient core) =>
      CoreAuthGateway(core, now: () => establishedAt);

  Future<AuthOutcome> registerWith(FakeCoreClient core) =>
      buildGateway(core).register(
        email: 'owner@example.com',
        password: 'a decent long passphrase',
        passwordConfirmation: 'a decent long passphrase',
      );

  Failure failureOf(AuthOutcome outcome) {
    expect(outcome, isA<FailedOutcome>());
    return (outcome as FailedOutcome).failure;
  }

  group('the happy path', () {
    test(
      'GivenTheCoreCreatesTheAccount_WhenTheOwnerSignsUp_ThenASessionIsReturned',
      () async {
        expect(
          await registerWith(FakeCoreClient()),
          isA<AuthenticatedOutcome>(),
        );
      },
    );

    test(
      'GivenTheCoreCreatesTheAccount_WhenTheOwnerSignsUp_ThenTheSessionCarriesTheCoresSessionId',
      () async {
        final outcome = await registerWith(FakeCoreClient());

        expect(
          (outcome as AuthenticatedOutcome).session.credential,
          '6f1c9d02-1f3b-4f3a-9a7e-0b1d2c3e4f50',
        );
      },
    );

    // The core normalizes the address, and the account holds its version.
    test(
      'GivenTheCoreNormalizesTheAddress_WhenTheOwnerSignsUp_ThenTheSessionCarriesTheCoresVersion',
      () async {
        final core = FakeCoreClient(
          authLocalRegisterResult: (
            status: AUTH_OK,
            json:
                '{"success":true,"email":"owner@example.com",'
                '"sessionId":"6f1c9d02"}',
          ),
        );

        final outcome = await buildGateway(core).register(
          email: 'Owner@Example.COM',
          password: 'a decent long passphrase',
          passwordConfirmation: 'a decent long passphrase',
        );

        expect(
          (outcome as AuthenticatedOutcome).session.email,
          'owner@example.com',
        );
      },
    );

    test(
      'GivenAnAddressPaddedWithSpaces_WhenTheOwnerSignsUp_ThenTheCoreReceivesItTrimmed',
      () async {
        final core = FakeCoreClient();

        await buildGateway(core).register(
          email: '  owner@example.com  ',
          password: 'a decent long passphrase',
          passwordConfirmation: 'a decent long passphrase',
        );

        expect(
          jsonDecode(core.authLocalRegisterBodies.single),
          containsPair('email', 'owner@example.com'),
        );
      },
    );

    // The core is the one that decides a mismatch, so it must receive both.
    test(
      'GivenBothEntries_WhenTheOwnerSignsUp_ThenTheCoreReceivesTheConfirmationToo',
      () async {
        final core = FakeCoreClient();

        await registerWith(core);

        expect(
          jsonDecode(core.authLocalRegisterBodies.single),
          containsPair('passwordConfirmation', 'a decent long passphrase'),
        );
      },
    );
  });

  group('the failures the core reports', () {
    // UC-01 AF-04.
    test(
      'GivenAnAccountAlreadyExists_WhenTheOwnerSignsUp_ThenItIsAConflict',
      () async {
        final outcome = await registerWith(
          FakeCoreClient(
            authLocalRegisterResult: (status: AUTH_ERR_CONFLICT, json: null),
          ),
        );

        expect(failureOf(outcome), isA<ConflictFailure>());
      },
    );

    // UC-01 AF-03: a password the core's strength policy refuses.
    test(
      'GivenTheCoreRefusesTheCredentials_WhenTheOwnerSignsUp_ThenItIsInvalidInput',
      () async {
        final outcome = await registerWith(
          FakeCoreClient(
            authLocalRegisterResult: (
              status: AUTH_ERR_INVALID_INPUT,
              json: null,
            ),
          ),
        );

        expect(failureOf(outcome), isA<InvalidInputFailure>());
      },
    );

    // UC-01 AF-05.
    test(
      'GivenTheCoreReportsAConfigurationFailure_WhenTheOwnerSignsUp_ThenItIsAConfigurationFailure',
      () async {
        final outcome = await registerWith(
          FakeCoreClient(
            authLocalRegisterResult: (status: AUTH_ERR_CONFIG, json: null),
          ),
        );

        expect(failureOf(outcome), isA<ConfigurationFailure>());
      },
    );

    test(
      'GivenTheCoreIsNotInitialized_WhenTheOwnerSignsUp_ThenItIsANotInitializedFailure',
      () async {
        final outcome = await registerWith(
          FakeCoreClient(
            authLocalRegisterResult: (
              status: AUTH_ERR_NOT_INITIALIZED,
              json: null,
            ),
          ),
        );

        expect(failureOf(outcome), isA<NotInitializedFailure>());
      },
    );

    test(
      'GivenTheCallCannotBeMadeAtAll_WhenTheOwnerSignsUp_ThenItIsUnexpectedRatherThanThrowing',
      () async {
        final outcome = await registerWith(
          FakeCoreClient(failOnAuthLocalRegister: true),
        );

        expect(failureOf(outcome), isA<UnexpectedFailure>());
      },
    );
  });

  group('payloads that cannot be trusted', () {
    test(
      'GivenSuccessWithNoPayload_WhenTheOwnerSignsUp_ThenNoSessionIsEstablished',
      () async {
        final outcome = await registerWith(
          FakeCoreClient(
            authLocalRegisterResult: (status: AUTH_OK, json: null),
          ),
        );

        expect(failureOf(outcome), isA<UnexpectedFailure>());
      },
    );

    test(
      'GivenSuccessWithAMalformedPayload_WhenTheOwnerSignsUp_ThenNoSessionIsEstablished',
      () async {
        final outcome = await registerWith(
          FakeCoreClient(
            authLocalRegisterResult: (status: AUTH_OK, json: 'not json'),
          ),
        );

        expect(failureOf(outcome), isA<UnexpectedFailure>());
      },
    );

    test(
      'GivenASuccessStatusButSuccessFalse_WhenTheOwnerSignsUp_ThenNoSessionIsEstablished',
      () async {
        final outcome = await registerWith(
          FakeCoreClient(
            authLocalRegisterResult: (
              status: AUTH_OK,
              json:
                  '{"success":false,"email":"owner@example.com",'
                  '"sessionId":"6f1c9d02"}',
            ),
          ),
        );

        expect(failureOf(outcome), isA<UnexpectedFailure>());
      },
    );
  });

  // FR-AU-01, main flow step 1. The core publishes no account-exists query, so
  // this reads what local login answers when no credentials are stored.
  group('the account-existence probe', () {
    Future<AccountExistence> probeWith(FakeCoreClient core) =>
        buildGateway(core).accountExists();

    test(
      'GivenTheCoreHoldsNoCredentials_WhenTheProbeRuns_ThenNoAccountIsReported',
      () async {
        expect(
          await probeWith(
            FakeCoreClient(
              authLocalLoginResult: (status: AUTH_ERR_CONFIG, json: null),
            ),
          ),
          AccountExistence.absent,
        );
      },
    );

    test(
      'GivenTheCoreHoldsCredentials_WhenTheProbeRuns_ThenAnAccountIsReported',
      () async {
        expect(
          await probeWith(
            FakeCoreClient(
              authLocalLoginResult: (status: AUTH_ERR_UNAUTHORIZED, json: null),
            ),
          ),
          AccountExistence.present,
        );
      },
    );

    test(
      'GivenTheCoreIsNotInitialized_WhenTheProbeRuns_ThenTheAnswerIsUnknown',
      () async {
        expect(
          await probeWith(
            FakeCoreClient(
              authLocalLoginResult: (
                status: AUTH_ERR_NOT_INITIALIZED,
                json: null,
              ),
            ),
          ),
          AccountExistence.unknown,
        );
      },
    );

    test(
      'GivenTheCallCannotBeMadeAtAll_WhenTheProbeRuns_ThenTheAnswerIsUnknown',
      () async {
        expect(
          await probeWith(FakeCoreClient(failOnAuthLocalLogin: true)),
          AccountExistence.unknown,
        );
      },
    );

    // The probe must never be able to authenticate anyone or collide with a
    // real account: the address is in a reserved domain that cannot exist.
    test(
      'GivenTheProbeRuns_WhenTheCoreIsInspected_ThenItWasAskedAboutAnUnusableAddress',
      () async {
        final core = FakeCoreClient(
          authLocalLoginResult: (status: AUTH_ERR_CONFIG, json: null),
        );

        await probeWith(core);

        final body =
            jsonDecode(core.authLocalLoginBodies.single)
                as Map<String, dynamic>;
        expect(body['email'], endsWith('.invalid'));
        expect(body['password'], isEmpty);
      },
    );

    test(
      'GivenTheProbeRuns_WhenItSucceedsUnexpectedly_ThenTheAnswerIsStillNotASession',
      () async {
        // AUTH_OK from a probe would mean the core authenticated an address in
        // a reserved domain. Not "present" — something is wrong, and unknown is
        // the honest answer.
        expect(
          await probeWith(
            FakeCoreClient(
              authLocalLoginResult: (status: AUTH_OK, json: '{"success":true}'),
            ),
          ),
          AccountExistence.unknown,
        );
      },
    );
  });
}
