/// What is wrong with one field of the login form (FR-AU-03, UC-02 AF-01).
///
/// Deliberately not a message: the domain layer names the condition and the
/// presentation layer localizes it, so the same verdict reads correctly in both
/// supported languages.
enum LoginFieldError {
  /// The field was left empty.
  missing,

  /// The field was filled in, but not with something the field accepts.
  malformed,

  /// The repeated password does not match the first (UC-01 AF-02).
  mismatched,
}

/// Whether [email] can be submitted, per UC-02 step 3.
///
/// This is a shape check, not an assertion that the address exists. The core's
/// verdict is the final one (FR-AU-03); this only avoids a call that cannot
/// possibly succeed (AF-01).
LoginFieldError? validateEmail(String email) {
  final trimmed = email.trim();
  if (trimmed.isEmpty) return LoginFieldError.missing;

  return _emailPattern.hasMatch(trimmed) ? null : LoginFieldError.malformed;
}

/// Whether [password] can be submitted.
///
/// Only emptiness is rejected. The application deliberately enforces no
/// composition rule of its own: password policy belongs to the core, and a
/// front-end that guessed at one would reject credentials the core accepts.
LoginFieldError? validatePassword(String password) =>
    password.isEmpty ? LoginFieldError.missing : null;

/// Whether the repeated password matches the first (UC-01 step 4, AF-02).
///
/// Checked before the core is called so a typo costs a message rather than a
/// round trip — but the core checks it too, and its verdict is the one that
/// decides. The owner's password is unrecoverable, so a typo here would lock
/// them out of their own catalog.
///
/// Reports [LoginFieldError.missing] for an empty repeat rather than a
/// mismatch: the owner has not made a mistake yet, they have not finished.
LoginFieldError? validatePasswordConfirmation(
  String password,
  String confirmation,
) {
  if (confirmation.isEmpty) return LoginFieldError.missing;

  return password == confirmation ? null : LoginFieldError.mismatched;
}

/// A local part, an `@`, and a dotted domain, with no whitespace anywhere.
///
/// Deliberately permissive. The purpose is to catch the address that is
/// obviously not one — a missing `@`, a bare hostname — not to implement
/// RFC 5322, which a regular expression cannot do and which would reject
/// addresses that work.
final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
