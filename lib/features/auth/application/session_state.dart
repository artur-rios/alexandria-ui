import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import '../domain/auth_gateway.dart';
import '../domain/session.dart';

part 'session_state.freezed.dart';

/// Whether the owner is authenticated, and — when they are not — why not.
///
/// A union rather than a nullable [Session] because "signed out" and "signed
/// out because the core rejected a call" are different things to the owner:
/// the second owes them an explanation (UC-02 AF-04, FR-AU-08).
@freezed
sealed class SessionState with _$SessionState {
  /// There is no active session. The login screen is presented and no catalog
  /// call is issued (FR-AU-07).
  ///
  /// [endedBecause] is set only when a session was discarded by rejection
  /// rather than never having existed.
  const factory SessionState.absent({Failure? endedBecause}) = SessionAbsent;

  /// The owner is authenticated.
  ///
  /// [confirmation] is what the core said about the confirmation message when
  /// this session began, and is present only for a session that registration
  /// opened. `null` after a login, which sends no message and reports none.
  const factory SessionState.active({
    required Session session,
    ConfirmationDelivery? confirmation,
  }) = SessionActive;
}
