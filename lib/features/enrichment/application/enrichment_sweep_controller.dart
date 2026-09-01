import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/enrichment_gateway.dart';

/// Where a library-wide lookup has got to.
enum SweepStage {
  /// Not started, or the last one has been acknowledged.
  idle,

  /// Working through the library, a batch at a time.
  running,

  /// Every file has been looked up. Nothing is left outstanding.
  finished,

  /// The owner stopped it. What was done is kept — every batch that
  /// completed is stored, and starting again resumes rather than restarts.
  stopped,

  /// Enrichment is switched off, or on with no contact configured.
  unavailable,

  /// A batch failed for a reason that is not worth continuing past.
  failed,
}

/// What a sweep is doing and what it has found (music enrichment design).
class SweepState {
  /// Creates a state.
  const SweepState({
    this.stage = SweepStage.idle,
    this.found = 0,
    this.considered = 0,
    this.remaining = 0,
  });

  /// Where it is.
  final SweepStage stage;

  /// How many lookups have found something, across every batch so far.
  final int found;

  /// How many items have been looked at.
  final int considered;

  /// How many files still have something outstanding.
  final int remaining;

  /// Whether a batch is in flight.
  bool get isRunning => stage == SweepStage.running;

  /// How far through, or `null` when there is nothing to be a fraction of.
  ///
  /// Against `considered + remaining` rather than a total counted up front:
  /// a library changes while a sweep runs — an index run can add files to it
  /// — and a bar measured against a stale total walks backwards or stops
  /// short of the end.
  double? get progress {
    final total = considered + remaining;
    if (total == 0) return null;

    return considered / total;
  }
}

/// Runs enrichment over the whole library, a batch at a time.
///
/// The batching is what makes this showable at all. A single call would run
/// for hours at MusicBrainz's one request per second and return only when it
/// was finished, giving a screen nothing to display and the owner no way to
/// stop. Each batch is a short, complete call; progress is what came back
/// from the last one, and stopping is not asking for the next.
class EnrichmentSweepController extends Notifier<SweepState> {
  /// How many files a single call works through.
  ///
  /// Small, and not for the core's sake — it is what sets how often the
  /// screen moves. At roughly a second or two an item, five is a few seconds
  /// between updates: often enough to look alive, rarely enough that the
  /// count is not flickering.
  static const int batchSize = 5;

  /// Set when the owner stops it, read between batches.
  ///
  /// A flag rather than cancelling the call in flight: the batch that is
  /// running has already spent its requests, and abandoning its answers
  /// would throw away work the services have already done for us.
  bool _stopping = false;

  @override
  SweepState build() => const SweepState();

  /// Works through the library until it is done, or until [stop] is called.
  Future<void> start() async {
    if (state.isRunning) return;
    // Switched off means the application asks for nothing (FR-UX-13) — not
    // that it asks and is refused. The core would refuse it, being
    // configured from this same preference, but a sweep is a long run of
    // requests and the first of them must not leave here.
    if (!ref.read(preferencesControllerProvider).musicLookupEnabled) {
      state = const SweepState(stage: SweepStage.unavailable);
      return;
    }

    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return;

    _stopping = false;
    state = const SweepState(stage: SweepStage.running);

    final gateway = ref.read(enrichmentGatewayProvider);

    while (!_stopping) {
      final outcome = await gateway.run(
        scope: const EnrichmentScope.pending(limit: batchSize),
        credential: credential,
      );

      // The owner may have stopped it while that batch was in flight. Its
      // results are already stored by the core, so they are counted before
      // the loop ends rather than discarded.
      switch (outcome) {
        case EnrichmentRunDone(:final report):
          state = SweepState(
            stage: SweepStage.running,
            found: state.found + report.found,
            considered: state.considered + report.considered,
            remaining: report.remaining,
          );

          // Nothing left outstanding: done, whether or not anything was
          // found. A library of untagged files finishes here immediately,
          // which is the truthful answer for it.
          if (report.remaining == 0) {
            state = SweepState(
              stage: SweepStage.finished,
              found: state.found,
              considered: state.considered,
            );
            return;
          }

          // A batch that considered nothing while claiming work remains
          // would spin forever asking for it. That should not happen — the
          // core answers `remaining` from the same rule it selects by — but
          // a loop that trusts a remote count to terminate is a loop that
          // hangs when the two ever disagree.
          if (report.considered == 0) {
            state = SweepState(
              stage: SweepStage.finished,
              found: state.found,
              considered: state.considered,
            );
            return;
          }

        // A rejected session returns the owner to login, as everywhere else.
        case EnrichmentRunFailed(failure: final UnauthorizedFailure failure):
          ref.read(sessionControllerProvider.notifier).invalidate(failure);
          state = const SweepState();
          return;

        case EnrichmentRunFailed(failure: ConfigurationFailure()):
          state = const SweepState(stage: SweepStage.unavailable);
          return;

        // Anything else stops the sweep rather than retrying it. A service
        // being down is already absorbed inside a batch — the core records
        // it and carries on — so a failure that reaches this far is about
        // the call itself, and repeating it a thousand more times would
        // just be a thousand more failures.
        case EnrichmentRunFailed():
          state = SweepState(
            stage: SweepStage.failed,
            found: state.found,
            considered: state.considered,
            remaining: state.remaining,
          );
          return;
      }
    }

    state = SweepState(
      stage: SweepStage.stopped,
      found: state.found,
      considered: state.considered,
      remaining: state.remaining,
    );
  }

  /// Stops after the batch in flight.
  ///
  /// Not immediately: that batch's requests are already spent, and its
  /// answers are already stored. What was done is kept, and starting again
  /// resumes rather than restarts.
  void stop() => _stopping = true;

  /// Clears the last result.
  void acknowledge() => state = const SweepState();
}
