import 'package:alexandria_ui/features/library_sources/domain/index_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_run.dart';
import 'package:alexandria_ui/features/library_sources/domain/run_priority.dart';

/// An [IndexGateway] that never reaches the core (Testing Specification §2.3).
///
/// A hand-written fake rather than a `mocktail` stub because a run is a
/// sequence: it is started, then read repeatedly, and what it answers on the
/// second read is the whole point of UC-06.
class FakeIndexGateway implements IndexGateway {
  /// Creates a gateway whose runs start and finish immediately.
  FakeIndexGateway({
    this.runId = '3f9a1b7c-2d4e-4a8b-9c1d-5e6f70819a2b',
    IndexStartOutcome? startOutcome,
  }) : startOutcome = startOutcome ?? IndexStartOutcome.started(runId: runId);

  /// The run id a successful start returns.
  final String runId;

  /// What [startIndex] answers.
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

  /// The credentials [startRefresh] was called with, in order.
  final List<String> refreshStarts = [];

  /// What [startIndex] was called with, in order.
  final List<({String root, RunPriority? priority, String credential})> starts =
      [];

  /// What [readRun] was called with, in order.
  final List<({String runId, String credential})> reads = [];

  /// What [pauseRun] answers.
  RunControlOutcome pauseOutcome = const RunControlOutcome.ok();

  /// What [cancelRun] answers.
  RunControlOutcome cancelOutcome = const RunControlOutcome.ok();

  /// What [resumeRun] answers, or `null` to reuse [startOutcome].
  IndexStartOutcome? resumeOutcome;

  /// What [listActiveRuns] answers. Empty by default: no outstanding runs is
  /// the normal case.
  ActiveRunsOutcome activeRunsOutcome = const ActiveRunsOutcome.read(runs: []);

  /// What [pauseRun] was called with, in order.
  final List<({String runId, String credential})> pauses = [];

  /// What [cancelRun] was called with, in order.
  final List<({String runId, String credential})> cancels = [];

  /// What [resumeRun] was called with, in order.
  final List<({String runId, RunPriority? priority, String credential})>
  resumes = [];

  @override
  Future<IndexStartOutcome> startIndex({
    required String root,
    RunPriority? priority,
    required String credential,
  }) async {
    starts.add((root: root, priority: priority, credential: credential));
    return startOutcome;
  }

  @override
  Future<IndexStartOutcome> startRefresh({
    RunPriority? priority,
    required String credential,
  }) async {
    refreshStarts.add(credential);
    return refreshOutcome ?? startOutcome;
  }

  @override
  Future<int> countCatalogedFiles() async {
    catalogedFileCountAsked++;
    return catalogedFileCount;
  }

  @override
  Future<IndexRunOutcome> readRun({
    required String runId,
    required String credential,
  }) async {
    reads.add((runId: runId, credential: credential));

    final index = reads.length - 1;
    return readOutcomes[index.clamp(0, readOutcomes.length - 1)];
  }

  @override
  Future<RunControlOutcome> pauseRun({
    required String runId,
    required String credential,
  }) async {
    pauses.add((runId: runId, credential: credential));
    return pauseOutcome;
  }

  @override
  Future<RunControlOutcome> cancelRun({
    required String runId,
    required String credential,
  }) async {
    cancels.add((runId: runId, credential: credential));
    return cancelOutcome;
  }

  @override
  Future<IndexStartOutcome> resumeRun({
    required String runId,
    RunPriority? priority,
    required String credential,
  }) async {
    resumes.add((runId: runId, priority: priority, credential: credential));
    return resumeOutcome ?? IndexStartOutcome.started(runId: runId);
  }

  @override
  Future<ActiveRunsOutcome> listActiveRuns({required String credential}) async {
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
