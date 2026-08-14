import 'dart:convert';

import '../../../core/failures/core_rejection.dart';

/// Reads the error envelope the core sends on a failed call.
///
/// The shape is `{"error": "…", "code": "…", "params": {…}}`, with `code` and
/// `params` omitted when there is nothing to say. It is the same envelope the
/// core's HTTP surface returns, which is what lets one client be written
/// against both.
///
/// Returns `null` whenever there is no usable code — an absent body, an older
/// core that sends none, a body that is not an object, or a code that is not a
/// string. The caller then falls back to the status code's own meaning, so a
/// core that stops sending codes degrades to the previous behaviour instead of
/// failing.
CoreRejection? readCoreRejection(String? json) {
  if (json == null || json.isEmpty) return null;

  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return null;
  }

  if (decoded is! Map<String, dynamic>) return null;

  final code = decoded['code'];
  if (code is! String || code.isEmpty) return null;

  final message = decoded['error'];
  final params = decoded['params'];

  return CoreRejection(
    code: code,
    // Values are strings by the core's own contract, but a number arriving
    // where a string was promised should degrade to a message without that
    // parameter rather than throw on a failure path.
    params: params is Map<String, dynamic>
        ? {
            for (final entry in params.entries)
              if (entry.value is String) entry.key: entry.value as String,
          }
        : const <String, String>{},
    message: message is String ? message : null,
  );
}
