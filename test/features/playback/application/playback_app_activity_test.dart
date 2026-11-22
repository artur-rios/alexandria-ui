import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/playback/application/playback_app_activity.dart';
import 'package:alexandria_ui/features/playback/application/video_playback_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_playback.dart';
import '../../../support/test_container.dart';

/// What playback does when the application's activities end.
void main() {
  final activityProvider = Provider((ref) => PlaybackAppActivity(ref));

  test(
    'GivenAVideoPlaying_WhenTheActivityEnds_ThenOnlyTheActivePlayerIsStopped',
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

  // The test above fakes both registries, so it would not notice a
  // registration going missing — and closing for an update would then leave
  // a video playing while the application exits. This reads the registries
  // the application itself builds.
  group('the registries the application builds', () {
    test(
      'GivenTheRealProviders_WhenTheRegistriesAreRead_ThenPlaybackIsInBoth',
      () {
        final container = buildTestContainer();

        expect(
          container
              .read(appActivitiesProvider)
              .whereType<PlaybackAppActivity>(),
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
  });
}
