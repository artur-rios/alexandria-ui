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
      // The specification has the owner land on the confirmation prompt here.
      // The core has no e-mail confirmation at all, so the session is
      // confirmed and the owner lands where a confirmed session lands. UC-40
      // is what changes this.
      case AuthenticatedOutcome(:final session):
        state = const SignUpState.editing();
        _session.establish(session);

      case FailedOutcome(:final failure):
        state = SignUpState.editing(problem: _problemFor(failure));
    }
  }

  /// How each failure the core can answer with reads to the owner.
  SignUpProblem _problemFor(Failure failure) => switch (failure) {
    // AF-04: the core refuses to overwrite an account that exists.
    ConflictFailure() => const SignUpProblem.accountExists(),

    // AF-03: the core rejected the credentials — a password too short, too
    // common, or containing the address.
    InvalidInputFailure() => const SignUpProblem.rejected(),

    // AF-05.
    ConfigurationFailure() ||
    NotInitializedFailure() => SignUpProblem.configuration(failure: failure),

    _ => SignUpProblem.other(failure: failure),
  };
}
