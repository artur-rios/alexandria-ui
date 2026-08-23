import 'package:freezed_annotation/freezed_annotation.dart';

part 'index_run.freezed.dart';

/// Where a run is (System Requirements §4.8).
///
/// The core's own vocabulary. `interrupted` is gone: a run the application
/// was closed on now comes back `paused` and resumable, which is a different
/// fact and deserves a different word.
enum IndexRunStatus {
  /// The core is scanning right now.
  running,

  /// The run stopped and can be picked up where it left off.
  paused,

  /// The run finished.
  complete,

  /// The run stopped on an error, which the run carries.
  failed,

  /// The run was abandoned. Terminal, and not resumable.
  cancelled;

  /// The status [raw] names, or [IndexRunStatus.failed] for one this
  /// application does not know.
  ///
  /// Falling back to failed rather than throwing: a core that grows a status
  /// must not make the screen unreadable, and "something is wrong with this
  /// run" is the safe reading of a word we cannot interpret.
  static IndexRunStatus parse(String? raw) => switch (raw) {
    'running' => IndexRunStatus.running,
    'paused' => IndexRunStatus.paused,
    'complete' => IndexRunStatus.complete,
    'cancelled' => IndexRunStatus.cancelled,
    _ => IndexRunStatus.failed,
  };

  /// Whether the core is working on this run right now.
  ///
  /// A paused run is outstanding but not in flight — nothing is happening
  /// until the owner resumes it, which is why polling follows this rather
  /// than "is the run finished".
  bool get isInFlight => this == IndexRunStatus.running;

  /// Whether the run is over for good.
  bool get isTerminal =>
      this == IndexRunStatus.complete ||
      this == IndexRunStatus.failed ||
      this == IndexRunStatus.cancelled;
}

/// Which half of a run is executing (FR-FC-28).
///
/// `discovering` has no total yet — the walk is still counting what it will
/// have to do — so a percentage during it would be invented.
enum IndexRunPhase {
  /// Walking the folder tree to find out what there is to process.
  discovering,

  /// Working through the entries discovery counted.
  processing;

  /// The phase [raw] names, or null for a run carrying none — which is every
  /// terminal run, and any run that never published one.
  static IndexRunPhase? parse(String? raw) => switch (raw) {
    'discovering' => IndexRunPhase.discovering,
    'processing' => IndexRunPhase.processing,
    _ => null,
  };
}

/// Which operation opened a run (System Requirements §4.8).
///
/// It decides which counts to read: the core's `RunCounts` is untagged and
/// flattened into the run body, and `kind` is what says which shape to expect.
enum IndexRunKind {
  /// A scan of one folder (UC-06).
  ///
  /// Named `scan` rather than `index`, which every enum already has as its
  /// ordinal.
  scan,

  /// A re-check of everything already cataloged (UC-07).
  refresh;

  /// The kind [raw] names, defaulting to [IndexRunKind.index].
  static IndexRunKind parse(String? raw) =>
      raw == 'refresh' ? IndexRunKind.refresh : IndexRunKind.scan;
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
  ///
  /// One class for both run kinds rather than a union, because the core sends
  /// one flattened object and `kind` already says which half of these fields
  /// it filled. Every field defaults, so reading the wrong half gives zeros
  /// rather than a parse failure — and the screen reads the half the kind
  /// names.
  const factory IndexRunCounts({
    // An index run's four (UC-06).
    @Default(0) int scanned,
    @Default(0) int indexed,
    @Default(0) int skipped,

    /// Entries already in the catalog when the walk reached them. Distinct
    /// from `skipped`, which is an unsupported file type: a resumed run
    /// re-walks and meets everything an earlier segment indexed, and folding
    /// the two together would report thousands of files as skipped.
    @Default(0) int alreadyCataloged,

    // A refresh run's three, plus the shared failure count (UC-07).
    @Default(0) int refreshed,
    @Default(0) int markedMissing,
    @Default(0) int unchanged,

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

    /// The folder being scanned, or empty for a refresh, which covers the
    /// whole catalog rather than one folder.
    required String root,

    /// Which operation opened this run.
    @Default(IndexRunKind.scan) IndexRunKind kind,

    /// Where the run is.
    required IndexRunStatus status,

    /// Which half of the run is executing, or null once it is terminal.
    IndexRunPhase? phase,

    /// How many entries the run has to get through, once discovery has
    /// counted them. Null while discovery is still counting.
    int? total,

    /// How many entries the run has finished with. Null for a run that never
    /// published progress.
    int? processed,

    /// How long the run has spent *working* — elapsed time minus the time it
    /// spent paused. The input to a remaining-time estimate; wall time would
    /// overstate the work done by however long the owner left it paused.
    @Default(0) int activeMillis,

    /// When the run was paused, for a run that is paused right now.
    DateTime? pausedAt,

    /// What it counted, once it has finished.
    IndexRunCounts? counts,

    /// Why it failed, when it did.
    String? error,
  }) = _IndexRun;

  const IndexRun._();

  /// Whether the core is still working on this run.
  bool get isInFlight => status.isInFlight;
}
