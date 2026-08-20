import 'dart:convert';

import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../domain/watch_progress_gateway.dart';

/// [WatchProgressGateway] over the core's `alexandria_watchlists_list`
/// (UC-16 AF-03).
///
/// The core publishes no "progress for this video" call, so the question is
/// answered from the browse it does publish: every watchlist, each carrying
/// the progress of what it tracks. That is more than is needed for one
/// answer, and it is what exists — a narrower call would be back-end work
/// (BR-02), not something to invent here.
class CoreWatchProgressGateway implements WatchProgressGateway {
  /// Wraps [_core].
  const CoreWatchProgressGateway(this._core);

  final CoreClient _core;

  @override
  Future<bool> episodesRecordedFor({
    required String uuid,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      // An empty filter is every watchlist, which is what this has to look
      // across: the video may be tracked by any of them.
      response = await _core.watchlistsList('', credential);
    } on CoreCallException {
      return false;
    }

    if (!CoreStatusFamily.watchlist.isOk(response.status)) return false;

    final json = response.json;
    if (json == null) return false;

    try {
      final watchlists = jsonDecode(json) as List<dynamic>;

      for (final watchlist in watchlists) {
        if (watchlist is! Map<String, dynamic>) continue;

        final items = watchlist['items'];
        if (items is! List<dynamic>) continue;

        for (final item in items) {
          if (item is! Map<String, dynamic>) continue;
          if (item['videoUuid'] != uuid) continue;

          // Either field being present is a progress counted in episodes: a
          // total with no current is a series somebody has not started, and
          // flattening it to a single item still loses what was recorded.
          if (item['currentEpisode'] != null || item['totalEpisodes'] != null) {
            return true;
          }
        }
      }

      return false;
    } on Object {
      // An answer that cannot be read is not a reason to warn, for the same
      // reason a failed call is not.
      return false;
    }
  }
}
