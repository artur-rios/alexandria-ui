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
    // No startup ever runs over this container, so it is honest about never
    // having a core to re-check against: `establish`'s own unawaited call to
    // `begin()` (FR-LB-21) would otherwise reach for one that was never
    // loaded, over a scenario this suite has nothing to do with.
    container
        .read(preferencesControllerProvider.notifier)
        .setRechecksAtStartup(false);
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);

    return container;
  }

  /// A library of one album ("Kind of Blue", two tracks, 1959 — a vinyl-era
  /// year) by one artist, and a second album ("Blue Train", 1957) by a
  /// different artist, so a test can move between records without building
  /// its own fixtures.
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
}
