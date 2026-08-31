import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/auth_gateway.dart';
import 'session_state.dart';

/// The owner's account, as the core reports it (UC-42 main flow step 1).
///
/// Read lazily, when something asks: it is one call, and the number it carries
/// only matters on the screen that offers to replace the set.
class AccountController extends AsyncNotifier<AccountSummary?> {
  @override
  Future<AccountSummary?> build() async {
    final credential = ref.watch(sessionControllerProvider) is SessionActive
        ? ref.read(sessionControllerProvider.notifier).credential
        : null;
    // No session, no call (FR-AU-07).
    if (credential == null) return null;

    final outcome = await ref
        .read(authGatewayProvider)
        .account(credential: credential);

    switch (outcome) {
      case AccountRead(:final account):
        return account;

      // AF-04: a rejected session returns the owner to login.
      case AccountFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        return null;

      // AF-03: the count could not be read. `null` rather than a throw — the
      // regeneration is still offered, because hiding it behind a number the
      // core would not give is the one outcome that helps nobody.
      case AccountFailed():
        return null;
    }
  }

  /// Reads it again, after the set has been replaced (step 5).
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

/// Why a regeneration did not happen (UC-42 AF-02).
class RegenerateRefusal {
  /// Creates a refusal.
  const RegenerateRefusal({required this.failure});

  /// What the core said. The existing codes are unchanged either way: the core
  /// replaced nothing.
  final Failure failure;
}

/// Drives UC-42: replacing the whole recovery-code set.
///
/// The new codes do not stay here. They go into the session state, which is
/// what puts them on screen under UC-40's rules — shown once, acknowledged,
/// then gone (`FR-AU-12`, `FR-AU-13`).
class RegenerateRecoveryCodesController extends Notifier<RegenerateRefusal?> {
  @override
  RegenerateRefusal? build() => null;

  /// Clears whatever the last attempt reported.
  void acknowledge() => state = null;

  /// Replaces the set (main flow steps 4 and 5).
  ///
  /// The confirmation is the screen's: it has to state that every existing
  /// code stops working before this is reached (`FR-AU-17`, BR-07).
  ///
  /// Answers whether the set was actually replaced. The screen closes itself
  /// on the way to showing the new codes, and it may only do that when there
  /// are new codes to show: closing on a refusal took away the one widget
  /// that renders the refusal, so the owner was returned to the catalog with
  /// no new codes, no explanation, and no sign that their existing ones still
  /// work.
  Future<bool> regenerate() async {
    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (credential == null) return false;

    final outcome = await ref
        .read(authGatewayProvider)
        .regenerateRecoveryCodes(credential: credential);

    switch (outcome) {
      case Regenerated(:final recoveryCodes):
        state = null;
        // Straight into the session state: the codes exist in that answer and
        // nowhere else, and this is what shows them before anything can lose
        // them.
        session.presentRecoveryCodes(recoveryCodes);
        await ref.read(accountControllerProvider.notifier).reload();
        return true;

      // AF-04: the session is discarded, which returns the owner to login.
      case FailedRegenerateOutcome(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);
        // The previous attempt's refusal, if there was one, is not about this
        // one — and the owner is on their way to the login screen.
        state = null;
        return false;

      // AF-02: the core refused and replaced nothing, so the existing codes
      // keep working and the screen says why.
      case FailedRegenerateOutcome(:final failure):
        state = RegenerateRefusal(failure: failure);
        return false;
    }
  }
}
