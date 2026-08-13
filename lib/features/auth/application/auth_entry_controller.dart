import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/auth_gateway.dart';

/// Which screen an owner without a session is shown.
enum AuthEntry {
  /// The core has not answered yet. The startup progress state stays on
  /// screen: flashing the wrong form and correcting it a moment later is worse
  /// than a slightly longer wait.
  resolving,

  /// No account exists — a fresh installation (UC-01, FR-AU-01).
  signUp,

  /// An account exists (UC-02).
  login,
}

/// Decides between sign-up and login, and lets either screen hand over to the
/// other (FR-AU-01).
///
/// The decision is made once per run, from the core, rather than remembered in
/// the settings store: the catalog database is the truth about whether an
/// account exists, and a stored answer would be wrong the moment the database
/// is replaced or removed.
class AuthEntryController extends Notifier<AuthEntry> {
  late AuthGateway _gateway;

  @override
  AuthEntry build() {
    _gateway = ref.read(authGatewayProvider);

    // Asked as soon as anything wants to know, which is when the application
    // has reached its ready state and found no session — the first moment the
    // core is loaded and the answer is needed. Deliberately not awaited: the
    // state starts at [AuthEntry.resolving] and moves when the core answers.
    unawaited(resolve());

    return AuthEntry.resolving;
  }

  /// Asks the core whether an account exists (main flow step 1).
  ///
  /// An unanswerable question resolves to [AuthEntry.login] rather than
  /// sign-up: login is the screen that recovers on its own, because its own
  /// AF-03 sends the owner to sign-up when the core turns out to hold nothing.
  /// Guessing the other way would offer to create an account over one that
  /// exists, and the core would refuse.
  Future<void> resolve() async {
    state = switch (await _gateway.accountExists()) {
      AccountExistence.absent => AuthEntry.signUp,
      AccountExistence.present => AuthEntry.login,
      AccountExistence.unknown => AuthEntry.login,
    };
  }

  /// Leaves sign-up for login (UC-01 AF-04).
  void goToLogin() => state = AuthEntry.login;

  /// Leaves login for sign-up (UC-02 AF-03).
  void goToSignUp() => state = AuthEntry.signUp;
}
