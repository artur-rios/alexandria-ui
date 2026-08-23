import 'dart:async';

import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_ui/features/auth/domain/session.dart';

/// An [AuthGateway] that never reaches the core (Testing Specification §2.3,
/// §6.2).
///
/// A hand-written fake rather than a `mocktail` stub because the tests care
/// about what the gateway was called with and how many times — including the
/// case where it must not be called at all — and a fake that misbehaves fails
/// loudly where a mis-stubbed mock passes quietly.
class FakeAuthGateway implements AuthGateway {
  /// Creates a fake that authenticates by default.
  FakeAuthGateway({AuthOutcome? outcome})
    : outcome = outcome ?? AuthOutcome.authenticated(session: defaultSession);

  /// The session a successful login returns unless a test says otherwise.
  static final Session defaultSession = Session(
    credential: 'a-real-looking-session-id',
    establishedAt: DateTime.utc(2026, 8, 12, 9, 30),
    email: 'owner@example.com',
  );

  /// A fake that fails every attempt with [failure].
  factory FakeAuthGateway.failing(Failure failure) =>
      FakeAuthGateway(outcome: AuthOutcome.failed(failure: failure));

  /// What [logIn] and [register] return.
  AuthOutcome outcome;

  /// What [account] returns (UC-42).
  AccountOutcome accountOutcome = const AccountOutcome.read(
    account: AccountSummary(
      email: 'owner@example.com',
      recoveryCodesRemaining: 7,
    ),
  );

  /// What [regenerateRecoveryCodes] returns (UC-42).
  RegenerateOutcome regenerateOutcome = const RegenerateOutcome.regenerated(
    recoveryCodes: ['new-aaaa', 'new-bbbb'],
  );

  /// How many regenerations were asked for.
  ///
  /// Zero is the assertion AF-01 needs: declining the confirmation must not
  /// reach the core, because reaching it would replace the set.
  int regenerations = 0;

  /// What [redeemRecoveryCode] returns. A successful redemption by default
  /// (UC-41).
  RecoveryOutcome recoveryOutcome = const RecoveryOutcome.recovered();

  /// Every redemption asked for, in order.
  ///
  /// Empty is the assertion AF-01 needs: local validation must not reach the
  /// core, because reaching it could spend a code.
  final List<({String code, String newPassword, String passwordConfirmation})>
  redemptions = [];

  /// What [changeCredentials] returns. A successful change by default.
  CredentialChangeOutcome changeOutcome =
      const CredentialChangeOutcome.changed();

  /// What [changeCredentials] was called with, in order.
  ///
  /// Empty is the assertion that matters for UC-04 AF-01: local validation
  /// failures never reach the core. The credential is recorded so a test can
  /// assert the call was authorized with the active session (step 4).
  final List<
    ({
      String email,
      String password,
      String passwordConfirmation,
      String credential,
    })
  >
  credentialChanges = [];

  /// What [accountExists] answers. An existing account by default, so a test
  /// that says nothing about it gets the login screen.
  AccountExistence existence = AccountExistence.present;

  /// The credentials [logIn] was called with, in order.
  ///
  /// Empty is the assertion that matters most: UC-02 AF-01 requires that local
  /// validation failures never reach the core.
  final List<({String email, String password})> calls = [];

  /// The credentials [register] was called with, in order.
  ///
  /// Empty is again the assertion that matters: UC-01 AF-01 and AF-02 both
  /// require that the core is never called.
  final List<({String email, String password, String passwordConfirmation})>
  registrations = [];

  /// Held open to keep an attempt in flight, so a test can observe the
  /// submitting state. Completed by [release].
  Completer<void>? _gate;

  /// Makes the next [logIn] hang until [release] is called.
  void hold() => _gate = Completer<void>();

  /// Lets a held [logIn] finish.
  void release() => _gate?.complete();

  @override
  Future<AuthOutcome> logIn({
    required String email,
    required String password,
  }) async {
    calls.add((email: email, password: password));
    await _gate?.future;
    return outcome;
  }

  @override
  Future<AuthOutcome> register({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    registrations.add((
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    ));
    await _gate?.future;
    return outcome;
  }

  @override
  Future<CredentialChangeOutcome> changeCredentials({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String credential,
  }) async {
    credentialChanges.add((
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      credential: credential,
    ));
    await _gate?.future;
    return changeOutcome;
  }

  @override
  Future<AccountOutcome> account({required String credential}) async {
    await _gate?.future;
    return accountOutcome;
  }

  @override
  Future<RegenerateOutcome> regenerateRecoveryCodes({
    required String credential,
  }) async {
    regenerations++;
    await _gate?.future;
    return regenerateOutcome;
  }

  @override
  Future<RecoveryOutcome> redeemRecoveryCode({
    required String code,
    required String newPassword,
    required String passwordConfirmation,
  }) async {
    redemptions.add((
      code: code,
      newPassword: newPassword,
      passwordConfirmation: passwordConfirmation,
    ));
    await _gate?.future;
    return recoveryOutcome;
  }

  @override
  Future<AccountExistence> accountExists() async => existence;
}
