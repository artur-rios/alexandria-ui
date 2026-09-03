import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/playback/domain/media_player.dart';
import 'package:alexandria_ui/features/stats/domain/play_threshold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_media_player.dart';
import '../../../support/fake_playback.dart';
import '../../../support/fake_stats_gateway.dart';

/// What the player reports to the play history (play history design).
///
/// The rule itself is pinned in `play_threshold_test.dart`; this is about
/// the player applying it — once per playthrough, and again when the same
/// record is put on a second time.
void main() {
  const track = Duration(minutes: 3);

  ({ProviderContainer container, FakeMediaPlayer player, FakeStatsGateway stats})
  buildContainer() {
    final player = FakeMediaPlayer();
    final stats = FakeStatsGateway();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
        audioPlayerProvider.overrideWithValue(player),
        playbackSourceGatewayProvider.overrideWithValue(
          FakePlaybackSourceGateway(),
        ),
        playbackPositionsProvider.overrideWithValue(
          FakePlaybackPositionStore(),
        ),
        statsGatewayProvider.overrideWithValue(stats),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);

    return (container: container, player: player, stats: stats);
  }

  test('GivenATrackSkippedEarly_ThenNoPlayIsCounted', () async {
    final built = buildContainer();
    await built.container
        .read(audioPlaybackControllerProvider.notifier)
        .playTrack(aFile(uuid: 'blue-1', name: 'So What.flac'));

    built.player.reportPosition(const Duration(seconds: 30), duration: track);
    await pumpEventQueue();

    // Thirty seconds of a three-minute track is not listening to it.
    expect(built.stats.recorded, isEmpty);
  });

  test('GivenHalfATrackHeard_ThenOnePlayIsCounted', () async {
    final built = buildContainer();
    await built.container
        .read(audioPlaybackControllerProvider.notifier)
        .playTrack(aFile(uuid: 'blue-1', name: 'So What.flac'));

    built.player.reportPosition(const Duration(seconds: 91), duration: track);
    await pumpEventQueue();

    expect(built.stats.recorded, ['blue-1']);
  });

  test('GivenTheRestOfTheTrack_ThenItIsStillOnePlay', () async {
    final built = buildContainer();
    await built.container
        .read(audioPlaybackControllerProvider.notifier)
        .playTrack(aFile(uuid: 'blue-1', name: 'So What.flac'));

    // The status stream reports several times a second, and every one of
    // them is past the threshold once the first is.
    for (final second in [91, 92, 93, 120, 179]) {
      built.player.reportPosition(Duration(seconds: second), duration: track);
      await pumpEventQueue();
    }
    built.player.report(
      const PlaybackStatus(position: track, duration: track, hasEnded: true),
    );
    await pumpEventQueue();

    expect(built.stats.recorded, ['blue-1']);
  });

  test('GivenATrackHeardToTheEnd_ThenAPlayIsCounted', () async {
    final built = buildContainer();
    // Twenty seconds long, so the end arrives before the four-minute rule
    // and while a status carrying a position has never been reported.
    await built.container
        .read(audioPlaybackControllerProvider.notifier)
        .playTrack(aFile(uuid: 'short-1', name: 'Interlude.flac'));

    built.player.report(
      const PlaybackStatus(
        position: Duration(seconds: 20),
        duration: Duration(seconds: 20),
        hasEnded: true,
      ),
    );
    await pumpEventQueue();

    expect(built.stats.recorded, ['short-1']);
  });

  test('GivenTheSameTrackPlayedAgain_ThenBothPlaysAreCounted', () async {
    final built = buildContainer();
    final file = aFile(uuid: 'blue-1', name: 'So What.flac');
    final audio = built.container.read(
      audioPlaybackControllerProvider.notifier,
    );

    // Heard to the end, which is also what clears the resume position — so
    // putting it on again starts it rather than offering to resume it.
    await audio.playTrack(file);
    built.player.report(
      const PlaybackStatus(position: track, duration: track, hasEnded: true),
    );
    await pumpEventQueue();

    await audio.playTrack(file);
    built.player.reportPosition(playedAfter, duration: track);
    await pumpEventQueue();

    // The same record put on again is the listening the rankings exist to
    // count, not a duplicate to be swallowed.
    expect(built.stats.recorded, ['blue-1', 'blue-1']);
  });
}
