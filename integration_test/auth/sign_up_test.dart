import 'dart:io';

import 'package:alexandria_desktop/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_desktop/core/bindings/core_client.dart';
import 'package:alexandria_desktop/core/failures/core_status.dart';
import 'package:alexandria_desktop/features/auth/data/core_auth_gateway.dart';
import 'package:alexandria_desktop/features/auth/domain/auth_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/temporary_catalog.dart';

/// UC-01 against the real Alexandria core over FFI (Testing Specification
/// §7.2, §7.4).
///
/// The account is created through the core's own registration call, which is
/// the whole point: what the unit suite fakes — the conflict code, the
/// strength policy, the payload shape — is what these tests exist to verify.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = 'owner@example.com';
  const password = 'a decent long passphrase';

  late TemporaryCatalog catalog;
  late String libraryPath;

  setUpAll(() {
    expect(
      Platform.isWindows || Platform.isLinux,
      isTrue,
      reason: 'IR-01 configures no other target',
    );

    final resolved = resolveRealCoreLibrary();
    expect(resolved, isNotNull, reason: missingCoreReason);
    libraryPath = resolved!;
  });

  setUp(() => catalog = TemporaryCatalog.create());
  tearDown(() => catalog.dispose());

  /// A core loaded and initialized against this run's throwaway database, with
  /// no account in it.
  Future<CoreClient> emptyCore() async {
    final client = await FfiCoreClient.load(libraryPath);
    addTearDown(client.dispose);

    final status = await client.initialize(catalog.databasePath);
    expect(
      CoreStatusFamily.indexing.isOk(status),
      isTrue,
      reason: 'the core would not initialize against ${catalog.databasePath}',
    );

    return client;
  }

  group('the main flow', () {
    test(
      'GivenAnEmptyCore_WhenTheOwnerSignsUp_ThenAnAccountIsCreatedAndASessionOpened',
      () async {
        final gateway = CoreAuthGateway(await emptyCore());

        final outcome = await gateway.register(
          email: email,
          password: password,
          passwordConfirmation: password,
        );

        expect(outcome, isA<AuthenticatedOutcome>());
        expect(
          (outcome as AuthenticatedOutcome).session.credential,
          isNotEmpty,
        );
      },
    );

    // The postcondition that matters and can be checked: the credentials the
    // owner just chose are the ones that now authenticate them.
    test(
      'GivenARegisteredAccount_WhenTheOwnerLogsInWithIt_ThenTheCoreAcceptsThem',
      () async {
        final gateway = CoreAuthGateway(await emptyCore());
        await gateway.register(
          email: email,
          password: password,
          passwordConfirmation: password,
        );

        final login = await gateway.logIn(email: email, password: password);

        expect(login, isA<AuthenticatedOutcome>());
      },
    );

    // FR-AU-12 / BR-25. The core creates the account unconfirmed and reports
    // it, on registration and on every later login. What the application does
    // with that is the catalog lock — and the lock only makes sense if the
    // owner can actually confirm, which is what makes these two facts worth
    // asserting against the real core rather than assuming.
    // FR-AU-12: the core mints ten single-use codes at registration and
    // returns them on this call alone. This is the one suite that can prove
    // the real core does it, and that they survive the gateway's parsing.
    test(
      'GivenAFreshRegistration_WhenTheCoreReports_ThenASessionIsOpened',
      () async {
        final gateway = CoreAuthGateway(await emptyCore());

        final outcome =
            await gateway.register(
                  email: email,
                  password: password,
                  passwordConfirmation: password,
                )
                as AuthenticatedOutcome;

        expect(outcome.session.credential, isNotEmpty);
      },
    );

    test(
      'GivenARegisteredAccount_WhenTheOwnerLogsIn_ThenTheCoreOpensASession',
      () async {
        final gateway = CoreAuthGateway(await emptyCore());
        await gateway.register(
          email: email,
          password: password,
          passwordConfirmation: password,
        );

        final login =
            await gateway.logIn(email: email, password: password)
                as AuthenticatedOutcome;

        expect(login.session.credential, isNotEmpty);
      },
    );

    test(
      'GivenARegisteredAccount_WhenTheOwnerLogsInWithAWrongPassword_ThenTheCoreRefuses',
      () async {
        final gateway = CoreAuthGateway(await emptyCore());
        await gateway.register(
          email: email,
          password: password,
          passwordConfirmation: password,
        );

        final login = await gateway.logIn(
          email: email,
          password: 'not the password',
        );

        expect(login, isA<FailedOutcome>());
      },
    );
  });

  // FR-AU-01, main flow step 1. The probe is the front-end's substitute for an
  // account-exists query the core does not publish, so it is only trustworthy
  // if the real core answers the way it assumes.
  group('the account-existence probe', () {
    test('GivenAnEmptyCore_WhenTheProbeRuns_ThenNoAccountIsReported', () async {
      final gateway = CoreAuthGateway(await emptyCore());

      expect(await gateway.accountExists(), AccountExistence.absent);
    });

    test(
      'GivenARegisteredAccount_WhenTheProbeRuns_ThenAnAccountIsReported',
      () async {
        final gateway = CoreAuthGateway(await emptyCore());
        await gateway.register(
          email: email,
          password: password,
          passwordConfirmation: password,
        );

        expect(await gateway.accountExists(), AccountExistence.present);
      },
    );

    // The probe must never create anything: it runs at launch, before the
    // owner has done anything at all.
    test('GivenAnEmptyCore_WhenTheProbeRuns_ThenItCreatesNoAccount', () async {
      final gateway = CoreAuthGateway(await emptyCore());

      await gateway.accountExists();

      expect(
        await gateway.accountExists(),
        AccountExistence.absent,
        reason: 'the probe registered an account by running',
      );
    });
  });

  // UC-01 AF-04, against the core that actually enforces it.
  test(
    'GivenAnAccountAlreadyExists_WhenTheOwnerSignsUpAgain_ThenTheCoreReportsAConflict',
    () async {
      final gateway = CoreAuthGateway(await emptyCore());
      await gateway.register(
        email: email,
        password: password,
        passwordConfirmation: password,
      );

      final second = await gateway.register(
        email: 'someone.else@example.com',
        password: 'another decent passphrase',
        passwordConfirmation: 'another decent passphrase',
      );

      expect(
        (second as FailedOutcome).failure.coreStatusCode,
        AUTH_ERR_CONFLICT,
        reason:
            'AF-04 is distinguished from AF-03 only by this code; if the core '
            'changes it, the sign-up screen silently starts telling the owner '
            'to fix their password instead of to sign in',
      );
    },
  );

  test(
    'GivenAnAccountAlreadyExists_WhenTheOwnerSignsUpAgain_ThenTheOriginalCredentialsStillWork',
    () async {
      final gateway = CoreAuthGateway(await emptyCore());
      await gateway.register(
        email: email,
        password: password,
        passwordConfirmation: password,
      );

      await gateway.register(
        email: 'someone.else@example.com',
        password: 'another decent passphrase',
        passwordConfirmation: 'another decent passphrase',
      );

      // Nothing outside the operation's scope changed: a refused registration
      // must not have overwritten the account it was refused because of.
      expect(
        await gateway.logIn(email: email, password: password),
        isA<AuthenticatedOutcome>(),
      );
    },
  );

  // UC-01 AF-03. The strength policy is the core's, and these are the tests
  // that prove the front-end never has to know it.
  group('AF-03 — the core refuses the credentials', () {
    Future<void> expectRefused(
      String password, {
      String withEmail = email,
      required String reason,
    }) async {
      final gateway = CoreAuthGateway(await emptyCore());

      final outcome = await gateway.register(
        email: withEmail,
        password: password,
        passwordConfirmation: password,
      );

      expect(outcome, isA<FailedOutcome>(), reason: reason);
      expect(
        (outcome as FailedOutcome).failure.coreStatusCode,
        AUTH_ERR_INVALID_INPUT,
        reason: reason,
      );
    }

    test(
      'GivenAShortPassword_WhenTheOwnerSignsUp_ThenTheCoreRefuses',
      () async {
        await expectRefused(
          'short',
          reason: 'under the core 12-character floor',
        );
      },
    );

    test(
      'GivenAPasswordOfOneRepeatedCharacter_WhenTheOwnerSignsUp_ThenTheCoreRefuses',
      () async {
        await expectRefused(
          'aaaaaaaaaaaaaaaa',
          reason: 'long enough, but a single repeated character',
        );
      },
    );

    test(
      'GivenThePasswordIsTheEmailAddress_WhenTheOwnerSignsUp_ThenTheCoreRefuses',
      () async {
        await expectRefused(email, reason: 'the password is the address');
      },
    );

    test(
      'GivenTheEntriesDoNotMatch_WhenTheyReachTheCore_ThenItRefusesThemToo',
      () async {
        // The application checks this first (AF-02) so the call is never made.
        // The core is the authority, and this is what proves the front-end
        // check is a convenience rather than the only thing enforcing it.
        final gateway = CoreAuthGateway(await emptyCore());

        final outcome = await gateway.register(
          email: email,
          password: password,
          passwordConfirmation: 'a different decent passphrase',
        );

        expect(outcome, isA<FailedOutcome>());
      },
    );

    test(
      'GivenARefusedRegistration_WhenTheProbeRuns_ThenNoAccountWasCreated',
      () async {
        final gateway = CoreAuthGateway(await emptyCore());

        await gateway.register(
          email: email,
          password: 'short',
          passwordConfirmation: 'short',
        );

        expect(await gateway.accountExists(), AccountExistence.absent);
      },
    );
  });

  // NFR-13: every string the core returns is freed, including on the failure
  // paths. A leak does not fail a single call, so the assertion is that a run
  // of calls settles rather than that one does.
  test(
    'GivenManyRefusedRegistrations_WhenTheyAllSettle_ThenEveryReturnedStringWasFreed',
    () async {
      final gateway = CoreAuthGateway(await emptyCore());
      await gateway.register(
        email: email,
        password: password,
        passwordConfirmation: password,
      );

      for (var attempt = 0; attempt < 50; attempt++) {
        expect(
          await gateway.register(
            email: email,
            password: password,
            passwordConfirmation: password,
          ),
          isA<FailedOutcome>(),
        );
        expect(await gateway.accountExists(), AccountExistence.present);
      }
    },
  );
}
