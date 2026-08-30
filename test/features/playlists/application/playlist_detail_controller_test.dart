import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/domain/music_metadata.dart';
import 'package:alexandria_ui/features/playlists/application/playlist_detail_controller.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_playlist_gateway.dart';

/// Reading, reordering, and trimming one playlist's tracks (playlists design
/// sections 2, 3 and 5).
void main() {
  const playlistUuid = 'pl-1';

  CatalogFile file(String uuid, {String name = 'track.flac'}) =>
      CatalogFile(uuid: uuid, name: name, path: '/music/$name', type: FileType.audio);

  PlaylistEntry entry({
    required String uuid,
    required int position,
    String fileUuid = 'f-1',
    String? title,
    bool missing = false,
  }) => PlaylistEntry(
    uuid: uuid,
    file: file(fileUuid),
    metadata: title == null ? null : MusicMetadata(title: title),
    position: position,
    missing: missing,
  );

  ({ProviderContainer ref, FakePlaylistGateway gateway}) build({
    PlaylistView? view,
    bool signedIn = true,
  }) {
    final gateway = FakePlaylistGateway();
    if (view != null) {
      gateway.reads[playlistUuid] = PlaylistRead.loaded(view: view);
    }

    final container = ProviderContainer(
      overrides: [playlistGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);

    if (signedIn) {
      container
          .read(sessionControllerProvider.notifier)
          .establish(FakeAuthGateway.defaultSession);
    }

    return (ref: container, gateway: gateway);
  }

  group('reading a playlist', () {
    test('GivenEntriesInPositionOrder_WhenRead_ThenTheyRenderInThatOrder', () async {
      final view = PlaylistView(
        playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
        entries: [
          entry(uuid: 'e-1', position: 0, title: 'So What'),
          entry(uuid: 'e-2', position: 1, title: 'Freddie Freeloader'),
        ],
      );
      final sut = build(view: view);

      final read = await sut.ref
          .read(playlistDetailControllerProvider(playlistUuid).future);

      expect(read?.entries.map((e) => e.metadata?.title), [
        'So What',
        'Freddie Freeloader',
      ]);
    });

    test('GivenNoSession_WhenRead_ThenTheCoreIsNeverCalled', () async {
      final sut = build(signedIn: false);

      final read = await sut.ref
          .read(playlistDetailControllerProvider(playlistUuid).future);

      expect(read, isNull);
      expect(sut.gateway.readsMade, isEmpty);
    });

    test('GivenNoSession_WhenAnEntryIsRemoved_ThenTheCoreIsNeverCalled', () async {
      final sut = build(signedIn: false);

      await sut.ref
          .read(playlistDetailControllerProvider(playlistUuid).notifier)
          .removeEntry('e-1');

      expect(sut.gateway.entriesRemoved, isEmpty);
    });

    test('GivenNoSession_WhenAnEntryIsMoved_ThenTheCoreIsNeverCalled', () async {
      final sut = build(signedIn: false);

      await sut.ref
          .read(playlistDetailControllerProvider(playlistUuid).notifier)
          .moveEntry(entryUuid: 'e-1', toIndex: 0);

      expect(sut.gateway.entriesMoved, isEmpty);
    });

    test('GivenAMissingEntry_WhenRead_ThenItIsKeptRatherThanDropped', () async {
      final view = PlaylistView(
        playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
        entries: [
          entry(uuid: 'e-1', position: 0, title: 'So What'),
          entry(uuid: 'e-2', position: 1, title: 'Gone', missing: true),
        ],
      );
      final sut = build(view: view);

      final read = await sut.ref
          .read(playlistDetailControllerProvider(playlistUuid).future);

      expect(read?.entries.length, 2);
      expect(read?.entries[1].missing, isTrue);
    });
  });

  group('removing an entry', () {
    // Removing an entry removes THAT entry: the same track appears twice, and
    // only one of the two entries is removed (playlists design section 2).
    test(
      'GivenTheSameTrackTwice_WhenOneEntryIsRemoved_ThenTheOtherSurvives',
      () async {
        final before = PlaylistView(
          playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [
            entry(uuid: 'e-1', position: 0, fileUuid: 'f-1', title: 'So What'),
            entry(uuid: 'e-2', position: 1, fileUuid: 'f-1', title: 'So What'),
          ],
        );
        final sut = build(view: before);
        await sut.ref
            .read(playlistDetailControllerProvider(playlistUuid).future);

        // What the core answers after the removal: only 'e-2' remains.
        final after = PlaylistView(
          playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [
            entry(uuid: 'e-2', position: 0, fileUuid: 'f-1', title: 'So What'),
          ],
        );
        sut.gateway.reads[playlistUuid] = PlaylistRead.loaded(view: after);

        await sut.ref
            .read(playlistDetailControllerProvider(playlistUuid).notifier)
            .removeEntry('e-1');

        expect(sut.gateway.entriesRemoved, [
          (uuid: playlistUuid, entryUuid: 'e-1'),
        ]);
        final state = sut.ref
            .read(playlistDetailControllerProvider(playlistUuid))
            .value;
        expect(state?.entries.map((e) => e.uuid), ['e-2']);
      },
    );
  });

  group('reordering', () {
    // Dragging DOWN is the case Flutter's off-by-one breaks: index 0 to the
    // end of a 4-item list reports `newIndex: 4`, not the `3` that is the
    // core's `toIndex`.
    test(
      'GivenTheOffByOneNewIndex_WhenAnItemIsDraggedDown_ThenTheCoreReceivesTheLastIndex',
      () {
        final toIndex = reorderDestinationIndex(oldIndex: 0, newIndex: 4);

        expect(toIndex, 3);
      },
    );

    test(
      'GivenAnUpwardDrag_WhenReordering_ThenNoAdjustmentIsMade',
      () {
        final toIndex = reorderDestinationIndex(oldIndex: 3, newIndex: 0);

        expect(toIndex, 0);
      },
    );

    // What the screen's no-op guard exists for: crossing the midpoint of the
    // very next item fires `onReorder(oldIndex, oldIndex + 1)` even though
    // nothing about the stored order would actually change — converted, the
    // destination is the entry's own current index.
    test(
      'GivenADropJustPastTheNextItem_WhenConverted_ThenTheResultEqualsOldIndex',
      () {
        final toIndex = reorderDestinationIndex(oldIndex: 1, newIndex: 2);

        expect(toIndex, 1);
      },
    );

    // The screen shows the core's returned order after a move, not a locally
    // computed one — the fake's answer deliberately differs from what naive
    // local arithmetic (moving 'e-1' to index 3) would produce.
    test(
      'GivenAMove_WhenTheCoreAnswers_ThenTheDisplayedOrderIsTheCoresOrder',
      () async {
        final before = PlaylistView(
          playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [
            entry(uuid: 'e-1', position: 0, title: 'A'),
            entry(uuid: 'e-2', position: 1, title: 'B'),
            entry(uuid: 'e-3', position: 2, title: 'C'),
            entry(uuid: 'e-4', position: 3, title: 'D'),
          ],
        );
        final sut = build(view: before);
        await sut.ref
            .read(playlistDetailControllerProvider(playlistUuid).future);

        // The core's real answer to "move e-1 to index 3": not the naive
        // [B, C, D, A] a local shift would produce, but an order that only
        // the core could have produced.
        final afterMove = PlaylistView(
          playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [
            entry(uuid: 'e-2', position: 0, title: 'B'),
            entry(uuid: 'e-4', position: 1, title: 'D'),
            entry(uuid: 'e-3', position: 2, title: 'C'),
            entry(uuid: 'e-1', position: 3, title: 'A'),
          ],
        );
        sut.gateway.reads[playlistUuid] = PlaylistRead.loaded(view: afterMove);

        await sut.ref
            .read(playlistDetailControllerProvider(playlistUuid).notifier)
            .moveEntry(entryUuid: 'e-1', toIndex: 3);

        expect(sut.gateway.entriesMoved, [
          (uuid: playlistUuid, entryUuid: 'e-1', toIndex: 3),
        ]);
        final state = sut.ref
            .read(playlistDetailControllerProvider(playlistUuid))
            .value;
        expect(state?.entries.map((e) => e.uuid), ['e-2', 'e-4', 'e-3', 'e-1']);
      },
    );
  });

  group('a session the core rejects', () {
    test(
      'GivenTheCoreRejectsTheSession_WhenReading_ThenTheOwnerSignsOut',
      () async {
        final sut = build();
        sut.gateway.reads[playlistUuid] = const PlaylistRead.failed(
          failure: Failure.unauthorized(
            family: CoreStatusFamily.playlist,
            code: PLAYLIST_ERR_UNAUTHORIZED,
          ),
        );

        await sut.ref
            .read(playlistDetailControllerProvider(playlistUuid).notifier)
            .reload();

        expect(sut.ref.read(sessionControllerProvider), isA<SessionAbsent>());
      },
    );

    // Covers `_afterWrite`'s `UnauthorizedFailure` branch: without this, a
    // controller that quietly dropped that branch's `invalidate` call would
    // still pass every other test in this file.
    test(
      'GivenTheCoreRejectsTheSessionOnAWrite_WhenAnEntryIsRemoved_ThenTheOwnerSignsOut',
      () async {
        final view = PlaylistView(
          playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [entry(uuid: 'e-1', position: 0, title: 'So What')],
        );
        final sut = build(view: view);
        await sut.ref
            .read(playlistDetailControllerProvider(playlistUuid).future);
        sut.gateway.writeOutcomes.add(
          const PlaylistWrite.failed(
            failure: Failure.unauthorized(
              family: CoreStatusFamily.playlist,
              code: PLAYLIST_ERR_UNAUTHORIZED,
            ),
          ),
        );

        await sut.ref
            .read(playlistDetailControllerProvider(playlistUuid).notifier)
            .removeEntry('e-1');

        expect(sut.ref.read(sessionControllerProvider), isA<SessionAbsent>());
      },
    );
  });
}
