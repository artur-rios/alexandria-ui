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
  const LocalLoginResult({required this.success, required this.sessionId});

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
}
