import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import '../domain/index_run.dart';

part 'index_runs_state.freezed.dart';

/// Why a refresh could not be started (UC-07 AF-01, AF-02).
enum RefreshRefusal {
  /// One is already running; the owner is pointed at it rather than given a
  /// second (AF-01).
  alreadyRunning,

  /// There is nothing cataloged to re-check, so adding a library is what is
  /// offered instead (AF-02).
  catalogEmpty,
}

/// The runs this session started or followed, per library, and the refresh.
///
/// Keyed by library uuid: on the 0.6.0 core a run indexes one library (or,
/// for a refresh, every library at once), and the library is what the owner
/// sees a run beside. A paused or running run this session did not start is
/// the active-runs listing's to show; this holds what this session asked
/// for, so its outcome can still be read once the run has left that listing.
@freezed
abstract class IndexRunsState with _$IndexRunsState {
  /// Creates the state.
  const factory IndexRunsState({
    /// The latest observation of each followed run, by library uuid.
    @Default(<String, IndexRun>{}) Map<String, IndexRun> runs,

    /// The libraries whose run is being started right now.
    @Default(<String>{}) Set<String> starting,

    /// The libraries whose followed run could no longer be read.
    ///
    /// A run in here is not polled again: the core has stopped answering for
    /// it, and asking every second would only repeat the failure.
    @Default(<String, Failure>{}) Map<String, Failure> failures,

    /// Whether a refresh is being started right now.
    @Default(false) bool refreshStarting,

    /// The refresh this session started, while it runs and once it settles.
    IndexRun? refreshRun,

    /// Why the last refresh was not started, when it was refused here.
    RefreshRefusal? refreshRefusal,

    /// Why the last refresh failed, when the core refused or failed it.
    Failure? refreshFailure,
  }) = _IndexRunsState;

  const IndexRunsState._();

  /// The run followed for [uuid], if any.
  IndexRun? runFor(String uuid) => runs[uuid];

  /// Why [uuid]'s followed run could not be read, if it could not.
  Failure? failureFor(String uuid) => failures[uuid];

  /// Whether [uuid]'s run is being started right now.
  bool isStarting(String uuid) => starting.contains(uuid);

  /// Whether the refresh is running.
  bool get isRefreshing => refreshRun?.isInFlight ?? false;

  /// Whether any followed run is running.
  bool get hasRunInFlight => runs.values.any((run) => run.isInFlight);

  /// The libraries whose followed run is still worth reading again.
  ///
  /// A paused run is one: it can be resumed from the activity strip or a
  /// library's row, and this session would otherwise keep showing it paused
  /// long after it finished.
  List<String> get pollable => [
    for (final entry in runs.entries)
      if (!entry.value.status.isTerminal && !failures.containsKey(entry.key))
        entry.key,
  ];

  /// [uuid]'s run is being started.
  IndexRunsState starting_(String uuid) => copyWith(
    starting: {...starting, uuid},
    failures: {...failures}..remove(uuid),
  );

  /// [uuid]'s run did not start.
  IndexRunsState idle(String uuid) =>
      copyWith(starting: {...starting}..remove(uuid));

  /// [run] was observed for [uuid].
  IndexRunsState observed(String uuid, IndexRun run) => copyWith(
    runs: {...runs, uuid: run},
    starting: {...starting}..remove(uuid),
    failures: {...failures}..remove(uuid),
  );

  /// [uuid]'s run could not be read.
  IndexRunsState failing(String uuid, Failure failure) =>
      copyWith(failures: {...failures, uuid: failure});

  /// Forgets everything about [uuid]'s run.
  IndexRunsState dismissed(String uuid) => copyWith(
    runs: {...runs}..remove(uuid),
    starting: {...starting}..remove(uuid),
    failures: {...failures}..remove(uuid),
  );
}
