import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/playlists/application/playlists_controller.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_playlist_gateway.dart';

/// Managing playlists: creating, renaming, and deleting them (playlists
/// design).
void main() {
  const jazz = Playlist(uuid: 'p-1', name: 'Jazz');

  ({ProviderContainer ref, FakePlaylistGateway gateway}) build({
    List<Playlist> playlists = const [jazz],
    bool signedIn = true,
  }) {
    final gateway = FakePlaylistGateway(playlists: playlists);

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

  group('the main flow', () {
    test('GivenPlaylists_WhenTheScreenOpens_ThenTheyAreListed', () async {
      final sut = build();

      final playlists = await sut.ref.read(playlistsControllerProvider.future);

      expect(playlists, [jazz]);
    });

    test('GivenNoSession_WhenBrowsing_ThenTheCoreIsNeverCalled', () async {
      // FR-AU-07: no session, no call.
      final sut = build(signedIn: false);

      final playlists = await sut.ref.read(playlistsControllerProvider.future);

      expect(playlists, isEmpty);
    });

    // Creating one adds it to the list without a manual refresh.
    test('GivenAName_WhenCreated_ThenItAppearsWithoutAManualRefresh', () async {
      final sut = build(playlists: const []);
      await sut.ref.read(playlistsControllerProvider.future);

      sut.ref.read(playlistsFormProvider.notifier).editName('Chill');
      await sut.ref.read(playlistsFormProvider.notifier).create();

      final playlists = sut.ref.read(playlistsControllerProvider).value;
      expect(playlists?.map((p) => p.name), ['Chill']);
      expect(sut.gateway.created, ['Chill']);
    });

    // Renaming shows the new name.
    test('GivenAPlaylist_WhenRenamed_ThenTheNewNameShows', () async {
      final sut = build();
      await sut.ref.read(playlistsControllerProvider.future);

      sut.ref
          .read(playlistsFormProvider.notifier)
          .startRenaming(uuid: jazz.uuid, currentName: jazz.name);
      sut.ref.read(playlistsFormProvider.notifier).editName('Bebop');
      await sut.ref.read(playlistsFormProvider.notifier).renameSubmitted();

      final playlists = sut.ref.read(playlistsControllerProvider).value;
      expect(playlists?.single.name, 'Bebop');
      expect(sut.gateway.renamed, [(uuid: jazz.uuid, name: 'Bebop')]);
    });

    test('GivenAPlaylist_WhenDeleted_ThenTheCoreIsCalled', () async {
      final sut = build();
      await sut.ref.read(playlistsControllerProvider.future);

      await sut.ref.read(playlistsFormProvider.notifier).delete(jazz.uuid);

      expect(sut.gateway.deleted, [jazz.uuid]);
      expect(sut.ref.read(playlistsControllerProvider).value, isEmpty);
    });
  });

  // A blank name never reaches the core (the presentation-layer courtesy,
  // not a re-implementation of the core's own rule, BR-02).
  group('a name the screen refuses', () {
    test('GivenABlankName_WhenCreateIsAsked_ThenTheCoreIsNotCalled', () async {
      final sut = build(playlists: const []);

      sut.ref.read(playlistsFormProvider.notifier).editName('   ');
      await sut.ref.read(playlistsFormProvider.notifier).create();

      expect(sut.gateway.created, isEmpty);
      expect(
        sut.ref.read(playlistsFormProvider).nameError,
        PlaylistNameError.empty,
      );
    });

    test('GivenABlankRename_WhenSaveIsAsked_ThenTheCoreIsNotCalled', () async {
      final sut = build();

      sut.ref
          .read(playlistsFormProvider.notifier)
          .startRenaming(uuid: jazz.uuid, currentName: jazz.name);
      sut.ref.read(playlistsFormProvider.notifier).editName('  ');
      await sut.ref.read(playlistsFormProvider.notifier).renameSubmitted();

      expect(sut.gateway.renamed, isEmpty);
      expect(
        sut.ref.read(playlistsFormProvider).nameError,
        PlaylistNameError.empty,
      );
    });
  });

  group('a session the core rejects', () {
    test(
      'GivenTheCoreRejectsTheSession_WhenBrowsing_ThenTheOwnerSignsOut',
      () async {
        final sut = build();
        sut.gateway.browseOutcome = const PlaylistBrowse.failed(
          failure: Failure.unauthorized(
            family: CoreStatusFamily.playlist,
            code: PLAYLIST_ERR_UNAUTHORIZED,
          ),
        );

        await sut.ref.read(playlistsControllerProvider.notifier).reload();

        expect(
          sut.ref.read(sessionControllerProvider),
          isA<SessionAbsent>(),
        );
      },
    );
  });

  group('a playlist the core no longer has', () {
    test('GivenItIsGone_WhenDeleted_ThenTheOwnerIsTold', () async {
      final sut = build();
      sut.gateway.writeOutcomes.add(
        const PlaylistWrite.failed(
          failure: Failure.notFound(
            family: CoreStatusFamily.playlist,
            code: PLAYLIST_ERR_NOT_FOUND,
          ),
        ),
      );

      await sut.ref.read(playlistsFormProvider.notifier).delete(jazz.uuid);

      expect(sut.ref.read(playlistsFormProvider).notice, PlaylistNotice.notFound);
    });
  });
}
