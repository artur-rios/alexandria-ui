import 'dart:async';

import 'package:alexandria_desktop/core/failures/failure.dart';
import 'package:alexandria_desktop/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_desktop/features/auth/domain/session.dart';

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
    emailConfirmed: true,
    email: 'owner@example.com',
  );

  /// A fake that fails every attempt with [failure].
  factory FakeAuthGateway.failing(Failure failure) =>
      FakeAuthGateway(outcome: AuthOutcome.failed(failure: failure));

  /// What [logIn] and [register] return.
  AuthOutcome outcome;

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
  final List<
    ({String email, String password, String passwordConfirmation})
  >
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
  Future<AccountExistence> accountExists() async => existence;
}
