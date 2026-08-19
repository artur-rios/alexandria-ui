import '../l10n/generated/app_localizations.dart';
import 'failure.dart';

/// The localized message for a [Failure] (IR-08, FR-UX-09).
///
/// The switch is exhaustive over the sealed union, so adding a variant without
/// giving it a message is a compile error rather than a screen that renders a
/// blank or a status code.
extension FailureMessage on Failure {
  /// The message the owner reads. Never a raw status code, and never empty.
  String localizedMessage(AppLocalizations l10n) => switch (this) {
    CoreLibraryNotLoadedFailure(:final path) =>
      l10n.failureCoreLibraryNotLoaded(path),
    ApplicationDirectoryUnavailableFailure(:final path) =>
      l10n.failureApplicationDirectoryUnavailable(path),
    CoreInitializationFailedFailure() => l10n.failureCoreInitializationFailed,
    CoreUnhealthyFailure() => l10n.failureCoreUnhealthy,
    CoreVersionUnsupportedFailure(:final found, :final required) =>
      l10n.failureCoreVersionUnsupported(found, required),
    PreferencesUnreadableFailure() => l10n.failurePreferencesUnreadable,
    InvalidInputFailure() => l10n.failureInvalidInput,
    // A named rejection reads as the rule it broke, which needs the catalog of
    // reason codes rather than one string. The screens that can show it use
    // `coreRejectionMessage`; this is the fallback for anywhere that treats a
    // failure generically.
    RejectedFailure() => l10n.failureInvalidInput,
    RateLimitedFailure() => l10n.failureRateLimited,
    ServiceUnavailableFailure() => l10n.failureServiceUnavailable,
    UnauthorizedFailure() => l10n.failureUnauthorized,
    NotInitializedFailure() => l10n.failureNotInitialized,
    NotFoundFailure() => l10n.failureNotFound,
    InvalidStateFailure() => l10n.failureInvalidState,
    DiskFailure() => l10n.failureDisk,
    IntegrityFailure() => l10n.failureIntegrity,
    ConfigurationFailure() => l10n.failureConfiguration,
    ConflictFailure() => l10n.failureConflict,
    UnexpectedFailure() => l10n.failureUnexpected,
  };
}
