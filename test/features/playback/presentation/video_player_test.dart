import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/playback/domain/media_player.dart';
import 'package:alexandria_ui/features/playback/domain/playback_position_store.dart';
import 'package:alexandria_ui/features/playback/domain/playback_session.dart';
import 'package:alexandria_ui/features/playback/presentation/video_player_screen.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_media_player.dart';
import '../../../support/fake_playback.dart';
import '../../../support/shell_harness.dart';

/// Watching a video (UC-19, FR-PL-01 … FR-PL-04, FR-PL-08 … FR-PL-10).
void main() {
  const uuid = 'a7f3c210-9d4b-4e58-8c31-6b2f5a0e9d47';
  final now = DateTime.utc(2026, 8, 19, 12);

  FileDetails aVideo({bool isDeleted = false}) => FileDetails(
    file: aFile(uuid: uuid, name: 'Stalker.mkv', type: LibraryType.video),
    metadata: const {},
    isDeleted: isDeleted,
  );

  /// Signs in, opens the video listing, and starts the player on the one file
  /// in it.
  Future<
    ({
      ProviderContainer container,
      FakeMediaPlayer player,
      FakePlaybackSourceGateway sources,
      FakePlaybackPositionStore positions,
    })
  >
  openPlayer(
    WidgetTester tester, {
    FakePlaybackPositionStore? positions,
    List<PlaybackSession> sessions = const [],
    FakePlaybackSourceGateway? sources,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    bool play = true,
  }) async {
    final catalog = FakeCatalogGateway(
      listings: {
        LibraryType.video: loadedDetails([aVideo().file]),
      },
    );
    catalog.details[uuid] = FileDetailsOutcome.read(details: aVideo());

    final player = FakeMediaPlayer();
    final resolved = sources ?? FakePlaybackSourceGateway();
    final store = positions ?? FakePlaybackPositionStore();

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(catalog),
        videoPlayerProvider.overrideWithValue(player),
        playbackSourceGatewayProvider.overrideWithValue(resolved),
        playbackPositionsProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(() => now),
        if (sessions.isNotEmpty)
          playbackSessionsProvider.overrideWithValue(sessions),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(ShellDestination.videos.icon),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stalker.mkv').first);
    await tester.pumpAndSettle();

    if (play) {
      await tester.tap(find.byIcon(Icons.play_arrow).first);
      await tester.pumpAndSettle();
    }

    return (
      container: container,
      player: player,
      sources: resolved,
      positions: store,
    );
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// A finder scoped to the player, because the detail view behind the
  /// full-screen dialog carries a play button of its own.
  Finder inPlayer(Finder matching) =>
      find.descendant(of: find.byType(VideoPlayerScreen), matching: matching);

  group('the main flow', () {
    testWidgets('GivenAVideoFile_WhenItsDetailsOpen_ThenPlayingIsOffered', (
      tester,
    ) async {
      await openPlayer(tester, play: false);

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    // Step 3: the file is opened from its on-disk path, with no bytes crossing
    // the core boundary (FR-PL-01).
    testWidgets('GivenAVideo_WhenItIsPlayed_ThenTheEngineOpensItsPath', (
      tester,
    ) async {
      final opened = await openPlayer(tester);

      expect(opened.sources.resolved, [uuid]);
      expect(opened.player.opened, ['/home/owner/videos/Stalker.mkv']);
      expect(opened.player.startedAt, [Duration.zero]);
    });

    testWidgets('GivenPlayback_WhenItIsRunning_ThenPauseIsOffered', (
      tester,
    ) async {
      final opened = await openPlayer(tester);
      opened.player.reportPosition(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    // Step 4 / FR-PL-02.
    testWidgets('GivenPlayback_WhenPauseIsPressed_ThenTheEngineIsPaused', (
      tester,
    ) async {
      final opened = await openPlayer(tester);
      opened.player.reportPosition(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();

      expect(opened.player.pauseCount, 1);
    });

    testWidgets('GivenPausedPlayback_WhenPlayIsPressed_ThenItResumes', (
      tester,
    ) async {
      final opened = await openPlayer(tester);
      opened.player.reportPosition(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();

      await tester.tap(inPlayer(find.byIcon(Icons.play_arrow)));
      await tester.pumpAndSettle();

      expect(opened.player.playCount, 1);
    });

    testWidgets('GivenPlayback_WhenSeekingForward_ThenTheEngineMovesOn', (
      tester,
    ) async {
      final opened = await openPlayer(tester);
      opened.player.reportPosition(
        const Duration(minutes: 1),
        duration: const Duration(minutes: 90),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.forward_10));
      await tester.pumpAndSettle();

      expect(opened.player.seeks, [const Duration(seconds: 70)]);
    });

    testWidgets('GivenPlaybackNearTheStart_WhenSeekingBack_ThenItStopsAtZero', (
      tester,
    ) async {
      final opened = await openPlayer(tester);
      opened.player.reportPosition(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.replay_10));
      await tester.pumpAndSettle();

      expect(opened.player.seeks, [Duration.zero]);
    });

    testWidgets('GivenPlayback_WhenFullScreenIsToggled_ThenTheControlsGoAway', (
      tester,
    ) async {
      await openPlayer(tester);

      await tester.tap(find.byIcon(Icons.fullscreen));
      await tester.pumpAndSettle();

      expect(inPlayer(find.byIcon(Icons.pause)), findsNothing);
      expect(inPlayer(find.byIcon(Icons.play_arrow)), findsNothing);
    });

    // Step 7 / FR-PL-09.
    testWidgets(
      'GivenPlaybackStops_WhenThePlayerIsClosed_ThenThePositionIsKept',
      (tester) async {
        final opened = await openPlayer(tester);
        opened.player.reportPosition(const Duration(minutes: 12));
        await tester.pumpAndSettle();

        await tester.tap(inPlayer(find.byIcon(Icons.close)));
        await tester.pumpAndSettle();

        expect(opened.positions.recorded, isNotEmpty);
        expect(opened.positions.recorded.last.fileUuid, uuid);
        expect(
          opened.positions.recorded.last.position,
          const Duration(minutes: 12),
        );
        expect(opened.player.stopCount, 1);
      },
    );

    // A file watched to the end has no position left to resume from.
    testWidgets('GivenPlaybackReachesTheEnd_WhenItDoes_ThenNoPositionIsKept', (
      tester,
    ) async {
      final opened = await openPlayer(tester);
      opened.player.reportPosition(const Duration(minutes: 88));
      await tester.pumpAndSettle();

      opened.player.report(
        const PlaybackStatus(hasEnded: true, position: Duration(minutes: 90)),
      );
      await tester.pumpAndSettle();

      expect(opened.positions.forgotten, contains(uuid));
    });
  });

  // AF-01: the file is absent from disk.
  group('a file that is not there', () {
    Future<
      ({
        ProviderContainer container,
        FakeMediaPlayer player,
        FakePlaybackSourceGateway sources,
        FakePlaybackPositionStore positions,
      })
    >
    openMissing(WidgetTester tester) => openPlayer(
      tester,
      sources: FakePlaybackSourceGateway()
        ..outcomes.add(FakePlaybackSourceGateway.missingOnDisk),
    );

    testWidgets('GivenTheFileIsGone_WhenItIsPlayed_ThenItIsReportedAsMissing', (
      tester,
    ) async {
      await openMissing(tester);

      expect(find.text(messages(tester).videoFileMissing), findsOneWidget);
    });

    testWidgets('GivenTheFileIsGone_WhenItIsPlayed_ThenNothingIsOpened', (
      tester,
    ) async {
      final opened = await openMissing(tester);

      expect(opened.player.opened, isEmpty);
    });

    testWidgets('GivenTheFileIsGone_WhenItIsReported_ThenARescanIsOffered', (
      tester,
    ) async {
      await openMissing(tester);

      expect(find.text(messages(tester).detailsRescan), findsOneWidget);
    });
  });

  // AF-02: the file cannot be decoded.
  group('a file the engine cannot read', () {
    testWidgets('GivenADecodeFailure_WhenItIsReported_ThenTheOwnerIsTold', (
      tester,
    ) async {
      final opened = await openPlayer(tester);

      opened.player.report(const PlaybackStatus(failedToDecode: true));
      await tester.pumpAndSettle();

      expect(find.text(messages(tester).videoCannotDecode), findsOneWidget);
    });

    // FR-PL-10: the application carries on. The shell is still behind it.
    testWidgets(
      'GivenADecodeFailure_WhenItIsReported_ThenTheShellIsStillThere',
      (tester) async {
        final opened = await openPlayer(tester);

        opened.player.report(const PlaybackStatus(failedToDecode: true));
        await tester.pumpAndSettle();

        expect(find.byType(ShellScreen), findsOneWidget);
      },
    );

    // A codec nobody has is not fixed by indexing again.
    testWidgets('GivenADecodeFailure_WhenItIsReported_ThenNoRescanIsOffered', (
      tester,
    ) async {
      final opened = await openPlayer(tester);

      opened.player.report(const PlaybackStatus(failedToDecode: true));
      await tester.pumpAndSettle();

      expect(find.text(messages(tester).detailsRescan), findsNothing);
    });
  });

  // AF-03: the file carries no subtitle or alternative audio track.
  group('a file with nothing to choose', () {
    testWidgets('GivenNoSubtitles_WhenTheMenuIsOpened_ThenItSaysSo', (
      tester,
    ) async {
      await openPlayer(tester);

      await tester.tap(find.byIcon(Icons.subtitles_outlined));
      await tester.pumpAndSettle();

      expect(find.text(messages(tester).videoNoSubtitles), findsOneWidget);
    });

    testWidgets('GivenNoAlternativeAudio_WhenTheMenuIsOpened_ThenItSaysSo', (
      tester,
    ) async {
      await openPlayer(tester);

      await tester.tap(find.byIcon(Icons.multitrack_audio));
      await tester.pumpAndSettle();

      expect(find.text(messages(tester).videoNoAudioTracks), findsOneWidget);
    });

    // The control is present either way — silently absent would read as the
    // application not supporting tracks at all.
    testWidgets('GivenNoTracks_WhenThePlayerIsShown_ThenTheControlsRemain', (
      tester,
    ) async {
      await openPlayer(tester);

      expect(find.byIcon(Icons.subtitles_outlined), findsOneWidget);
      expect(find.byIcon(Icons.multitrack_audio), findsOneWidget);
    });
  });

  group('choosing tracks', () {
    /// Reports a file carrying two subtitle tracks and two audio tracks.
    Future<FakeMediaPlayer> withTracks(WidgetTester tester) async {
      final opened = await openPlayer(tester);

      opened.player.report(
        const PlaybackStatus(
          isPlaying: true,
          subtitleTracks: [
            MediaTrack(id: 'sub-en', title: 'English'),
            MediaTrack(id: 'sub-pt', title: 'Portugues'),
          ],
          audioTracks: [
            MediaTrack(id: 'aud-ru', title: 'Russian'),
            MediaTrack(id: 'aud-en', title: 'English dub'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      return opened.player;
    }

    // Step 5 / FR-PL-03.
    testWidgets('GivenSubtitleTracks_WhenOneIsChosen_ThenTheEngineSwitches', (
      tester,
    ) async {
      final player = await withTracks(tester);

      await tester.tap(find.byIcon(Icons.subtitles_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portugues'));
      await tester.pumpAndSettle();

      expect(player.subtitleSelections, ['sub-pt']);
    });

    testWidgets('GivenSubtitlesOn_WhenTheyAreTurnedOff_ThenTheEngineIsTold', (
      tester,
    ) async {
      final player = await withTracks(tester);

      await tester.tap(find.byIcon(Icons.subtitles_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text(messages(tester).videoSubtitlesOff));
      await tester.pumpAndSettle();

      expect(player.subtitleSelections, [null]);
    });

    // Step 6 / FR-PL-04.
    testWidgets('GivenAudioTracks_WhenOneIsChosen_ThenTheEngineSwitches', (
      tester,
    ) async {
      final player = await withTracks(tester);

      await tester.tap(find.byIcon(Icons.multitrack_audio));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English dub'));
      await tester.pumpAndSettle();

      expect(player.audioSelections, ['aud-en']);
    });
  });

  // AF-04: a resume position exists.
  group('a video already started', () {
    FakePlaybackPositionStore storeWithPosition() => FakePlaybackPositionStore({
      uuid: PlaybackPosition(
        fileUuid: uuid,
        position: const Duration(minutes: 42),
        updatedAt: now,
      ),
    });

    testWidgets('GivenAResumePosition_WhenTheVideoIsOpened_ThenItAsksFirst', (
      tester,
    ) async {
      final opened = await openPlayer(tester, positions: storeWithPosition());

      expect(find.text(messages(tester).videoResume), findsOneWidget);
      expect(find.text(messages(tester).videoStartOver), findsOneWidget);
      expect(opened.player.opened, isEmpty);
    });

    testWidgets('GivenThePrompt_WhenResumeIsChosen_ThenItOpensAtThatPosition', (
      tester,
    ) async {
      final opened = await openPlayer(tester, positions: storeWithPosition());

      await tester.tap(find.text(messages(tester).videoResume));
      await tester.pumpAndSettle();

      expect(opened.player.startedAt, [const Duration(minutes: 42)]);
    });

    testWidgets('GivenThePrompt_WhenStartOverIsChosen_ThenItOpensAtZero', (
      tester,
    ) async {
      final opened = await openPlayer(tester, positions: storeWithPosition());

      await tester.tap(find.text(messages(tester).videoStartOver));
      await tester.pumpAndSettle();

      expect(opened.player.startedAt, [Duration.zero]);
      expect(opened.positions.forgotten, contains(uuid));
    });

    testWidgets('GivenNoResumePosition_WhenTheVideoIsOpened_ThenItJustPlays', (
      tester,
    ) async {
      final opened = await openPlayer(tester);

      expect(find.text(messages(tester).videoResume), findsNothing);
      expect(opened.player.opened, hasLength(1));
    });
  });

  // AF-05 and FR-PL-08: at most one playback session.
  group('one medium at a time', () {
    testWidgets('GivenAudioIsPlaying_WhenAVideoStarts_ThenTheAudioStopsFirst', (
      tester,
    ) async {
      final audio = FakePlaybackSession(medium: PlaybackMedium.audio);

      await openPlayer(tester, sessions: [audio]);

      expect(audio.stopCount, 1);
    });

    testWidgets('GivenNothingIsPlaying_WhenAVideoStarts_ThenNothingIsStopped', (
      tester,
    ) async {
      final audio = FakePlaybackSession(
        medium: PlaybackMedium.audio,
        isActive: false,
      );

      await openPlayer(tester, sessions: [audio]);

      expect(audio.stopCount, 0);
    });
  });

  group('themes and languages', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenThePlayerOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openPlayer(tester, themeMode: themeMode);

          expect(
            Theme.of(tester.element(find.byType(VideoPlayerScreen))).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenThePlayerOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openPlayer(tester, locale: locale);

          await tester.tap(find.byIcon(Icons.subtitles_outlined));
          await tester.pumpAndSettle();

          expect(
            find.textContaining(RegExp('video[A-Z]'), findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });
}
