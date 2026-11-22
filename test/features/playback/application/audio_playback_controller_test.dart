import 'dart:typed_data';

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/playback/domain/media_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_media_player.dart';
import '../../../support/fake_playback.dart';

/// Playing music from the library: a queue that is the list a track was
/// started from (libraries-only design §6).
void main() {
  CatalogFile track(String uuid, {String library = 'lib-1'}) => aFile(
    uuid: uuid,
    name: '$uuid.flac',
    type: FileType.audio,
    libraryUuid: library,
  );

  final one = track('one');
  final two = track('two');
  final three = track('three', library: 'lib-2');

  ({
    ProviderContainer ref,
    FakeMediaPlayer player,
    FakePlaybackSourceGateway sources,
    FakeCoverGateway covers,
  })
  build() {
    final player = FakeMediaPlayer();
    final sources = FakePlaybackSourceGateway()
      ..pathFor = (uuid) => '/music/$uuid.flac';
    final covers = FakeCoverGateway();

    final container = ProviderContainer(
      overrides: [
        audioPlayerProvider.overrideWithValue(player),
        videoPlayerProvider.overrideWithValue(FakeMediaPlayer()),
        playbackSourceGatewayProvider.overrideWithValue(sources),
        coverGatewayProvider.overrideWithValue(covers),
        playbackPositionsProvider.overrideWithValue(
          FakePlaybackPositionStore(),
        ),
      ],
    );
    addTearDown(container.dispose);

    return (ref: container, player: player, sources: sources, covers: covers);
  }

  test('GivenAQueue_WhenPlayTheSecond_ThenItPlaysAndIndexIsOne', () async {
    final sut = build();

    await sut.ref.read(audioPlaybackControllerProvider.notifier).play(two, [
      one,
      two,
      three,
    ]);

    final state = sut.ref.read(audioPlaybackControllerProvider);
    expect(state.index, 1);
    expect(state.current?.uuid, 'two');
    expect(sut.player.opened, ['/music/two.flac']);
  });

  test(
    'GivenDeletedAndVideoFilesInTheList_WhenPlay_ThenTheQueueHoldsActiveAudioOnly',
    () async {
      final sut = build();
      final deleted = track('gone').copyWith(isDeleted: true);
      final video = aFile(uuid: 'film', type: FileType.video);

      await sut.ref.read(audioPlaybackControllerProvider.notifier).play(one, [
        deleted,
        video,
        one,
        two,
      ]);

      expect(
        sut.ref
            .read(audioPlaybackControllerProvider)
            .queue
            .map((file) => file.uuid),
        ['one', 'two'],
      );
    },
  );

  test('GivenATrackEnds_WhenNotLast_ThenTheNextPlays', () async {
    final sut = build();
    await sut.ref.read(audioPlaybackControllerProvider.notifier).play(one, [
      one,
      two,
    ]);

    sut.player.report(const PlaybackStatus(hasEnded: true));
    await pumpEventQueue();

    expect(sut.ref.read(audioPlaybackControllerProvider).current?.uuid, 'two');
    expect(sut.player.opened.last, '/music/two.flac');
  });

  test('GivenTheLastTrackEnds_WhenNoMore_ThenPlaybackStopsAtTheEnd', () async {
    final sut = build();
    await sut.ref.read(audioPlaybackControllerProvider.notifier).play(two, [
      one,
      two,
    ]);

    sut.player.report(const PlaybackStatus(hasEnded: true));
    await pumpEventQueue();

    final state = sut.ref.read(audioPlaybackControllerProvider);
    expect(sut.player.opened, ['/music/two.flac']);
    expect(state.playing, isFalse);
    expect(state.current?.uuid, 'two');
  });

  test(
    'GivenATrackFailsToOpen_WhenOthersRemain_ThenItIsSkippedAndNamed',
    () async {
      final sut = build();
      sut.sources.failing.add('one');

      await sut.ref.read(audioPlaybackControllerProvider.notifier).play(one, [
        one,
        two,
      ]);

      final state = sut.ref.read(audioPlaybackControllerProvider);
      expect(state.current?.uuid, 'two');
      expect(state.skippedName, 'one.flac');
      expect(state.failure, isNull);
    },
  );

  test('GivenEveryRemainingTrackFails_WhenPlay_ThenTheFailureShows', () async {
    final sut = build();
    sut.sources.failing.addAll(['one', 'two']);

    await sut.ref.read(audioPlaybackControllerProvider.notifier).play(one, [
      one,
      two,
    ]);

    final state = sut.ref.read(audioPlaybackControllerProvider);
    expect(state.failure, isNotNull);
    expect(state.playing, isFalse);
    expect(sut.player.opened, isEmpty);
  });

  test('GivenPastThreeSeconds_WhenPrevious_ThenTheTrackRestarts', () async {
    final sut = build();
    final controller = sut.ref.read(audioPlaybackControllerProvider.notifier);
    await controller.play(two, [one, two]);
    sut.player.reportPosition(const Duration(seconds: 10));
    await pumpEventQueue();

    await controller.previous();

    expect(sut.ref.read(audioPlaybackControllerProvider).current?.uuid, 'two');
    expect(sut.player.seeks.last, Duration.zero);
  });

  test('GivenTheStartOfATrack_WhenPrevious_ThenThePreviousPlays', () async {
    final sut = build();
    final controller = sut.ref.read(audioPlaybackControllerProvider.notifier);
    await controller.play(two, [one, two]);

    await controller.previous();

    expect(sut.ref.read(audioPlaybackControllerProvider).current?.uuid, 'one');
  });

  test('GivenAVideoOpens_WhenMusicIsPlaying_ThenMusicPauses', () async {
    final sut = build();
    await sut.ref.read(audioPlaybackControllerProvider.notifier).play(one, [
      one,
    ]);

    await sut.ref
        .read(videoPlaybackControllerProvider.notifier)
        .open(aFile(uuid: 'film', type: FileType.video));

    expect(sut.player.pauseCount, 1);
    expect(sut.ref.read(audioPlaybackControllerProvider).playing, isFalse);
  });

  test(
    'GivenThePlayingTracksLibraryIsRemoved_WhenDropped_ThenPlaybackStopsAndItsTracksLeave',
    () async {
      final sut = build();
      final controller = sut.ref.read(audioPlaybackControllerProvider.notifier);
      await controller.play(one, [one, two, three]);

      await controller.dropLibrary('lib-1');

      final state = sut.ref.read(audioPlaybackControllerProvider);
      expect(state.current, isNull);
      expect(sut.player.stopCount, 1);
    },
  );

  test(
    'GivenAQueuedTracksLibraryIsRemoved_WhenDropped_ThenTheCurrentTrackKeepsPlaying',
    () async {
      final sut = build();
      final controller = sut.ref.read(audioPlaybackControllerProvider.notifier);
      await controller.play(one, [one, two, three]);

      await controller.dropLibrary('lib-2');

      final state = sut.ref.read(audioPlaybackControllerProvider);
      expect(state.current?.uuid, 'one');
      expect(state.queue.map((file) => file.uuid), ['one', 'two']);
      expect(sut.player.stopCount, 0);
    },
  );

  test('GivenATrackWithACover_WhenItPlays_ThenTheCoverIsShown', () async {
    final sut = build();
    sut.covers.covers['one'] = Uint8List.fromList([1, 2, 3]);

    await sut.ref.read(audioPlaybackControllerProvider.notifier).play(one, [
      one,
    ]);
    await pumpEventQueue();

    expect(sut.ref.read(audioPlaybackControllerProvider).cover, [1, 2, 3]);
  });

  test('GivenPlayback_WhenStopped_ThenNothingIsLoaded', () async {
    final sut = build();
    final controller = sut.ref.read(audioPlaybackControllerProvider.notifier);
    await controller.play(one, [one]);

    await controller.stop();

    expect(sut.ref.read(audioPlaybackControllerProvider).current, isNull);
    expect(sut.player.stopCount, 1);
  });

  test(
    'GivenTheOnlyTrackFailsToDecode_WhenItPlays_ThenTheFailureShowsAndPlaybackStops',
    () async {
      // A file gone from disk since the last refresh resolves fine — the
      // core does not look at the disk — and fails in the engine instead.
      final sut = build();
      await sut.ref.read(audioPlaybackControllerProvider.notifier).play(one, [
        one,
      ]);

      sut.player.report(const PlaybackStatus(failedToDecode: true));
      await pumpEventQueue();

      final state = sut.ref.read(audioPlaybackControllerProvider);
      expect(state.failure, isNotNull);
      expect(state.skippedName, 'one.flac');
      expect(state.playing, isFalse);
      expect(sut.player.stopCount, 1);
    },
  );

  test(
    'GivenATrackFailsToDecode_WhenAnotherFollows_ThenItIsSkippedAndTheNextPlays',
    () async {
      final sut = build();
      await sut.ref.read(audioPlaybackControllerProvider.notifier).play(one, [
        one,
        two,
      ]);

      sut.player.report(const PlaybackStatus(failedToDecode: true));
      await pumpEventQueue();

      final state = sut.ref.read(audioPlaybackControllerProvider);
      expect(state.current?.uuid, 'two');
      expect(state.skippedName, 'one.flac');
      expect(state.failure, isNull);
      expect(sut.player.opened.last, '/music/two.flac');
    },
  );

  test(
    'GivenTwoNextPressesInARow_WhenBothAreSent_ThenTwoTracksAdvance',
    () async {
      final sut = build();
      final controller = sut.ref.read(audioPlaybackControllerProvider.notifier);
      await controller.play(one, [one, two, three]);

      final first = controller.next();
      final second = controller.next();
      await first;
      await second;

      expect(
        sut.ref.read(audioPlaybackControllerProvider).current?.uuid,
        'three',
      );
    },
  );

  test('GivenATrackIsOpening_WhenAsked_ThenItIsAlreadyTheCurrentOne', () async {
    final sut = build();
    final controller = sut.ref.read(audioPlaybackControllerProvider.notifier);

    final opening = controller.play(two, [one, two]);
    final whileOpening = sut.ref.read(audioPlaybackControllerProvider).current;
    await opening;

    expect(whileOpening?.uuid, 'two');
  });
}
