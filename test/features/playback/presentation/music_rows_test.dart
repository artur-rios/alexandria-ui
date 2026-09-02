import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/view_layout.dart';
import 'package:alexandria_ui/features/enrichment/domain/track_enrichment.dart';
import 'package:alexandria_ui/features/playback/domain/music_browse.dart';
import 'package:alexandria_ui/features/playback/domain/playback_queue.dart';
import 'package:alexandria_ui/features/playback/presentation/music_display_name.dart';
import 'package:alexandria_ui/features/playback/presentation/music_rows.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist.dart';
import 'package:alexandria_ui/features/playlists/presentation/playlists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_enrichment_gateway.dart';
import '../../../support/fake_media_player.dart';
import '../../../support/fake_playback.dart';
import '../../../support/fake_playlist_gateway.dart';

/// The rows the music area lists artists, albums and tracks with (UC-46 main
/// flow step 2 and 3), and what a tap on one of them does.
///
/// Task 5 adds the context menu; what these rows already carry — text and a
/// tap — is the task's only new user action, so it is what this file tests.
void main() {
  /// A container with a session and every playback dependency faked, so
  /// [AudioPlaybackController] runs for real over [gateway] rather than being
  /// replaced itself — the point is that a tap reaches the real controller.
  ProviderContainer buildContainer(
    FakeCatalogGateway gateway, {
    FakePlaylistGateway? playlistGateway,
    FakeEnrichmentGateway? enrichmentGateway,
  }) {
    final container = ProviderContainer(
      overrides: [
        // The artist rows read what enrichment cached for each artist, so
        // every one of them is a call — faked here even when a case says
        // nothing about photographs, because the alternative is the real
        // core gateway.
        enrichmentGatewayProvider.overrideWithValue(
          enrichmentGateway ?? FakeEnrichmentGateway(),
        ),
        catalogGatewayProvider.overrideWithValue(gateway),
        audioPlayerProvider.overrideWithValue(FakeMediaPlayer()),
        playbackSourceGatewayProvider.overrideWithValue(
          FakePlaybackSourceGateway(),
        ),
        playbackPositionsProvider.overrideWithValue(
          FakePlaybackPositionStore(),
        ),
        if (playlistGateway != null)
          playlistGatewayProvider.overrideWithValue(playlistGateway),
        // Seeded, so "an order nobody chose" is still an order this test
        // knows: shuffling is the one behaviour here that would otherwise
        // have to be asserted as "probably not the original".
        shuffleRandomProvider.overrideWithValue(Random(7)),
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

  group('an artist row wears their face (music enrichment design)', () {
    /// A real file on disk, because a row shows a photograph by reading the
    /// bytes the core cached — there is no seam between this widget and the
    /// file system, and inventing one to avoid writing eight bytes would be
    /// testing a different application.
    String cachedPhotograph() {
      final directory = Directory.systemTemp.createTempSync('artist-image');
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File('${directory.path}/artist.png')
        ..writeAsBytesSync(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42m'
            'P8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
          ),
        );

      return file.path;
    }

    testWidgets(
      'GivenAPhotographWasCached_WhenTheArtistsAreListed_ThenTheRowShowsIt',
      (tester) async {
        // Where the photographs went. A lookup fetches the artist's picture
        // along with the words, and for one release it was shown over the
        // lyrics of whatever happened to be playing — the one place an owner
        // is not looking for artists. Here it is what the list is *of*.
        final path = cachedPhotograph();
        final gateway = FakeCatalogGateway()
          ..addAudio(uuid: '1', title: 'Airbag', artist: 'Radiohead');
        // Stored under the name the row shows, which is how the row asks for
        // it: a picture kept against whatever one file was tagged with is one
        // this list would never find.
        final container = buildContainer(
          gateway,
          enrichmentGateway: FakeEnrichmentGateway()
            ..artistImages['Radiohead'] = ArtistImage(
              artistName: 'Radiohead',
              path: path,
            ),
        );
        final library = await container.read(musicLibraryProvider.future);

        await pumpRows(
          tester,
          container,
          MusicGroupList(
            groups: artistsIn(library.entries),
            kind: MusicGroupKind.artist,
          ),
        );

        final image = tester.widget<Image>(find.byType(Image));
        expect((image.image as FileImage).file.path, path);
        expect(
          find.byIcon(Icons.person_outline),
          findsNothing,
          reason: 'the face replaces the stand-in, rather than joining it',
        );
      },
    );

    testWidgets(
      'GivenNothingWasCached_WhenTheArtistsAreListed_ThenTheRowKeepsTheIcon',
      (tester) async {
        // A library nobody has enriched looks exactly as it did before, and
        // listing artists never fetches anything by itself: a screenful of
        // rows would be dozens of requests a second against services that
        // allow one.
        final gateway = FakeCatalogGateway()
          ..addAudio(uuid: '1', title: 'Airbag', artist: 'Radiohead');
        final enrichment = FakeEnrichmentGateway();
        final container = buildContainer(
          gateway,
          enrichmentGateway: enrichment,
        );
        final library = await container.read(musicLibraryProvider.future);

        await pumpRows(
          tester,
          container,
          MusicGroupList(
            groups: artistsIn(library.entries),
            kind: MusicGroupKind.artist,
          ),
        );

        expect(find.byIcon(Icons.person_outline), findsOneWidget);
        expect(find.byType(Image), findsNothing);
        expect(enrichment.artistImageFetches, isEmpty);
      },
    );
  });

  /// A real PNG, painted here rather than pasted: a sleeve is only a sleeve
  /// once it decodes, and bytes that do not are the failing case rather than
  /// the passing one.
  ///
  /// Painted once in [setUpAll] rather than inside a case, because painting
  /// one goes through the engine: `toImage` and `toByteData` complete on real
  /// asynchrony, and a `testWidgets` body runs on a fake clock that never
  /// advances far enough to see them — the call simply never returns.
  late final Uint8List sleeve;

  Future<Uint8List> paintSleeve() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 10, 10),
      Paint()..color = const Color(0xFF102030),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(10, 10);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      return bytes!.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }
  }

  setUpAll(() async => sleeve = await paintSleeve());

  /// Lets the engine finish decoding a sleeve, then paints the result.
  ///
  /// Decoding is real asynchrony for the same reason painting one is, so a
  /// pump alone would only ever see the placeholder — this hands the fake
  /// clock back to the real one for long enough for the codec to answer.
  Future<void> settleArtwork(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }

  group('an album row wears its sleeve (UC-46)', () {
    testWidgets(
      'GivenATrackWithAnEmbeddedPicture_WhenTheAlbumsAreListed_ThenTheRowShowsIt',
      (tester) async {
        // The listing drew the same record glyph against every album ever
        // indexed, which says an album is an album and nothing about which
        // one. The sleeve is what an owner recognises across a room.
        final gateway = FakeCatalogGateway()
          ..addAudio(
            uuid: 'a1',
            title: 'One',
            artist: 'Artist',
            album: 'Album',
            track: 1,
          );
        gateway.thumbnails['a1'] = FileThumbnailOutcome.read(bytes: sleeve);
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
        await settleArtwork(tester);

        expect(find.byType(RawImage), findsOneWidget);
        expect(
          find.byIcon(Icons.album_outlined),
          findsNothing,
          reason: 'the sleeve replaces the stand-in rather than joining it',
        );
      },
    );

    testWidgets(
      'GivenNoEmbeddedPicture_WhenTheAlbumsAreListed_ThenTheRowKeepsTheGlyph',
      (tester) async {
        // Most of a real library, and not a failure worth wording: a record
        // whose files carry no picture reads exactly as it always did.
        final gateway = FakeCatalogGateway()
          ..addAudio(
            uuid: 'a1',
            title: 'One',
            artist: 'Artist',
            album: 'Album',
            track: 1,
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

        expect(find.byIcon(Icons.album_outlined), findsOneWidget);
        expect(find.byType(RawImage), findsNothing);
      },
    );
  });

  group('tiles (FR-CT-03)', () {
    /// Two records by one artist, each of two tracks.
    FakeCatalogGateway aShelf() => FakeCatalogGateway()
      ..addAudio(
        uuid: 'a1',
        title: 'One',
        artist: 'Artist',
        album: 'First',
        track: 1,
      )
      ..addAudio(
        uuid: 'a2',
        title: 'Two',
        artist: 'Artist',
        album: 'First',
        track: 2,
      )
      ..addAudio(
        uuid: 'b1',
        title: 'Three',
        artist: 'Artist',
        album: 'Second',
        track: 1,
      );

    testWidgets(
      'GivenTheGridLayout_WhenAlbumsAreShown_ThenEachRecordIsATileNamingIt',
      (tester) async {
        final container = buildContainer(aShelf());
        final library = await container.read(musicLibraryProvider.future);

        await pumpRows(
          tester,
          container,
          MusicGroupList(
            groups: albumsIn(library.entries),
            kind: MusicGroupKind.album,
            layout: ViewLayout.grid,
          ),
        );

        expect(find.byType(GridView), findsOneWidget);
        expect(find.byType(ListTile), findsNothing);
        expect(find.text('First'), findsOneWidget);
        expect(find.text('Second'), findsOneWidget);
      },
    );

    testWidgets('GivenAnAlbumTile_WhenItIsTapped_ThenTheRecordOpens', (
      tester,
    ) async {
      // The same drill-in the row does: choosing tiles changes how the area
      // looks, never what it does.
      final container = buildContainer(aShelf());
      final library = await container.read(musicLibraryProvider.future);

      await pumpRows(
        tester,
        container,
        MusicGroupList(
          groups: albumsIn(library.entries),
          kind: MusicGroupKind.album,
          layout: ViewLayout.grid,
        ),
      );

      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();

      expect(container.read(musicBrowseControllerProvider).album, 'Second');
    });

    testWidgets('GivenTheGridLayout_WhenSongsAreShown_ThenEachTrackIsATile', (
      tester,
    ) async {
      final container = buildContainer(aShelf());
      final library = await container.read(musicLibraryProvider.future);

      await pumpRows(
        tester,
        container,
        MusicTrackList(
          entries: library.entries,
          numbered: false,
          layout: ViewLayout.grid,
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);
    });
  });

  group('playing in an order nobody chose (FR-PL-06)', () {
    /// A record of four tracks, in order.
    FakeCatalogGateway aRecord() {
      final gateway = FakeCatalogGateway();
      for (final (index, title) in ['One', 'Two', 'Three', 'Four'].indexed) {
        gateway.addAudio(
          uuid: 'a${index + 1}',
          title: title,
          artist: 'Artist',
          album: 'Album',
          track: index + 1,
        );
      }

      return gateway;
    }

    testWidgets(
      'GivenAnAlbumRow_WhenItsShuffleIsPressed_ThenTheWholeRecordQueuesOutOfOrder',
      (tester) async {
        final container = buildContainer(aRecord());
        final library = await container.read(musicLibraryProvider.future);

        await pumpRows(
          tester,
          container,
          MusicGroupList(
            groups: albumsIn(library.entries),
            kind: MusicGroupKind.album,
          ),
        );

        await tester.tap(find.widgetWithIcon(IconButton, Icons.shuffle));
        await tester.pumpAndSettle();

        final state = container.read(audioPlaybackControllerProvider);
        expect(state.queue.kind, QueueKind.album);
        expect(
          [for (final file in state.queue.tracks) file.uuid],
          // Seeded, so the order is a fact rather than a coin toss: this is
          // the permutation `Random(7)` produces, and asserting it is what
          // makes a queue that quietly stayed in track order fail.
          ['a2', 'a4', 'a3', 'a1'],
        );
        expect(state.current?.uuid, 'a2');
      },
    );
  });

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

  // Task 5: adding to a playlist from the two entry points these rows carry —
  // one track's own context menu, and a whole album at once.
  group('adding to a playlist (Task 5)', () {
    const jazz = Playlist(uuid: 'p-1', name: 'Jazz');

    testWidgets(
      'GivenATracksMenu_WhenAddToPlaylistIsChosen_ThenThatOneFileUuidIsSent',
      (tester) async {
        final gateway = FakeCatalogGateway()
          ..addAudio(uuid: '1', title: 'Airbag', artist: 'Radiohead');
        final playlistGateway = FakePlaylistGateway(playlists: [jazz]);
        final container = buildContainer(
          gateway,
          playlistGateway: playlistGateway,
        );
        final library = await container.read(musicLibraryProvider.future);

        await pumpRows(
          tester,
          container,
          MusicTrackList(entries: library.entries, numbered: false),
        );

        // Opens the row's own context menu (the `more_vert` control), then
        // its "Add to a playlist" submenu.
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(MusicTrackList)),
        );
        await tester.tap(find.text(l10n.playlistAddTo));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Jazz'));
        await tester.pumpAndSettle();

        // Field-by-field, not a list-literal comparison: a record's `==`
        // compares a `List<String>` field by reference, so a fresh list
        // literal would never match regardless of its contents.
        expect(playlistGateway.entriesAdded, hasLength(1));
        expect(playlistGateway.entriesAdded.single.uuid, 'p-1');
        expect(playlistGateway.entriesAdded.single.fileUuids, ['1']);
      },
    );

    testWidgets(
      'GivenAnAlbumRow_WhenAddToPlaylistIsChosen_ThenEveryTrackIsSentInAlbumOrderInOneCall',
      (tester) async {
        final gateway = FakeCatalogGateway()
          ..addAudio(
            uuid: 'a2',
            title: 'Two',
            artist: 'Artist',
            album: 'Album',
            track: 2,
          )
          ..addAudio(
            uuid: 'a1',
            title: 'One',
            artist: 'Artist',
            album: 'Album',
            track: 1,
          );
        final playlistGateway = FakePlaylistGateway(playlists: [jazz]);
        final container = buildContainer(
          gateway,
          playlistGateway: playlistGateway,
        );
        final library = await container.read(musicLibraryProvider.future);

        await pumpRows(
          tester,
          container,
          MusicGroupList(
            groups: albumsIn(library.entries),
            kind: MusicGroupKind.album,
          ),
        );

        await tester.tap(find.byIcon(Icons.playlist_add));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Jazz'));
        await tester.pumpAndSettle();

        // One call for the whole album, in track order — not the order the
        // catalog happened to add the two files in.
        expect(playlistGateway.entriesAdded, hasLength(1));
        expect(playlistGateway.entriesAdded.single.uuid, 'p-1');
        expect(playlistGateway.entriesAdded.single.fileUuids, ['a1', 'a2']);
      },
    );

    testWidgets(
      'GivenAnArtistWithTwoAlbums_WhenAddToPlaylistIsChosen_ThenTracksComeInAlbumThenTrackOrder',
      (tester) async {
        // `artistsIn` groups an artist's row with `_inTrackOrder`, which
        // sorts by track number alone — no album key — so a naive read of
        // `group.entries` would interleave the two records track-for-track:
        // Dr. Jackle, So What, Freddie Freeloader, Sid's Ahead. The fix has
        // to re-sort album by album, matching what "Play artist" queues and
        // what drilling into the artist's own albums shows.
        final gateway = FakeCatalogGateway()
          ..addAudio(
            uuid: 'dj',
            title: 'Dr. Jackle',
            artist: 'Miles Davis',
            albumArtist: 'Miles Davis',
            album: 'Someday',
            track: 1,
          )
          ..addAudio(
            uuid: 'sa',
            title: "Sid's Ahead",
            artist: 'Miles Davis',
            albumArtist: 'Miles Davis',
            album: 'Someday',
            track: 2,
          )
          ..addAudio(
            uuid: 'sw',
            title: 'So What',
            artist: 'Miles Davis',
            albumArtist: 'Miles Davis',
            album: 'Kind of Blue',
            track: 1,
          )
          ..addAudio(
            uuid: 'ff',
            title: 'Freddie Freeloader',
            artist: 'Miles Davis',
            albumArtist: 'Miles Davis',
            album: 'Kind of Blue',
            track: 2,
          );
        final playlistGateway = FakePlaylistGateway(playlists: [jazz]);
        final container = buildContainer(
          gateway,
          playlistGateway: playlistGateway,
        );
        final library = await container.read(musicLibraryProvider.future);

        await pumpRows(
          tester,
          container,
          MusicGroupList(
            groups: artistsIn(library.entries),
            kind: MusicGroupKind.artist,
          ),
        );

        await tester.tap(find.byIcon(Icons.playlist_add));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Jazz'));
        await tester.pumpAndSettle();

        expect(playlistGateway.entriesAdded, hasLength(1));
        expect(playlistGateway.entriesAdded.single.uuid, 'p-1');
        expect(playlistGateway.entriesAdded.single.fileUuids, [
          'sw',
          'ff',
          'dj',
          'sa',
        ]);
      },
    );

    testWidgets(
      'GivenAnUntaggedArtistGroup_WhenAddToPlaylistIsChosen_ThenEveryTrackIsSentInOrder',
      (tester) async {
        // The untagged group is exactly where `artistOf`'s own null-artist
        // early return would bite if a future refactor reached for
        // `artistOf(group.entries.first, group.entries)` as a shortcut for
        // `inArtistOrder`: that early return answers just the *first* file
        // when its seed names no artist, so every other track in the group
        // would be silently dropped rather than sent. `inArtistOrder` never
        // seeds from a single entry, so it has no such early return — this
        // pins all four tracks reaching the core, not one, and (via two
        // distinct albums) that the order is a real sort rather than
        // whatever `group.entries` happened to hold.
        final gateway = FakeCatalogGateway()
          ..addAudio(uuid: 'b1', title: 'B One', album: 'Album B', track: 1)
          ..addAudio(uuid: 'b2', title: 'B Two', album: 'Album B', track: 2)
          ..addAudio(uuid: 'a1', title: 'A One', album: 'Album A', track: 1)
          ..addAudio(uuid: 'a2', title: 'A Two', album: 'Album A', track: 2);
        final playlistGateway = FakePlaylistGateway(playlists: [jazz]);
        final container = buildContainer(
          gateway,
          playlistGateway: playlistGateway,
        );
        final library = await container.read(musicLibraryProvider.future);

        await pumpRows(
          tester,
          container,
          MusicGroupList(
            groups: artistsIn(library.entries),
            kind: MusicGroupKind.artist,
          ),
        );

        await tester.tap(find.byIcon(Icons.playlist_add));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Jazz'));
        await tester.pumpAndSettle();

        expect(playlistGateway.entriesAdded, hasLength(1));
        expect(playlistGateway.entriesAdded.single.uuid, 'p-1');
        expect(playlistGateway.entriesAdded.single.fileUuids, [
          'a1',
          'a2',
          'b1',
          'b2',
        ]);
      },
    );

    testWidgets(
      'GivenNoPlaylistsYet_WhenTheTracksMenuIsOpened_ThenItOffersToCreateOneToo',
      (tester) async {
        // `AddToPlaylistButton`'s own empty-playlist branch is covered in
        // `add_to_playlist_button_test.dart`; `addToPlaylistMenu` is a
        // different widget family (a `SubmenuButton`, not a
        // `PopupMenuButton`) with its own, separately-built empty branch.
        final gateway = FakeCatalogGateway()
          ..addAudio(uuid: '1', title: 'Airbag', artist: 'Radiohead');
        final playlistGateway = FakePlaylistGateway(playlists: const []);
        final container = buildContainer(
          gateway,
          playlistGateway: playlistGateway,
        );
        final library = await container.read(musicLibraryProvider.future);

        await pumpRows(
          tester,
          container,
          MusicTrackList(entries: library.entries, numbered: false),
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(MusicTrackList)),
        );
        await tester.tap(find.text(l10n.playlistAddTo));
        await tester.pumpAndSettle();

        expect(find.text(l10n.playlistAddCreateOne), findsOneWidget);

        await tester.tap(find.text(l10n.playlistAddCreateOne));
        await tester.pumpAndSettle();

        expect(find.byType(PlaylistsScreen), findsOneWidget);
        expect(playlistGateway.entriesAdded, isEmpty);
      },
    );
  });
}
