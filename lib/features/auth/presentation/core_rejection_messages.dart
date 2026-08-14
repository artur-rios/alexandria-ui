import '../../../core/failures/core_rejection.dart';
import '../../../core/l10n/generated/app_localizations.dart';

/// The message the owner reads for a rejection the core named.
///
/// The core sends a stable code and the values behind it; this is where that
/// becomes a sentence, in the owner's language. Translating the core's own
/// English sentence would be impossible, and showing it would leave half the
/// product in one language (NFR-09).
///
/// A code this version does not know falls back to the generic message. That
/// matters: the core can add a rule at any time, and an owner meeting a new one
/// should read something plain rather than a code or a blank.
String coreRejectionMessage(AppLocalizations l10n, CoreRejection rejection) =>
    switch (rejection.code) {
      // The bound comes from the core, not from a number restated here — the
      // policy is the core's, and a hardcoded 12 would be wrong the day it
      // changes.
      'password_too_short' => l10n.rejectionPasswordTooShort(
        rejection.params['min'] ?? '',
      ),
      'password_too_long' => l10n.rejectionPasswordTooLong(
        rejection.params['max'] ?? '',
      ),
      'password_whitespace' => l10n.rejectionPasswordWhitespace,
      'password_repeated_character' => l10n.rejectionPasswordRepeatedCharacter,
      'password_too_common' => l10n.rejectionPasswordTooCommon,
      'password_contains_email' => l10n.rejectionPasswordContainsEmail,
      'password_confirmation_mismatch' => l10n.signUpPasswordMismatch,

      'email_required' => l10n.loginEmailMissing,
      'email_untrimmed' => l10n.rejectionEmailUntrimmed,
      'email_malformed' => l10n.loginEmailMalformed,

      _ => l10n.failureInvalidInput,
    };
