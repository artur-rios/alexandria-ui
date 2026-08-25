import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/playback/domain/music_browse.dart';
import 'package:alexandria_ui/features/playback/domain/playback_queue.dart';
import 'package:alexandria_ui/features/playback/presentation/music_rows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_media_player.dart';
import '../../../support/fake_playback.dart';

/// The rows the music area lists artists, albums and tracks with (UC-46 main
/// flow step 2 and 3), and what a tap on one of them does.
///
/// Task 5 adds the context menu; what these rows already carry — text and a
/// tap — is the task's only new user action, so it is what this file tests.
void main() {
  /// A container with a session and every playback dependency faked, so
  /// [AudioPlaybackController] runs for real over [gateway] rather than being
  /// replaced itself — the point is that a tap reaches the real controller.
  ProviderContainer buildContainer(FakeCatalogGateway gateway) {
    final container = ProviderContainer(
      overrides: [
        catalogGatewayProvider.overrideWithValue(gateway),
        audioPlayerProvider.overrideWithValue(FakeMediaPlayer()),
        playbackSourceGatewayProvider.overrideWithValue(
          FakePlaybackSourceGateway(),
        ),
        playbackPositionsProvider.overrideWithValue(
          FakePlaybackPositionStore(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);

    return container;
  }

  /// Pumps [child] over [container], with the localizations the rows read.
  Future<void> pumpRows(
    WidgetTester tester,
    ProviderContainer container,
    Widget child,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('a Songs row (main flow step 3)', () {
    testWidgets('GivenTheSongsView_WhenARowIsTapped_ThenThatTrackPlaysAlone', (
      tester,
    ) async {
      final gateway = FakeCatalogGateway()
        ..addAudio(uuid: '1', title: 'Airbag', artist: 'Radiohead')
        ..addAudio(uuid: '2', title: 'Karma', artist: 'Radiohead');
      final container = buildContainer(gateway);
      final library = await container.read(musicLibraryProvider.future);

      await pumpRows(
        tester,
        container,
        MusicTrackList(entries: library.entries, numbered: false),
      );

      await tester.tap(find.text('Airbag'));
      await tester.pumpAndSettle();

      final state = container.read(audioPlaybackControllerProvider);
      expect(state.queue.kind, QueueKind.track);
      expect(state.queue.tracks, hasLength(1));
      expect(state.current?.uuid, '1');
    });
  });

  group('a track row inside an album (main flow step 3)', () {
    testWidgets(
      'GivenAnAlbumsTracks_WhenARowIsTapped_ThenTheAlbumPlaysFromThere',
      (tester) async {
        final gateway = FakeCatalogGateway()
          ..addAudio(
            uuid: 'a1',
            title: 'One',
            artist: 'Artist',
            album: 'Album',
            track: 1,
          )
          ..addAudio(
            uuid: 'a2',
            title: 'Two',
            artist: 'Artist',
            album: 'Album',
            track: 2,
          );
        final container = buildContainer(gateway);
        final library = await container.read(musicLibraryProvider.future);

        await pumpRows(
          tester,
          container,
          MusicTrackList(entries: library.entries, numbered: true),
        );

        // The second track, not the first: this is what proves the album
        // starts from the row that was tapped rather than always from the
        // top.
        await tester.tap(find.text('Two'));
        await tester.pumpAndSettle();

        final state = container.read(audioPlaybackControllerProvider);
        expect(state.queue.kind, QueueKind.album);
        expect(state.queue.tracks.map((file) => file.uuid), ['a1', 'a2']);
        expect(state.current?.uuid, 'a2');
      },
    );
  });

  group('an artist or album row (main flow step 2)', () {
    testWidgets(
      'GivenAnArtistRow_WhenItIsTapped_ThenNothingStartsPlaying',
      (tester) async {
        final gateway = FakeCatalogGateway()
          ..addAudio(uuid: '1', title: 'Airbag', artist: 'Radiohead');
        final container = buildContainer(gateway);
        final library = await container.read(musicLibraryProvider.future);

        await pumpRows(
          tester,
          container,
          MusicGroupList(
            groups: artistsIn(library.entries),
            kind: MusicGroupKind.artist,
          ),
        );

        await tester.tap(find.text('Radiohead'));
        await tester.pumpAndSettle();

        // A tap here drills into the artist's albums (`music_browse.dart`),
        // which is what the row's own controller reflects; playback itself
        // must stay untouched — that action lives on the row's context menu,
        // not on a tap a misaimed click could trigger.
        final state = container.read(audioPlaybackControllerProvider);
        expect(state.isActive, isFalse);
        expect(
          container.read(musicBrowseControllerProvider).artist,
          'Radiohead',
        );
      },
    );

    testWidgets(
      'GivenAnAlbumRow_WhenItIsTapped_ThenNothingStartsPlaying',
      (tester) async {
        final gateway = FakeCatalogGateway()
          ..addAudio(
            uuid: '1',
            title: 'Airbag',
            artist: 'Radiohead',
            album: 'OK Computer',
          );
        final container = buildContainer(gateway);
        final library = await container.read(musicLibraryProvider.future);

        await pumpRows(
          tester,
          container,
          MusicGroupList(
            groups: albumsIn(library.entries),
            kind: MusicGroupKind.album,
          ),
        );

        await tester.tap(find.text('OK Computer'));
        await tester.pumpAndSettle();

        final state = container.read(audioPlaybackControllerProvider);
        expect(state.isActive, isFalse);
        expect(
          container.read(musicBrowseControllerProvider).album,
          'OK Computer',
        );
      },
    );

    testWidgets(
      'GivenAnAlbumRow_WhenShown_ThenItsSubtitleNamesTheArtist',
      (tester) async {
        final gateway = FakeCatalogGateway()
          ..addAudio(
            uuid: '1',
            title: 'Airbag',
            artist: 'Radiohead',
            album: 'OK Computer',
          );
        final container = buildContainer(gateway);
        final library = await container.read(musicLibraryProvider.future);

        await pumpRows(
          tester,
          container,
          MusicGroupList(
            groups: albumsIn(library.entries),
            kind: MusicGroupKind.album,
          ),
        );

        expect(find.text('OK Computer'), findsOneWidget);
        expect(find.text('Radiohead'), findsOneWidget);
      },
    );
  });
}
