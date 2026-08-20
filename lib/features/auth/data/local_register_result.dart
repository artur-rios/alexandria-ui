import 'package:json_annotation/json_annotation.dart';

part 'local_register_result.g.dart';

/// The core's `LocalRegisterResult` payload, as returned by
/// `alexandria_auth_local_register`.
///
/// The shape is the core's: `{"success": true, "email": "…", "sessionId": "…",
/// "recoveryCodes": ["…", …]}`. Registration opens a session, so the owner is
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
    this.recoveryCodes = const [],
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

  /// The ten single-use recovery codes the core minted, in plaintext.
  ///
  /// Returned exactly once: the core stores only their hashes, so this
  /// response is the only chance to record them, and UC-40 is what puts them
  /// in front of the owner. Defaulted to empty rather than required, because
  /// an account created without them is a state UC-40 AF-03 has to handle —
  /// not a payload this class should refuse to read.
  @JsonKey(defaultValue: <String>[])
  final List<String> recoveryCodes;
}
