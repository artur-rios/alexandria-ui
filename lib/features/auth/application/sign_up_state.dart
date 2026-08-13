import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import '../domain/login_validation.dart';

part 'sign_up_state.freezed.dart';

/// What went wrong with a registration attempt as a whole, as opposed to with
/// one field of the form.
@freezed
sealed class SignUpProblem with _$SignUpProblem {
  /// The core refused the credentials (UC-01 AF-03).
  ///
  /// Carries no reason: the core owns the password policy and answers with a
  /// status code alone — its explanation never crosses the FFI boundary. The
  /// message therefore names the rules the core enforces rather than reporting
  /// which one was broken.
  const factory SignUpProblem.rejected() = SignUpRejectedProblem;

  /// An account already exists, so registration is refused (AF-04).
  const factory SignUpProblem.accountExists() = AccountExistsProblem;

  /// The core cannot create an account in its current configuration (AF-05).
  const factory SignUpProblem.configuration({required Failure failure}) =
      SignUpConfigurationProblem;

  /// Anything else the core answered, presented as its own readable message
  /// (FR-UX-09).
  const factory SignUpProblem.other({required Failure failure}) =
      SignUpOtherProblem;
}

/// The state of the sign-up form.
@freezed
sealed class SignUpState with _$SignUpState {
  /// The owner is filling the form in, or has just had an attempt refused.
  const factory SignUpState.editing({
    LoginFieldError? emailError,
    LoginFieldError? passwordError,
    LoginFieldError? passwordConfirmationError,
    SignUpProblem? problem,
  }) = SignUpEditing;

  /// A call to the core is in flight. The form is disabled and no second
  /// attempt can be started — which matters more here than on login, because
  /// the operation creates something.
  const factory SignUpState.submitting() = SignUpSubmitting;
}
