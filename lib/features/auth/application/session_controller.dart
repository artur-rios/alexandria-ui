import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/failures/failure.dart';
import '../domain/auth_gateway.dart';
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
  /// [confirmation] is passed on by registration alone (UC-01 AF-06).
  void establish(Session session, {ConfirmationDelivery? confirmation}) {
    // Session.toString redacts the credential, so nothing here can leak it
    // into the log file this line lands in (FR-AU-11).
    _log.info('session established for ${session.email}');
    state = SessionState.active(session: session, confirmation: confirmation);
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

  /// Clears the explanation once the owner has seen it, so it does not
  /// reappear on every later visit to the login screen.
  void acknowledgeEnding() {
    if (state case SessionAbsent(:final endedBecause) when endedBecause != null) {
      state = const SessionState.absent();
    }
  }
}
