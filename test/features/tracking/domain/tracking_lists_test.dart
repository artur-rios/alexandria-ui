import 'package:alexandria_ui/features/tracking/domain/reading_list.dart';
import 'package:alexandria_ui/features/tracking/domain/watchlist.dart';
import 'package:flutter_test/flutter_test.dart';

/// Watchlists and reading lists: their wire names, what they track, and the
/// one rule on their names (UC-29, UC-30).
void main() {
  group('the wire names', () {
    for (final state in WatchState.values) {
      test(
        'GivenTheWireName${state.wireName}_WhenItIsRead_ThenItIsThe${state.name}WatchState',
        () {
          expect(WatchState.fromWireName(state.wireName), state);
        },
      );
    }

    for (final state in ReadingState.values) {
      test(
        'GivenTheWireName${state.wireName}_WhenItIsRead_ThenItIsThe${state.name}ReadingState',
        () {
          expect(ReadingState.fromWireName(state.wireName), state);
        },
      );
    }

    for (final kind in ReadingTargetKind.values) {
      test(
        'GivenTheWireName${kind.wireName}_WhenItIsRead_ThenItIsThe${kind.name}TargetKind',
        () {
          expect(ReadingTargetKind.fromWireName(kind.wireName), kind);
        },
      );
    }

    test(
      'GivenAnUnknownOrMissingWireName_WhenItIsRead_ThenNothingIsGuessed',
      () {
        expect(WatchState.fromWireName('paused'), isNull);
        expect(WatchState.fromWireName(null), isNull);
        expect(ReadingState.fromWireName('abandoned'), isNull);
        expect(ReadingState.fromWireName(null), isNull);
        expect(ReadingTargetKind.fromWireName('video'), isNull);
        expect(ReadingTargetKind.fromWireName(null), isNull);
      },
    );
  });

  group('Watchlist', () {
    const watching = WatchProgress(
      watchlistUuid: 'w-1',
      videoUuid: 'v-1',
      state: WatchState.watching,
    );
    const list = Watchlist(uuid: 'w-1', name: 'Series', items: [watching]);

    test('GivenATrackedVideo_WhenItsProgressIsAskedFor_ThenItIsAnswered', () {
      expect(list.progressFor('v-1'), watching);
      expect(list.tracks('v-1'), isTrue);
    });

    test('GivenAnUntrackedVideo_WhenItsProgressIsAskedFor_ThenThereIsNone', () {
      expect(list.progressFor('v-9'), isNull);
      expect(list.tracks('v-9'), isFalse);
    });

    test('GivenAnEmptyWatchlist_WhenAnyVideoIsAskedFor_ThenItIsNotTracked', () {
      expect(
        const Watchlist(uuid: 'w-2', name: 'Empty').tracks('v-1'),
        isFalse,
      );
    });

    test(
      'GivenEitherEpisodeCount_WhenItIsAsked_ThenTheProgressCountsEpisodes',
      () {
        expect(watching.countsEpisodes, isFalse);
        expect(watching.copyWith(currentEpisode: 2).countsEpisodes, isTrue);
        expect(watching.copyWith(totalEpisodes: 10).countsEpisodes, isTrue);
      },
    );
  });

  group('ReadingList', () {
    const reading = ReadingProgress(
      readingListUuid: 'r-1',
      itemUuid: 'd-1',
      targetKind: ReadingTargetKind.comic,
      state: ReadingState.reading,
    );
    const list = ReadingList(uuid: 'r-1', name: 'Comics', items: [reading]);

    test('GivenATrackedItem_WhenItsProgressIsAskedFor_ThenItIsAnswered', () {
      expect(list.progressFor('d-1'), reading);
      expect(list.tracks('d-1'), isTrue);
    });

    test('GivenAnUntrackedItem_WhenItsProgressIsAskedFor_ThenThereIsNone', () {
      expect(list.progressFor('d-9'), isNull);
      expect(list.tracks('d-9'), isFalse);
    });

    test('GivenEitherIssueCount_WhenItIsAsked_ThenTheProgressCountsIssues', () {
      expect(reading.countsIssues, isFalse);
      expect(reading.copyWith(currentIssue: 3).countsIssues, isTrue);
      expect(reading.copyWith(totalIssues: 12).countsIssues, isTrue);
    });
  });

  group('the list names', () {
    for (final name in ['', '   ', '\t\n']) {
      test(
        'GivenTheBlankName"${name.replaceAll('\t', r'\t').replaceAll('\n', r'\n')}"_WhenItIsValidated_ThenItIsRefusedAsEmpty',
        () {
          expect(validateWatchlistName(name), WatchlistNameError.empty);
          expect(validateReadingListName(name), ReadingListNameError.empty);
        },
      );
    }

    test('GivenANameWithText_WhenItIsValidated_ThenItIsAccepted', () {
      expect(validateWatchlistName(' Series '), isNull);
      expect(validateReadingListName('Comics'), isNull);
    });
  });
}
