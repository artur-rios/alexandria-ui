import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/playback/application/audio_playback_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_media_player.dart';
import '../../../support/fake_playback.dart';

/// Building a queue for an album or an artist (UC-20 main flow steps 1 and
/// 3), and what happens when the library it is built from cannot be read.
void main() {
  /// A container with a session and every playback dependency faked, so
  /// [AudioPlaybackController] runs for real over [gateway].
  ///
  /// Retries disabled: Riverpod retries a failed provider automatically
  /// (exponential backoff, up to ten attempts, ~35 seconds) before it
  /// settles into `AsyncError`, which a plain `test()` waits out in real
  /// time. This asserts the settled state without that wait.
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

  test(
    'GivenTheListingFails_WhenAnAlbumIsPlayed_ThenNothingIsPlayable',
    () async {
      // MusicLibraryController now throws a failed listing rather than
      // resolving to an empty library (UC-46's fix for a failure that used
      // to read as "no audio files"). `_playGrouped` awaits exactly that
      // future to build the queue — this is what an owner sees instead of
      // the queue sitting in AudioStage.starting forever.
      final file = aFile(uuid: 'blue-1', name: 'So What.flac');
      final gateway = FakeCatalogGateway()..failListing();
      final container = buildContainer(gateway);

      await container
          .read(audioPlaybackControllerProvider.notifier)
          .playAlbum(file);

      final state = container.read(audioPlaybackControllerProvider);
      expect(state.stage, AudioStage.allFailed);
      expect(state.queue.tracks, isEmpty);
      expect(state.lastSkipped?.uuid, file.uuid);
      expect(state.lastSkipReason, isA<Failure>());
    },
  );

  test(
    'GivenTheListingFails_WhenAnArtistIsPlayed_ThenNothingIsPlayable',
    () async {
      final file = aFile(uuid: 'blue-1', name: 'So What.flac');
      final gateway = FakeCatalogGateway()..failListing();
      final container = buildContainer(gateway);

      await container
          .read(audioPlaybackControllerProvider.notifier)
          .playArtist(file);

      final state = container.read(audioPlaybackControllerProvider);
      expect(state.stage, AudioStage.allFailed);
      expect(state.queue.tracks, isEmpty);
    },
  );
}
