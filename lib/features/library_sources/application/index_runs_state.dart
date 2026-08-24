import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import '../domain/index_run.dart';

part 'index_runs_state.freezed.dart';

/// Why a refresh could not be started (UC-07 AF-01, AF-02).
enum RefreshRefusal {
  /// One is already running; the owner is pointed at it rather than given a
  /// second (AF-01).
  alreadyRunning,

  /// There is nothing cataloged to re-check, so registering and indexing a
  /// folder is what is offered instead (AF-02).
  catalogEmpty,
}

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

    /// Whether a refresh has been asked for but not yet answered (FR-UX-08).
    @Default(false) bool refreshStarting,

    /// The catalog-wide refresh, in flight or finished (UC-07).
    ///
    /// Its own field rather than an entry in [runs], because a refresh belongs
    /// to no folder — keying it under one would make it look like that
    /// folder's scan and would block UC-08 from removing an unrelated folder.
    IndexRun? refreshRun,

    /// Why the last refresh was refused (UC-07 AF-01, AF-02), or `null`.
    RefreshRefusal? refreshRefusal,

    /// Why the refresh failed, when the core refused the start.
    Failure? refreshFailure,
  }) = _IndexRunsState;

  const IndexRunsState._();

  /// The run following [root], if there is one.
  IndexRun? runFor(String root) => runs[root];

  /// Why [root]'s last start was refused, if it was.
  Failure? failureFor(String root) => failures[root];

  /// Whether a start for [root] has been sent but not yet answered.
  bool isStarting(String root) => starting.contains(root);

  /// Whether a catalog-wide refresh is running (UC-07 AF-01).
  bool get isRefreshing => refreshRun?.isInFlight ?? false;

  /// Every folder the core is still scanning.
  List<String> get inFlightRoots => [
    for (final entry in runs.entries)
      if (entry.value.isInFlight) entry.key,
  ];

  /// Whether anything at all is being scanned.
  bool get hasRunInFlight => inFlightRoots.isNotEmpty;

  /// Every folder still being scanned whose status is worth reading again.
  ///
  /// A folder whose last read failed is left out. Its run stays in [runs], so
  /// the screen still shows what it was doing when the read broke, but polling
  /// it every interval would only spin on the same error. Starting the folder
  /// again clears the failure and puts it back in this list.
  ///
  /// This is what the poller iterates, rather than [inFlightRoots]: one
  /// folder's unreadable status must not stop the others from being followed.
  List<String> get pollableRoots => [
    for (final root in inFlightRoots)
      if (!failures.containsKey(root)) root,
  ];

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
