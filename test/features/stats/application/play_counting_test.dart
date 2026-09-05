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
/// the player applying it — once per playthrough, again when the same record
/// is put on a second time, and never for a stretch the owner did not
/// actually hear.
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

    built.player.hearUpTo(const Duration(seconds: 30), duration: track);
    await pumpEventQueue();

    // Thirty seconds of a three-minute track is not listening to it.
    expect(built.stats.recorded, isEmpty);
  });

  test('GivenHalfATrackHeard_ThenOnePlayIsCounted', () async {
    final built = buildContainer();
    await built.container
        .read(audioPlaybackControllerProvider.notifier)
        .playTrack(aFile(uuid: 'blue-1', name: 'So What.flac'));

    built.player.hearUpTo(const Duration(seconds: 91), duration: track);
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
    built.player.hearUpTo(track, duration: track);
    await pumpEventQueue();
    built.player.report(
      const PlaybackStatus(position: track, duration: track, hasEnded: true),
    );
    await pumpEventQueue();

    expect(built.stats.recorded, ['blue-1']);
  });

  test('GivenATrackHeardToTheEnd_ThenAPlayIsCounted', () async {
    final built = buildContainer();
    const short = Duration(seconds: 20);
    // Twenty seconds long, so the end arrives before the four-minute rule
    // and well before half of anything else would have counted.
    await built.container
        .read(audioPlaybackControllerProvider.notifier)
        .playTrack(aFile(uuid: 'short-1', name: 'Interlude.flac'));

    built.player.hearUpTo(short, duration: short);
    built.player.report(
      const PlaybackStatus(position: short, duration: short, hasEnded: true),
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
    built.player.hearUpTo(track, duration: track);
    built.player.report(
      const PlaybackStatus(position: track, duration: track, hasEnded: true),
    );
    await pumpEventQueue();

    await audio.playTrack(file);
    built.player.hearUpTo(playedAfter, duration: track);
    await pumpEventQueue();

    // The same record put on again is the listening the rankings exist to
    // count, not a duplicate to be swallowed.
    expect(built.stats.recorded, ['blue-1', 'blue-1']);
  });

  /// What the threshold is actually a threshold on.
  ///
  /// Every case here reaches a position past the rule without any of the
  /// track being heard, and every one of them used to record a play. A
  /// statistic that reports listening nobody did is worse than a missing
  /// one: the owner cannot tell it is wrong, and the rankings are built out
  /// of it.
  group('a position past the threshold is not listening', () {
    test('GivenATrackResumedNearItsEnd_ThenNoPlayIsCountedAtOnce', () async {
      final built = buildContainer();
      final audio = built.container.read(
        audioPlaybackControllerProvider.notifier,
      );
      final file = aFile(uuid: 'blue-1', name: 'So What.flac');

      // Left two thirds of the way in — far past half of it.
      await audio.playTrack(file);
      built.player.hearUpTo(const Duration(seconds: 20), duration: track);
      await pumpEventQueue();
      await audio.seekTo(const Duration(seconds: 120));
      await pumpEventQueue();
      await audio.stop();
      await pumpEventQueue();
      built.stats.recorded.clear();

      // Put on again and resumed from where it stopped. The engine seeks
      // there and reports it straight away — one status, at a position two
      // thirds through, with nothing heard.
      await audio.playTrack(file);
      await audio.resume();
      built.player.reportPosition(const Duration(seconds: 120), duration: track);
      await pumpEventQueue();

      expect(built.stats.recorded, isEmpty);
    });

    test('GivenTheSliderDraggedPastHalf_ThenNoPlayIsCounted', () async {
      final built = buildContainer();
      final audio = built.container.read(
        audioPlaybackControllerProvider.notifier,
      );

      await audio.playTrack(aFile(uuid: 'blue-1', name: 'So What.flac'));
      built.player.hearUpTo(const Duration(seconds: 10), duration: track);
      await pumpEventQueue();

      await audio.seekTo(const Duration(seconds: 150));
      await pumpEventQueue();
      built.player.hearUpTo(const Duration(seconds: 155), duration: track);
      await pumpEventQueue();

      // Fifteen seconds heard of a three-minute track, at a position five
      // seconds from its end.
      expect(built.stats.recorded, isEmpty);
    });

    test('GivenATrackDraggedToItsEnd_ThenEndingItCountsNothing', () async {
      final built = buildContainer();
      final audio = built.container.read(
        audioPlaybackControllerProvider.notifier,
      );

      await audio.playTrack(aFile(uuid: 'blue-1', name: 'So What.flac'));
      built.player.hearUpTo(const Duration(seconds: 5), duration: track);
      await pumpEventQueue();

      await audio.seekTo(track);
      await pumpEventQueue();
      built.player.report(
        const PlaybackStatus(position: track, duration: track, hasEnded: true),
      );
      await pumpEventQueue();

      // Reaching the end is not the same as having heard it.
      expect(built.stats.recorded, isEmpty);
    });

    test('GivenAResumeThenListening_ThenTheRestOfItStillCounts', () async {
      // The guard on the guard. Refusing to count a resume must not mean
      // refusing to count what is heard after one — an owner who comes back
      // to a track and listens to the rest of it has listened to it.
      final built = buildContainer();
      final audio = built.container.read(
        audioPlaybackControllerProvider.notifier,
      );
      final file = aFile(uuid: 'blue-1', name: 'So What.flac');

      await audio.playTrack(file);
      built.player.hearUpTo(const Duration(seconds: 20), duration: track);
      await pumpEventQueue();
      await audio.seekTo(const Duration(seconds: 60));
      await pumpEventQueue();
      await audio.stop();
      await pumpEventQueue();
      built.stats.recorded.clear();

      await audio.playTrack(file);
      await audio.resume();
      built.player.reportPosition(const Duration(seconds: 60), duration: track);
      await pumpEventQueue();
      built.player.hearUpTo(track, duration: track);
      await pumpEventQueue();

      expect(built.stats.recorded, ['blue-1']);
    });
  });
}
