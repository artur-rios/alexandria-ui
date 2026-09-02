import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/core/theme/breakpoints.dart';
import 'package:alexandria_ui/features/enrichment/presentation/lyrics_button.dart';
import 'package:alexandria_ui/features/playback/presentation/sound_bars.dart';
import 'package:alexandria_ui/features/playback/presentation/album_visor.dart';
import 'package:alexandria_ui/features/playback/domain/media_player.dart';
import 'package:alexandria_ui/features/playback/presentation/now_playing_screen.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/playback_bar.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_media_player.dart';
import '../../../support/fake_playback.dart';
import '../../../support/fake_playlist_gateway.dart';
import '../../../support/shell_harness.dart';

/// The full player (UC-21, FR-PL-07, FR-CT-13).
///
/// Rewritten with the screen. What stood here was an album animation — a
/// case, a medium and a machine to put it into — and most of this file was
/// about that: which device was drawn, where its buttons were, when the
/// medium went in again. None of it exists now. The screen shows the sleeve,
/// names what is playing, and moves with it ([SoundBars]), and this is what
/// holds that up.
///
/// Renamed from `album_player_screen_test.dart`, Task 7's own file, when
/// `AlbumPlayerScreen` — a 360-pixel dialog — was replaced wholesale by
/// `NowPlayingScreen`, a route that fills the window. The groups below cover
/// what still holds: what this screen does when the queue is a single track,
/// which is a record too (design §1), leaving and returning to the player
/// (AF-02), the screen never leaking a raw file name onto the page
/// (FR-CT-13), that the route really does fill the window, and the auto-open
/// behaviour Task 7 adds on top of what `album_animation_test.dart` covered
/// for `AlbumAnimation` itself (moved to `album_stage_test.dart` in Task 5)
/// and for `AlbumAnimationController` (covered directly in
/// `album_animation_controller_test.dart`, Task 6).
///
/// `pumpShell` runs with real motion by default — `AlbumStage`'s spin never
/// settles on its own while something plays, so every wait in this file that
/// might run while a stage is on screen uses [settle], a bounded pump,
/// rather than `pumpAndSettle`.
void main() {
  /// Pumps a few frames without waiting for the tree to settle.
  ///
  /// The bars run for as long as audio plays, so `pumpAndSettle` never
  /// returns once the player is on screen — which is the point of them, and
  /// exactly why this file does not lean on it past the point playback
  /// starts.
  Future<void> settle(WidgetTester tester) async {
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Signs in and plays a track of Miles Davis's "Kind of Blue" from the
  /// music area (UC-46), as an album unless [asTrack] says otherwise — the
  /// real path an owner takes.
  ///
  /// The auto-open is left on here, which is the owner's own default: a
  /// track started from the browsing area puts the player on screen, so a
  /// caller of this helper finds it already open.
  Future<({ProviderContainer container, FakeMediaPlayer player})> play(
    WidgetTester tester, {
    bool asTrack = false,
    int year = 1959,
    Size surfaceSize = const Size(1440, 1000),
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    bool opensPlayerOnPlay = true,
  }) async {
    final catalog = FakeCatalogGateway()
      ..addAudio(
        uuid: 'blue-1',
        title: 'So What',
        artist: 'Miles Davis',
        album: 'Kind of Blue',
        year: year,
        track: 1,
      )
      ..addAudio(
        uuid: 'blue-2',
        title: 'Blue in Green',
        artist: 'Miles Davis',
        album: 'Kind of Blue',
        year: year,
        track: 2,
      );

    final player = FakeMediaPlayer();
    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: surfaceSize,
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(catalog),
        audioPlayerProvider.overrideWithValue(player),
        playbackSourceGatewayProvider.overrideWithValue(
          FakePlaybackSourceGateway(),
        ),
        playbackPositionsProvider.overrideWithValue(
          FakePlaybackPositionStore(),
        ),
      ],
    );

    await container
        .read(preferencesControllerProvider.notifier)
        .setOpensPlayerOnPlay(opensPlayerOnPlay);

    container.read(shellControllerProvider.notifier).go(ShellDestination.music);
    await tester.pumpAndSettle();

    if (asTrack) {
      // Songs, where a row plays alone rather than continuing an album.
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      await tester.tap(find.text(l10n.musicViewSongs));
      await tester.pumpAndSettle();
      await tester.tap(find.text('So What'));
    } else {
      // Artists → the album → the track: a row here plays the album from
      // where it was tapped (main flow steps 1 and 3).
      await tester.tap(find.text('Miles Davis'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Kind of Blue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('So What'));
    }
    await settle(tester);

    return (container: container, player: player);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// Signs in and starts an album of two tracks playing, with the auto-open
  /// off unless a caller asks for it.
  Future<ProviderContainer> playSomething(
    WidgetTester tester, {
    bool opensPlayerOnPlay = false,
    bool reduceMotion = false,
  }) async {
    final catalog = FakeCatalogGateway()
      ..addAudio(
        uuid: 'kob-1',
        title: 'So What',
        artist: 'Miles Davis',
        album: 'Kind of Blue',
        year: 1959,
        track: 1,
      )
      ..addAudio(
        uuid: 'kob-2',
        title: 'Freddie Freeloader',
        artist: 'Miles Davis',
        album: 'Kind of Blue',
        year: 1959,
        track: 2,
      );

    final container = await tester.pumpShell(
      reduceMotion: reduceMotion,
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(catalog),
        audioPlayerProvider.overrideWithValue(FakeMediaPlayer()),
        playbackSourceGatewayProvider.overrideWithValue(
          FakePlaybackSourceGateway(),
        ),
        playbackPositionsProvider.overrideWithValue(
          FakePlaybackPositionStore(),
        ),
      ],
    );

    await container
        .read(preferencesControllerProvider.notifier)
        .setOpensPlayerOnPlay(opensPlayerOnPlay);
    await container
        .read(audioPlaybackControllerProvider.notifier)
        .playAlbum(aFile(uuid: 'kob-1'));
    await settle(tester);

    return container;
  }

  /// The tooltip the close control carries, read the same way every other
  /// helper in this file reads a string — through the running app's own
  /// [AppLocalizations], never a literal that could drift from it.
  ///
  /// Resolved from [NowPlayingScreen] itself rather than [ShellScreen]:
  /// `NowPlayingScreen.show` is a full route push, and the screen it covers
  /// is not guaranteed to still be the one a bare [find.byType] search on
  /// [ShellScreen] would resolve against once something is stacked over it.
  String closeLabel(WidgetTester tester) => AppLocalizations.of(
    tester.element(find.byType(NowPlayingScreen)),
  ).audioClosePlayer;

  /// The player's own transport, found by the tooltip a screen reader and a
  /// pointer both get — never by position in the row, which would pass just
  /// as happily with two of them transposed.
  Finder control(WidgetTester tester, String label) => find.descendant(
    of: find.byType(NowPlayingScreen),
    matching: find.byTooltip(label),
  );

  group('what the screen shows (FR-PL-07, FR-CT-13)', () {
    testWidgets(
      'GivenATrackPlaying_WhenThePlayerOpens_ThenItNamesTheTrackAndTheRecord',
      (tester) async {
        await play(tester);

        // The title, the record's artist and the record — the three facts an
        // owner opens this screen to read, and the whole of what the screen
        // says in words.
        expect(
          find.descendant(
            of: find.byType(NowPlayingScreen),
            matching: find.text('So What'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(NowPlayingScreen),
            matching: find.text('Miles Davis'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(NowPlayingScreen),
            matching: find.text('Kind of Blue'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('GivenATrackPlaying_WhenThePlayerOpens_ThenTheBarsAreOnIt', (
      tester,
    ) async {
      // The one thing on the screen that moves, and the reason the screen
      // exists rather than being a row in the bar.
      await play(tester);

      final bars = find.descendant(
        of: find.byType(NowPlayingScreen),
        matching: find.byType(SoundBars),
      );
      expect(bars, findsOneWidget);
      expect(
        tester.widget<SoundBars>(bars).isPlaying,
        isTrue,
        reason: 'audio is running, so the bars are running',
      );
    });

    testWidgets('GivenPlaybackPauses_WhenTheBarsAreRead_ThenTheyAreTold', (
      tester,
    ) async {
      // The bars settle on a pause rather than freezing mid-swell, and what
      // decides that is this flag reaching them at all.
      final played = await play(tester);
      final l10n = messages(tester);

      await tester.tap(control(tester, l10n.audioPause));
      await settle(tester);

      expect(played.player.pauseCount, 1);
      expect(
        tester
            .widget<SoundBars>(
              find.descendant(
                of: find.byType(NowPlayingScreen),
                matching: find.byType(SoundBars),
              ),
            )
            .isPlaying,
        isFalse,
      );
    });

    testWidgets(
      'GivenATrackPlaying_WhenTheBarsAreDrawn_ThenTheyFollowTheEngine',
      (tester) async {
        // The bars are drawn from the track's own sound at the position
        // playing (FR-MP-07), so the position the engine reports has to
        // reach them: without it they would draw the same moment of the
        // music for the whole track.
        final played = await play(tester);
        played.player.report(
          const PlaybackStatus(
            isPlaying: true,
            position: Duration(seconds: 12),
            duration: Duration(minutes: 4),
          ),
        );
        await settle(tester);

        expect(
          tester
              .widget<SoundBars>(
                find.descendant(
                  of: find.byType(NowPlayingScreen),
                  matching: find.byType(SoundBars),
                ),
              )
              .position,
          const Duration(seconds: 12),
        );
      },
    );

    testWidgets('GivenNoCoverYet_WhenThePlayerOpens_ThenAPlaceholderStandsIn', (
      tester,
    ) async {
      // A file with no embedded picture is ordinary, not an error: the
      // screen shows a sleeve-shaped placeholder rather than a hole where
      // the album should be.
      await play(tester);

      expect(
        find.descendant(
          of: find.byType(NowPlayingScreen),
          matching: find.byIcon(Icons.album_outlined),
        ),
        findsWidgets,
      );
    });
  });

  group('the transport (main flow step 6)', () {
    testWidgets('GivenAPlayingTrack_WhenPauseIsPressed_ThenPlaybackPauses', (
      tester,
    ) async {
      final played = await play(tester);
      final l10n = messages(tester);

      await tester.tap(control(tester, l10n.audioPause));
      await settle(tester);

      expect(played.player.pauseCount, 1);
    });

    testWidgets('GivenAPausedTrack_WhenPlayIsPressed_ThenPlaybackResumes', (
      tester,
    ) async {
      final played = await play(tester);
      final l10n = messages(tester);

      await tester.tap(control(tester, l10n.audioPause));
      await settle(tester);
      await tester.tap(control(tester, l10n.audioPlay));
      await settle(tester);

      expect(played.player.playCount, greaterThanOrEqualTo(1));
    });

    testWidgets('GivenAnAlbumQueue_WhenNextIsPressed_ThenTheQueueMovesOn', (
      tester,
    ) async {
      final played = await play(tester);
      final l10n = messages(tester);

      await tester.tap(control(tester, l10n.audioNext));
      await settle(tester);

      expect(
        played.container.read(audioPlaybackControllerProvider).queue.index,
        1,
      );
    });

    testWidgets('GivenATrackPlaying_WhenStopIsPressed_ThenPlaybackStops', (
      tester,
    ) async {
      final played = await play(tester);
      final l10n = messages(tester);

      await tester.tap(control(tester, l10n.audioStop));
      await settle(tester);

      expect(
        played.container.read(audioPlaybackControllerProvider).current,
        isNull,
      );
    });

    testWidgets(
      'GivenTheFirstTrackOfAQueue_WhenItIsShown_ThenPreviousIsRefused',
      (tester) async {
        // The queue's own rule, shown rather than restated: a disabled key
        // is what says "there is nothing behind this" without the owner
        // having to press it to find out.
        await play(tester);

        // By its glyph rather than its tooltip: a tooltip is a widget
        // *inside* the button it names, so a search for the button among its
        // own descendants finds nothing.
        expect(
          tester
              .widget<IconButton>(
                find.descendant(
                  of: find.byType(NowPlayingScreen),
                  matching: find.widgetWithIcon(
                    IconButton,
                    Icons.skip_previous,
                  ),
                ),
              )
              .onPressed,
          isNull,
        );
      },
    );
  });

  group('the transport (order and reach, main flow step 6)', () {
    testWidgets('GivenThePlayer_WhenTheKeysAreRead_ThenTheyAreInOrder', (
      tester,
    ) async {
      // Stop, back, play, forward — the order every machine with these four
      // keys prints them in. Play used to sit between back and stop, which
      // put the stop key between the two an owner reaches for most and left
      // forward stranded on the far side of it.
      await play(tester);

      double centreOf(IconData glyph) => tester
          .getCenter(
            find.descendant(
              of: find.byType(NowPlayingScreen),
              matching: find.widgetWithIcon(IconButton, glyph),
            ),
          )
          .dx;

      final places = [
        centreOf(Icons.stop),
        centreOf(Icons.skip_previous),
        centreOf(Icons.pause_circle),
        centreOf(Icons.skip_next),
      ];

      for (var index = 1; index < places.length; index++) {
        expect(
          places[index],
          greaterThan(places[index - 1]),
          reason: 'key $index sits right of the one before it',
        );
      }
    });
  });

  group('moving through the track (FR-PL-12)', () {
    testWidgets('GivenATrackPlaying_WhenTheSliderIsDragged_ThenItSeeks', (
      tester,
    ) async {
      // The line under the player is the thing an owner drags, and the engine
      // has offered `seek` all along — it was the queue's controller that had
      // no way to ask for it.
      final played = await play(tester);
      // A duration the engine has reported: nothing can be a fraction of a
      // length nobody knows yet, and the slider is refused until it is.
      played.player.report(
        const PlaybackStatus(
          isPlaying: true,
          position: Duration(seconds: 5),
          duration: Duration(minutes: 4),
        ),
      );
      await settle(tester);

      final slider = find.descendant(
        of: find.byType(NowPlayingScreen),
        matching: find.byType(Slider),
      );
      expect(slider, findsOneWidget);

      // Dragged to a little past halfway, which is a seek to a little past
      // two minutes of a four-minute track.
      final box = tester.getRect(slider);
      await tester.dragFrom(
        box.centerLeft + const Offset(8, 0),
        Offset(box.width * 0.5, 0),
      );
      await settle(tester);

      expect(played.player.seeks, isNotEmpty);
      expect(played.player.seeks.last, greaterThan(const Duration(minutes: 1)));
      expect(
        played.player.seeks.last,
        lessThanOrEqualTo(const Duration(minutes: 4)),
      );
    });

    testWidgets('GivenNoDurationYet_WhenTheSliderIsRead_ThenItRefusesToMove', (
      tester,
    ) async {
      // A track whose length the engine has not worked out cannot be
      // seeked into: a slider that moved anyway would be a control that
      // does nothing, which is what the plain bar before it at least never
      // pretended to be.
      await play(tester);

      final slider = tester.widget<Slider>(
        find.descendant(
          of: find.byType(NowPlayingScreen),
          matching: find.byType(Slider),
        ),
      );

      expect(slider.onChanged, isNull);
    });
  });

  group('opening itself when a track starts (main flow step 2)', () {
    testWidgets('GivenNothingHasPlayed_WhenATrackStarts_ThenThePlayerOpens', (
      tester,
    ) async {
      // What the owner asked for: the screen in front of them whenever
      // something new begins, from wherever they started it.
      final container = await playSomething(tester, opensPlayerOnPlay: true);

      expect(find.byType(NowPlayingScreen), findsOneWidget);
      expect(
        container.read(audioPlaybackControllerProvider).current,
        isNotNull,
      );
    });

    testWidgets(
      'GivenTheOwnerClosedIt_WhenTheNextTrackStarts_ThenItOpensAgain',
      (tester) async {
        // Every track, not every record: a screen that opened once and then
        // stayed shut for the rest of an album is the behaviour this
        // replaced.
        final container = await playSomething(tester, opensPlayerOnPlay: true);
        await tester.tap(find.byTooltip(closeLabel(tester)));
        // Twice: one `settle` is six frames and the pop is longer than that,
        // and `show` declines to stack a player on one still leaving.
        await settle(tester);
        await settle(tester);
        expect(find.byType(NowPlayingScreen), findsNothing);

        await container.read(audioPlaybackControllerProvider.notifier).next();
        await settle(tester);

        expect(find.byType(NowPlayingScreen), findsOneWidget);
      },
    );

    testWidgets('GivenTheAutoOpenIsOff_WhenATrackStarts_ThenNothingOpens', (
      tester,
    ) async {
      // The owner's own switch (FR-PL-11): playback starts where they left
      // the interface rather than in front of the player.
      await playSomething(tester, opensPlayerOnPlay: false);

      expect(find.byType(NowPlayingScreen), findsNothing);
    });

    testWidgets(
      'GivenThePlayerIsAlreadyOpen_WhenTheNextTrackStarts_ThenOnlyOneShows',
      (tester) async {
        final container = await playSomething(tester, opensPlayerOnPlay: true);

        await container.read(audioPlaybackControllerProvider.notifier).next();
        await settle(tester);

        expect(find.byType(NowPlayingScreen), findsOneWidget);
      },
    );
  });

  group('the words, beside the player (music enrichment design)', () {
    testWidgets(
      'GivenThePlayerIsOpen_WhenTheLyricsAreAskedFor_ThenTheyOpenBesideIt',
      (tester) async {
        // Beside, not over: timed lines are read while the music runs, and a
        // sheet over the player put the screen they belong to behind them.
        await play(tester);

        await tester.tap(find.byIcon(Icons.lyrics_outlined));
        await settle(tester);

        expect(find.byType(LyricsPanel), findsOneWidget);
        expect(
          tester.getTopLeft(find.byType(LyricsPanel)).dx,
          greaterThan(tester.getCenter(find.byType(SoundBars)).dx),
          reason: 'the words take the right of the window',
        );
      },
    );

    testWidgets(
      'GivenTheWordsAreOpen_WhenTheButtonIsPressedAgain_ThenTheyClose',
      (tester) async {
        await play(tester);

        await tester.tap(find.byIcon(Icons.lyrics_outlined));
        await settle(tester);
        await tester.tap(find.byIcon(Icons.lyrics));
        await settle(tester);

        expect(find.byType(LyricsPanel), findsNothing);
      },
    );
  });

  group('the full window', () {
    testWidgets(
      'GivenSomethingPlaying_WhenThePlayerIsOpened_ThenItFillsTheWindow',
      (tester) async {
        // A dialog cannot give the sleeve the room it needs, which is why
        // this is a route.
        await playSomething(tester);
        await tester.tap(find.byIcon(Icons.expand_less));
        await settle(tester);

        expect(find.byType(NowPlayingScreen), findsOneWidget);
        expect(
          tester.getSize(find.byType(NowPlayingScreen)).width,
          tester.getSize(find.byType(MaterialApp)).width,
        );
      },
    );

    testWidgets(
      'GivenTheMinimumWindow_WhenThePlayerOpens_ThenNothingOverflows',
      (tester) async {
        // NFR-07: the smallest window the application supports still has to
        // show a sleeve, a name and a transport without laying them over
        // each other.
        await play(tester, surfaceSize: Breakpoint.minimumWindowSize);

        expect(find.byType(NowPlayingScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('leaving the player', () {
    testWidgets('GivenTheFullPlayerIsClosed_WhenItIs_ThenPlaybackContinues', (
      tester,
    ) async {
      // AF-02: the queue and the bar are not this screen's, so closing it
      // takes nothing with it.
      final played = await play(tester);

      await tester.tap(find.byTooltip(closeLabel(tester)));
      await settle(tester);
      await settle(tester);

      expect(find.byType(NowPlayingScreen), findsNothing);
      expect(
        played.container.read(audioPlaybackControllerProvider).current,
        isNotNull,
      );
      expect(find.byType(PlaybackBar), findsOneWidget);
    });

    testWidgets('GivenTheBarsSleeve_WhenItIsPressed_ThenThePlayerOpensAgain', (
      tester,
    ) async {
      // The way back in an owner reaches for first (main flow step 2).
      await play(tester);
      await tester.tap(find.byTooltip(closeLabel(tester)));
      await settle(tester);
      await settle(tester);

      await tester.tap(find.byType(AlbumVisor));
      await settle(tester);

      expect(find.byType(NowPlayingScreen), findsOneWidget);
    });
  });

  group('never a file name (FR-CT-13)', () {
    testWidgets(
      'GivenAnUntaggedTrack_WhenThePlayerOpens_ThenTheUnknownWordsAreUsed',
      (tester) async {
        // A file called `01 - track.flac` is not a title, and the screen
        // that shows what is playing is the last place a path should appear.
        final catalog = FakeCatalogGateway()
          ..addAudio(uuid: 'raw-1', name: '01 - track.flac');
        final container = await tester.pumpShell(
          extraOverrides: <Override>[
            catalogGatewayProvider.overrideWithValue(catalog),
            audioPlayerProvider.overrideWithValue(FakeMediaPlayer()),
            playbackSourceGatewayProvider.overrideWithValue(
              FakePlaybackSourceGateway(),
            ),
            playbackPositionsProvider.overrideWithValue(
              FakePlaybackPositionStore(),
            ),
          ],
        );
        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playTrack(aFile(uuid: 'raw-1', name: '01 - track.flac'));
        await settle(tester);

        final l10n = messages(tester);
        expect(
          find.descendant(
            of: find.byType(NowPlayingScreen),
            matching: find.text(l10n.musicUnknownTitle),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('.flac'), findsNothing);
      },
    );
  });

  group('adding the current track to a playlist (Task 5)', () {
    testWidgets(
      'GivenThePlayerIsOpen_WhenAddToPlaylistIsChosen_ThenTheTrackIsSent',
      (tester) async {
        final playlists = FakePlaylistGateway(
          playlists: [const Playlist(uuid: 'p-1', name: 'Evening')],
        );
        final catalog = FakeCatalogGateway()
          ..addAudio(uuid: 'kob-1', title: 'So What', artist: 'Miles Davis');
        final container = await tester.pumpShell(
          extraOverrides: <Override>[
            catalogGatewayProvider.overrideWithValue(catalog),
            playlistGatewayProvider.overrideWithValue(playlists),
            audioPlayerProvider.overrideWithValue(FakeMediaPlayer()),
            playbackSourceGatewayProvider.overrideWithValue(
              FakePlaybackSourceGateway(),
            ),
            playbackPositionsProvider.overrideWithValue(
              FakePlaybackPositionStore(),
            ),
          ],
        );
        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playTrack(aFile(uuid: 'kob-1'));
        await settle(tester);

        final l10n = messages(tester);
        await tester.tap(
          find.descendant(
            of: find.byType(NowPlayingScreen),
            matching: find.byTooltip(l10n.playlistAddTo),
          ),
        );
        // `settle`, never `pumpAndSettle`: the bars are running behind the
        // menu and nothing in this tree ever settles while they are.
        await settle(tester);
        await tester.tap(find.text('Evening'));
        await settle(tester);

        expect(playlists.entriesAdded, isNotEmpty);
        expect(playlists.entriesAdded.last.fileUuids, ['kob-1']);
      },
    );
  });
}
