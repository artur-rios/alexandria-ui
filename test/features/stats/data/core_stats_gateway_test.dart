import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/stats/data/core_stats_gateway.dart';
import 'package:alexandria_ui/features/stats/domain/stats_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_core_client.dart';

/// Recording plays and reading the rankings over the core's calls (play
/// history design).
void main() {
  const credential = 'session-1';

  ({FakeCoreClient core, CoreStatsGateway gateway}) build(
    String? json, {
    int status = PLAY_OK,
  }) {
    final core = FakeCoreClient()..playResponse = (status: status, json: json);
    return (core: core, gateway: CoreStatsGateway(core));
  }

  group('recording a play', () {
    test('GivenATrack_WhenRecorded_ThenTheCoreIsToldWhatWasPlayed', () async {
      final built = build('{"fileUuid":"f-1","playedAt":"2026-09-03T12:00:00Z"}');

      final outcome = await built.gateway.record(
        fileUuid: 'f-1',
        credential: credential,
      );

      expect(outcome, isA<PlayRecordedDone>());
      expect(built.core.playRecordCalls.single.token, credential);
      // What, and only what: the moment is the core's to decide, and a body
      // carrying one would be this application deciding it instead.
      expect(built.core.playRecordCalls.single.jsonBody, '{"fileUuid":"f-1"}');
    });

    test('GivenTheCoreRefuses_WhenRecorded_ThenTheFailureIsNamed', () async {
      final built = build(null, status: PLAY_ERR_NOT_FOUND);

      final outcome = await built.gateway.record(
        fileUuid: 'f-1',
        credential: credential,
      );

      // The play family's own not-found, not another family's code that
      // happens to share the number.
      expect(
        (outcome as PlayRecordedFailed).failure,
        isA<NotFoundFailure>(),
      );
    });
  });

  group('reading the rankings', () {
    test('GivenEveryRanking_WhenRead_ThenTheyArriveParsed', () async {
      final built = build('''
        {
          "totalPlays": 7,
          "distinctTracks": 3,
          "firstPlayedAt": "2026-08-01T09:00:00Z",
          "lastPlayedAt": "2026-09-03T12:30:00Z",
          "topTracks": [
            {
              "fileUuid": "f-1",
              "title": "So What",
              "artist": "Miles Davis",
              "album": "Kind of Blue",
              "plays": 4,
              "lastPlayedAt": "2026-09-03T12:30:00Z"
            }
          ],
          "topArtists": [
            {"artist": "Miles Davis", "plays": 5, "tracks": 2}
          ],
          "topAlbums": [
            {"album": "Kind of Blue", "artist": "Miles Davis", "plays": 5}
          ],
          "topGenres": [
            {"genre": "Jazz", "plays": 7}
          ]
        }
      ''');

      final read = await built.gateway.read(limit: 10, credential: credential);

      final stats = (read as MusicStatsReadLoaded).stats;
      expect(stats.totalPlays, 7);
      expect(stats.distinctTracks, 3);
      expect(stats.firstPlayedAt, DateTime.utc(2026, 8, 1, 9));
      expect(stats.lastPlayedAt, DateTime.utc(2026, 9, 3, 12, 30));
      expect(stats.topTracks.single.title, 'So What');
      expect(stats.topTracks.single.plays, 4);
      expect(stats.topArtists.single.tracks, 2);
      expect(stats.topAlbums.single.artist, 'Miles Davis');
      expect(stats.topGenres.single.genre, 'Jazz');
      expect(built.core.musicStatsCalls.single.jsonQuery, '{"limit":10}');
    });

    test('GivenNothingPlayed_WhenRead_ThenTheWindowIsAbsentRatherThanZero',
        () async {
      final built = build('''
        {
          "totalPlays": 0,
          "distinctTracks": 0,
          "firstPlayedAt": null,
          "lastPlayedAt": null,
          "topTracks": [],
          "topArtists": [],
          "topAlbums": [],
          "topGenres": []
        }
      ''');

      final read = await built.gateway.read(limit: 10, credential: credential);

      final stats = (read as MusicStatsReadLoaded).stats;
      expect(stats.isEmpty, isTrue);
      // Not the epoch: nothing has been played, so there is no period for
      // the numbers to cover.
      expect(stats.firstPlayedAt, isNull);
      expect(stats.lastPlayedAt, isNull);
    });

    test('GivenAnAlbumNobodyAgreesOn_WhenRead_ThenItHasNoArtist', () async {
      final built = build('''
        {
          "totalPlays": 2,
          "distinctTracks": 2,
          "firstPlayedAt": "2026-09-03T12:00:00Z",
          "lastPlayedAt": "2026-09-03T12:05:00Z",
          "topTracks": [],
          "topArtists": [],
          "topAlbums": [{"album": "Compilation", "artist": null, "plays": 2}],
          "topGenres": []
        }
      ''');

      final read = await built.gateway.read(limit: 10, credential: credential);

      expect(
        (read as MusicStatsReadLoaded).stats.topAlbums.single.artist,
        isNull,
      );
    });

    test('GivenAMalformedRanking_WhenRead_ThenTheWholeReadFails', () async {
      // A ranking with a hole in it is a wrong answer drawn as a confident
      // one, where a listing missing a file is visibly one file short — so
      // this one does not drop the row and carry on.
      final built = build('{"totalPlays": 3, "topTracks": [{"title": 12}]}');

      final read = await built.gateway.read(limit: 10, credential: credential);

      expect(read, isA<MusicStatsReadFailed>());
    });
  });
}
