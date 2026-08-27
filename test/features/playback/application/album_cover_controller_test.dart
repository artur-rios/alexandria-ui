import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/playback/domain/album_cover.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_media_player.dart';
import '../../../support/fake_playback.dart';

/// What the current album's case sleeve shows (design section 4, UC-21,
/// FR-PL-07): the album's own embedded picture, or the designed jacket —
/// and the two of them never flicker into each other mid-insertion.
void main() {
  /// Built the same way `album_animation_controller_test.dart` builds one:
  /// a session and every playback dependency faked, so
  /// [AlbumCoverController] runs for real over [gateway].
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

  /// Flushes [AlbumCoverController]'s `build` against whatever the queue
  /// currently is, then gives any fetch that starts room to finish.
  ///
  /// A `NotifierProvider` with no active listener is lazy: it does not
  /// rebuild on its own the moment `audioPlaybackControllerProvider`
  /// changes, only the next time something reads it — exactly what a real
  /// host (`NowPlayingScreen`, watching continuously) never leaves it
  /// waiting for, but a test that only ever calls `container.read` has to
  /// do explicitly, and *before* waiting for the async work that read
  /// starts, not after.
  Future<void> settle(ProviderContainer container) async {
    container.read(albumCoverControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  /// A library of one album ("Kind of Blue", two tracks) and a second album
  /// ("Blue Train", one track) by a different artist, so a test can move
  /// between records without building its own fixtures.
  FakeCatalogGateway libraryGateway() {
    final gateway = FakeCatalogGateway();
    gateway.addAudio(
      uuid: 'kob-1',
      title: 'So What',
      album: 'Kind of Blue',
      artist: 'Miles Davis',
      track: 1,
    );
    gateway.addAudio(
      uuid: 'kob-2',
      title: 'Freddie Freeloader',
      album: 'Kind of Blue',
      artist: 'Miles Davis',
      track: 2,
    );
    gateway.addAudio(
      uuid: 'bt-1',
      title: 'Blue Train',
      album: 'Blue Train',
      artist: 'John Coltrane',
    );
    return gateway;
  }

  /// A tiny, genuinely decodable picture — real PNG bytes, produced the same
  /// way a golden test's own fixture image is, rather than an arbitrary byte
  /// string `ui.instantiateImageCodec` would just as validly reject. What
  /// the core's `bytesBase64` decodes to for a file that carries a picture.
  Future<Uint8List> testPictureBytes() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 10, 10),
      ui.Paint()..color = const ui.Color(0xFFCC3355),
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

  test(
    'GivenAFileWithAnEmbeddedPicture_WhenItsAlbumPlays_ThenTheSleeveShowsTheFetchedCover',
    () async {
      final gateway = libraryGateway();
      final pictureBytes = await testPictureBytes();
      gateway.thumbnails['kob-1'] = FileThumbnailOutcome.read(
        bytes: pictureBytes,
      );
      final container = buildContainer(gateway);

      await container
          .read(audioPlaybackControllerProvider.notifier)
          .playAlbum(aFile(uuid: 'kob-1'));
      await settle(container);

      expect(
        container.read(albumCoverControllerProvider),
        isA<AlbumCoverFetched>(),
      );
    },
  );

  test(
    'GivenAFileWithNoEmbeddedPicture_WhenItsAlbumPlays_ThenTheSleeveShowsTheDesignedJacket',
    () async {
      // No entry in `gateway.thumbnails` for 'kob-1' — the fake's own
      // stand-in for the core answering `InvalidInput`, which is the
      // ordinary case a file with no picture produces.
      final gateway = libraryGateway();
      final container = buildContainer(gateway);

      await container
          .read(audioPlaybackControllerProvider.notifier)
          .playAlbum(aFile(uuid: 'kob-1'));
      await settle(container);

      expect(
        container.read(albumCoverControllerProvider),
        isA<AlbumCoverDesigned>(),
      );
    },
  );

  test(
    'GivenTheThumbnailCallFails_WhenItsAlbumPlays_ThenTheSleeveShowsTheDesignedJacket',
    () async {
      final gateway = libraryGateway();
      gateway.thumbnails['kob-1'] = const FileThumbnailOutcome.failed(
        failure: Failure.unexpected(family: CoreStatusFamily.playback, code: 9),
      );
      final container = buildContainer(gateway);

      await container
          .read(audioPlaybackControllerProvider.notifier)
          .playAlbum(aFile(uuid: 'kob-1'));
      await settle(container);

      expect(
        container.read(albumCoverControllerProvider),
        isA<AlbumCoverDesigned>(),
      );
    },
  );

  test(
    'GivenTheCoverHasNotArrivedYet_WhenTheAlbumStartsPlaying_ThenTheSleeveShowsTheDesignedJacketUntilItDoes',
    () async {
      final gateway = libraryGateway();
      final pictureBytes = await testPictureBytes();
      gateway.thumbnails['kob-1'] = FileThumbnailOutcome.read(
        bytes: pictureBytes,
      );
      gateway.holdThumbnail();
      final container = buildContainer(gateway);

      await container
          .read(audioPlaybackControllerProvider.notifier)
          .playAlbum(aFile(uuid: 'kob-1'));

      // Reading (not `settle`, which would also wait — the point here is
      // to catch the state *before* anything has had a chance to arrive)
      // is what starts the fetch and returns immediately, held open behind
      // the gate: the designed jacket is what shows while it is, not a
      // blank or a stall.
      expect(
        container.read(albumCoverControllerProvider),
        isA<AlbumCoverDesigned>(),
      );

      gateway.releaseThumbnail();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(
        container.read(albumCoverControllerProvider),
        isA<AlbumCoverFetched>(),
      );
    },
  );

  test(
    'GivenTheSameAlbumsNextTrackStarts_WhenItPlays_ThenTheGatewayIsNotAskedAgain',
    () async {
      // Design section 4: the cover is fetched once per album and held —
      // never refetched — for as long as the same record keeps playing.
      final gateway = libraryGateway();
      final pictureBytes = await testPictureBytes();
      gateway.thumbnails['kob-1'] = FileThumbnailOutcome.read(
        bytes: pictureBytes,
      );
      final container = buildContainer(gateway);
      final audio = container.read(audioPlaybackControllerProvider.notifier);

      await audio.playAlbum(aFile(uuid: 'kob-1'));
      await settle(container);
      expect(gateway.thumbnailsRequested, ['kob-1']);
      final firstCover = container.read(albumCoverControllerProvider);
      expect(firstCover, isA<AlbumCoverFetched>());

      await audio.next();
      await settle(container);

      expect(gateway.thumbnailsRequested, ['kob-1']);
      expect(container.read(albumCoverControllerProvider), same(firstCover));
    },
  );

  test(
    'GivenACoverIsShown_WhenADifferentAlbumStartsPlaying_ThenTheDesignedJacketShowsAgainImmediately',
    () async {
      final gateway = libraryGateway();
      final pictureBytes = await testPictureBytes();
      gateway.thumbnails['kob-1'] = FileThumbnailOutcome.read(
        bytes: pictureBytes,
      );
      final container = buildContainer(gateway);
      final audio = container.read(audioPlaybackControllerProvider.notifier);

      await audio.playAlbum(aFile(uuid: 'kob-1'));
      await settle(container);
      expect(
        container.read(albumCoverControllerProvider),
        isA<AlbumCoverFetched>(),
      );

      // "Blue Train" has no thumbnail fixture, so its own fetch (once it
      // starts) answers `InvalidInput` — but the assertion that matters
      // here is the state *right after* the album changes and the fetch is
      // read to start, before anything has had any chance to answer at
      // all: a stale cover from the record before it must not still be
      // showing.
      await audio.playAlbum(aFile(uuid: 'bt-1'));

      expect(
        container.read(albumCoverControllerProvider),
        isA<AlbumCoverDesigned>(),
      );
    },
  );

  test(
    'GivenAnAlbumChangesWhileItsFetchIsStillPending_WhenTheStaleFetchAnswers_ThenItsAnswerIsDiscarded',
    () async {
      // The generation guard `AlbumCoverController` uses to keep a cover
      // that arrives late from clobbering whatever the *current* album's
      // own fetch already decided — the one rule most likely to be missed
      // by an implementation that only ever compares identities on the way
      // in, not on the way an answer comes back.
      final gateway = libraryGateway();
      final pictureBytes = await testPictureBytes();
      gateway.thumbnails['kob-1'] = FileThumbnailOutcome.read(
        bytes: pictureBytes,
      );
      // 'bt-1' carries no fixture, so its own fetch answers `InvalidInput`
      // once it is allowed to run.
      gateway.holdThumbnail();
      final container = buildContainer(gateway);
      final audio = container.read(audioPlaybackControllerProvider.notifier);

      await audio.playAlbum(aFile(uuid: 'kob-1'));
      // Read once to start 'kob-1's fetch — held behind the gate.
      container.read(albumCoverControllerProvider);

      // A different album starts before 'kob-1' ever got an answer, and is
      // itself read to start its own fetch — also held behind the same
      // gate.
      await audio.playAlbum(aFile(uuid: 'bt-1'));
      container.read(albumCoverControllerProvider);

      gateway.releaseThumbnail();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // 'kob-1' answered a real picture and 'bt-1' answers none — if the
      // late 'kob-1' answer were not discarded, this would read as fetched
      // instead.
      expect(
        container.read(albumCoverControllerProvider),
        isA<AlbumCoverDesigned>(),
      );
    },
  );

  // Finding 2: `AlbumCoverController` and `AlbumAnimationController` share
  // `recordOf` so a track queue's identity cannot silently disagree between
  // them — before the fix, this controller's own `_identityOf` was still
  // per-uuid for a track queue, so playing a second track of the same album
  // from the Songs list read as a *different* record and refetched.
  group('a track queue (Finding 2)', () {
    test(
      'GivenATracksCoverIsShown_WhenAnotherTrackOfTheSameAlbumStartsFromTheSongsList_ThenTheGatewayIsNotAskedAgain',
      () async {
        final gateway = libraryGateway();
        final pictureBytes = await testPictureBytes();
        gateway.thumbnails['kob-1'] = FileThumbnailOutcome.read(
          bytes: pictureBytes,
        );
        final container = buildContainer(gateway);
        final audio = container.read(audioPlaybackControllerProvider.notifier);

        await audio.playTrack(aFile(uuid: 'kob-1'));
        // Unlike `playAlbum`, `playTrack` never reads the music library
        // itself (design §3) — awaited explicitly here so the identity this
        // controller resolves is the real one from the first build, not a
        // library-still-loading fallback that would itself change identity,
        // and so trigger a spurious refetch, the moment the library
        // resolves behind it. In the running application the Songs list a
        // track was tapped from cannot be showing without the library
        // already having loaded, so this is the realistic case.
        await container.read(musicLibraryProvider.future);
        await settle(container);
        expect(gateway.thumbnailsRequested, ['kob-1']);
        final firstCover = container.read(albumCoverControllerProvider);
        expect(firstCover, isA<AlbumCoverFetched>());

        // 'kob-2' is the same album's next track, played from the Songs
        // list rather than as a continuing album queue — `playTrack` builds
        // an independent single-track queue for it, uuid and all. The two
        // controllers agreeing that this is still "Kind of Blue" is what
        // this test actually checks: `kob-2` carries no thumbnail fixture of
        // its own, so a refetch here would answer `AlbumCoverDesigned`
        // instead of leaving the held cover alone.
        await audio.playTrack(aFile(uuid: 'kob-2'));
        await container.read(musicLibraryProvider.future);
        await settle(container);

        expect(gateway.thumbnailsRequested, ['kob-1']);
        expect(container.read(albumCoverControllerProvider), same(firstCover));
      },
    );

    test(
      'GivenATracksCoverIsShown_WhenATrackFromADifferentAlbumStartsFromTheSongsList_ThenTheDesignedJacketShowsAgain',
      () async {
        final gateway = libraryGateway();
        final pictureBytes = await testPictureBytes();
        gateway.thumbnails['kob-1'] = FileThumbnailOutcome.read(
          bytes: pictureBytes,
        );
        final container = buildContainer(gateway);
        final audio = container.read(audioPlaybackControllerProvider.notifier);

        await audio.playTrack(aFile(uuid: 'kob-1'));
        await container.read(musicLibraryProvider.future);
        await settle(container);
        expect(
          container.read(albumCoverControllerProvider),
          isA<AlbumCoverFetched>(),
        );

        // 'bt-1' has no thumbnail fixture, so its own fetch answers
        // `InvalidInput` once it runs — the assertion that matters is the
        // state right after the record changes, before anything answers.
        await audio.playTrack(aFile(uuid: 'bt-1'));

        expect(
          container.read(albumCoverControllerProvider),
          isA<AlbumCoverDesigned>(),
        );
      },
    );
  });

  group('across a session', () {
    test(
      'GivenACoverIsShown_WhenTheOwnerSignsOutAndBackIn_ThenTheSameAlbumsCoverIsFetchedAgain',
      () async {
        // `AlbumCoverController.forgetSession`'s own counterpart to Finding
        // 4: nothing about a held image belongs to a *later* session, so
        // signing out and back in and playing the very same album fetches
        // its cover again rather than finding this controller still
        // showing the previous session's image.
        final gateway = libraryGateway();
        final pictureBytes = await testPictureBytes();
        gateway.thumbnails['kob-1'] = FileThumbnailOutcome.read(
          bytes: pictureBytes,
        );
        final container = buildContainer(gateway);

        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playAlbum(aFile(uuid: 'kob-1'));
        await settle(container);
        expect(gateway.thumbnailsRequested, ['kob-1']);
        expect(
          container.read(albumCoverControllerProvider),
          isA<AlbumCoverFetched>(),
        );

        // `SessionController.end` itself does not wind activities down —
        // its own doc comment says the caller does that first, and
        // `SignOutController` is what a real sign-out uses for it. `establish`
        // runs every registered activity's `end()` the same way, which is
        // the reset this assertion is actually checking either way (see
        // `album_animation_controller_test.dart`'s identical choice, for the
        // same reason).
        container.read(sessionControllerProvider.notifier).end();
        container
            .read(sessionControllerProvider.notifier)
            .establish(FakeAuthGateway.defaultSession);
        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playAlbum(aFile(uuid: 'kob-1'));
        await settle(container);

        expect(gateway.thumbnailsRequested, ['kob-1', 'kob-1']);
        expect(
          container.read(albumCoverControllerProvider),
          isA<AlbumCoverFetched>(),
        );
      },
    );
  });
}
