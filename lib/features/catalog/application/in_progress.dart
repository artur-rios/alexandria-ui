import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../tracking/application/tracked_videos_controller.dart';
import '../../tracking/domain/reading_list.dart';
import '../../tracking/domain/watchlist.dart';

/// What an entry's position counts (FR-TR-07, FR-TR-14).
///
/// A watchlist counts episodes and a reading list counts issues. The dashboard
/// merges the two into one section, so the unit travels with the entry rather
/// than being inferred from which list it came out of.
enum ProgressUnit {
  /// Episodes of a series.
  episodes,

  /// Issues of a comic series.
  issues,
}

/// One thing the owner is part-way through (UC-14 main flow step 2,
/// FR-CT-11).
///
/// A watchlist entry and a reading-list entry become the same shape here,
/// because the dashboard reports *what the owner is in the middle of* rather
/// than which feature is tracking it.
class InProgressItem {
  /// Creates an entry.
  const InProgressItem({
    required this.uuid,
    required this.title,
    required this.listName,
    required this.unit,
    this.position,
    this.total,
  });

  /// The file's uuid, so opening it from the dashboard behaves exactly as
  /// opening it from its listing (main flow step 4).
  final String uuid;

  /// The file's name, or its uuid when the catalog will not name it.
  final String title;

  /// The watchlist or reading list this progress belongs to.
  ///
  /// Carried because progress is per list: the same item tracked twice is two
  /// entries here, and without the list name they would read as a duplicate
  /// (UC-30 AF-05, UC-32 AF-05).
  final String listName;

  /// What [position] and [total] count.
  final ProgressUnit unit;

  /// The episode or issue the owner is on, when the entry counts them.
  final int? position;

  /// The total the owner has recorded, when they have recorded one.
  final int? total;
}

/// Everything the owner is part-way through, watchlists first (FR-CT-11).
///
/// A pure function over what the tracking feature already loads: the core
/// publishes no "in progress" call, and these two lists are the whole of what
/// the answer is made of. Keeping it pure is what lets the dashboard's section
/// be tested without a container.
List<InProgressItem> inProgressItems({
  List<Watchlist> watchlists = const [],
  Map<String, TrackedVideo> videos = const {},
  List<ReadingList> readingLists = const [],
  Map<String, String> readingItemNames = const {},
}) => [
  for (final watchlist in watchlists)
    for (final progress in watchlist.items)
      if (progress.state == WatchState.watching)
        InProgressItem(
          uuid: progress.videoUuid,
          title: videos[progress.videoUuid]?.name ?? progress.videoUuid,
          listName: watchlist.name,
          unit: ProgressUnit.episodes,
          position: progress.currentEpisode,
          total: progress.totalEpisodes,
        ),
  for (final readingList in readingLists)
    for (final progress in readingList.items)
      if (progress.state == ReadingState.reading)
        InProgressItem(
          uuid: progress.itemUuid,
          title: readingItemNames[progress.itemUuid] ?? progress.itemUuid,
          listName: readingList.name,
          unit: ProgressUnit.issues,
          position: progress.currentIssue,
          total: progress.totalIssues,
        ),
];

/// Everything the owner is part-way through, for the dashboard (UC-14 main
/// flow step 2, FR-CT-11).
///
/// A section in its own right, so a tracking query that fails is its own
/// failure and does not take the rest of the dashboard down (AF-03).
class InProgressController extends AsyncNotifier<List<InProgressItem>> {
  @override
  Future<List<InProgressItem>> build() async => inProgressItems(
    watchlists: await ref.watch(watchlistsControllerProvider.future),
    videos: await ref.watch(trackedVideosProvider.future),
    readingLists: await ref.watch(readingListsControllerProvider.future),
    readingItemNames: await ref.watch(trackedReadingItemsProvider.future),
  );

  /// Loads the watchlists and reading lists again (AF-03's retry).
  Future<void> reload() async {
    ref.invalidate(watchlistsControllerProvider);
    ref.invalidate(readingListsControllerProvider);
  }
}
