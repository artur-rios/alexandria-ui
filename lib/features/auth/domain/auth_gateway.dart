import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import 'session.dart';

part 'auth_gateway.freezed.dart';

/// What a login attempt produced.
///
/// A closed union rather than a nullable return or a thrown exception: the
/// caller must handle the failure branch to compile, and the failure is a
/// typed [Failure] that already knows its localized message (IR-08).
///
/// Deliberately local to this feature. A project-wide `Result<T>` designed
/// from a single example would be a guess; the second gateway is what should
/// generalize this shape, if it turns out to be the same shape.
@freezed
sealed class LoginOutcome with _$LoginOutcome {
  /// The core accepted the credentials and returned [session].
  const factory LoginOutcome.authenticated({required Session session}) =
      AuthenticatedOutcome;

  /// The call was made and did not authenticate the owner.
  const factory LoginOutcome.failed({required Failure failure}) = FailedOutcome;
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
  Future<LoginOutcome> logIn({
    required String email,
    required String password,
  });
}
