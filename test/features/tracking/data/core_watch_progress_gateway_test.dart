import 'package:alexandria_desktop/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_desktop/features/tracking/data/core_watch_progress_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_core_client.dart';

/// Reading whether a video's progress is counted per episode (UC-16 AF-03).
void main() {
  const uuid = '9b7c1d20-3a4e-4f51-8c02-7d6e5f4a3b2c';

  Future<bool> answerTo(({int status, String? json}) watchlists) {
    final core = FakeCoreClient()..watchlists = watchlists;

    return CoreWatchProgressGateway(
      core,
    ).episodesRecordedFor(uuid: uuid, credential: 'a-session');
  }

  test(
    'GivenAVideoTrackedByEpisode_WhenItIsAskedAbout_ThenEpisodesAreRecorded',
    () async {
      expect(
        await answerTo((
          status: WATCHLIST_OK,
          json:
              '[{"uuid":"w1","name":"Watching","items":'
              '[{"videoUuid":"$uuid","state":"watching","currentEpisode":3}]}]',
        )),
        isTrue,
      );
    },
  );

  // A total with no current is a series nobody has started, and flattening it
  // still loses what was recorded.
  test(
    'GivenOnlyATotalEpisodeCount_WhenItIsAskedAbout_ThenEpisodesAreRecorded',
    () async {
      expect(
        await answerTo((
          status: WATCHLIST_OK,
          json:
              '[{"uuid":"w1","name":"Later","items":'
              '[{"videoUuid":"$uuid","state":"planned","totalEpisodes":12}]}]',
        )),
        isTrue,
      );
    },
  );

  test(
    'GivenAVideoTrackedAsOneItem_WhenItIsAskedAbout_ThenNoEpisodesAreRecorded',
    () async {
      expect(
        await answerTo((
          status: WATCHLIST_OK,
          json:
              '[{"uuid":"w1","name":"Films","items":'
              '[{"videoUuid":"$uuid","state":"watched"}]}]',
        )),
        isFalse,
      );
    },
  );

  // The progress belongs to a different video, so it says nothing about this
  // one.
  test(
    'GivenAnotherVideosEpisodes_WhenThisOneIsAskedAbout_ThenNoneAreRecorded',
    () async {
      expect(
        await answerTo((
          status: WATCHLIST_OK,
          json:
              '[{"uuid":"w1","name":"Watching","items":'
              '[{"videoUuid":"another","currentEpisode":4}]}]',
        )),
        isFalse,
      );
    },
  );

  test(
    'GivenNoWatchlists_WhenItIsAskedAbout_ThenNoEpisodesAreRecorded',
    () async {
      expect(await answerTo((status: WATCHLIST_OK, json: '[]')), isFalse);
    },
  );

  // A warning nobody can justify is worse than none, so an answer the core
  // could not give is not one.
  test(
    'GivenTheCoreRefuses_WhenItIsAskedAbout_ThenNoEpisodesAreRecorded',
    () async {
      expect(
        await answerTo((status: WATCHLIST_ERR_UNAUTHORIZED, json: null)),
        isFalse,
      );
    },
  );

  test(
    'GivenAnUnreadableAnswer_WhenItIsAskedAbout_ThenNoEpisodesAreRecorded',
    () async {
      expect(await answerTo((status: WATCHLIST_OK, json: 'not json')), isFalse);
    },
  );

  test('GivenNoBody_WhenItIsAskedAbout_ThenNoEpisodesAreRecorded', () async {
    expect(await answerTo((status: WATCHLIST_OK, json: null)), isFalse);
  });
}
