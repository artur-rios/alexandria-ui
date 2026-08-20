import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../catalog/domain/catalog_gateway.dart';
import '../../catalog/domain/video_metadata.dart';

/// What a watchlist screen needs to know about a tracked video (UC-30).
class TrackedVideo {
  /// Creates an entry.
  const TrackedVideo({required this.name, this.mediaKind});

  /// The file's name, so the screen shows a title rather than a uuid.
  final String name;

  /// Whether the core marks it a movie or a series (UC-16, FR-ME-02).
  ///
  /// `null` when the core holds no marking, which the screen treats as a
  /// movie: episode fields for something nobody has said is a series would be
  /// this application inventing the marking UC-16 exists to set.
  final MediaKind? mediaKind;

  /// Whether progress on this one is counted per episode (FR-TR-07).
  bool get isSeries => mediaKind == MediaKind.series;
}

/// The tracked videos, by uuid (UC-30 main flow step 2).
///
/// A watchlist carries the uuid the core tracks a video by and nothing else,
/// so the name and the movie-or-series marking are read per video. That is a
/// call each, once, held for the run — the same shape and the same cost as the
/// music library's grouping, and for the same reason: the core publishes no
/// call that answers several files at once with their metadata.
class TrackedVideosController extends AsyncNotifier<Map<String, TrackedVideo>> {
  @override
  Future<Map<String, TrackedVideo>> build() async {
    final watchlists = await ref.watch(watchlistsControllerProvider.future);
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return const {};

    final uuids = {
      for (final watchlist in watchlists)
        for (final item in watchlist.items) item.videoUuid,
    };

    final gateway = ref.read(catalogGatewayProvider);
    final videos = <String, TrackedVideo>{};

    for (final uuid in uuids) {
      final details = await gateway.fileDetails(
        uuid: uuid,
        credential: credential,
      );

      videos[uuid] = switch (details) {
        FileDetailsRead(:final details) => TrackedVideo(
          name: details.file.name,
          mediaKind: VideoMetadata.fromDetails(details.metadata).mediaKind,
        ),
        // A video the catalog will not describe is still tracked, and the
        // watchlist still has to show it. Its uuid is the only name there is.
        FileDetailsFailed() => TrackedVideo(name: uuid),
      };
    }

    return videos;
  }
}
