import 'package:freezed_annotation/freezed_annotation.dart';

part 'index_run.freezed.dart';

/// Where a run is (System Requirements §4.8).
///
/// The core's own vocabulary, not a reinterpretation of it: `interrupted` is
/// what a run becomes when the application was closed while it was in flight
/// (UC-06 AF-05), and collapsing it into `failed` would tell the owner
/// something went wrong when nothing did.
enum IndexRunStatus {
  /// The core is still scanning.
  running,

  /// The run finished.
  complete,

  /// The run stopped on an error, which the run carries.
  failed,

  /// The run did not finish, and nothing is running now (AF-05).
  interrupted;

  /// The status [raw] names, or [IndexRunStatus.failed] when the core answers
  /// one this application does not know.
  ///
  /// Falling back to failed rather than throwing: a core that grows a status
  /// must not make the outcome screen unreadable, and "something is wrong
  /// with this run" is the safe reading of a word we cannot interpret.
  static IndexRunStatus parse(String? raw) => switch (raw) {
    'running' => IndexRunStatus.running,
    'complete' => IndexRunStatus.complete,
    'interrupted' => IndexRunStatus.interrupted,
    _ => IndexRunStatus.failed,
  };

  /// Whether the core is still working on this run.
  bool get isInFlight => this == IndexRunStatus.running;
}

/// What a finished index run counted (FR-LB-08).
///
/// These are the core's four, not the specification's three. `FR-LB-08` asks
/// for "files added, files updated, and files found missing"; the core's
/// `RunCounts::Index` reports scanned, indexed, skipped, and failed, and only
/// a *refresh* run reports anything missing. The names here are the core's,
/// because inventing a mapping onto the requirement's words would be inventing
/// numbers the core never sent.
@freezed
abstract class IndexRunCounts with _$IndexRunCounts {
  /// Creates a tally.
  const factory IndexRunCounts({
    @Default(0) int scanned,
    @Default(0) int indexed,
    @Default(0) int skipped,
    @Default(0) int failed,
  }) = _IndexRunCounts;
}

/// One index run, as the application observes it (System Requirements §4.8).
@freezed
abstract class IndexRun with _$IndexRun {
  /// Creates a run.
  const factory IndexRun({
    /// The identifier the core returned when the run was started.
    required String runId,

    /// The folder being scanned.
    required String root,

    /// Where the run is.
    required IndexRunStatus status,

    /// What it counted, once it has finished.
    IndexRunCounts? counts,

    /// Why it failed, when it did.
    String? error,
  }) = _IndexRun;

  const IndexRun._();

  /// Whether the core is still working on this run.
  bool get isInFlight => status.isInFlight;
}
