import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import '../domain/index_run.dart';
import '../domain/run_estimate.dart';

part 'active_runs_state.freezed.dart';

/// Every run the core still has outstanding, as one list rather than one per
/// folder (FR-LB-15 / core FR-FC-35).
///
/// [IndexRunsState] keeps a run per registered folder because that is the
/// question the library-sources screen asks. This is the other question —
/// "what is running right now, anywhere" — which the core answers directly
/// through `listActiveRuns` rather than through per-folder bookkeeping. A
/// later task renders this as the strip above the playback bar, and it is
/// meant to be the one place that answers that question, rather than a
/// second opinion alongside [IndexRunsState]'s.
@freezed
abstract class ActiveRunsState with _$ActiveRunsState {
  /// Creates a state.
  const factory ActiveRunsState({
    /// Every run the core reported as outstanding on the last successful
    /// read — running or paused.
    @Default(<IndexRun>[]) List<IndexRun> runs,

    /// Progress samples per run id, oldest first, used to estimate time
    /// remaining ([estimateRemaining]).
    ///
    /// Capped per run so a long scan does not grow this without bound; see
    /// [ActiveRunsController].
    @Default(<String, List<RunSample>>{}) Map<String, List<RunSample>> samples,

    /// A run that was outstanding on the previous read and is gone from this
    /// one, read back for the status it ended on — the active list only ever
    /// carries running and paused runs, so the outcome cannot come from
    /// there.
    ///
    /// One slot, and what stands in it is not simply the latest. A *failed*
    /// run is held until the owner dismisses it and is not replaced by a
    /// later outcome; anything else is replaced as soon as the next run
    /// ends, because a completion clears itself anyway and a cancellation is
    /// the owner's own doing. Null when the run's outcome could not be read.
    IndexRun? justFinished,

    /// Why the last read failed, if it did.
    ///
    /// [runs] is not cleared when this is set: a failed read is not evidence
    /// that nothing is running, only that the core could not be asked.
    Failure? failure,
  }) = _ActiveRunsState;

  const ActiveRunsState._();

  /// Whether the core has anything outstanding at all.
  bool get hasWork => runs.isNotEmpty;

  /// Whether any outstanding run is actually being worked on right now.
  ///
  /// A paused run is outstanding but not in flight — this is the question
  /// polling follows, not [hasWork].
  bool get anyRunning => runs.any((run) => run.isInFlight);

  /// The one outstanding run, when there is exactly one.
  ///
  /// A later task's strip reads this to decide between a single-run and a
  /// multi-run presentation.
  IndexRun? get single => runs.length == 1 ? runs.single : null;
}
