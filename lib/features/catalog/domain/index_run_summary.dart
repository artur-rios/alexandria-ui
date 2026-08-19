import '../../../core/l10n/generated/app_localizations.dart';

/// What the dashboard says about the most recent run (UC-14, FR-CT-11).
///
/// A closed set rather than a nullable run, because "nothing has run yet" and
/// "a run is going" and "the last one finished" are three different sentences
/// and the dashboard has to pick one.
enum IndexRunSummary {
  /// Nothing has been scanned or refreshed in this session.
  none,

  /// A run is in flight (AF-04).
  running,

  /// The last run finished.
  complete,

  /// The last run stopped on an error.
  failed,

  /// The last run did not finish, because the application closed.
  interrupted;

  /// The sentence this summary reads as.
  String describe(AppLocalizations l10n) => switch (this) {
    IndexRunSummary.none => l10n.dashboardLastRunNone,
    IndexRunSummary.running => l10n.dashboardLastRunRunning,
    IndexRunSummary.complete => l10n.dashboardLastRunComplete,
    IndexRunSummary.failed => l10n.dashboardLastRunFailed,
    IndexRunSummary.interrupted => l10n.dashboardLastRunInterrupted,
  };
}
