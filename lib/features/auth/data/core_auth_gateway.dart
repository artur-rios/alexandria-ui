import 'dart:convert';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../domain/auth_gateway.dart';
import '../domain/session.dart';
import 'core_error_body.dart';
import 'local_login_result.dart';
import 'local_register_result.dart';

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
  Future<AuthOutcome> logIn({
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
      return const AuthOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.auth,
          code: AuthLoginStatus.callFailedCode,
        ),
      );
    }

    if (!CoreStatusFamily.auth.isOk(response.status)) {
      return AuthOutcome.failed(
        failure: mapCoreStatus(
          CoreStatusFamily.auth,
          response.status,
          // The core names the rule it refused on. Reading it is what lets the
          // owner be told what to change rather than only that something was
          // wrong; a core that sends none falls back to the status code.
          rejection: readCoreRejection(response.json),
        ),
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

    return AuthOutcome.authenticated(
      session: Session(
        credential: result.sessionId,
        establishedAt: _now(),
        email: trimmedEmail,
      ),
    );
  }

  @override
  Future<AuthOutcome> register({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final trimmedEmail = email.trim();

    final CoreJsonResponse response;
    try {
      // Built here and referenced nowhere else, so both plaintext entries are
      // unreachable once this call settles (FR-AU-11, NFR-11).
      response = await _core.authLocalRegister(
        jsonEncode({
          'email': trimmedEmail,
          'password': password,
          'passwordConfirmation': passwordConfirmation,
        }),
      );
    } on CoreCallException {
      return const AuthOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.auth,
          code: AuthLoginStatus.callFailedCode,
        ),
      );
    }

    if (!CoreStatusFamily.auth.isOk(response.status)) {
      return AuthOutcome.failed(
        failure: mapCoreStatus(
          CoreStatusFamily.auth,
          response.status,
          // The core names the rule it refused on. Reading it is what lets the
          // owner be told what to change rather than only that something was
          // wrong; a core that sends none falls back to the status code.
          rejection: readCoreRejection(response.json),
        ),
      );
    }

    final json = response.json;
    if (json == null) return _unreadable();

    final LocalRegisterResult result;
    try {
      result = LocalRegisterResult.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } on Object {
      // Broad by intent, as on the login path: a malformed payload surfaces as
      // FormatException and a wrongly-typed field as TypeError, and either way
      // the owner needs a readable failure.
      return _unreadable();
    }

    if (!result.success) return _unreadable();

    return AuthOutcome.authenticated(
      session: Session(
        credential: result.sessionId,
        establishedAt: _now(),
        // The core's normalized address rather than the raw text typed: it is
        // what the account actually holds.
        email: result.email,
      ),
      // FR-AU-12: this response is the only place the codes ever exist, so
      // the outcome carries them out of it or they are gone.
      recoveryCodes: result.recoveryCodes,
    );
  }

  @override
  Future<CredentialChangeOutcome> changeCredentials({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      // Both arguments are built here and referenced nowhere else, so the new
      // plaintext and the session credential are unreachable once this call
      // settles (FR-AU-11, NFR-11).
      response = await _core.authLocalSetCredentials(
        jsonEncode({
          'email': email.trim(),
          'password': password,
          'passwordConfirmation': passwordConfirmation,
        }),
        credential,
      );
    } on CoreCallException {
      return const CredentialChangeOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.auth,
          code: AuthLoginStatus.callFailedCode,
        ),
      );
    }

    if (!CoreStatusFamily.auth.isOk(response.status)) {
      // AF-02 and AF-03 both land here and are told apart by the status the
      // core returned: an unauthorized one is the session's problem and the
      // caller discards it, anything else leaves the stored credentials
      // untouched and is reported as a reason.
      return CredentialChangeOutcome.failed(
        failure: mapCoreStatus(
          CoreStatusFamily.auth,
          response.status,
          rejection: readCoreRejection(response.json),
        ),
      );
    }

    // The core answers with the account body, which carries nothing this call
    // needs: the session it authorized with stays valid, and the new address
    // is what was just sent. Not reading it is deliberate — a payload change
    // must not turn a successful change into a failure.
    return const CredentialChangeOutcome.changed();
  }

  @override
  Future<RecoveryOutcome> redeemRecoveryCode({
    required String code,
    required String newPassword,
    required String passwordConfirmation,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.authLocalRedeemRecoveryCode(
        jsonEncode({
          'code': code.trim(),
          'newPassword': newPassword,
          'passwordConfirmation': passwordConfirmation,
        }),
      );
    } on CoreCallException {
      return const RecoveryOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.auth,
          code: AuthLoginStatus.callFailedCode,
        ),
      );
    }

    if (!CoreStatusFamily.auth.isOk(response.status)) {
      // AF-02, AF-03, and AF-04 all land here and are told apart by the
      // reason code the core named — `recovery_code_unknown`,
      // `recovery_code_used`, or one of the password-policy codes. The
      // application does not judge any of them (FR-AU-19); it reads which one
      // and says it in the owner's language.
      return RecoveryOutcome.failed(
        failure: mapCoreStatus(
          CoreStatusFamily.auth,
          response.status,
          rejection: readCoreRejection(response.json),
        ),
      );
    }

    // The core answers with the account body and how many codes are left.
    // Neither is read: the session is gone — the core invalidated every one —
    // so the owner is going back to the login screen regardless, and a
    // payload change must not turn a successful recovery into a failure.
    return const RecoveryOutcome.recovered();
  }

  /// Answers FR-AU-01 by asking the core to authenticate an address that
  /// cannot be registered.
  ///
  /// The core publishes no account-exists query, so this reads the one thing
  /// that distinguishes the two states on a call that already exists: local
  /// login answers `AUTH_ERR_CONFIG` when no credentials are stored and
  /// `AUTH_ERR_UNAUTHORIZED` when they are. Nothing is created or modified,
  /// and the core compares the address before verifying any password, so no
  /// hash is computed.
  ///
  /// It is a probe, not a login: the address is deliberately unusable and no
  /// session can result. When the core publishes a real query this method is
  /// the only thing that changes — nothing above it knows how the question was
  /// asked.
  @override
  Future<AccountExistence> accountExists() async {
    final CoreJsonResponse response;
    try {
      response = await _core.authLocalLogin(
        jsonEncode({'email': _probeAddress, 'password': ''}),
      );
    } on CoreCallException {
      return AccountExistence.unknown;
    }

    return switch (response.status) {
      AUTH_ERR_CONFIG => AccountExistence.absent,
      AUTH_ERR_UNAUTHORIZED => AccountExistence.present,
      // Anything else — the core not initialized, a code this version does not
      // know — leaves the question unanswered rather than guessed at.
      _ => AccountExistence.unknown,
    };
  }

  /// The address the existence probe presents.
  ///
  /// `.invalid` is reserved by RFC 2606 precisely so that it can never be a
  /// real address, which keeps the probe from colliding with an account
  /// somebody actually holds.
  static const String _probeAddress = 'account-probe@alexandria.invalid';

  AuthOutcome _unreadable() => const AuthOutcome.failed(
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
