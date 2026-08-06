/// The redaction applied to every record before it is written (IR-13).
///
/// Passwords, session credentials, file contents, and the personal contents of
/// metadata fields are never logged. A file is identified by its UUID, not by
/// its path or name (Operations & Infrastructure Document §4).
///
/// This is a last line of defence, not the first: call sites are expected not to
/// pass a credential in the first place. It exists because "nobody will log a
/// password" is a claim that stops being true the first time someone dumps a
/// request body while debugging, and a log file is exactly the artifact an owner
/// attaches to a report.
abstract final class LogRedaction {
  /// The placeholder a redacted value is replaced with.
  static const String placeholder = '[redacted]';

  /// Field names whose values never reach the log, in any casing.
  static const Set<String> sensitiveKeys = {
    'password',
    'newpassword',
    'currentpassword',
    'passwordconfirmation',
    'token',
    'sessionid',
    'session',
    'bearer',
    'credential',
    'credentials',
    'hash',
    'secret',
    'content',
    'body',
    'path',
    'filepath',
    'filename',
    'name',
    'title',
    'description',
  };

  // Matches `key: value`, `key=value`, and `"key": "value"` for the sensitive
  // keys only, so a message built by interpolation is covered as well as a
  // structured field.
  //
  // The pattern is keyed on the sensitive names rather than matching every
  // `key: value` pair and filtering afterwards. A general pair matcher consumes
  // left to right, so in `StateError: token=hunter2` the harmless first pair
  // swallows `token` as its own value and the credential walks straight through
  // — which is exactly the case that put this comment here.
  //
  // Longest first, so `newpassword` cannot be matched as `password`.
  static final RegExp _sensitivePair = RegExp(
    '\\b(${(sensitiveKeys.toList()..sort((a, b) => b.length - a.length)).join('|')})'
    '(["\x27]?\\s*[:=]\\s*)(["\x27][^"\x27]*["\x27]|[^\\s,;}]+)',
    caseSensitive: false,
  );

  /// Redacts every sensitive value in [message].
  static String redactMessage(String message) =>
      message.replaceAllMapped(_sensitivePair, (match) {
        final separator = match.group(2)!.replaceAll(RegExp('["\x27]'), '');
        return '${match.group(1)}$separator$placeholder';
      });

  /// Redacts every sensitive entry in a record's context fields.
  static Map<String, Object?> redactContext(Map<String, Object?> context) => {
    for (final entry in context.entries)
      entry.key: sensitiveKeys.contains(entry.key.toLowerCase())
          ? placeholder
          : entry.value,
  };
}
