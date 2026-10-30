import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/playback/application/playback_session_activity.dart';
import 'package:alexandria_ui/features/playback/application/video_playback_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_media_player.dart';
import '../../../support/fake_playback.dart';
import '../../../support/test_container.dart';

/// What playback does when a session ends (UC-03 main flow step 2).
void main() {
  final activityProvider = Provider((ref) => PlaybackSessionActivity(ref));

  test(
    'GivenAVideoPlaying_WhenTheSessionEnds_ThenOnlyTheActivePlayerIsStopped',
    () async {
      final video = FakePlaybackSession();
      final idle = FakePlaybackSession(isActive: false);
      final container = ProviderContainer(
        overrides: [
          playbackSessionsProvider.overrideWithValue([video, idle]),
        ],
      );
      addTearDown(container.dispose);

      await container.read(activityProvider).end();

      expect(video.stopCount, 1);
      expect(idle.stopCount, 0);
    },
  );

  // The test above and the sign-out tests fake both registries, so none of
  // them would notice a registration going missing — and sign-out would then
  // leave a video playing with nothing on screen. These read the registries
  // the application itself builds.
  group('the registries the application builds', () {
    test(
      'GivenTheRealProviders_WhenTheRegistriesAreRead_ThenPlaybackIsInBoth',
      () {
        final container = buildTestContainer();

        expect(
          container
              .read(sessionActivitiesProvider)
              .whereType<PlaybackSessionActivity>(),
          hasLength(1),
        );
        expect(
          container
              .read(playbackSessionsProvider)
              .whereType<VideoPlaybackSession>(),
          hasLength(1),
        );
      },
    );

    test(
      'GivenAVideoPlaying_WhenTheOwnerSignsOut_ThenThePlayerStops',
      () async {
        final player = FakeMediaPlayer();
        final container = buildTestContainer(
          overrides: [
            ...fakeCoreOverrides(),
            videoPlayerProvider.overrideWithValue(player),
            playbackSourceGatewayProvider.overrideWithValue(
              FakePlaybackSourceGateway(),
            ),
            playbackPositionsProvider.overrideWithValue(
              FakePlaybackPositionStore(),
            ),
          ],
        );
        await container.read(startupControllerProvider.notifier).start();
        container
            .read(sessionControllerProvider.notifier)
            .establish(FakeAuthGateway.defaultSession);

        await container
            .read(videoPlaybackControllerProvider.notifier)
            .open(aFile(name: 'Stalker.mkv', type: FileType.video));
        expect(container.read(videoPlaybackControllerProvider).isOpen, isTrue);

        await container.read(signOutControllerProvider).signOut();

        expect(player.stopCount, 1);
        expect(container.read(videoPlaybackControllerProvider).isOpen, isFalse);
      },
    );
  });
}
