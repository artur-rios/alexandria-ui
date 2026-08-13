import 'package:json_annotation/json_annotation.dart';

part 'local_login_result.g.dart';

/// The core's `LocalLoginResult` payload, as returned by
/// `alexandria_auth_local_login`.
///
/// The shape is the core's, byte for byte the same JSON its HTTP route
/// returns: `{"success": true, "sessionId": "<uuid>"}`.
@JsonSerializable(createToJson: false)
class LocalLoginResult {
  /// Creates a result.
  const LocalLoginResult({
    required this.success,
    required this.sessionId,
    this.emailConfirmed = true,
  });

  /// Reads the payload the core returned.
  ///
  /// Throws when a required field is absent or of the wrong type, which the
  /// gateway turns into a failure rather than letting it escape: a core that
  /// answered with something unreadable is a failed call, not a crash.
  factory LocalLoginResult.fromJson(Map<String, dynamic> json) =>
      _$LocalLoginResultFromJson(json);

  /// The core's own success flag.
  final bool success;

  /// The session material presented on subsequent calls (FR-AU-06).
  final String sessionId;

  /// Whether the account's e-mail is confirmed (FR-AU-12).
  ///
  /// **Absent from the core's current payload**, and so defaulted to `true`
  /// here. Reporting confirmation state is one of the pending core operations
  /// in [System Requirements §5.4]; until it lands there is no unconfirmed
  /// account to represent, because the only thing that creates one is UC-01,
  /// which is blocked on the same table.
  ///
  /// Read from the payload when present rather than hardcoded, so the day the
  /// core publishes the field the lock in FR-AU-12 starts working without this
  /// class changing. That is not the front-end inventing a call — it is
  /// reading a field of a payload it already receives.
  final bool emailConfirmed;
}
