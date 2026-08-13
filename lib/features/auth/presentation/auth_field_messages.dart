import '../../../core/l10n/generated/app_localizations.dart';
import '../domain/login_validation.dart';

/// The fields the authentication forms are built from.
///
/// Named here rather than passing a boolean, because the same
/// [LoginFieldError] reads differently per field: "missing" is *enter your
/// e-mail* on one and *repeat your password* on another.
enum AuthField {
  /// The e-mail address, on both the login and the sign-up form.
  email,

  /// The password, on both forms.
  password,

  /// The repeated password, on the sign-up form only (UC-01).
  passwordConfirmation,
}

/// The message the owner reads for a field-level verdict, or `null` when the
/// field is fine.
///
/// The domain names the condition and this is where it becomes language, so
/// both screens phrase the same verdict identically. The switch is total over
/// both enums, which is what makes adding a field or a verdict a compile error
/// rather than a screen that renders nothing.
String? authFieldMessage(
  AppLocalizations l10n,
  AuthField field,
  LoginFieldError? error,
) => switch ((field, error)) {
  (_, null) => null,

  (AuthField.email, LoginFieldError.missing) => l10n.loginEmailMissing,
  (AuthField.email, LoginFieldError.malformed) => l10n.loginEmailMalformed,

  (AuthField.password, LoginFieldError.missing) => l10n.loginPasswordMissing,

  (AuthField.passwordConfirmation, LoginFieldError.missing) =>
    l10n.signUpPasswordConfirmationMissing,
  (AuthField.passwordConfirmation, LoginFieldError.mismatched) =>
    l10n.signUpPasswordMismatch,

  // The combinations the domain cannot produce: an e-mail is never
  // "mismatched", and a password is judged only for emptiness here because its
  // strength is the core's verdict to give (FR-AU-03). They are mapped rather
  // than left to a wildcard so that a future validator producing one shows up
  // as a wrong message instead of a blank field.
  (AuthField.email, LoginFieldError.mismatched) ||
  (AuthField.password, LoginFieldError.malformed) ||
  (AuthField.password, LoginFieldError.mismatched) ||
  (AuthField.passwordConfirmation, LoginFieldError.malformed) =>
    l10n.failureUnexpected,
};
