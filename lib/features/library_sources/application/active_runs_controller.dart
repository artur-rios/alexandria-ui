import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../auth/application/session_controller.dart';
import '../domain/index_gateway.dart';
import '../domain/index_run.dart';
import '../domain/run_estimate.dart';
import '../domain/run_priority.dart';
import 'active_runs_state.dart';

/// The single source of truth for what the core is running right now
/// (FR-FC-29).
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

  @override
  ActiveRunsState build() {
    _gateway = ref.read(indexGatewayProvider);
    _session = ref.read(sessionControllerProvider.notifier);
    _pollInterval = ref.read(runPollIntervalProvider);

    ref.onDispose(_stopPolling);

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

    final outcome = await _gateway.listActiveRuns(credential: credential);

    switch (outcome) {
      case ActiveRunsRead(:final runs):
        _applyRead(runs);

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

  /// Pauses [runId], then re-reads the outstanding runs (FR-FC-28).
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
  /// (FR-FC-30).
  Future<void> cancel(String runId) async {
    final credential = _session.credential;
    if (credential == null) return;

    final outcome = await _gateway.cancelRun(
      runId: runId,
      credential: credential,
    );
    await _afterControl(outcome);
  }

  /// Picks [runId] back up, then re-reads the outstanding runs (FR-FC-29).
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

  void _applyRead(List<IndexRun> runs) {
    final previouslyKnown = {for (final run in state.runs) run.runId: run};
    final stillActive = {for (final run in runs) run.runId};

    // A run held from last time and absent now is the one the strip should
    // report as just finished — held until the owner dismisses it, rather
    // than overwritten silently the moment it drops off the active list.
    var justFinished = state.justFinished;
    for (final entry in previouslyKnown.entries) {
      if (!stillActive.contains(entry.key)) {
        justFinished = entry.value;
        break;
      }
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

    if (state.anyRunning) {
      _schedulePolling();
    } else {
      // Nothing left to make progress on: a paused run's state moves only
      // when the owner acts, and that action's own response already updates
      // the strip, so polling here would only ever read the same answer.
      _stopPolling();
    }
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
