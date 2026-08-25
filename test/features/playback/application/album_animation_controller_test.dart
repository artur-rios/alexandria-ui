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
      container.read(albumAnimationControllerProvider.notifier).insertionShown();

      await audio.next();

      final state = container.read(albumAnimationControllerProvider);
      expect(state.insertionOwed, isFalse);
    },
  );

  test('GivenARecordIsPlaying_WhenAnotherAlbumStarts_ThenAnInsertionIsOwed', (
  ) async {
    final gateway = libraryGateway();
    final container = buildContainer(gateway);
    final audio = container.read(audioPlaybackControllerProvider.notifier);

    await audio.playAlbum(aFile(uuid: 'kob-1'));
    container.read(albumAnimationControllerProvider.notifier).insertionShown();

    await audio.playAlbum(aFile(uuid: 'bt-1'));

    final state = container.read(albumAnimationControllerProvider);
    expect(state.insertionOwed, isTrue);
  });

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

  test('GivenAnInsertionWasShown_WhenItIsAcknowledged_ThenNoneIsOwed', () async {
    final gateway = libraryGateway();
    final container = buildContainer(gateway);

    await container
        .read(audioPlaybackControllerProvider.notifier)
        .playAlbum(aFile(uuid: 'kob-1'));
    expect(container.read(albumAnimationControllerProvider).insertionOwed, isTrue);

    container.read(albumAnimationControllerProvider.notifier).insertionShown();

    expect(
      container.read(albumAnimationControllerProvider).insertionOwed,
      isFalse,
    );
  });

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
}
