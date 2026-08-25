import 'dart:io';

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/playback/data/media_kit_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// The media_kit binding, against the real native library (IR-14, Testing
/// Specification §2.4).
///
/// The unit and widget suites substitute a fake engine for every playback
/// flow, which is what makes those flows testable without libmpv — and is also
/// why they cannot see whether the real engine can be built at all. That is
/// what this suite is for: the players are read through the application's own
/// provider graph, exactly as UC-19 and UC-20 read them, so a native library
/// that will not initialize fails here rather than the first time an owner
/// presses play.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    expect(
      Platform.isWindows || Platform.isLinux,
      isTrue,
      reason: 'IR-01 configures no other target',
    );
  });

  test(
    'GivenTheProviderGraph_WhenTheAudioEngineIsRead_ThenTheRealPlayerIsBuilt',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final player = container.read(audioPlayerProvider);

      expect(player, isA<MediaKitPlayer>());
      expect(player.currentStatus.isPlaying, isFalse);
    },
  );

  test(
    'GivenTheProviderGraph_WhenTheVideoEngineIsRead_ThenTheRealPlayerIsBuilt',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final player = container.read(videoPlayerProvider);

      expect(player, isA<MediaKitPlayer>());
      expect(player.currentStatus.isPlaying, isFalse);
    },
  );
}
