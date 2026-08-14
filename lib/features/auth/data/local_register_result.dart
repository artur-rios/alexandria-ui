import 'package:json_annotation/json_annotation.dart';

part 'local_register_result.g.dart';

/// The core's `LocalRegisterResult` payload, as returned by
/// `alexandria_auth_local_register`.
///
/// The shape is the core's: `{"success": true, "email": "…", "sessionId": "…",
/// "emailConfirmed": false, "confirmationSent": false, "confirmationError":
/// "…"}`. Registration opens a session, so the owner is authenticated by the
/// same call that creates the account (UC-01 step 7).
///
/// Unlike the login payload this one echoes the address back, and it is the
/// core's normalized form rather than the raw text typed — so it is what the
/// session carries.
@JsonSerializable(createToJson: false)
class LocalRegisterResult {
  /// Creates a result.
  const LocalRegisterResult({
    required this.success,
    required this.email,
    required this.sessionId,
    required this.emailConfirmed,
    required this.confirmationSent,
    this.confirmationError,
  });

  /// Reads the payload the core returned.
  ///
  /// Throws when a required field is absent or of the wrong type, which the
  /// gateway turns into a failure rather than letting it escape.
  factory LocalRegisterResult.fromJson(Map<String, dynamic> json) =>
      _$LocalRegisterResultFromJson(json);

  /// The core's own success flag.
  final bool success;

  /// The account's address, as the core normalized it.
  final String email;

  /// The session material presented on subsequent calls (FR-AU-06).
  final String sessionId;

  /// Whether the account's e-mail is confirmed (FR-AU-12).
  ///
  /// Always `false` here — an account is confirmed by UC-40, never by being
  /// created. Read rather than assumed, because the field is what the catalog
  /// lock is decided from and this class should not be the thing that decides
  /// it.
  final bool emailConfirmed;

  /// Whether the confirmation message reached a transport (UC-01 AF-06).
  ///
  /// `false` on every install today: the core generates and stores the code,
  /// but outbound mail is not yet integrated, so nothing delivers it. The
  /// account exists and the session is open either way — a failed send is
  /// reported, never rolled back.
  final bool confirmationSent;

  /// Why the confirmation message was not sent, as a stable code — today
  /// `mail_not_configured`. Absent when [confirmationSent] is `true`.
  final String? confirmationError;
}
