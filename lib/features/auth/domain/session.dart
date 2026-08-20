import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';

/// The owner's authenticated session (System Requirements §4.9).
///
/// Application-owned and **memory only**: it is never written to the settings
/// store, never to the log, and never to any other persistent place
/// (FR-AU-05, FR-AU-11). It lives for the duration of the application run and
/// is discarded on sign-out, on a rejected call (UC-02 AF-04), and on a
/// completed password reset (FR-AU-19).
@freezed
abstract class Session with _$Session {
  const Session._();

  /// Creates a session from what the core returned at login.
  const factory Session({
    /// The material the core returned — its `sessionId`. Presented on every
    /// subsequent core call that requires one (FR-AU-06).
    required String credential,

    /// When the session began.
    required DateTime establishedAt,

    /// The account's address. Held because the account screen shows it, and
    /// because the login result does not echo it back — it is what the owner
    /// typed.
    required String email,
  }) = _Session;

  /// A description safe to log.
  ///
  /// Freezed would otherwise generate one that prints every field, and this
  /// object is interpolated into log messages by anything holding it. The
  /// credential is the one field that must never appear in a log or any
  /// diagnostic output (FR-AU-11), so it is replaced here rather than at each
  /// of the call sites that might print a session.
  @override
  String toString() =>
      'Session(credential: <redacted>, establishedAt: $establishedAt, '
      'email: $email)';
}
