import 'package:json_annotation/json_annotation.dart';

part 'local_register_result.g.dart';

/// The core's `LocalRegisterResult` payload, as returned by
/// `alexandria_auth_local_register`.
///
/// The shape is the core's: `{"success": true, "email": "…", "sessionId":
/// "…"}`, the session id being a UUID. Registration opens a session, so the
/// owner is
/// authenticated by the same call that creates the account (UC-01 step 7).
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
    this.emailConfirmed = true,
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
  /// **Absent from the core's current payload**, and defaulted to `true` for
  /// the same reason as on the login result: the core has no e-mail
  /// confirmation at all — no message, no token, no confirmed state — so there
  /// is no unconfirmed account to represent yet.
  ///
  /// This is why UC-01's postcondition "an account whose e-mail is not yet
  /// confirmed, and has sent a confirmation message" does not hold, and why
  /// its AF-06 is unimplementable. Read from the payload when present so the
  /// lock starts working the day the core publishes it.
  final bool emailConfirmed;
}
