import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/auth_gateway.dart';
import '../domain/login_validation.dart';
import 'change_credentials_state.dart';
import 'session_controller.dart';

/// Drives UC-04: replacing the stored e-mail and password.
///
/// It validates locally, calls the core once with the active session, and
/// turns the outcome into a confirmation or something the owner can read. As
/// with sign-up, it enforces no password policy of its own — the strength
/// rules belong to the core (BR-02, FR-AU-03).
class ChangeCredentialsController extends Notifier<ChangeCredentialsState> {
  // Read from the composition root in build(), as the other auth controllers
  // do.
  late AuthGateway _gateway;
  late SessionController _session;

  @override
  ChangeCredentialsState build() {
    _gateway = ref.read(authGatewayProvider);
    _session = ref.read(sessionControllerProvider.notifier);
    return const ChangeCredentialsState.editing();
  }

  /// Attempts the change (main flow steps 3–6).
  ///
  /// Returns without calling the core when local validation rejects the input
  /// (AF-01), and does nothing while an attempt is already in flight.
  Future<void> submit({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (state is ChangeCredentialsSubmitting) return;

    // Step 3, before the call, so an attempt that cannot succeed never becomes
    // one (AF-01).
    final emailError = validateEmail(email);
    final passwordError = validatePassword(password);
    final confirmationError = validatePasswordConfirmation(
      password,
      passwordConfirmation,
    );

    if (emailError != null ||
        passwordError != null ||
        confirmationError != null) {
      state = ChangeCredentialsState.editing(
        emailError: emailError,
        passwordError: passwordError,
        passwordConfirmationError: confirmationError,
      );
      return;
    }

    final credential = _session.credential;
    if (credential == null) {
      // Defensive. The form is only offered inside an active session — the
      // preferences dialog reaches it from the shell, and the shell is what a
      // signed-in owner sees — so this is unreachable from the interface. It
      // returns rather than inventing a failure to report, because there is no
      // core status behind it and a fabricated one would read as the core
      // having refused something it was never asked.
      state = const ChangeCredentialsState.editing();
      return;
    }

    state = const ChangeCredentialsState.submitting();

    final outcome = await _gateway.changeCredentials(
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      credential: credential,
    );

    switch (outcome) {
      // Step 6. The plaintext is left behind with this call's arguments, and
      // the session that authorized the change stays exactly as it was — the
      // postcondition says it remains valid, so nothing is re-established
      // (FR-AU-11).
      case ChangedOutcome():
        state = const ChangeCredentialsState.changed();

      // AF-02: the core rejected the session itself. Discarding it returns the
      // owner to login with the reason stated, which is what the session
      // controller already does for every other rejected call (FR-AU-08).
      case FailedChangeOutcome(failure: final UnauthorizedFailure failure):
        state = const ChangeCredentialsState.editing();
        _session.invalidate(failure);

      // AF-03: the core refused the new credentials and left the stored ones
      // alone. The owner reads why and the form keeps what they typed.
      case FailedChangeOutcome(:final failure):
        state = ChangeCredentialsState.editing(problem: failure);
    }
  }

  /// Clears the verdicts as the owner edits, so a form being corrected does
  /// not keep showing a complaint about text that has changed.
  void resetProblems() {
    if (state
        case ChangeCredentialsEditing(
          :final emailError,
          :final passwordError,
          :final passwordConfirmationError,
          :final problem,
        )
        when emailError != null ||
            passwordError != null ||
            passwordConfirmationError != null ||
            problem != null) {
      state = const ChangeCredentialsState.editing();
    }
  }

  /// Returns the form to its initial state, so reopening it does not show the
  /// previous change's confirmation.
  void reset() => state = const ChangeCredentialsState.editing();
}
