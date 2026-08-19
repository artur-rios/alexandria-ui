import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import '../domain/index_run.dart';

part 'index_runs_state.freezed.dart';

/// Every run the application is following, keyed by the folder it scans
/// (UC-06).
///
/// Keyed by folder rather than by run id because that is the question the
/// screen asks — "is this folder being scanned?" — and it is what AF-01 turns
/// on. A folder has at most one run in flight by definition, which is the rule
/// FR-LB-09 states.
@freezed
abstract class IndexRunsState with _$IndexRunsState {
  /// Creates a state.
  const factory IndexRunsState({
    /// The run for each folder, in flight or finished.
    ///
    /// A finished run stays here until the owner dismisses it, which is what
    /// keeps its outcome on screen (FR-LB-08).
    @Default(<String, IndexRun>{}) Map<String, IndexRun> runs,

    /// Folders whose start is in flight but which have no run id yet.
    @Default(<String>{}) Set<String> starting,

    /// Why a start was refused, per folder (AF-02, AF-03).
    @Default(<String, Failure>{}) Map<String, Failure> failures,

    /// The folder a second run was refused for (AF-01), or `null`.
    String? refusedSecondRunFor,
  }) = _IndexRunsState;

  const IndexRunsState._();

  /// The run following [root], if there is one.
  IndexRun? runFor(String root) => runs[root];

  /// Why [root]'s last start was refused, if it was.
  Failure? failureFor(String root) => failures[root];

  /// Whether a start for [root] has been sent but not yet answered.
  bool isStarting(String root) => starting.contains(root);

  /// Every folder the core is still scanning.
  List<String> get inFlightRoots => [
    for (final entry in runs.entries)
      if (entry.value.isInFlight) entry.key,
  ];

  /// Whether anything at all is being scanned.
  bool get hasRunInFlight => inFlightRoots.isNotEmpty;

  /// [root]'s start is in flight.
  IndexRunsState starting_(String root) => copyWith(
    starting: {...starting, root},
    failures: {...failures}..remove(root),
    refusedSecondRunFor: null,
  );

  /// [root]'s start is no longer in flight.
  IndexRunsState idle(String root) =>
      copyWith(starting: {...starting}..remove(root));

  /// [root]'s run has begun.
  IndexRunsState started(String root, IndexRun run) => copyWith(
    runs: {...runs, root: run},
    starting: {...starting}..remove(root),
  );

  /// [root]'s run has been read again.
  IndexRunsState observed(String root, IndexRun run) => copyWith(
    runs: {...runs, root: run},
    starting: {...starting}..remove(root),
  );

  /// [root]'s start or observation failed.
  IndexRunsState failing(String root, Failure failure) => copyWith(
    starting: {...starting}..remove(root),
    failures: {...failures, root: failure},
  );

  /// A second run was refused for [root] (AF-01).
  IndexRunsState refusingSecondRun(String root) =>
      copyWith(refusedSecondRunFor: root);

  /// The AF-01 notice has been read.
  IndexRunsState withoutRefusal() => copyWith(refusedSecondRunFor: null);

  /// [root]'s finished outcome has been dismissed (FR-LB-08).
  IndexRunsState dismissed(String root) => copyWith(
    runs: {...runs}..remove(root),
    failures: {...failures}..remove(root),
  );
}
