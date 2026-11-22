import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/index_gateway.dart';
import '../domain/index_run.dart';

/// The files one run could not record (core FR-FC-42).
///
/// Read on demand — when the owner asks which files — rather than carried on
/// the run status, which is polled every second while a run is in flight.
class RunFailuresController extends AsyncNotifier<List<RunFailure>> {
  /// Creates the controller for [runId].
  RunFailuresController(this.runId);

  /// The run this instance reads.
  final String runId;

  @override
  Future<List<RunFailure>> build() async {
    final outcome = await ref
        .read(indexGatewayProvider)
        .readFailures(runId: runId);

    switch (outcome) {
      case RunFailuresRead(:final failures):
        return failures;

      // Thrown rather than answered as an empty list: "could not ask" and
      // "nothing to show" are answers the owner would act on differently,
      // and the screen's own failure state is what tells them which this is.
      case RunFailuresFailed(:final failure):
        throw failure;
    }
  }
}
