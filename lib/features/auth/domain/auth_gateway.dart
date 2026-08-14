import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import 'session.dart';

part 'auth_gateway.freezed.dart';

/// What an authentication attempt produced — a login (UC-02) or a
/// registration (UC-01), which both end in the same place: a session, or a
/// reason there is not one.
///
/// A closed union rather than a nullable return or a thrown exception: the
/// caller must handle the failure branch to compile, and the failure is a
/// typed [Failure] that already knows its localized message (IR-08).
///
/// Deliberately local to this feature. A project-wide `Result<T>` designed
/// from one example would be a guess; the first gateway outside `auth` is what
/// should generalize this shape, if it turns out to be the same shape.
@freezed
sealed class AuthOutcome with _$AuthOutcome {
  /// The core accepted the credentials and returned [session].
  ///
  /// [confirmation] is what the core said about the confirmation message it
  /// tried to send, and is present only for registration — logging in sends no
  /// message and reports none (UC-01 AF-06).
  const factory AuthOutcome.authenticated({
    required Session session,
    ConfirmationDelivery? confirmation,
  }) = AuthenticatedOutcome;

  /// The call was made and did not authenticate the owner.
  const factory AuthOutcome.failed({required Failure failure}) = FailedOutcome;
}

/// What became of the confirmation message the core tried to send when the
/// account was created (UC-01 AF-06).
///
/// A failed send is not a failed registration: the account exists and the
/// session is open. It changes only what the owner is told next — that the
/// message they are waiting for is not coming, rather than leaving them
/// watching an empty inbox.
@freezed
abstract class ConfirmationDelivery with _$ConfirmationDelivery {
  /// Creates a delivery outcome.
  const factory ConfirmationDelivery({
    /// Whether the message reached a transport.
    required bool sent,

    /// Why it did not, as the core's stable reason code — today
    /// `mail_not_configured`. Absent when [sent] is `true`.
    String? reasonCode,
  }) = _ConfirmationDelivery;
}

/// The application's view of the core's authentication operations (IR-02,
/// NFR-17).
///
/// Owned by the Domain layer so that Application and Presentation depend on
/// this rather than on the FFI boundary behind it. The implementation lives in
/// the Data layer and is bound in the composition root.
abstract interface class AuthGateway {
  /// Authenticates [email] and [password] through the core's local-login
  /// operation (FR-AU-04).
  ///
  /// [password] is used for the duration of this call and not retained
  /// (FR-AU-11).
  Future<AuthOutcome> logIn({
    required String email,
    required String password,
  });

  /// Creates the owner's single account through the core and opens a session
  /// (FR-AU-02, UC-01).
  ///
  /// The core takes the confirmation as well as the password: it is the one
  /// that refuses a mismatch, and the application checks first only so an
  /// attempt that cannot succeed never becomes a call (AF-02).
  ///
  /// Neither password is retained beyond this call (FR-AU-11).
  Future<AuthOutcome> register({
    required String email,
    required String password,
    required String passwordConfirmation,
  });

  /// Whether the core already holds an account (FR-AU-01).
  ///
  /// Answers main flow step 1: the application shows sign-up on a fresh
  /// installation and login otherwise, before the owner types anything.
  Future<AccountExistence> accountExists();
}

/// What the core answered when asked whether an account exists.
///
/// Three-valued rather than a boolean because "the core could not be asked" is
/// not the same as "there is no account", and treating it as one would send an
/// owner with an account to a sign-up screen that would then refuse them.
enum AccountExistence {
  /// The core holds credentials. The login screen is the entry point.
  present,

  /// The core holds none. This is a fresh installation, so sign-up is.
  absent,

  /// The question could not be answered. Login is presented, because it is the
  /// screen that recovers on its own — its own AF-03 sends the owner to
  /// sign-up if the core turns out to hold nothing.
  unknown,
}
