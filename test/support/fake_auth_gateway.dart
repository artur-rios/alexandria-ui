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
  FakeAuthGateway({LoginOutcome? outcome})
    : outcome = outcome ?? LoginOutcome.authenticated(session: defaultSession);

  /// The session a successful login returns unless a test says otherwise.
  static final Session defaultSession = Session(
    credential: 'a-real-looking-session-id',
    establishedAt: DateTime.utc(2026, 8, 12, 9, 30),
    emailConfirmed: true,
    email: 'owner@example.com',
  );

  /// A fake that fails every attempt with [failure].
  factory FakeAuthGateway.failing(Failure failure) =>
      FakeAuthGateway(outcome: LoginOutcome.failed(failure: failure));

  /// What [logIn] returns.
  LoginOutcome outcome;

  /// The credentials [logIn] was called with, in order.
  ///
  /// Empty is the assertion that matters most: UC-02 AF-01 requires that local
  /// validation failures never reach the core.
  final List<({String email, String password})> calls = [];

  /// Held open to keep an attempt in flight, so a test can observe the
  /// submitting state. Completed by [release].
  Completer<void>? _gate;

  /// Makes the next [logIn] hang until [release] is called.
  void hold() => _gate = Completer<void>();

  /// Lets a held [logIn] finish.
  void release() => _gate?.complete();

  @override
  Future<LoginOutcome> logIn({
    required String email,
    required String password,
  }) async {
    calls.add((email: email, password: password));
    await _gate?.future;
    return outcome;
  }
}
