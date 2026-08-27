import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/playback/domain/music_browse.dart';
import 'package:alexandria_ui/features/playback/domain/playback_queue.dart';
import 'package:alexandria_ui/features/playback/presentation/music_display_name.dart';
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

  group('a track row and the album artist (UC-46)', () {
    testWidgets(
      'GivenATrackWithAnAlbumArtist_WhenTheSongsRowIsShown_ThenItNamesThePerformer',
      (tester) async {
        // Who made the record and who played the track are two different
        // facts. The rows are gathered by the first and still say the second:
        // a guest appearance shows the guest, which is the point of having
        // both tags.
        final gateway = FakeCatalogGateway()
          ..addAudio(
            uuid: 'c1',
            title: 'One',
            artist: 'First Performer',
            albumArtist: 'Various Artists',
            album: "Now That's Music",
          );
        final container = buildContainer(gateway);
        final library = await container.read(musicLibraryProvider.future);

        await pumpRows(
          tester,
          container,
          MusicTrackList(entries: library.entries, numbered: false),
        );

        expect(find.text('First Performer'), findsOneWidget);
        expect(find.text('Various Artists'), findsNothing);
      },
    );

    testWidgets(
      'GivenACompilationsTracks_WhenTheAlbumIsListed_ThenEachRowNamesItsPerformer',
      (tester) async {
        // The view this feature exists for: a compilation is one album now,
        // so the album's own list is the only place its twelve performers
        // can be read. A row that named nobody would have hidden them.
        final gateway = FakeCatalogGateway()
          ..addAudio(
            uuid: 'c1',
            title: 'One',
            artist: 'First Performer',
            albumArtist: 'Various Artists',
            album: "Now That's Music",
            track: 1,
          )
          ..addAudio(
            uuid: 'c2',
            title: 'Two',
            artist: 'Second Performer',
            albumArtist: 'Various Artists',
            album: "Now That's Music",
            track: 2,
          );
        final container = buildContainer(gateway);
        final library = await container.read(musicLibraryProvider.future);

        await pumpRows(
          tester,
          container,
          MusicTrackList(entries: library.entries, numbered: true),
        );

        expect(find.text('First Performer'), findsOneWidget);
        expect(find.text('Second Performer'), findsOneWidget);
      },
    );

    testWidgets(
      'GivenAnOrdinaryAlbum_WhenItIsListed_ThenNoRowRepeatsTheAlbumArtist',
      (tester) async {
        // The same name under all twelve rows of a single-artist record is
        // noise, not information: the record already says whose it is.
        final gateway = FakeCatalogGateway()
          ..addAudio(
            uuid: 'a1',
            title: 'Airbag',
            artist: 'Radiohead',
            albumArtist: 'Radiohead',
            album: 'OK Computer',
            track: 1,
          )
          ..addAudio(
            uuid: 'a2',
            title: 'Karma Police',
            artist: 'Radiohead',
            albumArtist: 'Radiohead',
            album: 'OK Computer',
            track: 2,
          );
        final container = buildContainer(gateway);
        final library = await container.read(musicLibraryProvider.future);

        await pumpRows(
          tester,
          container,
          MusicTrackList(entries: library.entries, numbered: true),
        );

        expect(find.text('Radiohead'), findsNothing);
      },
    );

    testWidgets(
      'GivenATrackWithNoPerformer_WhenTheAlbumIsListed_ThenNoUnknownIsShown',
      (tester) async {
        // The record's artist is known, so a row with no performer tag has
        // nothing to add — and "Unknown artist" under a record whose artist
        // is named would be a contradiction rather than a fact.
        final gateway = FakeCatalogGateway()
          ..addAudio(
            uuid: 'c1',
            title: 'One',
            artist: 'First Performer',
            albumArtist: 'Various Artists',
            album: "Now That's Music",
            track: 1,
          )
          ..addAudio(
            uuid: 'c2',
            title: 'Two',
            albumArtist: 'Various Artists',
            album: "Now That's Music",
            track: 2,
          );
        final container = buildContainer(gateway);
        final library = await container.read(musicLibraryProvider.future);

        await pumpRows(
          tester,
          container,
          MusicTrackList(entries: library.entries, numbered: true),
        );

        final l10n = AppLocalizations.of(
          tester.element(find.byType(MusicTrackList)),
        );
        expect(find.text('First Performer'), findsOneWidget);
        expect(find.text(l10n.musicUnknownArtist), findsNothing);
      },
    );

    testWidgets(
      'GivenACompilation_WhenATrackRowIsTapped_ThenTheWholeRecordIsQueued',
      (tester) async {
        // Every track the album listed, including the ones another performer
        // played: the queue has to contain what the group showed.
        final gateway = FakeCatalogGateway()
          ..addAudio(
            uuid: 'c1',
            title: 'One',
            artist: 'First Performer',
            albumArtist: 'Various Artists',
            album: "Now That's Music",
            track: 1,
          )
          ..addAudio(
            uuid: 'c2',
            title: 'Two',
            artist: 'Second Performer',
            albumArtist: 'Various Artists',
            album: "Now That's Music",
            track: 2,
          );
        final container = buildContainer(gateway);
        final library = await container.read(musicLibraryProvider.future);

        await pumpRows(
          tester,
          container,
          MusicTrackList(entries: library.entries, numbered: true),
        );

        await tester.tap(find.text('Two'));
        await tester.pumpAndSettle();

        final state = container.read(audioPlaybackControllerProvider);
        expect(state.queue.kind, QueueKind.album);
        expect(state.queue.tracks.map((file) => file.uuid), ['c1', 'c2']);
      },
    );

    testWidgets(
      'GivenACompilation_WhenTheAlbumRowIsShown_ThenItNamesTheAlbumArtist',
      (tester) async {
        // The album row's subtitle is whose record it is — and it is also
        // what the row drills in with, so a compilation opens on the whole
        // record rather than on one performer's track.
        final gateway = FakeCatalogGateway()
          ..addAudio(
            uuid: 'c1',
            title: 'One',
            artist: 'First Performer',
            albumArtist: 'Various Artists',
            album: "Now That's Music",
            track: 1,
          )
          ..addAudio(
            uuid: 'c2',
            title: 'Two',
            artist: 'Second Performer',
            albumArtist: 'Various Artists',
            album: "Now That's Music",
            track: 2,
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

        expect(find.text("Now That's Music"), findsOneWidget);
        expect(find.text('Various Artists'), findsOneWidget);

        await tester.tap(find.text("Now That's Music"));
        await tester.pumpAndSettle();

        expect(
          container.read(musicBrowseControllerProvider).artist,
          'Various Artists',
        );
      },
    );
  });

  group('an artist or album row (main flow step 2)', () {
    testWidgets('GivenAnArtistRow_WhenItIsTapped_ThenNothingStartsPlaying', (
      tester,
    ) async {
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
      expect(container.read(musicBrowseControllerProvider).artist, 'Radiohead');
    });

    testWidgets('GivenAnAlbumRow_WhenItIsTapped_ThenNothingStartsPlaying', (
      tester,
    ) async {
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
    });

    testWidgets('GivenAnAlbumRow_WhenShown_ThenItsSubtitleNamesTheArtist', (
      tester,
    ) async {
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
    });
  });
}
