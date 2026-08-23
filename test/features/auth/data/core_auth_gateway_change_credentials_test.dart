import 'dart:convert';

import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/auth/data/core_auth_gateway.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_core_client.dart';

/// The credential-change call over the core boundary (UC-04, FR-AU-10).
void main() {
  CoreAuthGateway buildGateway(FakeCoreClient core) =>
      CoreAuthGateway(core, now: () => DateTime.utc(2026, 8, 19, 9));

  Future<CredentialChangeOutcome> changeWith(FakeCoreClient core) =>
      buildGateway(core).changeCredentials(
        email: 'new@example.com',
        password: 'a decent long passphrase',
        passwordConfirmation: 'a decent long passphrase',
        credential: 'a-real-looking-session-id',
      );

  Failure failureOf(CredentialChangeOutcome outcome) {
    expect(outcome, isA<FailedChangeOutcome>());
    return (outcome as FailedChangeOutcome).failure;
  }

  group('the happy path', () {
    test(
      'GivenTheCoreAccepts_WhenTheCredentialsChange_ThenItReportsChanged',
      () async {
        expect(await changeWith(FakeCoreClient()), isA<ChangedOutcome>());
      },
    );

    test('GivenAChange_WhenItIsSent_ThenTheBodyCarriesBothEntries', () async {
      final core = FakeCoreClient();

      await changeWith(core);

      final body =
          jsonDecode(core.authLocalSetCredentialsCalls.single.jsonBody)
              as Map<String, dynamic>;
      expect(body['email'], 'new@example.com');
      expect(body['password'], 'a decent long passphrase');
      expect(body['passwordConfirmation'], 'a decent long passphrase');
    });

    test(
      'GivenAChange_WhenItIsSent_ThenItIsAuthorizedWithTheSession',
      () async {
        final core = FakeCoreClient();

        await changeWith(core);

        expect(
          core.authLocalSetCredentialsCalls.single.token,
          'a-real-looking-session-id',
          reason: 'the core requires a session to change existing credentials',
        );
      },
    );

    test('GivenAnUntrimmedAddress_WhenItIsSent_ThenItIsTrimmed', () async {
      final core = FakeCoreClient();

      await buildGateway(core).changeCredentials(
        email: '  new@example.com  ',
        password: 'a decent long passphrase',
        passwordConfirmation: 'a decent long passphrase',
        credential: 'a-real-looking-session-id',
      );

      final body =
          jsonDecode(core.authLocalSetCredentialsCalls.single.jsonBody)
              as Map<String, dynamic>;
      expect(body['email'], 'new@example.com');
    });

    test(
      'GivenTheCoreAnswersAnUnreadableBody_WhenItSucceeded_ThenItStillChanged',
      () async {
        // The success is the status, not the payload: UC-04 reads nothing from
        // the body, and a payload change must not turn a stored hash into a
        // reported failure.
        final core = FakeCoreClient(
          authLocalSetCredentialsResult: (
            status: CoreStatusFamily.auth.okCode,
            json: 'not json at all',
          ),
        );

        expect(await changeWith(core), isA<ChangedOutcome>());
      },
    );
  });

  group('the core refuses', () {
    test(
      'GivenTheCoreRejectsTheSession_WhenTheChangeIsSent_ThenItIsUnauthorized',
      () async {
        // AF-02, as the gateway sees it.
        final core = FakeCoreClient(
          authLocalSetCredentialsResult: (status: 2, json: null),
        );

        expect(failureOf(await changeWith(core)), isA<UnauthorizedFailure>());
      },
    );

    test(
      'GivenTheCoreRejectsTheInput_WhenTheChangeIsSent_ThenItIsInvalidInput',
      () async {
        // AF-03.
        final core = FakeCoreClient(
          authLocalSetCredentialsResult: (status: 1, json: null),
        );

        expect(failureOf(await changeWith(core)), isA<InvalidInputFailure>());
      },
    );

    test(
      'GivenTheCoreNamesTheRule_WhenItRefuses_ThenTheRejectionIsCarried',
      () async {
        final core = FakeCoreClient(
          authLocalSetCredentialsResult: (
            status: 1,
            json: '{"code":"password_too_short","params":{"minimum":12}}',
          ),
        );

        expect(failureOf(await changeWith(core)), isA<RejectedFailure>());
      },
    );

    test(
      'GivenTheCallItselfFails_WhenTheChangeIsSent_ThenItIsUnexpected',
      () async {
        final core = FakeCoreClient(failOnAuthLocalSetCredentials: true);

        expect(failureOf(await changeWith(core)), isA<UnexpectedFailure>());
      },
    );
  });
}
