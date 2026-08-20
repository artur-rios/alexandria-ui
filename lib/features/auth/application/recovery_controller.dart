import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/core_rejection.dart';
import '../../../core/failures/failure.dart';
import '../domain/auth_gateway.dart';

/// What is wrong with what the owner typed, before the core is called
/// (UC-41 AF-01).
enum RecoveryFieldError {
  /// The recovery code is blank after trimming.
  codeMissing,

  /// The new password is empty.
  passwordMissing,

  /// The two password entries differ.
  passwordMismatch,
}

/// Why a redemption did not happen (UC-41 AF-02 … AF-04).
sealed class RecoveryProblem {
  const RecoveryProblem();
}

/// Local validation refused it, and the core was not called.
class RecoveryInvalidInput extends RecoveryProblem {
  /// Creates the problem.
  const RecoveryInvalidInput({this.codeError, this.passwordError});

  /// What is wrong with the code, if anything.
  final RecoveryFieldError? codeError;

  /// What is wrong with the password or its confirmation, if anything.
  final RecoveryFieldError? passwordError;
}

/// The core refused, and named a reason (AF-02, AF-03, AF-04).
class RecoveryRefused extends RecoveryProblem {
  /// Creates the problem.
  const RecoveryRefused({this.rejection});

  /// The core's own stable reason code, when it gave one. `null` is a refusal
  /// with nothing to distinguish it, which reads as the generic message.
  final CoreRejection? rejection;
}

/// The core could not be reached, or answered something unreadable.
class RecoveryUnavailable extends RecoveryProblem {
  /// Creates the problem.
  const RecoveryUnavailable({required this.failure});

  /// What went wrong.
  final Failure failure;
}

/// Where UC-41 is.
sealed class RecoveryState {
  const RecoveryState();
}

/// The owner is filling the form in.
class RecoveryEditing extends RecoveryState {
  /// Creates the state.
  const RecoveryEditing({this.problem});

  /// What the last attempt hit, or `null` before there was one.
  final RecoveryProblem? problem;
}

/// A redemption is in flight.
class RecoverySubmitting extends RecoveryState {
  /// Creates the state.
  const RecoverySubmitting();
}

/// The password was replaced (main flow step 6).
class RecoveryDone extends RecoveryState {
  /// Creates the state.
  const RecoveryDone();
}

/// Drives UC-41: spending a recovery code on a new password.
///
/// It validates locally, calls the core once, and turns what comes back into
/// something the owner can read. It enforces no password policy of its own and
/// judges no code: both belong to the core (`BR-02`, `FR-AU-19`).
class RecoveryController extends Notifier<RecoveryState> {
  late AuthGateway _gateway;

  @override
  RecoveryState build() {
    _gateway = ref.read(authGatewayProvider);
    return const RecoveryEditing();
  }

  /// Returns the owner to an empty form, discarding whatever the last attempt
  /// reported.
  void reset() => state = const RecoveryEditing();

  /// Attempts the redemption (main flow steps 3 to 6).
  ///
  /// Does nothing while an attempt is already in flight: a second call would
  /// spend a second code.
  Future<void> submit({
    required String code,
    required String newPassword,
    required String passwordConfirmation,
  }) async {
    if (state is RecoverySubmitting) return;

    // Step 3, and AF-01: everything checkable without the core is checked
    // here, so an attempt that cannot succeed never spends a code.
    final codeError = code.trim().isEmpty
        ? RecoveryFieldError.codeMissing
        : null;
    final passwordError = switch (newPassword) {
      '' => RecoveryFieldError.passwordMissing,
      _ when newPassword != passwordConfirmation =>
        RecoveryFieldError.passwordMismatch,
      _ => null,
    };

    if (codeError != null || passwordError != null) {
      state = RecoveryEditing(
        problem: RecoveryInvalidInput(
          codeError: codeError,
          passwordError: passwordError,
        ),
      );
      return;
    }

    state = const RecoverySubmitting();

    final outcome = await _gateway.redeemRecoveryCode(
      code: code,
      newPassword: newPassword,
      passwordConfirmation: passwordConfirmation,
    );

    switch (outcome) {
      // Step 6: the core invalidated every session, so there is nothing to
      // establish here — the owner signs in with the password they just set.
      case RecoveredOutcome():
        state = const RecoveryDone();

      case FailedRecoveryOutcome(:final failure):
        state = RecoveryEditing(problem: _problemFor(failure));
    }
  }

  /// How each failure the core can answer with reads to the owner.
  RecoveryProblem _problemFor(Failure failure) => switch (failure) {
    // AF-02, AF-03, and AF-04: the core named which — `recovery_code_unknown`,
    // `recovery_code_used`, or a password-policy code. Carrying the rejection
    // rather than deciding here is what lets the screen tell an unrecognised
    // code from a spent one (FR-AU-16).
    RejectedFailure(:final rejection) => RecoveryRefused(rejection: rejection),

    // The same refusals from a core that named no code. Readable, but only
    // generically — which is the honest outcome when there is nothing to read.
    InvalidInputFailure() => const RecoveryRefused(),

    // AF-06: no account to recover. Reported as an ordinary refusal rather
    // than as its own message: this call is unauthenticated, and an answer
    // that distinguished "no account" would tell a stranger whether one
    // exists.
    NotFoundFailure() => const RecoveryRefused(),

    _ => RecoveryUnavailable(failure: failure),
  };
}
