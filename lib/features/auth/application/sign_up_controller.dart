import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/auth_gateway.dart';
import '../domain/login_validation.dart';
import 'session_controller.dart';
import 'sign_up_state.dart';

/// Drives UC-01's main flow and its implementable alternative flows.
///
/// It validates locally, calls the core once, and turns the outcome into
/// either a session or something the owner can read. It enforces no password
/// policy of its own: the strength rules belong to the core, and a front-end
/// that guessed at them would reject credentials the core accepts, or accept
/// ones it rejects (BR-02, FR-AU-03).
class SignUpController extends Notifier<SignUpState> {
  // Read from the composition root in build(), as the login controller does.
  late AuthGateway _gateway;
  late SessionController _session;

  @override
  SignUpState build() {
    _gateway = ref.read(authGatewayProvider);
    _session = ref.read(sessionControllerProvider.notifier);
    return const SignUpState.editing();
  }

  /// Attempts to create the account (UC-01 main flow, steps 3–7).
  ///
  /// Returns without calling the core when local validation rejects the input
  /// (AF-01, AF-02), and does nothing while an attempt is already in flight —
  /// a second call would either create a second account or be refused as a
  /// conflict caused by the first.
  Future<void> submit({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (state is SignUpSubmitting) return;

    // Step 4: the address is well-formed, the password is not empty, and the
    // two entries match — all before the call, so an attempt that cannot
    // succeed never becomes one.
    final emailError = validateEmail(email);
    final passwordError = validatePassword(password);
    final confirmationError = validatePasswordConfirmation(
      password,
      passwordConfirmation,
    );

    if (emailError != null ||
        passwordError != null ||
        confirmationError != null) {
      state = SignUpState.editing(
        emailError: emailError,
        passwordError: passwordError,
        passwordConfirmationError: confirmationError,
      );
      return;
    }

    state = const SignUpState.submitting();

    final outcome = await _gateway.register(
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );

    switch (outcome) {
      // Step 7: the session the core opened is held in memory, and both
      // plaintext entries are left behind with this call's arguments
      // (FR-AU-05, FR-AU-11).
      //
      // The owner lands in the shell. The specification once had them land on
      // an e-mail confirmation prompt; the core has no confirmation to give,
      // so there is nothing to hold them here. UC-40 puts the recovery codes
      // in front of them at this point instead.
      case AuthenticatedOutcome(:final session, :final recoveryCodes):
        state = const SignUpState.editing();

        // An account exists from here on, so the screen for any later
        // signed-out state is login rather than sign-up. The entry is resolved
        // once per run (FR-AU-01), and this is the one moment in a run that
        // changes the answer — without it, signing out from the recovery-code
        // prompt (UC-40 AF-04) would offer to create the account again.
        ref.read(authEntryProvider.notifier).goToLogin();

        // UC-40: the codes go into the session state, which is what puts them
        // on screen in place of the catalog until they are acknowledged.
        _session.establish(session, recoveryCodes: recoveryCodes ?? const []);

      case FailedOutcome(:final failure):
        state = SignUpState.editing(problem: _problemFor(failure));
    }
  }

  /// Clears what the last attempt reported, as the owner types (AF-01) —
  /// the same rule the login form keeps, for the same reason: a mark that
  /// outlives the mistake it named is a mark that is no longer true.
  void resetProblems() {
    if (state case final SignUpEditing editing) {
      if (editing.emailError == null &&
          editing.passwordError == null &&
          editing.passwordConfirmationError == null &&
          editing.problem == null) {
        return;
      }
      state = const SignUpState.editing();
    }
  }

  /// How each failure the core can answer with reads to the owner.
  SignUpProblem _problemFor(Failure failure) => switch (failure) {
    // AF-04: the core refuses to overwrite an account that exists.
    ConflictFailure() => const SignUpProblem.accountExists(),

    // AF-03: the core rejected the credentials — a password too short, too
    // common, or containing the address. When it named which, the screen can
    // say so; when it did not, the message names the rules instead.
    RejectedFailure(:final rejection) => SignUpProblem.rejected(
      rejection: rejection,
    ),
    InvalidInputFailure() => const SignUpProblem.rejected(),

    // AF-05.
    ConfigurationFailure() ||
    NotInitializedFailure() => SignUpProblem.configuration(failure: failure),

    _ => SignUpProblem.other(failure: failure),
  };
}
