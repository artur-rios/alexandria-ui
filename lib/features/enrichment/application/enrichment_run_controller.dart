import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/enrichment_gateway.dart';

/// Where a lookup the owner asked for has got to.
enum EnrichmentRunStage {
  /// Nothing asked for yet, or the answer has been seen.
  idle,

  /// Reaching the services. Not instant: this is the one thing in the
  /// application that goes out to the network.
  running,

  /// It finished and found something, which the panel is now showing.
  found,

  /// It finished and the services had nothing. An answer, not a failure, and
  /// one the core records so it is not asked again.
  nothingFound,

  /// The installation has enrichment switched off, or on with no MusicBrainz
  /// contact configured. Not the owner's mistake.
  unavailable,

  /// Something else went wrong.
  failed,
}

/// What a lookup is doing, and what it concluded.
class EnrichmentRunState {
  /// Creates a state.
  const EnrichmentRunState({this.stage = EnrichmentRunStage.idle});

  /// Where the lookup is.
  final EnrichmentRunStage stage;

  /// Whether one is in flight.
  bool get isRunning => stage == EnrichmentRunStage.running;
}

/// Runs a lookup for one track on the owner's say-so (music enrichment
/// design).
///
/// Deliberately one track at a time, and not the sweep. A single track costs
/// a few seconds; everything not yet looked up costs hours at MusicBrainz's
/// one-request-per-second limit, and an action that can run for hours needs
/// somewhere to report progress and be cancelled from — a screen of its own,
/// not a button on the player.
class EnrichmentRunController extends Notifier<EnrichmentRunState> {
  @override
  EnrichmentRunState build() => const EnrichmentRunState();

  /// Looks up [fileUuid], then refreshes what the panel is showing.
  ///
  /// [artistName] is only used to re-read afterwards — the core resolves the
  /// artist from the file's own tags when it runs.
  Future<void> runForTrack({
    required String fileUuid,
    String? artistName,
  }) async {
    if (state.isRunning) return;
    if (!_lookupIsOn) {
      state = const EnrichmentRunState(stage: EnrichmentRunStage.unavailable);
      return;
    }

    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return;

    state = const EnrichmentRunState(stage: EnrichmentRunStage.running);

    final outcome = await ref
        .read(enrichmentGatewayProvider)
        .run(
          scope: EnrichmentScope.file(fileUuid),
          credential: credential,
        );

    switch (outcome) {
      case EnrichmentRunDone(:final report):
        // The panel reads through its own provider, which has already
        // answered for this track and will not ask again on its own —
        // invalidating it is what turns a finished run into something on
        // screen.
        ref.invalidate(
          trackEnrichmentControllerProvider((
            fileUuid: fileUuid,
            artistName: artistName,
          )),
        );
        state = EnrichmentRunState(
          // "Found nothing" is an answer worth saying out loud. Left silent,
          // a lookup that legitimately found nothing is indistinguishable
          // from one that never ran.
          stage: report.found > 0
              ? EnrichmentRunStage.found
              : EnrichmentRunStage.nothingFound,
        );

      // A rejected session returns the owner to login, as everywhere else.
      case EnrichmentRunFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        state = const EnrichmentRunState();

      // Switched off, or on with no contact configured. The core answers
      // this as a configuration failure precisely so it can be told apart
      // from something the owner did.
      case EnrichmentRunFailed(failure: ConfigurationFailure()):
        state = const EnrichmentRunState(
          stage: EnrichmentRunStage.unavailable,
        );

      case EnrichmentRunFailed():
        state = const EnrichmentRunState(stage: EnrichmentRunStage.failed);
    }
  }

  /// Whether the owner has left music lookup switched on (FR-UX-13).
  ///
  /// Read before the call rather than left to the core to refuse. The core
  /// would refuse it — it is configured from this same preference — but the
  /// request would have been made, and "off" has to mean the application
  /// asks for nothing rather than asks and is told no. The owner sees the
  /// same sentence either way.
  bool get _lookupIsOn =>
      ref.read(preferencesControllerProvider).musicLookupEnabled;

  /// Clears whatever the last lookup reported.
  void acknowledge() => state = const EnrichmentRunState();
}
