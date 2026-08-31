import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../auth/application/session_controller.dart';
import '../../catalog/application/catalog_projections.dart';
import '../domain/index_gateway.dart';
import '../domain/index_run.dart';
import '../domain/run_estimate.dart';
import '../domain/run_priority.dart';
import 'active_runs_state.dart';

/// The single source of truth for what the core is running right now
/// (FR-LB-15, FR-LB-19, FR-LB-20 / core FR-FC-35).
///
/// [IndexRunsController] answers "is this folder being scanned?" by
/// remembering one run id per registered folder. This controller answers a
/// different question — "what is outstanding, anywhere" — and answers it the
/// way the core itself does: by asking `listActiveRuns` rather than by
/// reconstructing the picture from per-folder memory. A later task renders
/// this as the strip above the playback bar; it is meant to be the one place
/// that holds that opinion.
class ActiveRunsController extends Notifier<ActiveRunsState> {
  static final Logger _log = Logger('library_sources');

  /// How many samples are kept per run.
  ///
  /// Enough for [estimateRemaining]'s window to stay meaningful without
  /// letting the list grow without bound over a long scan.
  static const int _maxSamplesPerRun = 10;

  late IndexGateway _gateway;
  late SessionController _session;
  late Duration _pollInterval;

  Timer? _poller;

  /// Whether a [refresh] is in flight.
  ///
  /// A tick landing on top of one still reading is dropped, for the reason
  /// [IndexRunsController] drops its own: core calls are made one at a time
  /// on a single worker isolate, so a read slower than the poll interval left
  /// `Timer.periodic` stacking rounds onto a queue that only grew. What the
  /// skipped tick would have read, the next one reads.
  bool _refreshing = false;

  @override
  ActiveRunsState build() {
    _gateway = ref.read(indexGatewayProvider);
    _session = ref.read(sessionControllerProvider.notifier);
    _pollInterval = ref.read(runPollIntervalProvider);

    ref.onDispose(_stopPolling);

    // FR-FC-29: a run the core was still working on when the application last
    // closed comes back paused, and the offer to pick it back up is the strip
    // appearing in its paused state. Nothing else asks for that first reading
    // — polling cannot bootstrap itself, because it only starts once a running
    // run is known — so the controller takes it itself rather than depending
    // on a widget's initState, which would make the first read of core state
    // a question of which screen mounted first.
    //
    // Deferred by a microtask so the state this build returns is in place
    // before the read can replace it.
    Future.microtask(() {
      if (!ref.mounted) return;
      unawaited(refresh());
    });

    return const ActiveRunsState();
  }

  /// Whether the poller is running.
  ///
  /// Exposed only so a test can assert that a launch with only paused runs
  /// never starts polling, and that polling stops once nothing is running —
  /// there is no other way to observe a `Timer` from outside.
  bool get debugIsPolling => _poller != null;

  /// Reads every outstanding run once.
  ///
  /// Public so a test can advance the observation without waiting on a
  /// timer, and so the screen can ask for a fresh reading when it opens.
  Future<void> refresh() async {
    final credential = _session.credential;
    if (credential == null) return;
    if (_refreshing) return;
    _refreshing = true;

    try {
      await _read(credential);
    } finally {
      // In a `finally`, so a read that threw does not leave the flag set and
      // the poller silently dead for the rest of the session.
      _refreshing = false;
    }
  }

  Future<void> _read(String credential) async {
    final outcome = await _gateway.listActiveRuns(credential: credential);

    switch (outcome) {
      case ActiveRunsRead(:final runs):
        await _applyRead(runs, credential);

      // The core rejected the session. Discarding what is known would
      // report "nothing running" on no evidence, but the session is gone
      // either way, so there is nothing left to poll for.
      case ActiveRunsFailed(failure: final UnauthorizedFailure failure):
        _stopPolling();
        _session.invalidate(failure);

      // A read that failed for any other reason is not evidence that
      // nothing is running — only that the core could not be asked this
      // time. The runs already known are kept rather than cleared.
      case ActiveRunsFailed(:final failure):
        _log.warning('active runs unreadable (${failure.coreStatusCode})');
        state = state.copyWith(failure: failure);
    }
  }

  /// Pauses [runId], then re-reads the outstanding runs (FR-LB-16 / core
  /// FR-FC-32).
  Future<void> pause(String runId) async {
    final credential = _session.credential;
    if (credential == null) return;

    final outcome = await _gateway.pauseRun(
      runId: runId,
      credential: credential,
    );
    await _afterControl(outcome);
  }

  /// Abandons [runId] for good, then re-reads the outstanding runs
  /// (FR-LB-16 / core FR-FC-34).
  Future<void> cancel(String runId) async {
    final credential = _session.credential;
    if (credential == null) return;

    final outcome = await _gateway.cancelRun(
      runId: runId,
      credential: credential,
    );
    await _afterControl(outcome);
  }

  /// Picks [runId] back up, then re-reads the outstanding runs (FR-LB-16 /
  /// core FR-FC-33).
  ///
  /// [priority] carries forward if given; null asks the core to keep the
  /// pace the run already had — the same convention [IndexGateway.resumeRun]
  /// follows, and it must reach the core unchanged rather than default to
  /// `normal`, or a plain resume would silently re-pace a scan the owner
  /// deliberately throttled.
  Future<void> resume(String runId, {RunPriority? priority}) async {
    final credential = _session.credential;
    if (credential == null) return;

    final outcome = await _gateway.resumeRun(
      runId: runId,
      priority: priority,
      credential: credential,
    );

    switch (outcome) {
      case IndexStarted():
        await refresh();

      case IndexStartFailed(failure: final UnauthorizedFailure failure):
        _stopPolling();
        _session.invalidate(failure);

      // Refused for any other reason — most likely the run is no longer
      // paused. Re-reading it is the correct response, the same as every
      // other control call below.
      case IndexStartFailed():
        await refresh();
    }
  }

  /// Clears the held outcome of a run that disappeared from the active list.
  void dismissFinished() => state = state.copyWith(justFinished: null);

  Future<void> _afterControl(RunControlOutcome outcome) async {
    switch (outcome) {
      case RunControlOk():
        await refresh();

      case RunControlFailed(failure: final UnauthorizedFailure failure):
        _stopPolling();
        _session.invalidate(failure);

      // Refused for state — most commonly `RUN_ERR_INVALID_STATE`, because
      // the run moved on between the strip rendering and the owner clicking.
      // The run is not gone, only stale here, so this is read back rather
      // than surfaced as an error the strip would have to render.
      case RunControlFailed():
        await refresh();
    }
  }

  Future<void> _applyRead(List<IndexRun> runs, String credential) async {
    final stillActive = {for (final run in runs) run.runId};

    // A run held from last time and absent now is one the strip should report
    // as just finished. Every one of them is read, not only the first: two
    // runs can drop off the same reading, and taking whichever came first in
    // the list would decide by list order which outcome the owner is told
    // about.
    var justFinished = state.justFinished;
    // Whether any run left the active list on this read — the edge that
    // means the catalog itself changed, as opposed to the polling loop
    // simply running again while a run is still in flight.
    var anyEnded = false;
    for (final run in state.runs) {
      if (stillActive.contains(run.runId)) continue;

      final ended = await _endOf(run, credential);

      // A held failure is not replaced. The slot is one run wide, and a
      // failure standing in it is the outcome the owner has not seen yet — a
      // second run finishing thirty seconds later must not push it off before
      // it was read. Every other outcome clears itself, so nothing stays
      // hidden behind one for long.
      if (ended != null && justFinished?.status != IndexRunStatus.failed) {
        justFinished = ended;
      }

      // A run leaving the active list is the edge that means the catalog
      // changed — regardless of which status it ended on. A failed run has
      // usually still catalogued something part-way through, so this is not
      // narrowed to `complete`; only a cancellation with nothing processed
      // would have nothing to show for it, and re-reading an unchanged
      // catalog costs nothing worth guarding against. `ended == null` means
      // the outcome could not even be read, which is not evidence the
      // catalog changed, so that case invalidates nothing.
      if (ended != null) anyEnded = true;
    }

    final samples = <String, List<RunSample>>{};
    for (final run in runs) {
      final priorSamples = state.samples[run.runId] ?? const <RunSample>[];

      // A paused run makes no progress, so it contributes nothing new to
      // its own estimate — only a running run's samples grow.
      if (!run.isInFlight) {
        if (priorSamples.isNotEmpty) samples[run.runId] = priorSamples;
        continue;
      }

      final updated = [
        ...priorSamples,
        RunSample(
          processed: run.processed ?? 0,
          activeMillis: run.activeMillis,
        ),
      ];
      samples[run.runId] = updated.length <= _maxSamplesPerRun
          ? updated
          : updated.sublist(updated.length - _maxSamplesPerRun);
    }

    state = state.copyWith(
      runs: runs,
      samples: samples,
      justFinished: justFinished,
      failure: null,
    );

    // Once per read, not once per run: a batch where two runs end together
    // still only needs the catalog's projections read again once.
    if (anyEnded) _invalidateCatalogProjections();

    if (state.anyRunning) {
      _schedulePolling();
    } else {
      // Nothing left to make progress on: a paused run's state moves only
      // when the owner acts, and that action's own response already updates
      // the strip, so polling here would only ever read the same answer.
      _stopPolling();
    }
  }

  /// How [disappeared] actually ended, or null when that cannot be known.
  ///
  /// `listActiveRuns` answers with what is *outstanding*, so every run it
  /// reports is running or paused by definition. The snapshot of a run that
  /// has just left that list therefore never carries the status it ended on,
  /// and holding it would make a completion, a failure and a cancellation
  /// indistinguishable — which is to say, unreportable. The run is read
  /// directly for the one fact the list cannot carry.
  Future<IndexRun?> _endOf(IndexRun disappeared, String credential) async {
    final outcome = await _gateway.readRun(
      runId: disappeared.runId,
      credential: credential,
    );

    switch (outcome) {
      // Kind and root come from the snapshot: the active list carries both,
      // and they are what names the folder in the report. Everything the
      // read is for — status, counts, error — is the read's own.
      case IndexRunRead(:final run) when run.status.isTerminal:
        return run.copyWith(root: disappeared.root, kind: disappeared.kind);

      // Off the list but not terminal. The core has moved it somewhere this
      // application has no word for, and announcing an end that has not
      // happened is worse than saying nothing.
      case IndexRunRead():
        return null;

      case IndexRunFailed(failure: final UnauthorizedFailure failure):
        _stopPolling();
        _session.invalidate(failure);

        return null;

      // A run the core no longer knows — most often one it has already
      // forgotten. There is no honest outcome to report, and guessing at one
      // is worse than a strip that says nothing; what matters is that the run
      // still leaves the list and whatever else is outstanding is still
      // followed.
      case IndexRunFailed(:final failure):
        _log.warning(
          'run outcome unreadable for ${disappeared.runId} '
          '(${failure.coreStatusCode})',
        );

        return null;
    }
  }

  /// Refetches every projection the catalog itself feeds, once a run's
  /// ending has just changed what the catalog holds (FR-LB-15 /
  /// FR-CT-01/09/11/13).
  ///
  /// This is what `deletion_controller.dart`'s `onDone` does for a deletion —
  /// the catalog changed, so its listings, counts, search index, recent
  /// files, open file details, and music library are all read again rather
  /// than kept from before the run. Deliberately narrower than what signing
  /// out invalidates (`catalog_session_activity.dart`): a run finishing is
  /// not a session ending, so what the owner has open or typed —
  /// `openFileProvider`, `searchTermProvider`, the metadata and rename
  /// editors — is left alone. An owner mid-search or mid-edit when a scan
  /// completes underneath them must not have that thrown away.
  void _invalidateCatalogProjections() {
    invalidateCatalogProjections(ref);
  }

  void _schedulePolling() {
    if (_poller != null) return;

    // Polling rather than a subscription, because the core's FFI surface
    // publishes a status query and no callback. The interval is injected so
    // a test drives the observation directly instead of waiting on a clock.
    _poller = Timer.periodic(_pollInterval, (_) => unawaited(refresh()));
  }

  void _stopPolling() {
    _poller?.cancel();
    _poller = null;
  }
}
