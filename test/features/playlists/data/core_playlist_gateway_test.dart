import 'dart:convert';

import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/playlists/data/core_playlist_gateway.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_core_client.dart';

/// One `FileView`-shaped track, in the exact shape the playlist read answers:
/// `{entryUuid, position, missing, file: <FileView>}` where `<FileView>` is
/// itself `{file, metadata}` (confirmed against `alexandria-core`'s
/// `PlaylistTrack`/`FileView`, not paraphrased from the task brief).
String _trackJson({
  required String entryUuid,
  required int position,
  required String fileUuid,
  String title = 'A Track',
  bool missing = false,
}) =>
    '{"entryUuid":"$entryUuid","position":$position,"missing":$missing,'
    '"file":{"file":{"uuid":"$fileUuid","name":"$title.flac",'
    '"path":"/music/$title.flac","fileType":"audio","state":"active"},'
    '"metadata":{"type":"audio","title":"$title"}}}';

void main() {
  group('read', () {
    test(
      'GivenEntriesOutOfPositionOrderInTheArray_WhenAPlaylistIsRead_ThenTheyAreNotReSorted',
      () async {
        // Position 0 is listed *second* in the JSON array — a parser that
        // trusts array index, or that re-sorts by `position` itself, fails
        // this (BR-02: the core owns ordering, this gateway renders what it
        // is given).
        final core = FakeCoreClient()
          ..playlistResponse = (
            status: PLAYLIST_OK,
            json:
                '{"playlist":{"uuid":"pl-1","name":"Road trip"},'
                '"entries":[${_trackJson(entryUuid: "e-2", position: 1, fileUuid: "f-2", title: "Second")},'
                '${_trackJson(entryUuid: "e-1", position: 0, fileUuid: "f-1", title: "First")}]}',
          );
        final gateway = CorePlaylistGateway(core);

        final result = await gateway.read(uuid: 'pl-1', credential: 'token');

        expect(result, isA<PlaylistReadLoaded>());
        final entries = (result as PlaylistReadLoaded).view.entries;
        expect(entries.map((e) => e.uuid), ['e-2', 'e-1']);
        expect(entries.map((e) => e.position), [1, 0]);
      },
    );

    test(
      'GivenAnEntryFlaggedMissing_WhenAPlaylistIsRead_ThenItParsesAsMissingRatherThanBeingDropped',
      () async {
        final core = FakeCoreClient()
          ..playlistResponse = (
            status: PLAYLIST_OK,
            json:
                '{"playlist":{"uuid":"pl-1","name":"Road trip"},'
                '"entries":[${_trackJson(entryUuid: "e-1", position: 0, fileUuid: "f-1", missing: true)}]}',
          );
        final gateway = CorePlaylistGateway(core);

        final result = await gateway.read(uuid: 'pl-1', credential: 'token');

        expect(result, isA<PlaylistReadLoaded>());
        final entries = (result as PlaylistReadLoaded).view.entries;
        expect(entries, hasLength(1));
        expect(entries.single.missing, isTrue);
      },
    );

    test(
      'GivenTheSameTrackTwice_WhenAPlaylistIsRead_ThenItParsesAsTwoEntriesWithDifferentUuids',
      () async {
        final core = FakeCoreClient()
          ..playlistResponse = (
            status: PLAYLIST_OK,
            json:
                '{"playlist":{"uuid":"pl-1","name":"Road trip"},'
                '"entries":[${_trackJson(entryUuid: "e-1", position: 0, fileUuid: "f-1")},'
                '${_trackJson(entryUuid: "e-2", position: 1, fileUuid: "f-1")}]}',
          );
        final gateway = CorePlaylistGateway(core);

        final result = await gateway.read(uuid: 'pl-1', credential: 'token');

        expect(result, isA<PlaylistReadLoaded>());
        final entries = (result as PlaylistReadLoaded).view.entries;
        expect(entries, hasLength(2));
        expect(entries.map((e) => e.file.uuid).toSet(), {'f-1'});
        expect(entries.map((e) => e.uuid).toSet(), {'e-1', 'e-2'});
      },
    );

    test(
      'GivenAMalformedPayload_WhenAPlaylistIsRead_ThenItFailsRatherThanThrowing',
      () async {
        final core = FakeCoreClient()
          ..playlistResponse = (
            status: PLAYLIST_OK,
            json: '{"notAPlaylist":true}',
          );
        final gateway = CorePlaylistGateway(core);

        final result = await gateway.read(uuid: 'pl-1', credential: 'token');

        expect(result, isA<PlaylistReadFailed>());
      },
    );

    test(
      'GivenAnUnauthorizedAnswer_WhenAPlaylistIsRead_ThenItMapsToUnauthorizedFailure',
      () async {
        final core = FakeCoreClient()
          ..playlistResponse = (status: PLAYLIST_ERR_UNAUTHORIZED, json: null);
        final gateway = CorePlaylistGateway(core);

        final result = await gateway.read(uuid: 'pl-1', credential: 'token');

        expect(result, isA<PlaylistReadFailed>());
        expect(
          (result as PlaylistReadFailed).failure,
          isA<UnauthorizedFailure>(),
        );
      },
    );

    test(
      'GivenNullJsonOnSuccess_WhenAPlaylistIsRead_ThenItFailsRatherThanThrowing',
      () async {
        final core = FakeCoreClient()
          ..playlistResponse = (status: PLAYLIST_OK, json: null);
        final gateway = CorePlaylistGateway(core);

        final result = await gateway.read(uuid: 'pl-1', credential: 'token');

        expect(result, isA<PlaylistReadFailed>());
      },
    );
  });

  group('browse', () {
    test(
      'GivenPlaylistsTheCoreAnswers_WhenBrowsing_ThenTheyParseInOrder',
      () async {
        final core = FakeCoreClient()
          ..playlistResponse = (
            status: PLAYLIST_OK,
            json:
                '[{"uuid":"pl-1","name":"Road trip"},'
                '{"uuid":"pl-2","name":"Focus"}]',
          );
        final gateway = CorePlaylistGateway(core);

        final result = await gateway.browse(credential: 'token');

        expect(result, isA<PlaylistBrowseLoaded>());
        final playlists = (result as PlaylistBrowseLoaded).playlists;
        expect(playlists, [
          const Playlist(uuid: 'pl-1', name: 'Road trip'),
          const Playlist(uuid: 'pl-2', name: 'Focus'),
        ]);
      },
    );

    test(
      'GivenAMalformedPayload_WhenBrowsing_ThenItFailsRatherThanThrowing',
      () async {
        final core = FakeCoreClient()
          ..playlistResponse = (status: PLAYLIST_OK, json: 'not json');
        final gateway = CorePlaylistGateway(core);

        final result = await gateway.browse(credential: 'token');

        expect(result, isA<PlaylistBrowseFailed>());
      },
    );
  });

  group('writes', () {
    test(
      'GivenAName_WhenCreatingAPlaylist_ThenTheBodyCarriesJustTheName',
      () async {
        final core = FakeCoreClient()
          ..playlistResponse = (status: PLAYLIST_OK, json: '{}');
        final gateway = CorePlaylistGateway(core);

        final result = await gateway.create(
          name: 'Road trip',
          credential: 'token',
        );

        expect(result, isA<PlaylistWriteDone>());
        expect(
          core.playlistCreateCalls.single.jsonBody,
          jsonEncode({'name': 'Road trip'}),
        );
      },
    );

    test('GivenANewName_WhenRenamingAPlaylist_ThenTheBodyCarriesIt', () async {
      final core = FakeCoreClient()
        ..playlistResponse = (status: PLAYLIST_OK, json: '{}');
      final gateway = CorePlaylistGateway(core);

      final result = await gateway.rename(
        uuid: 'pl-1',
        name: 'Focus',
        credential: 'token',
      );

      expect(result, isA<PlaylistWriteDone>());
      final call = core.playlistRenameCalls.single;
      expect(call.uuid, 'pl-1');
      expect(call.jsonBody, jsonEncode({'name': 'Focus'}));
    });

    test('GivenAUuid_WhenDeletingAPlaylist_ThenItIsSent', () async {
      final core = FakeCoreClient()
        ..playlistResponse = (status: PLAYLIST_OK, json: '{}');
      final gateway = CorePlaylistGateway(core);

      final result = await gateway.delete(uuid: 'pl-1', credential: 'token');

      expect(result, isA<PlaylistWriteDone>());
      expect(core.playlistDeleteCalls.single.uuid, 'pl-1');
    });

    test(
      // An empty object is the core's success answer for every write here —
      // it must never be mistaken for a malformed payload.
      'GivenAnEmptyObjectAnswer_WhenDeletingAPlaylist_ThenItStillCountsAsDone',
      () async {
        final core = FakeCoreClient()
          ..playlistResponse = (status: PLAYLIST_OK, json: '{}');
        final gateway = CorePlaylistGateway(core);

        final result = await gateway.delete(uuid: 'pl-1', credential: 'token');

        expect(result, isA<PlaylistWriteDone>());
      },
    );

    test(
      'GivenFileUuids_WhenAddingEntries_ThenTheyAreSentInOrderInOneCall',
      () async {
        final core = FakeCoreClient()
          ..playlistResponse = (status: PLAYLIST_OK, json: '{}');
        final gateway = CorePlaylistGateway(core);

        final result = await gateway.addEntries(
          uuid: 'pl-1',
          fileUuids: const ['f-1', 'f-2'],
          credential: 'token',
        );

        expect(result, isA<PlaylistWriteDone>());
        expect(core.playlistAddEntriesCalls, hasLength(1));
        final call = core.playlistAddEntriesCalls.single;
        expect(call.uuid, 'pl-1');
        expect(
          call.jsonBody,
          jsonEncode({
            'fileUuids': ['f-1', 'f-2'],
          }),
        );
      },
    );

    test(
      'GivenAnEntryUuid_WhenRemovingAnEntry_ThenTheEntryUuidIsSentNotAFileUuid',
      () async {
        final core = FakeCoreClient()
          ..playlistResponse = (status: PLAYLIST_OK, json: '{}');
        final gateway = CorePlaylistGateway(core);

        final result = await gateway.removeEntry(
          uuid: 'pl-1',
          entryUuid: 'e-1',
          credential: 'token',
        );

        expect(result, isA<PlaylistWriteDone>());
        final call = core.playlistRemoveEntryCalls.single;
        expect(call.uuid, 'pl-1');
        expect(call.entryUuid, 'e-1');
      },
    );

    test(
      'GivenADestinationIndex_WhenMovingAnEntry_ThenTheBodyCarriesToIndexOnly',
      () async {
        final core = FakeCoreClient()
          ..playlistResponse = (status: PLAYLIST_OK, json: '{}');
        final gateway = CorePlaylistGateway(core);

        final result = await gateway.moveEntry(
          uuid: 'pl-1',
          entryUuid: 'e-1',
          toIndex: 2,
          credential: 'token',
        );

        expect(result, isA<PlaylistWriteDone>());
        final call = core.playlistMoveEntryCalls.single;
        expect(call.uuid, 'pl-1');
        expect(call.entryUuid, 'e-1');
        expect(call.jsonBody, jsonEncode({'toIndex': 2}));
      },
    );

    test(
      'GivenAnUnauthorizedAnswer_WhenCreatingAPlaylist_ThenItMapsToUnauthorizedFailure',
      () async {
        final core = FakeCoreClient()
          ..playlistResponse = (status: PLAYLIST_ERR_UNAUTHORIZED, json: null);
        final gateway = CorePlaylistGateway(core);

        final result = await gateway.create(
          name: 'Road trip',
          credential: 'token',
        );

        expect(result, isA<PlaylistWriteFailed>());
        expect(
          (result as PlaylistWriteFailed).failure,
          isA<UnauthorizedFailure>(),
        );
      },
    );
  });
}
