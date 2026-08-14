// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Alexandria';

  @override
  String get retry => 'Try again';

  @override
  String get coreUnavailableTitle => 'Alexandria\'s core is not available';

  @override
  String get loginTitle => 'Sign in to Alexandria';

  @override
  String get loginEmailLabel => 'E-mail';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginEmailMissing => 'Enter your e-mail address.';

  @override
  String get loginEmailMalformed =>
      'That does not look like an e-mail address.';

  @override
  String get loginPasswordMissing => 'Enter your password.';

  @override
  String get loginRejected =>
      'That e-mail and password do not match an account.';

  @override
  String get loginNoAccount =>
      'No account has been set up on this computer yet.';

  @override
  String get signUpTitle => 'Create your Alexandria account';

  @override
  String get signUpIntro =>
      'This is the only account. Its password cannot be recovered, so choose one you will not lose.';

  @override
  String get signUpPasswordConfirmationLabel => 'Repeat password';

  @override
  String get signUpSubmit => 'Create account';

  @override
  String get signUpPasswordConfirmationMissing => 'Repeat your password.';

  @override
  String get signUpPasswordMismatch => 'The two passwords do not match.';

  @override
  String get signUpRejected =>
      'Alexandria did not accept those credentials. Try a longer, less predictable password that is not your e-mail address.';

  @override
  String get signUpAccountExists =>
      'An account already exists on this computer. Sign in instead.';

  @override
  String get signUpGoToLogin => 'Go to sign in';

  @override
  String get loginGoToSignUp => 'Create an account';

  @override
  String get loginSessionEndedTitle => 'You were signed out';

  @override
  String get catalogLockedTitle => 'Confirm your e-mail address';

  @override
  String catalogLockedBody(String email) {
    return 'Alexandria stays locked until the address $email is confirmed.';
  }

  @override
  String failureCoreLibraryNotLoaded(String path) {
    return 'The Alexandria core could not be loaded from $path.';
  }

  @override
  String failureApplicationDirectoryUnavailable(String path) {
    return 'The application folder $path could not be created.';
  }

  @override
  String get failureCoreInitializationFailed =>
      'The Alexandria core could not open the catalog.';

  @override
  String get failureCoreUnhealthy =>
      'The Alexandria core reported that it is not healthy.';

  @override
  String failureCoreVersionUnsupported(String found, String required) {
    return 'This version of Alexandria needs a core matching $required, but found $found.';
  }

  @override
  String get failurePreferencesUnreadable =>
      'Your preferences could not be read, so the system theme and language are being used.';

  @override
  String get failureInvalidInput => 'Alexandria rejected that as invalid.';

  @override
  String get failureUnauthorized =>
      'Your session has ended. Please sign in again.';

  @override
  String get failureNotInitialized =>
      'Alexandria is not ready yet. Please restart the application.';

  @override
  String get failureNotFound => 'That item no longer exists.';

  @override
  String get failureInvalidState =>
      'That cannot be done to this item right now.';

  @override
  String get failureDisk =>
      'The file could not be read or written on disk. Nothing was changed.';

  @override
  String get failureIntegrity =>
      'The file on disk no longer matches what Alexandria recorded.';

  @override
  String get failureConfiguration =>
      'Alexandria\'s configuration could not be read.';

  @override
  String get failureConflict => 'That already exists in Alexandria.';

  @override
  String get failureRateLimited =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get failureServiceUnavailable =>
      'Alexandria could not reach a service it needs, so that step did not happen.';

  @override
  String rejectionPasswordTooShort(String min) {
    return 'Use at least $min characters.';
  }

  @override
  String rejectionPasswordTooLong(String max) {
    return 'Use at most $max characters.';
  }

  @override
  String get rejectionPasswordWhitespace => 'A password cannot be only spaces.';

  @override
  String get rejectionPasswordRepeatedCharacter =>
      'A password cannot be one character repeated.';

  @override
  String get rejectionPasswordTooCommon =>
      'That password is too common. Choose something less predictable.';

  @override
  String get rejectionPasswordContainsEmail =>
      'A password cannot contain your e-mail address.';

  @override
  String get rejectionEmailUntrimmed =>
      'Remove the spaces around your e-mail address.';

  @override
  String get catalogLockedUndeliverable =>
      'The confirmation message could not be sent, so it is not on its way. Alexandria cannot deliver e-mail yet.';

  @override
  String get failureUnexpected => 'Something went wrong in Alexandria.';
}
