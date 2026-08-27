import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/playback/application/audio_playback_controller.dart';
import 'package:alexandria_ui/features/playback/domain/playback_queue.dart';
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
      // Not "skipped": nothing was ever attempted, since the listing itself
      // failed before any track was resolved. lastSkipped names a track
      // _openAt actually tried and actually failed — claiming that of [file]
      // here would say something untrue, and the bar would show a second,
      // contradictory "Skipped" banner alongside "nothing playable".
      expect(state.lastSkipped, isNull);
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

  test(
    'GivenAGuestTrack_WhenTheArtistIsPlayed_ThenTheQueueIsTheAlbumArtists',
    () async {
      // The queue is gathered by the album artist (UC-46), so its label has
      // to name that artist too: labelled with the guest, the bar would
      // title the host's whole catalog after one track's guest, and the
      // animation — which reads the label as the record's identity — would
      // call it a different record.
      final gateway = FakeCatalogGateway()
        ..addAudio(
          uuid: 'host-1',
          title: 'Opener',
          artist: 'Host',
          albumArtist: 'Host',
          album: 'Record',
          track: 1,
        )
        ..addAudio(
          uuid: 'guest-1',
          title: 'The Feature',
          artist: 'Guest',
          albumArtist: 'Host',
          album: 'Record',
          track: 2,
        );
      final container = buildContainer(gateway);

      // Started from the guest's own track, which is where the two tags
      // disagree.
      await container
          .read(audioPlaybackControllerProvider.notifier)
          .playArtist(aFile(uuid: 'guest-1'));

      final state = container.read(audioPlaybackControllerProvider);
      expect(state.queue.kind, QueueKind.artist);
      expect(state.queue.label, 'Host');
      expect(state.queue.tracks.map((file) => file.uuid), [
        'host-1',
        'guest-1',
      ]);
    },
  );
}
