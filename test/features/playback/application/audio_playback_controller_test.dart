import 'dart:math';

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/playback/application/audio_playback_controller.dart';
import 'package:alexandria_ui/features/playback/domain/playback_queue.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_media_player.dart';
import '../../../support/fake_playback.dart';

/// Building a queue for an album, an artist or a playlist (UC-20 main flow
/// steps 1 and 3), what happens when the library it is built from cannot be
/// read, and what a queue does with a file it cannot open.
void main() {
  /// A container with a session and every playback dependency faked, so
  /// [AudioPlaybackController] runs for real over [gateway].
  ///
  /// Retries disabled: Riverpod retries a failed provider automatically
  /// (exponential backoff, up to ten attempts, ~35 seconds) before it
  /// settles into `AsyncError`, which a plain `test()` waits out in real
  /// time. This asserts the settled state without that wait.
  ///
  /// [source] lets a test decide what a resolve answers — which is how a
  /// missing file is staged, since "missing" is what the core refuses a
  /// resolve for rather than anything the queue itself carries.
  ProviderContainer buildContainer(
    FakeCatalogGateway gateway, {
    FakePlaybackSourceGateway? source,
    Random? shuffle,
  }) {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        // Seeded where a test asks, so "an order nobody chose" is still an
        // order the test knows.
        if (shuffle != null) shuffleRandomProvider.overrideWithValue(shuffle),
        catalogGatewayProvider.overrideWithValue(gateway),
        audioPlayerProvider.overrideWithValue(FakeMediaPlayer()),
        playbackSourceGatewayProvider.overrideWithValue(
          source ?? FakePlaybackSourceGateway(),
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

  test(
    'GivenAPlaylist_WhenItIsPlayed_ThenTheQueueIsReplacedAndStartsAtTheFirstTrack',
    () async {
      // Design section 6: playing a playlist replaces the queue and plays in
      // order, exactly as pressing play on an album does — there is no second
      // notion of "what is playing" to keep consistent.
      final container = buildContainer(FakeCatalogGateway());
      final audio = container.read(audioPlaybackControllerProvider.notifier);

      // Something else is playing first, so "replaces" is actually asserted
      // rather than assumed of an idle player.
      await audio.playTrack(aFile(uuid: 'other-1'));

      await audio.playPlaylist(
        name: 'Road Trip',
        tracks: [
          aFile(uuid: 'pl-a'),
          aFile(uuid: 'pl-b'),
        ],
      );

      final state = container.read(audioPlaybackControllerProvider);
      expect(state.queue.kind, QueueKind.playlist);
      expect(state.queue.tracks.map((file) => file.uuid), ['pl-a', 'pl-b']);
      expect(state.queue.index, 0);
      expect(state.stage, AudioStage.playing);
    },
  );

  test('GivenAPlaylist_WhenItIsPlayed_ThenItNamesNoRecordOfItsOwn', () async {
    // Design section 6: the queue carries the playlist's name for the bar
    // to show, but no year — the medium and the record identity are the
    // current track's to answer, never the playlist's (see `recordOf`).
    final container = buildContainer(FakeCatalogGateway());

    await container
        .read(audioPlaybackControllerProvider.notifier)
        .playPlaylist(
          name: 'Road Trip',
          tracks: [aFile(uuid: 'pl-a')],
        );

    final queue = container.read(audioPlaybackControllerProvider).queue;
    expect(queue.namesOwnRecord, isFalse);
    expect(queue.label, 'Road Trip');
  });

  test(
    'GivenAMissingTrack_WhenAPlaylistIsPlayed_ThenItIsSteppedOverAndTheNextPlays',
    () async {
      // Design section 5: a missing file stays in the list and is passed
      // over, rather than stopping the list dead partway through. Nothing new
      // does that — the entry is queued like any other and AF-01's existing
      // skip does the work, which is also what names the skipped file to the
      // owner.
      final source = FakePlaybackSourceGateway()
        ..outcomes.add(FakePlaybackSourceGateway.missingOnDisk);
      final container = buildContainer(FakeCatalogGateway(), source: source);

      await container
          .read(audioPlaybackControllerProvider.notifier)
          .playPlaylist(
            name: 'Road Trip',
            tracks: [
              aFile(uuid: 'gone'),
              aFile(uuid: 'here'),
            ],
          );

      final state = container.read(audioPlaybackControllerProvider);
      expect(state.stage, AudioStage.playing);
      expect(state.queue.current?.uuid, 'here');
      expect(state.lastSkipped?.uuid, 'gone');
      // Kept in the queue, not dropped from it: the list the owner curated is
      // still the list, and the detail screen still shows the entry greyed.
      expect(state.queue.tracks.map((file) => file.uuid), ['gone', 'here']);
    },
  );

  test(
    'GivenEveryTrackIsMissing_WhenAPlaylistIsPlayed_ThenNothingIsPlayable',
    () async {
      // AF-03 rather than a player that appears to play silence.
      final source = FakePlaybackSourceGateway()
        ..outcomes.addAll([
          FakePlaybackSourceGateway.missingOnDisk,
          FakePlaybackSourceGateway.missingOnDisk,
        ]);
      final container = buildContainer(FakeCatalogGateway(), source: source);

      await container
          .read(audioPlaybackControllerProvider.notifier)
          .playPlaylist(
            name: 'Road Trip',
            tracks: [
              aFile(uuid: 'gone-1'),
              aFile(uuid: 'gone-2'),
            ],
          );

      final state = container.read(audioPlaybackControllerProvider);
      expect(state.stage, AudioStage.allFailed);
      expect(state.lastSkipped?.uuid, 'gone-2');
    },
  );

  test(
    'GivenAnEmptyPlaylist_WhenItIsPlayed_ThenWhatWasPlayingIsLeftAlone',
    () async {
      // An empty queue would leave `_openAt` with nothing to open and the
      // player parked in `starting` forever. Nothing was asked to play here —
      // which is not AF-03, where tracks were tried and all failed — so the
      // player is left exactly as it was.
      final source = FakePlaybackSourceGateway();
      final container = buildContainer(FakeCatalogGateway(), source: source);
      final audio = container.read(audioPlaybackControllerProvider.notifier);

      await audio.playTrack(aFile(uuid: 'other-1'));
      await audio.playPlaylist(name: 'Empty', tracks: const []);

      final state = container.read(audioPlaybackControllerProvider);
      expect(state.stage, AudioStage.playing);
      expect(state.queue.current?.uuid, 'other-1');
      expect(source.resolved, ['other-1']);
    },
  );

  group('playing in an order nobody chose (FR-PL-06)', () {
    /// One record of four tracks, tagged in order.
    FakeCatalogGateway aRecord() {
      final gateway = FakeCatalogGateway();
      for (final (index, title) in ['One', 'Two', 'Three', 'Four'].indexed) {
        gateway.addAudio(
          uuid: 'a${index + 1}',
          title: title,
          artist: 'Artist',
          album: 'Album',
          track: index + 1,
        );
      }

      return gateway;
    }

    test(
      'GivenAnAlbum_WhenItIsShuffled_ThenTheWholeRecordQueuesOutOfOrder',
      () async {
        // The record, all of it, in a different order — not a subset, and
        // not the one track the owner's click happened to land on.
        final container = buildContainer(aRecord(), shuffle: Random(7));

        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playAlbum(aFile(uuid: 'a1'), shuffled: true);

        final state = container.read(audioPlaybackControllerProvider);
        expect(state.queue.kind, QueueKind.album);
        expect(
          [for (final file in state.queue.tracks) file.uuid],
          ['a2', 'a4', 'a3', 'a1'],
        );
      },
    );

    test('GivenAShuffledAlbum_WhenItStarts_ThenItStartsAtTheTop', () async {
      // Starting at the track that was clicked would make the first track
      // the one predictable thing about a shuffle.
      final container = buildContainer(aRecord(), shuffle: Random(7));

      await container
          .read(audioPlaybackControllerProvider.notifier)
          .playAlbum(aFile(uuid: 'a1'), shuffled: true);

      final state = container.read(audioPlaybackControllerProvider);
      expect(state.current?.uuid, 'a2');
    });

    test(
      'GivenAnAlbum_WhenItIsPlayedPlainly_ThenTheOrderIsTheRecords',
      () async {
        // The default is untouched: shuffling is something asked for, never
        // something that happens.
        final container = buildContainer(aRecord(), shuffle: Random(7));

        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playAlbum(aFile(uuid: 'a1'));

        final state = container.read(audioPlaybackControllerProvider);
        expect(
          [for (final file in state.queue.tracks) file.uuid],
          ['a1', 'a2', 'a3', 'a4'],
        );
      },
    );

    test(
      'GivenTheWholeLibrary_WhenEverythingIsShuffled_ThenItAllQueuesUnderTheGivenName',
      () async {
        // Every audio file in the catalog, as a named sequence with no record
        // of its own — which is what a playlist queue is.
        final container = buildContainer(aRecord(), shuffle: Random(7));

        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playEverythingShuffled(label: 'Shuffled library');

        final state = container.read(audioPlaybackControllerProvider);
        expect(state.queue.kind, QueueKind.playlist);
        expect(state.queue.label, 'Shuffled library');
        expect(
          [for (final file in state.queue.tracks) file.uuid],
          ['a2', 'a4', 'a3', 'a1'],
        );
      },
    );

    test(
      'GivenAnEmptyLibrary_WhenEverythingIsShuffled_ThenNothingIsQueued',
      () async {
        // Nothing to play is not a failure to report; it is a library with
        // no audio in it.
        final container = buildContainer(FakeCatalogGateway());

        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playEverythingShuffled(label: 'Shuffled library');

        final state = container.read(audioPlaybackControllerProvider);
        expect(state.queue.tracks, isEmpty);
        expect(state.stage, isNot(AudioStage.allFailed));
      },
    );

    test(
      'GivenTheListingFails_WhenEverythingIsShuffled_ThenNothingIsPlayable',
      () async {
        // The same answer "play album" gives when the catalog cannot be
        // asked: said out loud rather than left parked in `starting`.
        final container = buildContainer(FakeCatalogGateway()..failListing());

        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playEverythingShuffled(label: 'Shuffled library');

        final state = container.read(audioPlaybackControllerProvider);
        expect(state.stage, AudioStage.allFailed);
        expect(state.queue.tracks, isEmpty);
      },
    );
  });
}
