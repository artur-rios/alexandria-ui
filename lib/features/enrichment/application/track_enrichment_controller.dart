import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/enrichment_gateway.dart';
import '../domain/track_enrichment.dart';

/// Which track's enrichment to read, and under whose name.
///
/// A record rather than the file uuid alone: the image is keyed by artist,
/// and the caller is already holding the track's tags. Resolving the artist
/// here instead would mean reading the music library a second time for a
/// fact the screen has on hand.
typedef TrackEnrichmentKey = ({String fileUuid, String? artistName});

/// What enrichment holds for the track being shown (music enrichment
/// design).
///
/// Keyed by track, and auto-disposed: a player moves through a queue, and an
/// entry per track ever played would be held for the life of the process —
/// the same defect the playlists detail controller had until its family was
/// made to dispose.
class TrackEnrichmentController extends AsyncNotifier<TrackEnrichment> {
  /// Creates the controller for [key].
  TrackEnrichmentController(this.key);

  /// The track this instance reads.
  final TrackEnrichmentKey key;

  @override
  Future<TrackEnrichment> build() async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07).
    if (credential == null) return TrackEnrichment.none;

    final outcome = await ref
        .read(enrichmentGatewayProvider)
        .readTrack(
          fileUuid: key.fileUuid,
          artistName: key.artistName,
          credential: credential,
        );

    switch (outcome) {
      case TrackEnrichmentReadLoaded(:final enrichment):
        return enrichment;

      // A rejected session returns the owner to login, as everywhere else.
      case TrackEnrichmentReadFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        return TrackEnrichment.none;

      // Anything else reads as "nothing to show" rather than as an error.
      //
      // Deliberate, and the one judgement in this class. Lyrics and a
      // photograph are an embellishment beside a playing track: a player
      // that grew a red failure banner because a cache read failed would be
      // louder about the embellishment than about the music. The absence is
      // indistinguishable on screen from a track nothing was found for,
      // which is the honest presentation of both.
      case TrackEnrichmentReadFailed():
        return TrackEnrichment.none;
    }
  }
}
