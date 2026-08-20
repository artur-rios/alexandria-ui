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
  /// [recoveryCodes] is the set registration minted, and is `null` for a
  /// login: only the call that creates the account returns them, and only
  /// once (FR-AU-12). An empty list is not the same as `null` — it is an
  /// account created without codes, which UC-40 AF-03 reports.
  const factory AuthOutcome.authenticated({
    required Session session,
    List<String>? recoveryCodes,
  }) = AuthenticatedOutcome;

  /// The call was made and did not authenticate the owner.
  const factory AuthOutcome.failed({required Failure failure}) = FailedOutcome;
}

/// What redeeming a recovery code produced (UC-41 main flow step 5).
@freezed
sealed class RecoveryOutcome with _$RecoveryOutcome {
  /// The core replaced the password, spent the code, and invalidated every
  /// session.
  const factory RecoveryOutcome.recovered() = RecoveredOutcome;

  /// The core refused, and the stored password is unchanged (AF-02, AF-03,
  /// AF-04). The code is spent only on success — the core does not consume it
  /// for a redemption that failed for any other reason.
  const factory RecoveryOutcome.failed({required Failure failure}) =
      FailedRecoveryOutcome;
}

/// What the core knows about the owner's account (UC-42 main flow step 1).
@freezed
abstract class AccountSummary with _$AccountSummary {
  /// Creates a summary.
  const factory AccountSummary({
    /// The account's address, as the core holds it.
    required String email,

    /// How many recovery codes are still unspent, or `null` when the core did
    /// not report it.
    ///
    /// Nullable rather than defaulted to zero: zero means the account cannot
    /// currently be recovered, which is a thing worth saying, and a core that
    /// answered without the number must not be made to say it (`FR-AU-19`).
    int? recoveryCodesRemaining,
  }) = _AccountSummary;
}

/// What reading the account produced (UC-42 main flow step 1).
@freezed
sealed class AccountOutcome with _$AccountOutcome {
  /// The core answered.
  const factory AccountOutcome.read({required AccountSummary account}) =
      AccountRead;

  /// The core could not answer (AF-03, AF-04).
  const factory AccountOutcome.failed({required Failure failure}) =
      AccountFailed;
}

/// What regenerating the recovery codes produced (UC-42 main flow step 4).
@freezed
sealed class RegenerateOutcome with _$RegenerateOutcome {
  /// The core replaced the whole set and returned the new one, once.
  const factory RegenerateOutcome.regenerated({
    required List<String> recoveryCodes,
  }) = Regenerated;

  /// The core refused, and every existing code still works (AF-02, AF-04).
  const factory RegenerateOutcome.failed({required Failure failure}) =
      FailedRegenerateOutcome;
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
  Future<AuthOutcome> logIn({required String email, required String password});

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

  /// Replaces the stored e-mail and password (FR-AU-10, UC-04).
  ///
  /// [credential] is the active session's, which the core requires: this
  /// changes credentials that already exist. The session stays valid
  /// afterwards, so the caller keeps the one it passed in.
  ///
  /// As with registration, the core takes the confirmation too — it is the
  /// one that refuses a mismatch, and the application checks first only so an
  /// attempt that cannot succeed never becomes a call (AF-01).
  ///
  /// Neither password nor [credential] is retained beyond this call
  /// (FR-AU-11).
  Future<CredentialChangeOutcome> changeCredentials({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String credential,
  });

  /// Reads the owner's address and how many recovery codes remain
  /// (FR-AU-14, UC-42).
  Future<AccountOutcome> account({required String credential});

  /// Replaces the whole recovery-code set (FR-AU-17, UC-42).
  ///
  /// Answers the new codes, which exist in that answer and nowhere else. Every
  /// code from the previous set stops working.
  Future<RegenerateOutcome> regenerateRecoveryCodes({
    required String credential,
  });

  /// Replaces a forgotten password with a recovery code (FR-AU-15, UC-41).
  ///
  /// Takes no session credential: this is the call for an owner who cannot
  /// sign in. Every plaintext is used for the duration of this call and not
  /// retained (FR-AU-11).
  Future<RecoveryOutcome> redeemRecoveryCode({
    required String code,
    required String newPassword,
    required String passwordConfirmation,
  });

  /// Whether the core already holds an account (FR-AU-01).
  ///
  /// Answers main flow step 1: the application shows sign-up on a fresh
  /// installation and login otherwise, before the owner types anything.
  Future<AccountExistence> accountExists();
}

/// What a credential change produced (UC-04).
///
/// Its own union rather than reusing [AuthOutcome]: changing credentials does
/// not authenticate anyone. The session that authorized the call is the one
/// that stays valid afterwards, and an outcome carrying a `Session` would
/// invite a caller to replace it with a new one that does not exist.
@freezed
sealed class CredentialChangeOutcome with _$CredentialChangeOutcome {
  /// The core stored the new salted hash (main flow step 5).
  const factory CredentialChangeOutcome.changed() = ChangedOutcome;

  /// The core refused, and the stored credentials are unchanged (AF-03).
  const factory CredentialChangeOutcome.failed({required Failure failure}) =
      FailedChangeOutcome;
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
