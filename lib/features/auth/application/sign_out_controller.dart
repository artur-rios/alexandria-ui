import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../shell/domain/session_activity.dart';

/// Drives UC-03: ending the session without closing the application.
///
/// Not a [Notifier], because signing out holds no state of its own — what it
/// produces is the absence of a session, which
/// [SessionController][sessionControllerProvider] already owns. This is the
/// order of operations and nothing else: wind the activities down, then
/// discard the credential.
class SignOutController {
  /// Creates the controller over [_ref].
  const SignOutController(this._ref);

  final Ref _ref;

  List<SessionActivity> get _activities => _ref.read(sessionActivitiesProvider);

  /// Whether anything would lose unsaved changes (AF-01, FR-ME-09).
  ///
  /// Asked before signing out rather than during it, so the warning can be
  /// shown while the session is still there to go back to.
  bool get holdsUnsavedChanges =>
      _activities.any((activity) => activity.holdsUnsavedChanges);

  /// Signs the owner out (main flow steps 2 to 4).
  ///
  /// Step 2 stops playback and step 3 discards the projections — both are
  /// activities, and both finish before the credential goes, so nothing is
  /// still holding it when it does. Step 4 needs no code here: the root
  /// presents the login screen the moment the session is absent (FR-AU-07).
  ///
  /// AF-01 is the caller's: this signs out when asked, and warning first is
  /// the dialog's job. AF-02 is answered here, because whether a run is in
  /// flight is only knowable before the activities are wound down.
  Future<void> signOut() async {
    final activities = _activities;

    final continues = activities.any(
      (activity) => activity.continuesInTheCore,
    );

    for (final activity in activities) {
      await activity.end();
    }

    _ref
        .read(sessionControllerProvider.notifier)
        .end(indexRunContinues: continues);
  }
}
