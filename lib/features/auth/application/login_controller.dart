import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/auth_gateway.dart';
import '../domain/login_validation.dart';
import 'login_state.dart';
import 'session_controller.dart';
import 'session_state.dart';

/// Drives UC-02's main flow and its alternative flows.
///
/// It validates locally, calls the core once, and turns the outcome into
/// either a session or something the owner can read. It never decides whether
/// credentials are correct — that is the core's alone (BR-02).
class LoginController extends Notifier<LoginState> {
  // Read from the composition root in build() rather than taken as constructor
  // arguments, as StartupController does: a NotifierProvider builds its
  // notifier without a ref, and reading here is what lets a test override the
  // gateway wholesale (IR-07).
  late AuthGateway _gateway;
  late SessionController _session;

  @override
  LoginState build() {
    _gateway = ref.read(authGatewayProvider);
    _session = ref.read(sessionControllerProvider.notifier);
    return const LoginState.editing();
  }

  /// Attempts a login with what the owner typed (UC-02 main flow, steps 3–7).
  ///
  /// Returns without calling the core when local validation rejects the input
  /// (AF-01), and does nothing at all while an attempt is already in flight.
  Future<void> submit({required String email, required String password}) async {
    if (state is LoginSubmitting) return;

    // Step 4: validate before the call, so an attempt that cannot succeed
    // never becomes one (FR-AU-03).
    final emailError = validateEmail(email);
    final passwordError = validatePassword(password);

    if (emailError != null || passwordError != null) {
      state = LoginState.editing(
        emailError: emailError,
        passwordError: passwordError,
      );
      return;
    }

    // Whatever ended the previous session has been superseded by the owner
    // acting, so its explanation is cleared before this attempt reports its
    // own outcome.
    _session.acknowledgeEnding();
    state = const LoginState.submitting();

    final outcome = await _gateway.logIn(email: email, password: password);

    switch (outcome) {
      // Steps 5–7: the session is held in memory, and the plaintext password
      // is left behind with the arguments of this call (FR-AU-05, FR-AU-11).
      case AuthenticatedOutcome(:final session):
        state = const LoginState.editing();
        _session.establish(session);

      case FailedOutcome(:final failure):
        state = LoginState.editing(problem: _problemFor(failure));
    }
  }

  /// How each failure the core can answer with reads to the owner.
  ///
  /// `ConfigurationFailure` is AF-03 rather than a generic configuration
  /// problem because, within the core's login command, the only thing that
  /// produces it is credentials never having been set. If the core grows a
  /// second configuration failure on that path, this mapping is the line that
  /// has to change.
  LoginProblem _problemFor(Failure failure) => switch (failure) {
    UnauthorizedFailure() => const LoginProblem.rejected(),
    ConfigurationFailure() => const LoginProblem.noAccount(),
    NotInitializedFailure() => LoginProblem.coreNotReady(failure: failure),
    _ => LoginProblem.other(failure: failure),
  };
}

/// Whether the catalog is reachable for [state] (FR-AU-07).
///
/// A session and nothing else. The core used to gate this on the account's
/// e-mail being confirmed; it dropped confirmation entirely on 2026-08-18 and
/// no longer reports the flag, so there is nothing left to lock the catalog
/// behind. An owner who cannot sign in recovers with a recovery code (UC-41)
/// rather than through their inbox.
bool catalogIsReachable(SessionState state) => switch (state) {
  SessionActive() => true,
  SessionAbsent() => false,
};
