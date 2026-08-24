import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import 'index_run.dart';
import 'run_priority.dart';

part 'index_gateway.freezed.dart';

/// What starting a run produced (UC-06 main flow step 2).
@freezed
sealed class IndexStartOutcome with _$IndexStartOutcome {
  /// The core started the scan and returned [runId] (FR-LB-05).
  const factory IndexStartOutcome.started({required String runId}) =
      IndexStarted;

  /// The core refused (AF-02, AF-03, AF-06).
  const factory IndexStartOutcome.failed({required Failure failure}) =
      IndexStartFailed;
}

/// What reading a run's status produced (main flow steps 4 and 5).
@freezed
sealed class IndexRunOutcome with _$IndexRunOutcome {
  /// The core answered with the run.
  const factory IndexRunOutcome.read({required IndexRun run}) = IndexRunRead;

  /// The core could not answer (AF-06, or a run it no longer knows).
  const factory IndexRunOutcome.failed({required Failure failure}) =
      IndexRunFailed;
}

/// What a pause or cancel produced.
///
/// No payload on success: the run's new state is read back through the
/// status query like any other, and inventing a return value here would give
/// callers a second, staler source for it.
@freezed
sealed class RunControlOutcome with _$RunControlOutcome {
  const factory RunControlOutcome.ok() = RunControlOk;
  const factory RunControlOutcome.failed({required Failure failure}) =
      RunControlFailed;
}

/// What listing the outstanding runs produced.
@freezed
sealed class ActiveRunsOutcome with _$ActiveRunsOutcome {
  const factory ActiveRunsOutcome.read({required List<IndexRun> runs}) =
      ActiveRunsRead;
  const factory ActiveRunsOutcome.failed({required Failure failure}) =
      ActiveRunsFailed;
}

/// The application's view of the core's indexing operations (IR-02, NFR-17).
///
/// Owned by the Domain layer so Application and Presentation depend on this
/// rather than on the FFI boundary behind it.
abstract interface class IndexGateway {
  /// Starts a scan of [root] (FR-LB-05).
  ///
  /// Returns as soon as the core has started it; the scan itself runs on the
  /// core's own runtime, which is what leaves the interface free (FR-LB-07).
  Future<IndexStartOutcome> startIndex({
    required String root,
    RunPriority? priority,
    required String credential,
  });

  /// Starts a refresh over everything already cataloged (FR-LB-06, UC-07).
  ///
  /// Takes no folder: a refresh is catalog-wide, which is what separates it
  /// from [startIndex].
  Future<IndexStartOutcome> startRefresh({
    RunPriority? priority,
    required String credential,
  });

  /// How many files the catalog holds, or a negative number when the core
  /// could not be asked (UC-07 AF-02).
  ///
  /// Unknown is not empty: offering to register a folder because the count
  /// failed would answer AF-02 on a guess.
  Future<int> countCatalogedFiles();

  /// Reads a run's status and outcome (FR-LB-07, FR-LB-08).
  Future<IndexRunOutcome> readRun({
    required String runId,
    required String credential,
  });

  /// Pauses a running run (FR-LB-16 / core FR-FC-32).
  ///
  /// Refused with [Failure] wrapping `RUN_ERR_INVALID_STATE` for a run that
  /// is not currently running — a terminal or already-paused run has nothing
  /// to pause.
  Future<RunControlOutcome> pauseRun({
    required String runId,
    required String credential,
  });

  /// Abandons a run for good (FR-LB-16 / core FR-FC-34).
  ///
  /// Terminal and not resumable, which is what separates this from
  /// [pauseRun]: a cancelled run cannot be picked back up.
  Future<RunControlOutcome> cancelRun({
    required String runId,
    required String credential,
  });

  /// Picks a paused run back up (FR-LB-16 / core FR-FC-33).
  ///
  /// [priority] carries forward if given; null asks the core to keep the
  /// pace the run already had — which is *not* what null means to
  /// [startIndex] and [startRefresh], where it asks for the core's own
  /// default. A run being resumed already has a width, and defaulting it to
  /// `normal` here would silently re-pace a scan the owner throttled.
  Future<IndexStartOutcome> resumeRun({
    required String runId,
    RunPriority? priority,
    required String credential,
  });

  /// Lists every run the core still has outstanding — running or paused
  /// (FR-FC-29).
  ///
  /// What lets the application find a paused run to offer resuming without
  /// having kept its id since the session that started it.
  Future<ActiveRunsOutcome> listActiveRuns({required String credential});
}
