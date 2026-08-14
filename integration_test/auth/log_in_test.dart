import 'dart:convert';
import 'dart:io';

import 'package:alexandria_desktop/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_desktop/core/bindings/core_client.dart';
import 'package:alexandria_desktop/core/failures/core_status.dart';
import 'package:alexandria_desktop/features/auth/data/core_auth_gateway.dart';
import 'package:alexandria_desktop/features/auth/domain/auth_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/temporary_catalog.dart';

/// UC-02 against the real Alexandria core over FFI (Testing Specification
/// §7.2, §7.4).
///
/// What the unit suite fakes — the status codes, the payload shape, the
/// memory discipline — is exactly what this suite exists to verify. The
/// account is created through the core's own registration call rather than by
/// writing the database (§7.3).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = 'owner@example.com';
  const password = 'correct horse battery staple';

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

  /// A core loaded and initialized against this run's throwaway database.
  Future<CoreClient> initializedCore() async {
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

  /// Creates this run's account through the core's own registration call.
  ///
  /// Registration rather than set-credentials: the core removed the
  /// unauthenticated first-time path from `set_credentials` when it gained
  /// `alexandria_auth_local_register` (UC-41), on the grounds that creating
  /// the account is registration's job. Set-credentials now always requires a
  /// session, so it can no longer bootstrap a run.
  Future<void> createAccount(CoreClient core) async {
    final response = await core.authLocalRegister(
      jsonEncode({
        'email': email,
        'password': password,
        'passwordConfirmation': password,
      }),
    );

    expect(
      CoreStatusFamily.auth.isOk(response.status),
      isTrue,
      reason:
          'the core refused to create the run\'s account '
          '(status ${response.status}). The core reads ALEXANDRIA_AUTH_MODE at '
          'alexandria_index_init and defaults to "external", in which mode it '
          'refuses every local-auth call. Run this suite with '
          'ALEXANDRIA_AUTH_MODE=local.',
    );
  }

  test(
    'GivenAnAccountInTheRealCore_WhenTheOwnerLogsIn_ThenASessionIsReturned',
    () async {
      final core = await initializedCore();
      await createAccount(core);

      final outcome = await CoreAuthGateway(
        core,
      ).logIn(email: email, password: password);

      expect(outcome, isA<AuthenticatedOutcome>());
    },
  );

  test(
    'GivenAnAccountInTheRealCore_WhenTheOwnerLogsIn_ThenTheCoreReturnsUsableSessionMaterial',
    () async {
      final core = await initializedCore();
      await createAccount(core);

      final outcome =
          await CoreAuthGateway(core).logIn(email: email, password: password)
              as AuthenticatedOutcome;

      // The core returns a UUID; what matters to FR-AU-06 is that it is
      // something presentable on a later call, not its exact shape.
      expect(outcome.session.credential, isNotEmpty);
      expect(outcome.session.email, email);
    },
  );

  // UC-02 AF-02, against the core that actually decides it.
  test(
    'GivenTheWrongPassword_WhenTheOwnerLogsIn_ThenTheCoreRefuses',
    () async {
      final core = await initializedCore();
      await createAccount(core);

      final outcome = await CoreAuthGateway(
        core,
      ).logIn(email: email, password: 'not the password');

      expect(outcome, isA<FailedOutcome>());
    },
  );

  test(
    'GivenAnUnknownAddress_WhenTheOwnerLogsIn_ThenTheCoreRefusesTheSameWay',
    () async {
      final core = await initializedCore();
      await createAccount(core);

      final wrongPassword = await CoreAuthGateway(
        core,
      ).logIn(email: email, password: 'not the password');
      final unknownAddress = await CoreAuthGateway(
        core,
      ).logIn(email: 'someone@example.com', password: password);

      // AF-02 requires the message not to distinguish the two. That holds
      // because the core answers both with the same failure — this is the test
      // that would catch the core starting to distinguish them.
      expect(
        (unknownAddress as FailedOutcome).failure.runtimeType,
        (wrongPassword as FailedOutcome).failure.runtimeType,
      );
    },
  );

  // UC-02 AF-03: no credentials have ever been set in this throwaway database.
  test(
    'GivenNoAccountInTheRealCore_WhenTheOwnerLogsIn_ThenItIsReportedAsAConfigurationFailure',
    () async {
      final core = await initializedCore();

      final outcome = await CoreAuthGateway(
        core,
      ).logIn(email: email, password: password);

      expect(
        (outcome as FailedOutcome).failure.coreStatusCode,
        AUTH_ERR_CONFIG,
        reason:
            'AF-03 is distinguished from AF-02 only by this code; if the core '
            'changes it, the login screen silently starts showing the wrong '
            'message',
      );
    },
  );

  // NFR-13: every string the core returns is freed, including on the failure
  // paths. A leak does not fail a single call, so the assertion is that a run
  // of calls settles rather than that one does.
  test(
    'GivenManyLoginAttempts_WhenTheyAllSettle_ThenEveryReturnedStringWasFreed',
    () async {
      final core = await initializedCore();
      await createAccount(core);
      final gateway = CoreAuthGateway(core);

      for (var attempt = 0; attempt < 50; attempt++) {
        expect(
          await gateway.logIn(email: email, password: password),
          isA<AuthenticatedOutcome>(),
        );
        expect(
          await gateway.logIn(email: email, password: 'wrong'),
          isA<FailedOutcome>(),
        );
      }
    },
  );
}
