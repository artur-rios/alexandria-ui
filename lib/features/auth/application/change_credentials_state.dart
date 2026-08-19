import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import '../domain/login_validation.dart';

part 'change_credentials_state.freezed.dart';

/// Where the credential-change form is (UC-04).
///
/// The same shape as the login and sign-up forms: an editing state carrying
/// per-field verdicts, a submitting state that disables the action, and a
/// terminal state. The terminal one here is a success rather than a session,
/// because the owner stays signed in with the session they already had.
@freezed
sealed class ChangeCredentialsState with _$ChangeCredentialsState {
  /// The owner is filling the form in.
  ///
  /// The three field errors are what local validation found (AF-01), and
  /// [problem] is what the core refused on (AF-03). Both are cleared as soon
  /// as the owner edits, so an attempt starts from a clean form rather than
  /// from a verdict about text that has since changed.
  const factory ChangeCredentialsState.editing({
    LoginFieldError? emailError,
    LoginFieldError? passwordError,
    LoginFieldError? passwordConfirmationError,
    Failure? problem,
  }) = ChangeCredentialsEditing;

  /// The call is in flight (FR-UX-08).
  const factory ChangeCredentialsState.submitting() =
      ChangeCredentialsSubmitting;

  /// The core stored the new hash (main flow step 6).
  const factory ChangeCredentialsState.changed() = ChangeCredentialsChanged;
}
