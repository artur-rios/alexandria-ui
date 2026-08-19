import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import 'index_run.dart';

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
    required String credential,
  });

  /// Reads a run's status and outcome (FR-LB-07, FR-LB-08).
  Future<IndexRunOutcome> readRun({
    required String runId,
    required String credential,
  });
}
