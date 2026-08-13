import 'dart:convert';

import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../domain/auth_gateway.dart';
import '../domain/session.dart';
import 'local_login_result.dart';

/// The [AuthGateway] backed by the real core over FFI (FR-AU-04).
///
/// Nothing here interprets credentials: it hands the core what the owner
/// typed and turns what the core answers into a typed failure. The core owns
/// the verdict (BR-02).
class CoreAuthGateway implements AuthGateway {
  /// Creates a gateway over [_core], reading the clock through [_now] so a
  /// test can fix the session's start (Testing Specification §6.2).
  CoreAuthGateway(this._core, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final CoreClient _core;
  final DateTime Function() _now;

  @override
  Future<LoginOutcome> logIn({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();

    final CoreJsonResponse response;
    try {
      // The body is built here and referenced nowhere else, so the plaintext
      // password is unreachable once this call settles (FR-AU-11, NFR-11).
      response = await _core.authLocalLogin(
        jsonEncode({'email': trimmedEmail, 'password': password}),
      );
    } on CoreCallException {
      // The call could not be made at all — as distinct from a call that was
      // made and refused. Deliberately not logged with its message here: the
      // message is the core's and the caller logs the failure it becomes.
      return const LoginOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.auth,
          code: AuthLoginStatus.callFailedCode,
        ),
      );
    }

    if (!CoreStatusFamily.auth.isOk(response.status)) {
      return LoginOutcome.failed(
        failure: mapCoreStatus(CoreStatusFamily.auth, response.status),
      );
    }

    final json = response.json;
    if (json == null) {
      return _unreadable();
    }

    final LocalLoginResult result;
    try {
      result = LocalLoginResult.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } on Object {
      // Broad by intent: a malformed payload surfaces as FormatException, a
      // wrongly-typed field as TypeError, and either way the owner needs a
      // readable failure rather than an unhandled error reaching the screen.
      return _unreadable();
    }

    // A success status with `success: false` is a contradiction in the core's
    // own payload. Trusting the status alone here would establish a session
    // the core does not believe in.
    if (!result.success) return _unreadable();

    return LoginOutcome.authenticated(
      session: Session(
        credential: result.sessionId,
        establishedAt: _now(),
        emailConfirmed: result.emailConfirmed,
        email: trimmedEmail,
      ),
    );
  }

  LoginOutcome _unreadable() => const LoginOutcome.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.auth,
      code: AuthLoginStatus.unreadablePayloadCode,
    ),
  );
}

/// The codes this gateway reports for conditions the core has no code for.
///
/// They are negative so they can never collide with a real `AUTH_*` code, and
/// they exist so the log records *which* front-end-side failure occurred while
/// the owner still reads one ordinary message (FR-UX-09).
abstract final class AuthLoginStatus {
  /// The core call could not be made at all.
  static const int callFailedCode = -1;

  /// The core reported success but its payload could not be read.
  static const int unreadablePayloadCode = -2;
}
