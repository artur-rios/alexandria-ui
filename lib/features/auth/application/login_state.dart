import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import '../domain/login_validation.dart';

part 'login_state.freezed.dart';

/// What went wrong with a login attempt as a whole, as opposed to with one
/// field of the form.
///
/// A closed set because each member reads differently on screen, and because
/// UC-02's alternative flows are only covered if the screen can tell them
/// apart.
@freezed
sealed class LoginProblem with _$LoginProblem {
  /// The core refused the credentials (AF-02).
  ///
  /// Carries nothing: the message must not distinguish an unknown address from
  /// a wrong password, and a variant that carried the reason would invite a
  /// screen that leaked it.
  const factory LoginProblem.rejected() = RejectedProblem;

  /// No account has been set up in the core yet (AF-03).
  const factory LoginProblem.noAccount() = NoAccountProblem;

  /// The core is not ready to authenticate anyone (AF-05). Offered with a
  /// retry that re-runs the startup sequence.
  const factory LoginProblem.coreNotReady({required Failure failure}) =
      CoreNotReadyProblem;

  /// Anything else the core answered, presented as its own readable message
  /// (FR-UX-09).
  const factory LoginProblem.other({required Failure failure}) = OtherProblem;
}

/// The state of the login form.
@freezed
sealed class LoginState with _$LoginState {
  /// The owner is filling the form in, or has just had an attempt refused.
  const factory LoginState.editing({
    LoginFieldError? emailError,
    LoginFieldError? passwordError,
    LoginProblem? problem,
  }) = LoginEditing;

  /// A call to the core is in flight. The form is disabled and no second
  /// attempt can be started (NFR-10).
  const factory LoginState.submitting() = LoginSubmitting;
}
