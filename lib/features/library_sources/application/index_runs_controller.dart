import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../auth/application/session_controller.dart';
import '../domain/index_gateway.dart';
import '../domain/index_run.dart';
import '../domain/library_source_store.dart';
import 'index_runs_state.dart';

/// Drives UC-06: starting an index run and watching it finish.
///
/// The scan itself belongs to the core and runs on the core's own runtime, so
/// nothing here blocks the interface (FR-LB-07). What this owns is the run
/// identifier, the polling that follows it, and the outcome that stays on
/// screen until the owner dismisses it (FR-LB-08).
class IndexRunsController extends Notifier<IndexRunsState> {
  static final Logger _log = Logger('library_sources');

  late IndexGateway _gateway;
  late LibrarySourceStore _store;
  late SessionController _session;
  late Duration _pollInterval;

  Timer? _poller;

  @override
  IndexRunsState build() {
    _gateway = ref.read(indexGatewayProvider);
    _store = ref.read(librarySourceStoreProvider);
    _session = ref.read(sessionControllerProvider.notifier);
    _pollInterval = ref.read(runPollIntervalProvider);

    ref.onDispose(_stopPolling);

    return const IndexRunsState();
  }

  /// Starts a run for [root] (main flow steps 1 and 2).
  ///
  /// AF-01: a folder with a run already in flight is refused rather than
  /// started again, and the running one is what the screen keeps pointing at.
  Future<void> startIndex(String root) async {
    if (state.runFor(root)?.isInFlight ?? false) {
      _log.info('index run already in flight for $root');
      state = state.refusingSecondRun(root);
      return;
    }

    final credential = _session.credential;
    if (credential == null) return;

    state = state.starting_(root);

    final outcome = await _gateway.startIndex(
      root: root,
      credential: credential,
    );

    switch (outcome) {
      case IndexStarted(:final runId):
        // Recorded against the folder before anything is polled, so a run
        // survives the application closing: AF-05 reads it back at the next
        // launch rather than losing track of a scan the core is still doing.
        await _rememberRun(root, runId);
        state = state.started(
          root,
          IndexRun(runId: runId, root: root, status: IndexRunStatus.running),
        );
        await _poll(root);
        _schedulePolling();

      case IndexStartFailed(:final failure):
        _reportStartFailure(root, failure);
    }
  }

  /// Reads every in-flight run once (main flow step 4).
  ///
  /// Public so a test can advance the observation without waiting on a timer,
  /// and so the screen can ask for a fresh reading when it opens.
  Future<void> refresh() async {
    for (final root in state.inFlightRoots) {
      await _poll(root);
    }

    if (state.inFlightRoots.isEmpty) _stopPolling();
  }

  /// Picks up runs the core is still doing, or finished while the application
  /// was closed (AF-05).
  ///
  /// The run belongs to the core, not to this process, so its outcome is
  /// waiting to be read rather than lost.
  Future<void> resumeRecordedRuns() async {
    final credential = _session.credential;
    if (credential == null) return;

    for (final source in _store.read()) {
      final runId = source.lastRunId;
      if (runId == null) continue;

      final outcome = await _gateway.readRun(
        runId: runId,
        credential: credential,
      );
      if (outcome case IndexRunRead(:final run)) {
        state = state.observed(source.path, run);
      }
    }

    if (state.inFlightRoots.isNotEmpty) _schedulePolling();
  }

  /// Clears a finished run's outcome, which stays until asked (FR-LB-08).
  void dismiss(String root) => state = state.dismissed(root);

  /// Clears the refusal notice AF-01 raised.
  void acknowledgeRefusal() => state = state.withoutRefusal();

  Future<void> _poll(String root) async {
    final run = state.runFor(root);
    final credential = _session.credential;
    if (run == null || credential == null) return;

    final outcome = await _gateway.readRun(
      runId: run.runId,
      credential: credential,
    );

    switch (outcome) {
      case IndexRunRead(run: final observed):
        state = state.observed(root, observed);
        if (!observed.isInFlight) {
          await _recordOutcome(root, observed);
          if (state.inFlightRoots.isEmpty) _stopPolling();
        }

      // AF-06: the core rejected the session. Discarding it returns the owner
      // to login, and there is nothing left to poll.
      case IndexRunFailed(failure: final UnauthorizedFailure failure):
        _stopPolling();
        _session.invalidate(failure);

      case IndexRunFailed(:final failure):
        _log.warning(
          'run status unreadable for $root (${failure.coreStatusCode})',
        );
        state = state.failing(root, failure);
        _stopPolling();
    }
  }

  void _reportStartFailure(String root, Failure failure) {
    // AF-06 is the one refusal that is not about the folder: the session is
    // gone, so the owner goes back to login rather than reading a message
    // about a scan they can no longer start.
    if (failure is UnauthorizedFailure) {
      state = state.idle(root);
      _session.invalidate(failure);
      return;
    }

    // AF-02 and AF-03 both land here. They are the same shape to this layer —
    // the core refused the start — and differ only in what the owner is
    // offered next, which the screen decides from the failure.
    _log.info('index run refused for $root (${failure.coreStatusCode})');
    state = state.failing(root, failure);
  }

  /// Records the run against its folder, so it can be found again (AF-05).
  Future<void> _rememberRun(String root, String runId) async {
    final sources = [
      for (final source in _store.read())
        if (source.path == root)
          source.copyWith(
            lastRunId: runId,
            lastRunOutcome: null,
            lastRunAt: null,
          )
        else
          source,
    ];
    await _store.write(sources);
  }

  Future<void> _recordOutcome(String root, IndexRun run) async {
    final now = ref.read(clockProvider)();
    final sources = [
      for (final source in _store.read())
        if (source.path == root)
          source.copyWith(
            lastRunId: run.runId,
            lastRunOutcome: run.status.name,
            lastRunAt: now,
          )
        else
          source,
    ];
    await _store.write(sources);
  }

  void _schedulePolling() {
    if (_poller != null || state.inFlightRoots.isEmpty) return;

    // Polling rather than a subscription, because the core's FFI surface
    // publishes a status query and no callback. The interval is injected so a
    // test drives the observation directly instead of waiting on a clock.
    _poller = Timer.periodic(_pollInterval, (_) => unawaited(refresh()));
  }

  void _stopPolling() {
    _poller?.cancel();
    _poller = null;
  }
}
