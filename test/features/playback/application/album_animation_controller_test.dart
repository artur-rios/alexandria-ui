import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_media_player.dart';
import '../../../support/fake_playback.dart';

/// Whether the medium has to be put in again (UC-21 main flow step 2).
void main() {
  /// A container with a session and every playback dependency faked, so
  /// [AlbumAnimationController] runs for real over [gateway] — built the same
  /// way `audio_playback_controller_test.dart` builds one, since this
  /// controller only ever answers questions about the queue that one drives.
  ProviderContainer buildContainer(FakeCatalogGateway gateway) {
    final container = ProviderContainer(
      retry: (_, _) => null,
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

  /// A library of one album ("Kind of Blue", three tracks, 1959 — a
  /// vinyl-era year) by one artist, and a second album ("Blue Train", 1957)
  /// by a different artist, so a test can move between records without
  /// building its own fixtures.
  FakeCatalogGateway libraryGateway() {
    final gateway = FakeCatalogGateway();
    gateway.addAudio(
      uuid: 'kob-1',
      title: 'So What',
      album: 'Kind of Blue',
      artist: 'Miles Davis',
      year: 1959,
      track: 1,
    );
    gateway.addAudio(
      uuid: 'kob-2',
      title: 'Freddie Freeloader',
      album: 'Kind of Blue',
      artist: 'Miles Davis',
      year: 1959,
      track: 2,
    );
    gateway.addAudio(
      uuid: 'kob-3',
      title: 'Blue in Green',
      album: 'Kind of Blue',
      artist: 'Miles Davis',
      year: 1959,
      track: 3,
    );
    gateway.addAudio(
      uuid: 'bt-1',
      title: 'Blue Train',
      album: 'Blue Train',
      artist: 'John Coltrane',
      year: 1957,
    );
    // Two loose, untagged files — no album tag on either — so a test can
    // play one "album of one" and then the other. `albumOf` groups an
    // untagged file with itself alone (`music_grouping.dart`), so these are
    // two different records despite sharing a null label.
    gateway.addAudio(uuid: 'loose-1', year: 2001);
    gateway.addAudio(uuid: 'loose-2', year: 2001);
    return gateway;
  }

  test(
    'GivenNothingHasPlayed_WhenTheFirstTrackStarts_ThenAnInsertionIsOwed',
    () async {
      // The session's first play, which is what the brainstorm asked always
      // shows the animation.
      final gateway = libraryGateway();
      final container = buildContainer(gateway);

      await container
          .read(audioPlaybackControllerProvider.notifier)
          .playAlbum(aFile(uuid: 'kob-1'));

      final state = container.read(albumAnimationControllerProvider);
      expect(state.insertionOwed, isTrue);
      expect(state.medium, isNotNull);
    },
  );

  test(
    'GivenARecordIsPlaying_WhenTheNextTrackOfItStarts_ThenNoInsertionIsOwed',
    () async {
      // A record already on the platter is not taken off and put back for its
      // next track.
      final gateway = libraryGateway();
      final container = buildContainer(gateway);
      final audio = container.read(audioPlaybackControllerProvider.notifier);

      await audio.playAlbum(aFile(uuid: 'kob-1'));
      container
          .read(albumAnimationControllerProvider.notifier)
          .insertionShown();

      await audio.next();

      final state = container.read(albumAnimationControllerProvider);
      expect(state.insertionOwed, isFalse);
    },
  );

  test(
    'GivenARecordIsPlaying_WhenAnotherAlbumStarts_ThenAnInsertionIsOwed',
    () async {
      final gateway = libraryGateway();
      final container = buildContainer(gateway);
      final audio = container.read(audioPlaybackControllerProvider.notifier);

      await audio.playAlbum(aFile(uuid: 'kob-1'));
      container
          .read(albumAnimationControllerProvider.notifier)
          .insertionShown();

      await audio.playAlbum(aFile(uuid: 'bt-1'));

      final state = container.read(albumAnimationControllerProvider);
      expect(state.insertionOwed, isTrue);
    },
  );

  test(
    'GivenAnUntaggedAlbumIsPlaying_WhenADifferentUntaggedAlbumStarts_ThenAnInsertionIsOwed',
    () async {
      // Both untagged albums have a null label, so `(kind, label)` alone
      // would call them the same record — exactly what `albumOf`
      // (`music_grouping.dart`) already refuses to do: "two untitled files
      // are not the same record". The identity has to fall back to
      // something that tells them apart, such as the first track's uuid.
      final gateway = libraryGateway();
      final container = buildContainer(gateway);
      final audio = container.read(audioPlaybackControllerProvider.notifier);

      await audio.playAlbum(aFile(uuid: 'loose-1'));
      container
          .read(albumAnimationControllerProvider.notifier)
          .insertionShown();

      await audio.playAlbum(aFile(uuid: 'loose-2'));

      final state = container.read(albumAnimationControllerProvider);
      expect(state.insertionOwed, isTrue);
    },
  );

  test(
    'GivenAnArtistIsPlaying_WhenAnotherArtistStarts_ThenAnInsertionIsOwed',
    () async {
      final gateway = libraryGateway();
      final container = buildContainer(gateway);
      final audio = container.read(audioPlaybackControllerProvider.notifier);

      await audio.playArtist(aFile(uuid: 'kob-1'));
      container
          .read(albumAnimationControllerProvider.notifier)
          .insertionShown();

      await audio.playArtist(aFile(uuid: 'bt-1'));

      final state = container.read(albumAnimationControllerProvider);
      expect(state.insertionOwed, isTrue);
    },
  );

  test(
    'GivenAnInsertionWasShown_WhenItIsAcknowledged_ThenNoneIsOwed',
    () async {
      final gateway = libraryGateway();
      final container = buildContainer(gateway);

      await container
          .read(audioPlaybackControllerProvider.notifier)
          .playAlbum(aFile(uuid: 'kob-1'));
      expect(
        container.read(albumAnimationControllerProvider).insertionOwed,
        isTrue,
      );

      container
          .read(albumAnimationControllerProvider.notifier)
          .insertionShown();

      expect(
        container.read(albumAnimationControllerProvider).insertionOwed,
        isFalse,
      );
    },
  );

  test(
    'GivenTheModeIsOff_WhenAnythingPlays_ThenThereIsNoMediumAndNothingIsOwed',
    () async {
      final gateway = libraryGateway();
      final container = buildContainer(gateway);

      await container
          .read(preferencesControllerProvider.notifier)
          .setAlbumAnimation(AlbumAnimationMode.off);

      await container
          .read(audioPlaybackControllerProvider.notifier)
          .playAlbum(aFile(uuid: 'kob-1'));

      final state = container.read(albumAnimationControllerProvider);
      expect(state.medium, isNull);
      expect(state.insertionOwed, isFalse);
    },
  );

  test(
    'GivenAPinnedMode_WhenAnAlbumOfAnotherEraPlays_ThenTheMediumIsThePinnedOne',
    () async {
      // "Kind of Blue" is a 1959, vinyl-era record — pinning the animation to
      // a cassette must still show a cassette, proving the pin overrides the
      // year rather than merely narrowing it.
      final gateway = libraryGateway();
      final container = buildContainer(gateway);

      await container
          .read(preferencesControllerProvider.notifier)
          .setAlbumAnimation(AlbumAnimationMode.tape);

      await container
          .read(audioPlaybackControllerProvider.notifier)
          .playAlbum(aFile(uuid: 'kob-1'));

      final state = container.read(albumAnimationControllerProvider);
      expect(state.medium, AlbumMedium.tape);
    },
  );

  // A track is a record too (design §1, §2, §3): when the queue names no
  // record of its own, the identity and the medium resolve from the current
  // track's own metadata instead.
  group('a track queue', () {
    test(
      'GivenNothingHasPlayed_WhenALoneTrackStarts_ThenAnInsertionIsOwedAndThereIsAMedium',
      () async {
        // The owner's own report: playing a single track from the Songs
        // list showed no animation. `showsAlbumAnimation` no longer excludes
        // a track queue, so its first play owes an insertion exactly as an
        // album's or an artist's does.
        final gateway = libraryGateway();
        final container = buildContainer(gateway);

        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playTrack(aFile(uuid: 'kob-1'));

        final state = container.read(albumAnimationControllerProvider);
        expect(state.insertionOwed, isTrue);
        expect(state.medium, isNotNull);
      },
    );

    test(
      'GivenATrackOfAnAlbumIsPlaying_WhenTwoMoreTracksOfTheSameAlbumStartFromTheSongsList_ThenNoInsertionIsOwed',
      () async {
        // Three tracks of one album, played one after another from the
        // Songs list rather than as an album queue, insert once: the
        // identity is the record — the track's own album and artist — not
        // the queue's uuid-per-track identity `playTrack` builds. Three
        // rather than two, matching the design's own testing list exactly.
        final gateway = libraryGateway();
        final container = buildContainer(gateway);
        final audio = container.read(audioPlaybackControllerProvider.notifier);

        await audio.playTrack(aFile(uuid: 'kob-1'));
        await container.read(musicLibraryProvider.future);
        container
            .read(albumAnimationControllerProvider.notifier)
            .insertionShown();

        await audio.playTrack(aFile(uuid: 'kob-2'));
        await container.read(musicLibraryProvider.future);
        expect(
          container.read(albumAnimationControllerProvider).insertionOwed,
          isFalse,
        );

        await audio.playTrack(aFile(uuid: 'kob-3'));
        await container.read(musicLibraryProvider.future);

        final state = container.read(albumAnimationControllerProvider);
        expect(state.insertionOwed, isFalse);
      },
    );

    test(
      'GivenATrackIsPlaying_WhenATrackFromADifferentAlbumStartsFromTheSongsList_ThenAnInsertionIsOwed',
      () async {
        final gateway = libraryGateway();
        final container = buildContainer(gateway);
        final audio = container.read(audioPlaybackControllerProvider.notifier);

        await audio.playTrack(aFile(uuid: 'kob-1'));
        await container.read(musicLibraryProvider.future);
        container
            .read(albumAnimationControllerProvider.notifier)
            .insertionShown();

        await audio.playTrack(aFile(uuid: 'bt-1'));
        await container.read(musicLibraryProvider.future);

        final state = container.read(albumAnimationControllerProvider);
        expect(state.insertionOwed, isTrue);
      },
    );

    test(
      'GivenAnUntaggedTrackIsPlaying_WhenADifferentUntaggedTrackStartsFromTheSongsList_ThenAnInsertionIsOwed',
      () async {
        // Neither `loose-1` nor `loose-2` carries an album tag, so the
        // identity falls back to each track's own uuid — the same untagged
        // rule `albumOf` (`music_grouping.dart`) already states — and two
        // different untagged tracks are still two different records.
        final gateway = libraryGateway();
        final container = buildContainer(gateway);
        final audio = container.read(audioPlaybackControllerProvider.notifier);

        await audio.playTrack(aFile(uuid: 'loose-1'));
        await container.read(musicLibraryProvider.future);
        container
            .read(albumAnimationControllerProvider.notifier)
            .insertionShown();

        await audio.playTrack(aFile(uuid: 'loose-2'));
        await container.read(musicLibraryProvider.future);

        final state = container.read(albumAnimationControllerProvider);
        expect(state.insertionOwed, isTrue);
      },
    );

    test(
      'GivenATrackHasItsOwnYear_WhenItStartsFromTheSongsList_ThenItsOwnYearPicksTheMedium',
      () async {
        // `playTrack` builds a queue with no year of its own (`queue.year`
        // is `null`), which `mediumFor` would otherwise answer a compact
        // disc for regardless of era. "Kind of Blue" is a 1959, vinyl-era
        // record, so a disc here would mean the track's own year was never
        // consulted.
        final gateway = libraryGateway();
        final container = buildContainer(gateway);

        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playTrack(aFile(uuid: 'kob-1'));
        await container.read(musicLibraryProvider.future);

        final state = container.read(albumAnimationControllerProvider);
        expect(state.medium, AlbumMedium.vinyl);
      },
    );

    test(
      'GivenTheLibraryHasNotLoaded_WhenALoneTrackStartsFromTheSongsList_ThenTheAnimationStillShowsWithTheFallbackMedium',
      () async {
        // `playTrack` is deliberately left alone: it never reads the music
        // library at all, which is what keeps a track playable when the
        // library listing has failed (design §3). Nothing here awaits
        // `musicLibraryProvider`, so the controller reads it still loading —
        // the animation still shows, with a compact disc rather than an
        // error, a reasonable picture of an unknown record.
        final gateway = libraryGateway();
        final container = buildContainer(gateway);

        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playTrack(aFile(uuid: 'kob-1'));

        final state = container.read(albumAnimationControllerProvider);
        expect(state.insertionOwed, isTrue);
        expect(state.medium, AlbumMedium.disc);
      },
    );

    test(
      'GivenTheLibraryDoesNotHoldTheTrack_WhenItStartsFromTheSongsList_ThenTheAnimationStillShowsWithTheFallbackMedium',
      () async {
        // A file the catalog gateway never listed at all — unlike the
        // previous test, the library here is fully loaded, and simply has
        // nothing for this uuid. The same fallback applies either way.
        final gateway = libraryGateway();
        final container = buildContainer(gateway);

        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playTrack(aFile(uuid: 'not-catalogued'));
        await container.read(musicLibraryProvider.future);

        final state = container.read(albumAnimationControllerProvider);
        expect(state.insertionOwed, isTrue);
        expect(state.medium, AlbumMedium.disc);
      },
    );
  });

  group('across a session (Finding 4)', () {
    test(
      'GivenAnInsertionWasShown_WhenTheOwnerSignsOutAndBackIn_ThenTheSameAlbumOwesOneAgain',
      () async {
        // The doc comment on `_shownFor` claimed it reset "whenever the
        // provider itself is invalidated ... which is what a new session
        // is" — but nothing invalidated it. Signing out and back in and
        // playing the very same album must owe an insertion the same way the
        // session's first play did, not find `_shownFor` still remembering
        // it from before.
        final gateway = libraryGateway();
        final container = buildContainer(gateway);

        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playAlbum(aFile(uuid: 'kob-1'));
        container
            .read(albumAnimationControllerProvider.notifier)
            .insertionShown();
        expect(
          container.read(albumAnimationControllerProvider).insertionOwed,
          isFalse,
        );

        // `SessionController.end`/`.establish` directly, rather than
        // `signOutControllerProvider`: `SignOutController` also asks every
        // activity whether an index run continues in the core, which pulls
        // in library-sources dependencies this file's fakes do not set up —
        // orthogonal to what this test is about. `establish` runs every
        // registered activity's `end()` the same way sign-out does (see its
        // own doc comment), which is the half of the reset this test is
        // checking either way: a fresh session's activities are wound down
        // the same way an ended one's are.
        container.read(sessionControllerProvider.notifier).end();
        container
            .read(sessionControllerProvider.notifier)
            .establish(FakeAuthGateway.defaultSession);

        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playAlbum(aFile(uuid: 'kob-1'));

        expect(
          container.read(albumAnimationControllerProvider).insertionOwed,
          isTrue,
        );
      },
    );
  });

  test(
    'GivenACompilationTrackIsPlaying_WhenAnotherOfItsTracksStarts_ThenNoInsertionIsOwed',
    () async {
      // Two tracks of one compilation, played one after another from the
      // Songs list. Identified by the track's own performer they would be
      // two different records, and the case would come out and go back in
      // between two tracks of the same sleeve; identified by the album
      // artist — the same key the browsing area groups them under — they are
      // the one record they are.
      final gateway = FakeCatalogGateway()
        ..addAudio(
          uuid: 'comp-1',
          title: 'One',
          artist: 'First Performer',
          albumArtist: 'Various Artists',
          album: "Now That's Music",
          year: 1959,
          track: 1,
        )
        ..addAudio(
          uuid: 'comp-2',
          title: 'Two',
          artist: 'Second Performer',
          albumArtist: 'Various Artists',
          album: "Now That's Music",
          year: 1959,
          track: 2,
        );
      final container = buildContainer(gateway);
      final audio = container.read(audioPlaybackControllerProvider.notifier);

      await audio.playTrack(aFile(uuid: 'comp-1'));
      await container.read(musicLibraryProvider.future);
      final first = container.read(albumAnimationControllerProvider);
      expect(first.insertionOwed, isTrue);
      container
          .read(albumAnimationControllerProvider.notifier)
          .insertionShown();

      await audio.playTrack(aFile(uuid: 'comp-2'));
      await container.read(musicLibraryProvider.future);

      final state = container.read(albumAnimationControllerProvider);
      expect(state.insertionOwed, isFalse);
      expect(state.owedIdentity, isNull);
    },
  );

  test(
    'GivenAPlaylistIsPlaying_WhenTheNextTrackIsTheSameAlbum_ThenNoInsertionIsOwed',
    () async {
      // Design section 6: a playlist queue names no record of its own, so the
      // record is resolved from the track playing now — and two tracks of one
      // album are one record inside a playlist exactly as they are inside an
      // album queue. Were the identity read off the queue instead, it would
      // be one constant value for the whole playlist and this would pass for
      // the wrong reason — which is why the crossing test below is its pair.
      final gateway = libraryGateway();
      final container = buildContainer(gateway);
      final audio = container.read(audioPlaybackControllerProvider.notifier);

      await audio.playPlaylist(
        name: 'Road Trip',
        tracks: [aFile(uuid: 'kob-1'), aFile(uuid: 'kob-2')],
      );
      await container.read(musicLibraryProvider.future);
      container
          .read(albumAnimationControllerProvider.notifier)
          .insertionShown();

      await audio.next();
      await container.read(musicLibraryProvider.future);

      final state = container.read(albumAnimationControllerProvider);
      expect(state.insertionOwed, isFalse);
      expect(state.owedIdentity, isNull);
    },
  );

  test(
    'GivenAPlaylistIsPlaying_WhenTheNextTrackIsAnotherAlbum_ThenAnInsertionIsOwed',
    () async {
      // The other half of design section 6: crossing from one album to the
      // next inside a playlist puts the new record on. A queue-level identity
      // — the playlist's own name, or its first track's uuid — never changes
      // between these two tracks, so this is the case that fails unless
      // `recordOf` reads the current track.
      final gateway = libraryGateway();
      final container = buildContainer(gateway);
      final audio = container.read(audioPlaybackControllerProvider.notifier);

      await audio.playPlaylist(
        name: 'Road Trip',
        tracks: [aFile(uuid: 'kob-1'), aFile(uuid: 'bt-1')],
      );
      await container.read(musicLibraryProvider.future);
      container
          .read(albumAnimationControllerProvider.notifier)
          .insertionShown();

      await audio.next();
      await container.read(musicLibraryProvider.future);

      final state = container.read(albumAnimationControllerProvider);
      expect(state.insertionOwed, isTrue);
      expect(state.owedIdentity, isNotNull);
    },
  );

  test(
    'GivenAPlaylistOfOneAlbum_WhenItStartsMidRecord_ThenTheMediumIsTheCurrentTracksYear',
    () async {
      // The year picks the medium (UC-21, FR-PL-07), and a playlist carries
      // none of its own — so it is read off whichever track is playing, not
      // off a queue field that is always null here. Without that, every
      // playlist would show the medium an unknown year falls back to.
      final gateway = libraryGateway();
      final container = buildContainer(gateway);

      await container
          .read(audioPlaybackControllerProvider.notifier)
          .playPlaylist(name: 'Road Trip', tracks: [aFile(uuid: 'kob-1')]);
      await container.read(musicLibraryProvider.future);

      final state = container.read(albumAnimationControllerProvider);
      // 1959 is a vinyl-era year; an unknown one falls back to a disc.
      expect(state.medium, AlbumMedium.vinyl);
    },
  );
}
