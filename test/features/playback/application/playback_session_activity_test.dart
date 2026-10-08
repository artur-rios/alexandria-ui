import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/playback/application/playback_session_activity.dart';
import 'package:alexandria_ui/features/playback/domain/playback_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_playback.dart';

/// What playback does when a session ends (UC-03 main flow step 2).
void main() {
  final activityProvider = Provider((ref) => PlaybackSessionActivity(ref));

  test(
    'GivenSomethingPlaying_WhenTheSessionEnds_ThenEveryPlayerIsStopped',
    () async {
      final audio = FakePlaybackSession(medium: PlaybackMedium.audio);
      final video = FakePlaybackSession(medium: PlaybackMedium.video);
      final idle = FakePlaybackSession(
        medium: PlaybackMedium.video,
        isActive: false,
      );
      final container = ProviderContainer(
        overrides: [
          playbackSessionsProvider.overrideWithValue([audio, video, idle]),
        ],
      );
      addTearDown(container.dispose);

      await container.read(activityProvider).end();

      expect(audio.stopCount, 1);
      expect(video.stopCount, 1);
      expect(idle.stopCount, 0);
    },
  );
}
