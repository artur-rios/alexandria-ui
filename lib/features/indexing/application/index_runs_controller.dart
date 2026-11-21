import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/di/providers.dart';
import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/failure.dart';
import '../../auth/application/session_controller.dart';
import '../../catalog/application/catalog_projections.dart';
import '../domain/index_gateway.dart';
import '../domain/index_run.dart';
import 'index_runs_state.dart';

/// Drives UC-06: starting a library's index run and watching it finish.
///
/// Runs are kept by library uuid: the 0.6.0 core indexes nothing that is not
/// a library, so a library is what every run but a refresh belongs to.
///
/// The scan itself belongs to the core and runs on the core's own runtime, so
/// nothing here blocks the interface (FR-LB-07). What this owns is the run
/// identifier, the polling that follows it, and the outcome that stays on
/// screen until the owner dismisses it (FR-LB-08).
class IndexRunsController extends Notifier<IndexRunsState> {
  static final Logger _log = Logger('indexing');

  late IndexGateway _gateway;
  late SessionController _session;
  late Duration _pollInterval;

  Timer? _poller;

  /// Whether a [refresh] is in flight.
  ///
  /// A tick that lands while the last one is still reading is dropped rather
  /// than queued. Every core call goes through one worker isolate and is made
  /// one at a time, so a sweep across several folders on a slow disk can
  /// outlast the poll interval — and `Timer.periodic` does not wait. Left
  /// unguarded, each tick queued another round of reads onto a worker already
  /// behind, and the queue only ever grew. Dropping is right rather than
  /// merely cheap: this reads the current state of a run, so the reading the
  /// skipped tick would have taken is one the next tick takes instead.
  bool _refreshing = false;

  @override
  IndexRunsState build() {
    _gateway = ref.read(indexGatewayProvider);
    _session = ref.read(sessionControllerProvider.notifier);
    _pollInterval = ref.read(runPollIntervalProvider);

    ref.onDispose(_stopPolling);

    return const IndexRunsState();
  }

  /// Whether the poller is running.
  ///
  /// Exposed only so a test can assert that one run finishing does not stop
  /// the others from being followed — there is no other way to observe a
  /// `Timer` from outside. The same hook [ActiveRunsController] carries, for
  /// the same reason.
  bool get debugIsPolling => _poller != null;

  /// Scans the library [uuid] again (core 0.6.0) and follows the run.
  ///
  /// Answers why the run did not start, or null when it did — the caller is
  /// a button, and the refusal is a sentence to show beside it rather than a
  /// state for the whole screen. A run this session already follows that is
  /// still unfinished is refused here with the conflict the core would
  /// answer, without asking it: one unfinished run per library is the
  /// core's rule, and asking would only repeat it.
  Future<Failure?> startLibraryIndex(String uuid) async {
    final followed = state.runFor(uuid);
    if (followed != null && !followed.status.isTerminal) {
      _log.info('library $uuid already has an unfinished run');
      return const Failure.conflict(
        family: CoreStatusFamily.indexing,
        code: INDEX_ERR_CONFLICT,
      );
    }
    if (state.isStarting(uuid)) return null;

    final credential = _session.credential;
    if (credential == null) return null;

    state = state.starting_(uuid);

    final outcome = await _gateway.startLibraryIndex(
      uuid: uuid,
      credential: credential,
    );

    switch (outcome) {
      case IndexStarted(:final runId):
        await follow(uuid, runId);
        return null;

      case IndexStartFailed(failure: final UnauthorizedFailure failure):
        state = state.idle(uuid);
        _session.invalidate(failure);
        return failure;

      case IndexStartFailed(:final failure):
        _log.info('library run refused for $uuid (${failure.coreStatusCode})');
        state = state.idle(uuid);
        return failure;
    }
  }

  /// Follows [runId], the run the core started for the library [uuid].
  ///
  /// Called by [startLibraryIndex] and by adding a library, whose first run
  /// the core starts itself and answers the id of.
  Future<void> follow(String uuid, String runId) async {
    state = state.observed(
      uuid,
      IndexRun(
        runId: runId,
        root: '',
        libraryUuid: uuid,
        status: IndexRunStatus.running,
      ),
    );
    await _poll(uuid);
    _schedulePolling();

    // ActiveRunsController learns what is running from its own reads, and
    // nothing else tells it a run has just started: the strip would show
    // stale state until something re-read it. Awaited, so a caller that
    // disposes its ref straight after (a test's container) does not cut the
    // read short.
    await ref.read(activeRunsControllerProvider.notifier).refresh();
  }

  /// Starts a refresh over everything already cataloged (UC-07, FR-LB-06).
  ///
  /// AF-01 refuses a second one while a refresh is running, and AF-02 refuses
  /// an empty catalog — there is nothing to re-check, and registering a folder
  /// is what the owner actually needs (UC-05, UC-06).
  ///
  /// [reportRefusals] is false when nobody pressed anything — the startup
  /// re-check (FR-LB-21). A refusal explains to an owner why the button they
  /// pressed did nothing; left on screen after a re-check they never asked
  /// for, it is an answer to a question nobody asked. This covers AF-01's own
  /// refusal notice and a failure the core returns for the start itself —
  /// both are equally an answer to a question nobody asked.
  Future<void> startRefresh({bool reportRefusals = true}) async {
    if (state.isRefreshing) {
      if (reportRefusals) {
        state = state.copyWith(refreshRefusal: RefreshRefusal.alreadyRunning);
      }
      return;
    }

    final credential = _session.credential;
    if (credential == null) return;

    state = state.copyWith(
      refreshRefusal: null,
      refreshFailure: null,
      refreshStarting: true,
    );

    // Asked before the call rather than after a refusal, because "nothing to
    // refresh" is not a failure and should not read as one. A count the core
    // could not answer is not treated as empty (AF-02).
    final cataloged = await _gateway.countCatalogedFiles();
    if (cataloged == 0) {
      state = state.copyWith(
        refreshStarting: false,
        refreshRefusal: reportRefusals ? RefreshRefusal.catalogEmpty : null,
      );
      return;
    }

    final outcome = await _gateway.startRefresh(credential: credential);

    switch (outcome) {
      case IndexStarted(:final runId):
        state = state.copyWith(
          refreshStarting: false,
          refreshRun: IndexRun(
            runId: runId,
            root: '',
            kind: IndexRunKind.refresh,
            status: IndexRunStatus.running,
          ),
        );
        await _pollRefresh();
        _schedulePolling();

        // Same choke point [startIndex] refreshes through. A refresh is
        // catalog-wide and can run for hours, and the strip cannot discover
        // it on its own: its polling only starts once a run is already known,
        // so without this "Re-check library" starts work the owner is never
        // shown outside this screen.
        await ref.read(activeRunsControllerProvider.notifier).refresh();

      // AF-04: the same rule every other call follows — a rejected session
      // returns the owner to login.
      case IndexStartFailed(failure: final UnauthorizedFailure failure):
        state = state.copyWith(refreshStarting: false);
        _session.invalidate(failure);

      case IndexStartFailed(:final failure):
        _log.info('refresh refused (${failure.coreStatusCode})');
        state = state.copyWith(
          refreshStarting: false,
          refreshFailure: reportRefusals ? failure : null,
        );
    }
  }

  /// Clears the refresh's outcome, which stays until asked (FR-LB-08).
  void dismissRefresh() => state = state.copyWith(
    refreshRun: null,
    refreshRefusal: null,
    refreshFailure: null,
  );

  Future<void> _pollRefresh() async {
    final run = state.refreshRun;
    final credential = _session.credential;
    if (run == null || credential == null) return;

    final outcome = await _gateway.readRun(
      runId: run.runId,
      credential: credential,
    );

    switch (outcome) {
      case IndexRunRead(run: final observed):
        state = state.copyWith(
          refreshRun: observed.copyWith(kind: IndexRunKind.refresh),
        );

      case IndexRunFailed(failure: final UnauthorizedFailure failure):
        _stopPolling();
        _session.invalidate(failure);

      // The refresh is off the board, but the folder scans are not: stopping
      // outright here would freeze every one of them on its last reading.
      case IndexRunFailed(:final failure):
        state = state.copyWith(refreshRun: null, refreshFailure: failure);
        _stopPollingIfIdle();
    }
  }

  /// Reads every in-flight run once (main flow step 4).
  ///
  /// Public so a test can advance the observation without waiting on a timer,
  /// and so the screen can ask for a fresh reading when it opens.
  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;

    try {
      for (final uuid in state.pollable) {
        await _poll(uuid);
      }
      if (state.isRefreshing) await _pollRefresh();

      _stopPollingIfIdle();
    } finally {
      // In a `finally`, so a read that threw does not leave the flag set and
      // the poller silently dead for the rest of the session.
      _refreshing = false;
    }
  }

  /// Forgets [uuid]'s run: a finished outcome the owner dismissed, or a
  /// library that was removed, whose run the core deleted with it.
  void dismiss(String uuid) => state = state.dismissed(uuid);

  Future<void> _poll(String uuid) async {
    final run = state.runFor(uuid);
    final credential = _session.credential;
    if (run == null || credential == null) return;

    final outcome = await _gateway.readRun(
      runId: run.runId,
      credential: credential,
    );

    // Removed while the read was out: the library is gone, and recording its
    // run again would bring it back on screen.
    if (state.runFor(uuid) == null) return;

    switch (outcome) {
      case IndexRunRead(run: final observed):
        state = state.observed(uuid, observed.copyWith(libraryUuid: uuid));
        if (observed.status.isTerminal) {
          _stopPollingIfIdle();
          // The run is what filled or changed the catalog, so everything that
          // shows it reads it again. The active-runs listing does this for
          // the runs it sees — but a small library's first run is over
          // before that listing ever lists it.
          if (!run.status.isTerminal) invalidateCatalogProjections(ref);
        }

      // AF-06: the core rejected the session. Discarding it returns the owner
      // to login, and there is nothing left to poll.
      case IndexRunFailed(failure: final UnauthorizedFailure failure):
        _stopPolling();
        _session.invalidate(failure);

      // This library's run is the one that could not be read. Everything
      // else still followed — another library's run, or the refresh — is
      // unaffected and must keep being followed.
      case IndexRunFailed(:final failure):
        _log.warning(
          'run status unreadable for $uuid (${failure.coreStatusCode})',
        );
        state = state.failing(uuid, failure);
        _stopPollingIfIdle();
    }
  }

  /// Stops the poller once there is nothing left for it to read.
  ///
  /// The one place that decides this. It used to be spelled out at each call
  /// site, and three of the four spellings were wrong in the same direction:
  /// they weighed only the library runs, so one finishing — or one library's
  /// read failing — stopped the timer while the catalog-wide refresh
  /// was still going, freezing it on its last reading with nothing left to
  /// restart it.
  void _stopPollingIfIdle() {
    if (state.pollable.isEmpty && !state.isRefreshing) _stopPolling();
  }

  void _schedulePolling() {
    if (_poller != null) return;
    if (state.pollable.isEmpty && !state.isRefreshing) return;

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
