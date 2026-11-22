import 'dart:async';

import 'package:alexandria_ui/features/indexing/domain/index_gateway.dart';
import 'package:alexandria_ui/features/indexing/domain/index_run.dart';
import 'package:alexandria_ui/features/indexing/domain/run_priority.dart';

/// An [IndexGateway] that never reaches the core (Testing Specification §2.3).
///
/// A hand-written fake rather than a `mocktail` stub because a run is a
/// sequence: it is started, then read repeatedly, and what it answers on the
/// second read is the whole point of UC-06.
class FakeIndexGateway implements IndexGateway {
  /// What [readFailures] answers, by run id.
  ///
  /// Absent is a run that failed on nothing, which is what almost every test
  /// wants — the interesting case is the one that names files.
  final Map<String, RunFailuresOutcome> failures = {};

  /// Every run whose failures were asked for, in order.
  final List<String> failuresRequested = [];

  @override
  Future<RunFailuresOutcome> readFailures({required String runId}) async {
    failuresRequested.add(runId);

    return failures[runId] ?? const RunFailuresOutcome.read(failures: []);
  }

  /// Creates a gateway whose runs start and finish immediately.
  FakeIndexGateway({
    this.runId = '3f9a1b7c-2d4e-4a8b-9c1d-5e6f70819a2b',
    IndexStartOutcome? startOutcome,
  }) : startOutcome = startOutcome ?? IndexStartOutcome.started(runId: runId);

  /// The run id a successful start returns.
  final String runId;

  /// What a start answers, unless a more specific outcome is set.
  IndexStartOutcome startOutcome;

  /// What [readRun] answers, in order.
  ///
  /// Each read takes the next entry and the last one repeats, so a test writes
  /// "running, then complete" as two entries and gets exactly that.
  late List<IndexRunOutcome> readOutcomes = [
    IndexRunOutcome.read(
      run: IndexRun(
        runId: runId,
        root: '/home/owner/music',
        status: IndexRunStatus.complete,
        counts: const IndexRunCounts(scanned: 120, indexed: 118, skipped: 2),
      ),
    ),
  ];

  /// What [startRefresh] answers, or `null` to reuse [startOutcome].
  IndexStartOutcome? refreshOutcome;

  /// How many files [countCatalogedFiles] reports. Negative is "unknown".
  int catalogedFileCount = 120;

  /// How many times [countCatalogedFiles] was asked.
  ///
  /// AF-02's own count-before-call ordering means every `startRefresh`
  /// reaches this whether or not it goes on to call the core, so a test
  /// that wants proof `startRefresh` was reached at all — not merely that
  /// the core was not asked to start — asserts on this rather than on
  /// [refreshStarts].
  int catalogedFileCountAsked = 0;

  /// When set, [countCatalogedFiles] waits for this to complete before
  /// answering — a test's hook for pausing `startRefresh` mid-flight, most
  /// concretely to end the activities while the call is still outstanding.
  Completer<void>? catalogedFileCountGate;

  /// The priority each [startRefresh] was called with, in order.
  final List<RunPriority?> refreshStarts = [];

  /// What [readRun] was called with, in order.
  final List<({String runId})> reads = [];

  /// What [pauseRun] answers.
  RunControlOutcome pauseOutcome = const RunControlOutcome.ok();

  /// What [cancelRun] answers.
  RunControlOutcome cancelOutcome = const RunControlOutcome.ok();

  /// What [resumeRun] answers, or `null` to reuse [startOutcome].
  IndexStartOutcome? resumeOutcome;

  /// What [listActiveRuns] answers. Empty by default: no outstanding runs is
  /// the normal case.
  ActiveRunsOutcome activeRunsOutcome = const ActiveRunsOutcome.read(runs: []);

  /// What [listActiveRuns] answers once [startRefresh] has actually been
  /// called, replacing [activeRunsOutcome] from that point on. Ignored while
  /// null, which is the default.
  ///
  /// Exists for a scenario [activeRunsOutcome] alone cannot express: a test
  /// proving `IndexAppActivity.begin()` checks what the core already has
  /// outstanding (FR-LB-19) before it ever asks `startRefresh` to start one,
  /// and then wants the run that check just allowed to appear as outstanding
  /// once it exists. A call count could not stand in for this: this gateway
  /// also answers `ActiveRunsController`'s own bootstrap read, which the
  /// controller schedules on its own the moment anything first reads it, so
  /// how many times `listActiveRuns` has been called is not in a test's
  /// control. Which of the two outcomes is true, by contrast, is exactly
  /// what changed — a refresh that has actually started.
  ActiveRunsOutcome? activeRunsOutcomeOnceRefreshStarts;

  /// What [startLibraryIndex] answers, in order; empty reuses
  /// [startOutcome].
  final List<IndexStartOutcome> libraryStartOutcomes = [];

  /// What [startLibraryIndex] was called with, in order.
  final List<({String uuid, RunPriority? priority})> libraryStarts = [];

  @override
  Future<IndexStartOutcome> startLibraryIndex({
    required String uuid,
    RunPriority? priority,
  }) async {
    libraryStarts.add((uuid: uuid, priority: priority));
    return libraryStartOutcomes.isNotEmpty
        ? libraryStartOutcomes.removeAt(0)
        : startOutcome;
  }

  /// What [pauseRun] was called with, in order.
  final List<({String runId})> pauses = [];

  /// What [cancelRun] was called with, in order.
  final List<({String runId})> cancels = [];

  /// What [resumeRun] was called with, in order.
  final List<({String runId, RunPriority? priority})> resumes = [];

  @override
  Future<IndexStartOutcome> startRefresh({RunPriority? priority}) async {
    refreshStarts.add(priority);
    return refreshOutcome ?? startOutcome;
  }

  @override
  Future<int> countCatalogedFiles() async {
    catalogedFileCountAsked++;
    if (catalogedFileCountGate case final gate?) await gate.future;
    return catalogedFileCount;
  }

  @override
  Future<IndexRunOutcome> readRun({required String runId}) async {
    reads.add((runId: runId));

    final index = reads.length - 1;
    return readOutcomes[index.clamp(0, readOutcomes.length - 1)];
  }

  @override
  Future<RunControlOutcome> pauseRun({required String runId}) async {
    pauses.add((runId: runId));
    return pauseOutcome;
  }

  @override
  Future<RunControlOutcome> cancelRun({required String runId}) async {
    cancels.add((runId: runId));
    return cancelOutcome;
  }

  @override
  Future<IndexStartOutcome> resumeRun({
    required String runId,
    RunPriority? priority,
  }) async {
    resumes.add((runId: runId, priority: priority));
    return resumeOutcome ?? IndexStartOutcome.started(runId: runId);
  }

  @override
  Future<ActiveRunsOutcome> listActiveRuns() async {
    if (refreshStarts.isNotEmpty &&
        activeRunsOutcomeOnceRefreshStarts != null) {
      return activeRunsOutcomeOnceRefreshStarts!;
    }
    return activeRunsOutcome;
  }
}

/// A run in flight, for a test that wants one to still be going.
IndexRunOutcome runningRun({
  String runId = '3f9a1b7c-2d4e-4a8b-9c1d-5e6f70819a2b',
  String root = '/home/owner/music',
}) => IndexRunOutcome.read(
  run: IndexRun(runId: runId, root: root, status: IndexRunStatus.running),
);

/// A finished run carrying [counts].
IndexRunOutcome finishedRun({
  String runId = '3f9a1b7c-2d4e-4a8b-9c1d-5e6f70819a2b',
  String root = '/home/owner/music',
  IndexRunCounts counts = const IndexRunCounts(scanned: 120, indexed: 118),
  IndexRunStatus status = IndexRunStatus.complete,
}) => IndexRunOutcome.read(
  run: IndexRun(runId: runId, root: root, status: status, counts: counts),
);
