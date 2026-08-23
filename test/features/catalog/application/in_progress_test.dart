import 'package:alexandria_ui/features/catalog/application/in_progress.dart';
import 'package:alexandria_ui/features/catalog/domain/video_metadata.dart';
import 'package:alexandria_ui/features/tracking/application/tracked_videos_controller.dart';
import 'package:alexandria_ui/features/tracking/domain/reading_list.dart';
import 'package:alexandria_ui/features/tracking/domain/watchlist.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the dashboard's in-progress section is built from (UC-14, FR-CT-11).
///
/// A pure selector over the watchlists and reading lists the tracking feature
/// already loads: the core publishes no "in progress" call, and the two lists
/// together are the whole of what the answer is made of.
void main() {
  const movie = TrackedVideo(name: 'Stalker', mediaKind: MediaKind.movie);
  const series = TrackedVideo(name: 'The Wire', mediaKind: MediaKind.series);

  Watchlist watchlistWith(WatchProgress progress) =>
      Watchlist(uuid: 'wl-1', name: 'Evenings', items: [progress]);

  ReadingList readingListWith(ReadingProgress progress) =>
      ReadingList(uuid: 'rl-1', name: 'Winter', items: [progress]);

  group('what counts as in progress', () {
    test(
      'GivenAVideoBeingWatched_WhenTheItemsAreSelected_ThenItIsListedUnderItsWatchlist',
      () {
        final items = inProgressItems(
          watchlists: [
            watchlistWith(
              const WatchProgress(
                watchlistUuid: 'wl-1',
                videoUuid: 'v-1',
                state: WatchState.watching,
              ),
            ),
          ],
          videos: const {'v-1': movie},
        );

        expect(items, hasLength(1));
        expect(items.single.uuid, 'v-1');
        expect(items.single.title, 'Stalker');
        expect(items.single.listName, 'Evenings');
      },
    );

    test(
      'GivenAVideoNotYetStarted_WhenTheItemsAreSelected_ThenItIsNotListed',
      () {
        final items = inProgressItems(
          watchlists: [
            watchlistWith(
              const WatchProgress(
                watchlistUuid: 'wl-1',
                videoUuid: 'v-1',
                state: WatchState.pending,
              ),
            ),
          ],
          videos: const {'v-1': movie},
        );

        expect(items, isEmpty);
      },
    );

    test(
      'GivenAVideoAlreadyWatched_WhenTheItemsAreSelected_ThenItIsNotListed',
      () {
        final items = inProgressItems(
          watchlists: [
            watchlistWith(
              const WatchProgress(
                watchlistUuid: 'wl-1',
                videoUuid: 'v-1',
                state: WatchState.watched,
              ),
            ),
          ],
          videos: const {'v-1': movie},
        );

        expect(items, isEmpty);
      },
    );

    test(
      'GivenAnItemBeingRead_WhenTheItemsAreSelected_ThenItIsListedUnderItsReadingList',
      () {
        final items = inProgressItems(
          readingLists: [
            readingListWith(
              const ReadingProgress(
                readingListUuid: 'rl-1',
                itemUuid: 'b-1',
                targetKind: ReadingTargetKind.document,
                state: ReadingState.reading,
              ),
            ),
          ],
          readingItemNames: const {'b-1': 'Solaris'},
        );

        expect(items, hasLength(1));
        expect(items.single.title, 'Solaris');
        expect(items.single.listName, 'Winter');
      },
    );

    test(
      'GivenAnItemAlreadyRead_WhenTheItemsAreSelected_ThenItIsNotListed',
      () {
        final items = inProgressItems(
          readingLists: [
            readingListWith(
              const ReadingProgress(
                readingListUuid: 'rl-1',
                itemUuid: 'b-1',
                targetKind: ReadingTargetKind.comic,
                state: ReadingState.read,
              ),
            ),
          ],
          readingItemNames: const {'b-1': 'Solaris'},
        );

        expect(items, isEmpty);
      },
    );

    test('GivenNothingTracked_WhenTheItemsAreSelected_ThenNoneAreListed', () {
      expect(inProgressItems(), isEmpty);
    });
  });

  group('how far through the owner is', () {
    test(
      'GivenASeriesOnAnEpisode_WhenTheItemsAreSelected_ThenThePositionIsCarried',
      () {
        final items = inProgressItems(
          watchlists: [
            watchlistWith(
              const WatchProgress(
                watchlistUuid: 'wl-1',
                videoUuid: 'v-1',
                state: WatchState.watching,
                currentEpisode: 4,
                totalEpisodes: 12,
              ),
            ),
          ],
          videos: const {'v-1': series},
        );

        expect(items.single.position, 4);
        expect(items.single.total, 12);
      },
    );

    test(
      'GivenASeriesOnAnEpisode_WhenTheItemsAreSelected_ThenTheUnitIsEpisodes',
      () {
        final items = inProgressItems(
          watchlists: [
            watchlistWith(
              const WatchProgress(
                watchlistUuid: 'wl-1',
                videoUuid: 'v-1',
                state: WatchState.watching,
                currentEpisode: 4,
              ),
            ),
          ],
          videos: const {'v-1': series},
        );

        expect(items.single.unit, ProgressUnit.episodes);
      },
    );

    test(
      'GivenAComicOnAnIssue_WhenTheItemsAreSelected_ThenTheUnitIsIssues',
      () {
        final items = inProgressItems(
          readingLists: [
            readingListWith(
              const ReadingProgress(
                readingListUuid: 'rl-1',
                itemUuid: 'c-1',
                targetKind: ReadingTargetKind.comic,
                state: ReadingState.reading,
                currentIssue: 7,
              ),
            ),
          ],
          readingItemNames: const {'c-1': 'Sandman'},
        );

        expect(items.single.unit, ProgressUnit.issues);
      },
    );

    test(
      'GivenAMovieBeingWatched_WhenTheItemsAreSelected_ThenItHasNoPosition',
      () {
        final items = inProgressItems(
          watchlists: [
            watchlistWith(
              const WatchProgress(
                watchlistUuid: 'wl-1',
                videoUuid: 'v-1',
                state: WatchState.watching,
              ),
            ),
          ],
          videos: const {'v-1': movie},
        );

        expect(items.single.position, isNull);
        expect(items.single.total, isNull);
      },
    );

    test(
      'GivenAComicOnAnIssue_WhenTheItemsAreSelected_ThenThePositionIsCarried',
      () {
        final items = inProgressItems(
          readingLists: [
            readingListWith(
              const ReadingProgress(
                readingListUuid: 'rl-1',
                itemUuid: 'c-1',
                targetKind: ReadingTargetKind.comic,
                state: ReadingState.reading,
                currentIssue: 7,
                totalIssues: 30,
              ),
            ),
          ],
          readingItemNames: const {'c-1': 'Sandman'},
        );

        expect(items.single.position, 7);
        expect(items.single.total, 30);
      },
    );
  });

  group('the same item in more than one list', () {
    // UC-30 AF-05 and UC-32 AF-05: progress is per list, so the dashboard
    // reports it per list too rather than merging two answers into one.
    test(
      'GivenAVideoWatchedInTwoWatchlists_WhenTheItemsAreSelected_ThenEachListIsReported',
      () {
        final items = inProgressItems(
          watchlists: [
            const Watchlist(
              uuid: 'wl-1',
              name: 'Evenings',
              items: [
                WatchProgress(
                  watchlistUuid: 'wl-1',
                  videoUuid: 'v-1',
                  state: WatchState.watching,
                ),
              ],
            ),
            const Watchlist(
              uuid: 'wl-2',
              name: 'Weekends',
              items: [
                WatchProgress(
                  watchlistUuid: 'wl-2',
                  videoUuid: 'v-1',
                  state: WatchState.watching,
                ),
              ],
            ),
          ],
          videos: const {'v-1': movie},
        );

        expect(items.map((item) => item.listName), ['Evenings', 'Weekends']);
      },
    );
  });

  group('an item the catalog will not name', () {
    // The same fallback the watchlist screen makes: the uuid is the only name
    // there is, and an entry with no title at all would be worse.
    test(
      'GivenAVideoWithNoKnownName_WhenTheItemsAreSelected_ThenTheUuidIsTheTitle',
      () {
        final items = inProgressItems(
          watchlists: [
            watchlistWith(
              const WatchProgress(
                watchlistUuid: 'wl-1',
                videoUuid: 'v-9',
                state: WatchState.watching,
              ),
            ),
          ],
          videos: const {},
        );

        expect(items.single.title, 'v-9');
      },
    );

    test(
      'GivenAReadingItemWithNoKnownName_WhenTheItemsAreSelected_ThenTheUuidIsTheTitle',
      () {
        final items = inProgressItems(
          readingLists: [
            readingListWith(
              const ReadingProgress(
                readingListUuid: 'rl-1',
                itemUuid: 'b-9',
                targetKind: ReadingTargetKind.document,
                state: ReadingState.reading,
              ),
            ),
          ],
          readingItemNames: const {},
        );

        expect(items.single.title, 'b-9');
      },
    );
  });
}
