import 'dart:async';

import 'package:alexandria_ui/app.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/presentation/file_details_view.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:alexandria_ui/features/playback/domain/media_player.dart';
import 'package:alexandria_ui/features/playback/domain/playback_position_store.dart';
import 'package:alexandria_ui/features/playback/domain/playback_session.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/playback_bar.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_media_player.dart';
import '../../../support/fake_playback.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/login_harness.dart';
import '../../../support/shell_harness.dart';
import '../../../support/test_container.dart';

/// Listening to a track, an album, or an artist (UC-20, FR-PL-05, FR-PL-06,
/// FR-PL-08 … FR-PL-10).
void main() {
  final now = DateTime.utc(2026, 8, 19, 13);

  /// Three tracks of one album by one artist, and one loose track.
  final blue1 = aFile(uuid: 'blue-1', name: 'So What.flac');
  final blue2 = aFile(uuid: 'blue-2', name: 'Blue in Green.flac');
  final other = aFile(uuid: 'other', name: 'Naima.flac');

  Map<String, Map<String, String>> metadata = {};

  FakeCatalogGateway catalogWith(List<CatalogFile> files) {
    final rows = [
      for (final file in files)
        FileDetails(file: file, metadata: metadata[file.uuid] ?? const {}),
    ];
    final gateway = FakeCatalogGateway(
      listings: {FileType.audio: CatalogListing.loaded(files: rows)},
    );

    for (final row in rows) {
      gateway.details[row.file.uuid] = FileDetailsOutcome.read(details: row);
    }

    return gateway;
  }

  setUp(() {
    metadata = {
      'blue-1': const {
        'title': 'So What',
        'album': 'Kind of Blue',
        'artist': 'Miles Davis',
        'track': '1',
      },
      'blue-2': const {
        'title': 'Blue in Green',
        'album': 'Kind of Blue',
        'artist': 'Miles Davis',
        'track': '2',
      },
      'other': const {
        'title': 'Naima',
        'album': 'Giant Steps',
        'artist': 'John Coltrane',
      },
    };
  });

  /// Signs in and opens the detail view of [file] in the audio listing.
  Future<
    ({
      ProviderContainer container,
      FakeMediaPlayer player,
      FakePlaybackSourceGateway sources,
      FakePlaybackPositionStore positions,
    })
  >
  openTrack(
    WidgetTester tester, {
    CatalogFile? file,
    List<CatalogFile>? library,
    FakePlaybackPositionStore? positions,
    FakePlaybackSourceGateway? sources,
    List<PlaybackSession>? sessions,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final files = library ?? [blue1, blue2, other];
    final target = file ?? blue1;
    final player = FakeMediaPlayer();
    final resolved = sources ?? FakePlaybackSourceGateway();
    final store = positions ?? FakePlaybackPositionStore();

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(catalogWith(files)),
        audioPlayerProvider.overrideWithValue(player),
        playbackSourceGatewayProvider.overrideWithValue(resolved),
        playbackPositionsProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(() => now),
        if (sessions != null)
          playbackSessionsProvider.overrideWithValue(sessions),
      ],
    );

    // This file is about UC-20's transport itself — the bar, the queue, the
    // resume prompt — not about UC-21's animation or the screen Task 7 gives
    // it (`now_playing_screen_test.dart` covers those). Left at its
    // untouched default, playing an album here would owe an insertion and
    // the shell's own auto-open listener would push that screen over the
    // bar mid-test, which is exactly what these tests do not expect from
    // pressing a transport button.
    await container
        .read(preferencesControllerProvider.notifier)
        .setAlbumAnimation(AlbumAnimationMode.off);

    // Opens the details dialog directly through the same static `show` the
    // application calls, rather than reaching it via a listing: UC-46 gave
    // audio its own browsing area (Task 4), whose rows play a track or an
    // album on tap rather than opening this dialog, so this is how a test
    // now reaches the play buttons several of these tests drive. `ShellScreen`
    // is a `ConsumerWidget`, whose element implements `WidgetRef` — the same
    // `ref` its own `build` would have received — so this calls `show` for
    // real rather than re-implementing its body.
    final element = tester.element(find.byType(ShellScreen));
    unawaited(FileDetailsView.show(element, element as WidgetRef, target.uuid));
    await tester.pumpAndSettle();

    return (
      container: container,
      player: player,
      sources: resolved,
      positions: store,
    );
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  Future<void> press(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  /// The transport in the bar, which the detail view's own play button is not.
  Finder inBar(Finder matching) =>
      find.descendant(of: find.byType(PlaybackBar), matching: matching);

  group('where the track has got to (FR-PL-09)', () {
    testWidgets('GivenATrackIsPlaying_WhenTheBarIsRead_ThenThePositionShows', (
      tester,
    ) async {
      // The bar reported what was playing and offered a transport, but never
      // where in the track playback was — the one thing a listener glances
      // down for.
      final opened = await openTrack(tester);
      await press(tester, messages(tester).audioPlay);

      opened.player.report(
        const PlaybackStatus(
          isPlaying: true,
          position: Duration(minutes: 1, seconds: 5),
          duration: Duration(minutes: 4, seconds: 30),
        ),
      );
      await tester.pumpAndSettle();

      expect(inBar(find.textContaining('01:05')), findsOneWidget);
      expect(inBar(find.textContaining('04:30')), findsOneWidget);
    });

    testWidgets('GivenNothingIsPlaying_WhenTheBarIsRead_ThenNoPositionShows', (
      tester,
    ) async {
      await openTrack(tester);

      expect(inBar(find.textContaining('00:00')), findsNothing);
    });
  });

  group('nothing in the selection could be played (AF-03)', () {
    testWidgets(
      'GivenEverythingFailed_WhenTheReportIsRead_ThenItCanBeDismissed',
      (tester) async {
        // The skip notice beside it has always been dismissable; this one sat
        // in the bar with no way to clear it.
        final opened = await openTrack(tester);
        await press(tester, messages(tester).audioPlay);

        opened.player.report(const PlaybackStatus(failedToDecode: true));
        await tester.pumpAndSettle();

        expect(
          find.text(messages(tester).audioNothingPlayable),
          findsOneWidget,
        );

        await tester.tap(inBar(find.text(messages(tester).editorDismiss)).last);
        await tester.pumpAndSettle();

        expect(find.text(messages(tester).audioNothingPlayable), findsNothing);
      },
    );
  });

  group('the main flow', () {
    testWidgets(
      'GivenAnAudioFile_WhenItsDetailsOpen_ThenThreeWaysToPlayAreOffered',
      (tester) async {
        await openTrack(tester);

        expect(find.text(messages(tester).audioPlay), findsOneWidget);
        expect(find.text(messages(tester).audioPlayAlbum), findsOneWidget);
        expect(find.text(messages(tester).audioPlayArtist), findsOneWidget);
      },
    );

    // Step 4: the file is played from its on-disk path.
    testWidgets('GivenATrack_WhenItIsPlayed_ThenTheEngineOpensItsPath', (
      tester,
    ) async {
      final opened = await openTrack(tester);

      await press(tester, messages(tester).audioPlay);

      expect(opened.sources.resolved, ['blue-1']);
      expect(opened.player.opened, hasLength(1));
    });

    testWidgets('GivenATrackIsPlaying_WhenTheShellIsShown_ThenTheBarNamesIt', (
      tester,
    ) async {
      await openTrack(tester);

      await press(tester, messages(tester).audioPlay);

      expect(inBar(find.text('So What')), findsOneWidget);
    });

    // Step 3 / FR-PL-06: the album's tracks, in order.
    testWidgets('GivenAnAlbum_WhenItIsPlayed_ThenItsTracksAreQueuedInOrder', (
      tester,
    ) async {
      final opened = await openTrack(tester);

      await press(tester, messages(tester).audioPlayAlbum);

      final queue = opened.container
          .read(audioPlaybackControllerProvider)
          .queue;
      expect(queue.tracks.map((file) => file.uuid), ['blue-1', 'blue-2']);
      expect(queue.label, 'Kind of Blue');
    });

    testWidgets('GivenAnArtist_WhenPlayed_ThenEveryTrackOfTheirsIsQueued', (
      tester,
    ) async {
      final opened = await openTrack(tester);

      await press(tester, messages(tester).audioPlayArtist);

      expect(
        opened.container
            .read(audioPlaybackControllerProvider)
            .queue
            .tracks
            .map((file) => file.uuid),
        ['blue-1', 'blue-2'],
      );
    });

    // An album started from track two begins at two.
    testWidgets('GivenAnAlbumStartedMidway_WhenPlayed_ThenItBeginsThere', (
      tester,
    ) async {
      final opened = await openTrack(tester, file: blue2);

      await press(tester, messages(tester).audioPlayAlbum);

      expect(
        opened.container.read(audioPlaybackControllerProvider).current?.uuid,
        'blue-2',
      );
    });

    // Step 6 / FR-PL-06.
    testWidgets('GivenAQueue_WhenTheNextTrackIsAskedFor_ThenItPlays', (
      tester,
    ) async {
      final opened = await openTrack(tester);
      await press(tester, messages(tester).audioPlayAlbum);

      await tester.tap(inBar(find.byIcon(Icons.skip_next)));
      await tester.pumpAndSettle();

      expect(
        opened.container.read(audioPlaybackControllerProvider).current?.uuid,
        'blue-2',
      );
      expect(opened.player.opened, hasLength(2));
    });

    testWidgets(
      'GivenTheLastTrack_WhenItIsPlaying_ThenSkippingOnIsNotOffered',
      (tester) async {
        await openTrack(tester, file: blue2);
        await press(tester, messages(tester).audioPlayAlbum);

        expect(
          tester
              .widget<IconButton>(
                inBar(find.widgetWithIcon(IconButton, Icons.skip_next)),
              )
              .onPressed,
          isNull,
        );
      },
    );

    testWidgets('GivenPlayback_WhenPauseIsPressed_ThenTheEngineIsPaused', (
      tester,
    ) async {
      final opened = await openTrack(tester);
      await press(tester, messages(tester).audioPlay);
      opened.player.reportPosition(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.tap(inBar(find.byIcon(Icons.pause)));
      await tester.pumpAndSettle();

      expect(opened.player.pauseCount, 1);
    });

    // Step 5: the player outlives the screen it was started from (FR-PL-05).
    testWidgets('GivenPlayback_WhenTheOwnerNavigatesAway_ThenItContinues', (
      tester,
    ) async {
      final opened = await openTrack(tester);
      // Starting playback leaves the detail view, which is what puts the
      // owner back in the shell to navigate from.
      await press(tester, messages(tester).audioPlay);

      await tester.tap(
        find.descendant(
          of: find.byType(ShellNavigationPanel),
          matching: find.byIcon(ShellDestination.books.icon),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        opened.container.read(audioPlaybackControllerProvider).current?.uuid,
        'blue-1',
      );
      expect(inBar(find.text('So What')), findsOneWidget);
      expect(opened.player.stopCount, 0);
    });

    // Step 7 / FR-PL-09.
    testWidgets('GivenPlayback_WhenItIsStopped_ThenThePositionIsKept', (
      tester,
    ) async {
      final opened = await openTrack(tester);
      await press(tester, messages(tester).audioPlay);
      opened.player.reportPosition(const Duration(minutes: 2));
      await tester.pumpAndSettle();

      await tester.tap(inBar(find.byIcon(Icons.stop)));
      await tester.pumpAndSettle();

      expect(
        opened.positions.recorded.last.position,
        const Duration(minutes: 2),
      );
      expect(opened.player.stopCount, 1);
    });

    testWidgets(
      'GivenTheQueueEnds_WhenTheLastTrackFinishes_ThenPlaybackStops',
      (tester) async {
        final opened = await openTrack(tester);
        await press(tester, messages(tester).audioPlay);

        opened.player.report(const PlaybackStatus(hasEnded: true));
        await tester.pumpAndSettle();

        expect(
          opened.container.read(audioPlaybackControllerProvider).isActive,
          isFalse,
        );
        expect(
          find.text(messages(tester).playbackNothingPlaying),
          findsOneWidget,
        );
      },
    );
  });

  // AF-01 and AF-02: a queued file that cannot be played.
  group('a track that will not play', () {
    testWidgets('GivenAMissingFile_WhenTheQueueReachesIt_ThenItIsSkipped', (
      tester,
    ) async {
      final sources = FakePlaybackSourceGateway()
        ..outcomes.add(FakePlaybackSourceGateway.missingOnDisk);
      final opened = await openTrack(tester, sources: sources);

      await press(tester, messages(tester).audioPlayAlbum);

      expect(
        opened.container.read(audioPlaybackControllerProvider).current?.uuid,
        'blue-2',
      );
    });

    testWidgets('GivenASkippedFile_WhenItIsReported_ThenItIsNamed', (
      tester,
    ) async {
      final sources = FakePlaybackSourceGateway()
        ..outcomes.add(FakePlaybackSourceGateway.missingOnDisk);
      await openTrack(tester, sources: sources);

      await press(tester, messages(tester).audioPlayAlbum);

      expect(
        find.text(messages(tester).audioSkipped('So What')),
        findsOneWidget,
      );
    });

    testWidgets('GivenAnUndecodableTrack_WhenItFails_ThenTheQueueCarriesOn', (
      tester,
    ) async {
      final opened = await openTrack(tester);
      await press(tester, messages(tester).audioPlayAlbum);

      opened.player.report(const PlaybackStatus(failedToDecode: true));
      await tester.pumpAndSettle();

      expect(
        opened.container.read(audioPlaybackControllerProvider).current?.uuid,
        'blue-2',
      );
    });
  });

  // AF-03: every queued file fails.
  group('a selection where nothing plays', () {
    testWidgets('GivenEveryFileIsMissing_WhenTheAlbumIsPlayed_ThenItStops', (
      tester,
    ) async {
      final sources = FakePlaybackSourceGateway()
        ..outcomes.addAll([
          FakePlaybackSourceGateway.missingOnDisk,
          FakePlaybackSourceGateway.missingOnDisk,
        ]);
      final opened = await openTrack(tester, sources: sources);

      await press(tester, messages(tester).audioPlayAlbum);

      expect(
        opened.container.read(audioPlaybackControllerProvider).queue.isEmpty,
        isTrue,
      );
      expect(opened.player.opened, isEmpty);
    });

    testWidgets('GivenEveryFileIsMissing_WhenItStops_ThenTheOwnerIsTold', (
      tester,
    ) async {
      final sources = FakePlaybackSourceGateway()
        ..outcomes.addAll([
          FakePlaybackSourceGateway.missingOnDisk,
          FakePlaybackSourceGateway.missingOnDisk,
        ]);
      await openTrack(tester, sources: sources);

      await press(tester, messages(tester).audioPlayAlbum);

      expect(find.text(messages(tester).audioNothingPlayable), findsOneWidget);
    });

    // The consequence of MusicLibraryController now throwing a failed
    // listing instead of returning an empty library (UC-46's fix 3): a
    // grouped play can now fail before any track is even resolved. This
    // asserts what the bar actually shows for it, which is where an
    // earlier version of this fix got it wrong — see below.
    testWidgets(
      'GivenTheListingFails_WhenTheAlbumIsPlayed_ThenOneHonestBannerShows',
      (tester) async {
        final gateway = catalogWith([blue1, blue2, other])..failListing();
        final player = FakeMediaPlayer();

        // Sized the same as `pumpShell`'s default: this test builds its own
        // widget tree instead of going through it (see below), so it would
        // otherwise render at the 800x600 test-window default, too short for
        // the details dialog's now-longer content to leave "Play album"
        // inside the visible surface.
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1280, 800);
        addTearDown(tester.view.reset);

        // Built directly rather than through tester.pumpShell: Riverpod
        // retries a failed provider automatically (exponential backoff, up
        // to ten attempts, ~35 seconds) before it settles into AsyncError,
        // and pumpShell's container has no way to turn that off. Retrying
        // is disabled here so this settles without a ~35-second test.
        final container = ProviderContainer(
          retry: (_, _) => null,
          overrides: [
            ...fakeCoreOverrides(settings: InMemorySettingsStore()),
            authGatewayProvider.overrideWithValue(FakeAuthGateway()),
            catalogGatewayProvider.overrideWithValue(gateway),
            audioPlayerProvider.overrideWithValue(player),
            playbackSourceGatewayProvider.overrideWithValue(
              FakePlaybackSourceGateway(),
            ),
            playbackPositionsProvider.overrideWithValue(
              FakePlaybackPositionStore(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const AlexandriaApp(),
          ),
        );
        await container.read(startupControllerProvider.notifier).start();
        await tester.pumpAndSettle();
        await tester.signIn();

        final element = tester.element(find.byType(ShellScreen));
        unawaited(
          FileDetailsView.show(element, element as WidgetRef, blue1.uuid),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(messages(tester).audioPlayAlbum).last);
        await tester.pumpAndSettle();

        // Exactly one banner — "nothing in the selection could be played"
        // — and not the skip notice a first version of this fix wrongly
        // stacked on top of it (naming blue1 as a track that was "skipped"
        // when nothing was ever attempted). One dismiss button proves only
        // one banner is on screen; a second would mean the skip notice was
        // showing too.
        expect(
          find.text(messages(tester).audioNothingPlayable),
          findsOneWidget,
        );
        expect(find.text(messages(tester).editorDismiss), findsOneWidget);
        expect(
          container.read(audioPlaybackControllerProvider).lastSkipped,
          isNull,
        );
      },
    );
  });

  // AF-04: a resume position exists for a single track.
  group('a track already started', () {
    FakePlaybackPositionStore storeWithPosition() => FakePlaybackPositionStore({
      'blue-1': PlaybackPosition(
        fileUuid: 'blue-1',
        position: const Duration(minutes: 3),
        updatedAt: now,
      ),
    });

    testWidgets('GivenAResumePosition_WhenTheTrackIsPlayed_ThenItAsksFirst', (
      tester,
    ) async {
      final opened = await openTrack(tester, positions: storeWithPosition());

      await press(tester, messages(tester).audioPlay);

      expect(find.text(messages(tester).videoResume), findsOneWidget);
      expect(opened.player.opened, isEmpty);
    });

    testWidgets('GivenThePrompt_WhenResumeIsChosen_ThenItOpensAtThatPosition', (
      tester,
    ) async {
      final opened = await openTrack(tester, positions: storeWithPosition());

      await press(tester, messages(tester).audioPlay);
      await tester.tap(find.text(messages(tester).videoResume));
      await tester.pumpAndSettle();

      expect(opened.player.startedAt, [const Duration(minutes: 3)]);
    });

    testWidgets('GivenThePrompt_WhenStartOverIsChosen_ThenItOpensAtZero', (
      tester,
    ) async {
      final opened = await openTrack(tester, positions: storeWithPosition());

      await press(tester, messages(tester).audioPlay);
      await tester.tap(find.text(messages(tester).videoStartOver));
      await tester.pumpAndSettle();

      expect(opened.player.startedAt, [Duration.zero]);
      expect(opened.positions.forgotten, contains('blue-1'));
    });

    // An album is a sequence, and the question is about one file.
    testWidgets('GivenAResumePosition_WhenTheAlbumIsPlayed_ThenItJustPlays', (
      tester,
    ) async {
      final opened = await openTrack(tester, positions: storeWithPosition());

      await press(tester, messages(tester).audioPlayAlbum);

      expect(find.text(messages(tester).videoResume), findsNothing);
      expect(opened.player.opened, hasLength(1));
    });
  });

  // AF-05 and FR-PL-08.
  group('one medium at a time', () {
    testWidgets('GivenAVideoIsPlaying_WhenAudioStarts_ThenTheVideoStopsFirst', (
      tester,
    ) async {
      final video = FakePlaybackSession(medium: PlaybackMedium.video);

      await openTrack(tester, sessions: [video]);
      await press(tester, messages(tester).audioPlay);

      expect(video.stopCount, 1);
    });
  });

  group('themes and languages', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheBarIsShown_ThenItRendersInThatBrightness',
        (tester) async {
          await openTrack(tester, themeMode: themeMode);
          await press(tester, messages(tester).audioPlay);

          expect(
            Theme.of(tester.element(find.byType(PlaybackBar))).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheBarIsShown_ThenNoStringRendersAsItsKey',
        (tester) async {
          final sources = FakePlaybackSourceGateway()
            ..outcomes.add(FakePlaybackSourceGateway.missingOnDisk);
          await openTrack(tester, locale: locale, sources: sources);

          await press(tester, messages(tester).audioPlayAlbum);

          expect(
            find.textContaining(RegExp('audio[A-Z]'), findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });
}
