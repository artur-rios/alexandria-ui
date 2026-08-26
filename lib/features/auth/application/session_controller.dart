import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/session.dart';
import 'session_state.dart';

/// Holds the owner's session for the duration of the application run
/// (FR-AU-05).
///
/// This is the only place the session lives: it is never handed to the
/// settings store, and the credential never reaches the log (FR-AU-11).
class SessionController extends Notifier<SessionState> {
  static final Logger _log = Logger('auth');

  @override
  SessionState build() => const SessionState.absent();

  /// The credential to present on a core call that requires one (FR-AU-06),
  /// or `null` when there is no active session.
  String? get credential => switch (state) {
    SessionActive(:final session) => session.credential,
    SessionAbsent() => null,
  };

  /// Records the session a successful login or registration produced.
  ///
  /// Whatever the previous session left in memory is wound down first
  /// (UC-03 main flow step 3, BR-05). The same activities sign-out ends are
  /// ended again here, and for the same reason from the other side: a
  /// projection cached before the sign-out must not be what the new session
  /// sees. Doing it *before* the session is recorded is what makes the reads
  /// that follow use the new credential rather than answer from the old
  /// session's cache.
  void establish(Session session, {List<String>? recoveryCodes}) {
    for (final activity in ref.read(sessionActivitiesProvider)) {
      // Not awaited, and deliberately: establishing a session is what the
      // login screen does on the way to the shell, and none of these ends
      // blocks on anything — they drop what is held, they do not go and ask
      // the core.
      unawaited(activity.end());
    }

    // Session.toString redacts the credential, so nothing here can leak it
    // into the log file this line lands in (FR-AU-11).
    _log.info('session established for ${session.email}');
    state = SessionState.active(session: session, recoveryCodes: recoveryCodes);

    // After the state assignment, not with the `end()` calls above: an
    // activity that begins by reading the credential — the library re-check
    // does — would find none if it ran before the session was recorded.
    for (final activity in ref.read(sessionActivitiesProvider)) {
      // Not awaited, for the same reason as the `end()` loop above, though not
      // for the same cause: `end()` only drops what it already holds, but a
      // `begin()` may genuinely go and ask the core, and establishing a
      // session — what the login screen calls on its way to the shell — must
      // not block on that.
      unawaited(activity.begin());
    }
  }

  /// Puts a freshly regenerated set on screen (UC-42 main flow step 4).
  ///
  /// The same state UC-40 uses, and deliberately: a set is a set, and the
  /// rules for showing one — once, acknowledged, then gone — do not change
  /// with where it came from (FR-AU-12, FR-AU-17).
  void presentRecoveryCodes(List<String> codes) {
    if (state case SessionActive(:final session)) {
      state = SessionState.active(session: session, recoveryCodes: codes);
    }
  }

  /// Records that the owner has stored the recovery codes (UC-40 step 4).
  ///
  /// Dropping them from the state is what opens the catalog, and it is also
  /// the whole of FR-AU-13's "no way back": nothing wrote them anywhere, so
  /// forgetting the list is forgetting the codes.
  void acknowledgeRecoveryCodes() {
    if (state case SessionActive(:final session)) {
      state = SessionState.active(session: session);
    }
  }

  /// Discards the session and returns the owner to the login screen, stating
  /// why (UC-02 AF-04, FR-AU-08).
  ///
  /// A no-op when there is no active session: two rejected calls arriving
  /// together must not produce two explanations, and neither should replace
  /// the reason the owner has not read yet.
  void invalidate(Failure reason) {
    if (state is! SessionActive) return;

    _log.info('session discarded (core status ${reason.coreStatusCode})');
    state = SessionState.absent(endedBecause: reason);
  }

  /// Discards the session because the owner asked to sign out (UC-03 main
  /// flow steps 3 and 4, FR-AU-09).
  ///
  /// Separate from [invalidate] because the two endings owe the owner
  /// different things: a rejection has to be explained, and a sign-out asked
  /// for is explanation enough on its own. [indexRunContinues] carries the one
  /// thing a sign-out does have to say (AF-02).
  ///
  /// The activities are wound down before this is called, so by the time the
  /// credential goes nothing is still using it.
  void end({bool indexRunContinues = false}) {
    if (state is! SessionActive) return;

    _log.info('session ended by the owner');
    state = SessionState.absent(indexRunContinues: indexRunContinues);
  }

  /// Clears the explanation once the owner has seen it, so it does not
  /// reappear on every later visit to the login screen.
  void acknowledgeEnding() {
    if (state case SessionAbsent(
      :final endedBecause,
      :final indexRunContinues,
    ) when endedBecause != null || indexRunContinues) {
      state = const SessionState.absent();
    }
  }
}
