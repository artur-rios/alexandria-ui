import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/di/providers.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/failure.dart';
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
    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    // No session, no call (FR-AU-07) — and thrown rather than answered as an
    // empty list, for the same reason the failed read below is. An empty
    // list on this screen reads as "this scan read every file it found",
    // which is a claim about the catalog, and one nobody made.
    if (credential == null) {
      throw const Failure.unauthorized(
        family: CoreStatusFamily.run,
        code: RUN_ERR_UNAUTHORIZED,
      );
    }

    final outcome = await ref
        .read(indexGatewayProvider)
        .readFailures(runId: runId, credential: credential);

    switch (outcome) {
      case RunFailuresRead(:final failures):
        return failures;

      // A rejected session returns the owner to login, as everywhere else.
      case RunFailuresFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);
        return const [];

      // Thrown rather than answered as an empty list: "could not ask" and
      // "nothing to show" are answers the owner would act on differently,
      // and the screen's own failure state is what tells them which this is.
      case RunFailuresFailed(:final failure):
        throw failure;
    }
  }
}
