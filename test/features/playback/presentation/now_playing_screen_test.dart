import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/playback/application/audio_playback_controller.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:alexandria_ui/features/playback/presentation/album_stage.dart';
import 'package:alexandria_ui/features/playback/presentation/now_playing_screen.dart';
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
import '../../../support/shell_harness.dart';

/// The full player's own behaviour, apart from whatever medium `AlbumStage`
/// draws inside it (UC-21, FR-PL-07, FR-CT-13).
///
/// Renamed from `album_player_screen_test.dart`, Task 7's own file, when
/// `AlbumPlayerScreen` — a 360-pixel dialog — was replaced wholesale by
/// `NowPlayingScreen`, a route that fills the window. The groups below cover
/// what still holds: what this screen does when the queue is a single track
/// (AF-02), leaving and returning to the player (AF-03), the screen never
/// leaking a raw file name onto the page (FR-CT-13), that the route really
/// does fill the window, and the auto-open behaviour Task 7 adds on top of
/// what `album_animation_test.dart` covered for `AlbumAnimation` itself
/// (moved to `album_stage_test.dart` in Task 5) and for
/// `AlbumAnimationController` (covered directly in
/// `album_animation_controller_test.dart`, Task 6).
void main() {
  /// Signs in and plays a track of Miles Davis's "Kind of Blue" from the
  /// music area (UC-46), as an album unless [asTrack] says otherwise — the
  /// real path an owner takes, and now the only one: the rows play on tap
  /// rather than opening a details dialog with play buttons on it.
  Future<({ProviderContainer container, FakeMediaPlayer player})> play(
    WidgetTester tester, {
    bool asTrack = false,
    int year = 1959,
    Size surfaceSize = const Size(1440, 1000),
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
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
    await tester.pumpAndSettle();

    return (container: container, player: player);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// Opens the full player from the bar (main flow step 2) — unless step 4's
  /// own auto-open listener already has, which it does for every album
  /// `play` starts here (`play`'s queue always owes an insertion under the
  /// default, untouched preference these older groups play under). Tapping
  /// the bar's own button again in that case would hit nothing: the bar is
  /// the route beneath the one already pushed. Idempotent either way is what
  /// lets every group written before step 4 existed keep asking for the
  /// player open without needing to know which route got it there.
  Future<void> openPlayer(WidgetTester tester) async {
    if (find.byType(NowPlayingScreen).evaluate().isNotEmpty) return;

    await tester.tap(
      find.descendant(
        of: find.byType(PlaybackBar),
        matching: find.byIcon(Icons.expand_less),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Signs in (`pumpShell` disables the animation via accessibility
  /// settings, so the medium's spin — which repeats for as long as audio
  /// plays — never leaves a frame scheduled for `pumpAndSettle` to wait out)
  /// and starts an album playing. These tests are about the screen the
  /// medium sits inside, not about the medium's own motion, which
  /// `album_stage_test.dart` already covers.
  ///
  /// Plays an album of two tracks (never a single one) so that whatever
  /// [mode] resolves to actually has a queue eligible to show it (AF-02).
  ///
  /// [mode] defaults to off rather than to the owner's untouched default: the
  /// shell's own auto-open listener (step 4) would otherwise push the player
  /// before a caller here ever gets to, which is exactly wrong for the tests
  /// in this file that open it by hand. The step 4 group below passes a mode
  /// that owes an insertion explicitly, which is what makes that behaviour
  /// its own to test rather than something every other test trips over.
  Future<ProviderContainer> playSomething(
    WidgetTester tester, {
    AlbumAnimationMode mode = AlbumAnimationMode.off,
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
        .setAlbumAnimation(mode);
    await container
        .read(audioPlaybackControllerProvider.notifier)
        .playAlbum(aFile(uuid: 'kob-1'));
    await tester.pumpAndSettle();

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

  // The player is a route that fills the window, not a 360-pixel dialog
  // (Task 7).
  group('the full window (Task 7)', () {
    testWidgets(
      'GivenSomethingPlaying_WhenThePlayerIsOpened_ThenItFillsTheWindow',
      (tester) async {
        // A dialog cannot give the animation the room it needs, which is why
        // this stopped being one.
        await playSomething(tester);
        await tester.tap(find.byIcon(Icons.expand_less));
        await tester.pumpAndSettle();

        expect(find.byType(NowPlayingScreen), findsOneWidget);
        expect(
          tester.getSize(find.byType(NowPlayingScreen)).width,
          tester.getSize(find.byType(MaterialApp)).width,
        );
      },
    );

    testWidgets(
      'GivenThePlayerIsOpen_WhenItIsClosed_ThenTheQueueAndTheBarAreUntouched',
      (tester) async {
        // AF-03: closing the player is not stopping playback.
        final container = await playSomething(tester);
        await tester.tap(find.byIcon(Icons.expand_less));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip(closeLabel(tester)));
        await tester.pumpAndSettle();

        expect(
          container.read(audioPlaybackControllerProvider).isPlaying,
          isTrue,
        );
        expect(find.byType(PlaybackBar), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheAnimationIsOff_WhenThePlayerIsOpened_ThenNoStageIsShown',
      (tester) async {
        // FR-PL-11: off means off, on every surface.
        await playSomething(tester, mode: AlbumAnimationMode.off);
        await tester.tap(find.byIcon(Icons.expand_less));
        await tester.pumpAndSettle();

        expect(find.byType(AlbumStage), findsNothing);
        expect(find.byType(NowPlayingScreen), findsOneWidget);
      },
    );
  });

  // AF-01 was "the window is too small" — a check the compact *dialog*
  // needed because its own content was fixed at 360 pixels wide regardless of
  // the window around it. A route that fills the window has no such ceiling:
  // there is no width the shell runs at (NFR-07's floor is 1024 × 640) where
  // the stage has less room than the dialog ever offered, so the two tests
  // that used to assert the medium was hidden at the minimum window are
  // replaced by the opposite assertion — the medium is still shown there,
  // and playback still runs.
  group('the minimum window', () {
    testWidgets(
      'GivenTheMinimumWindow_WhenTheFullPlayerOpens_ThenTheStageIsStillShown',
      (tester) async {
        await play(tester, surfaceSize: const Size(1024, 700));

        await openPlayer(tester);

        expect(find.byType(AlbumStage), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheMinimumWindow_WhenTheFullPlayerOpens_ThenItStillPlays',
      (tester) async {
        final playing = await play(tester, surfaceSize: const Size(1024, 700));

        await openPlayer(tester);

        expect(playing.player.opened, hasLength(1));
        expect(find.byIcon(Icons.pause_circle), findsOneWidget);
      },
    );
  });

  // AF-02: a single track is not a record.
  group('a single track', () {
    testWidgets(
      'GivenOneTrackPlays_WhenTheFullPlayerOpens_ThenNoMediumIsShown',
      (tester) async {
        await play(tester, asTrack: true);

        await openPlayer(tester);

        expect(find.byType(AlbumStage), findsNothing);
      },
    );

    testWidgets('GivenOneTrackPlays_WhenTheFullPlayerOpens_ThenItStillPlays', (
      tester,
    ) async {
      await play(tester, asTrack: true);

      await openPlayer(tester);

      expect(find.byIcon(Icons.pause_circle), findsOneWidget);
    });
  });

  // AF-03: the owner goes elsewhere.
  group('leaving the player', () {
    testWidgets('GivenTheFullPlayerIsClosed_WhenItIs_ThenPlaybackContinues', (
      tester,
    ) async {
      final playing = await play(tester);
      await openPlayer(tester);

      await tester.tap(find.byTooltip(closeLabel(tester)));
      await tester.pumpAndSettle();

      expect(playing.player.stopCount, 0);
      expect(
        find.descendant(
          of: find.byType(PlaybackBar),
          matching: find.text('So What'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'GivenTheOwnerReopensThePlayer_WhenTheyDo_ThenTheMediumIsBack',
      (tester) async {
        await play(tester);
        await openPlayer(tester);
        await tester.tap(find.byTooltip(closeLabel(tester)));
        await tester.pumpAndSettle();

        await openPlayer(tester);

        expect(find.byType(AlbumStage), findsOneWidget);
      },
    );
  });

  // The queue label beside the track title (UC-20, UC-21, FR-CT-13): named
  // through the controller directly rather than the browsing area's own
  // navigation, since an untagged album or artist has no named group tile to
  // tap through — the whole point of these fixtures is that the tag is
  // absent.
  group('the queue label (FR-CT-13)', () {
    /// Signs in over [gateway] and asks the controller to play [file] via
    /// [action], then settles the tree.
    ///
    /// The animation is turned off first: an untagged album or artist here
    /// is still a record, not a lone track, so step 4's auto-open would
    /// otherwise push the player open on its own before `openPlayer` below
    /// gets a chance to — a real interaction this group is not the one
    /// testing. `opening itself for an owed insertion` (Task 7 step 4) is.
    Future<ProviderContainer> playDirect(
      WidgetTester tester, {
      required FakeCatalogGateway gateway,
      required Future<void> Function(AudioPlaybackController) action,
    }) async {
      final container = await tester.pumpShell(
        extraOverrides: <Override>[
          catalogGatewayProvider.overrideWithValue(gateway),
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
          .setAlbumAnimation(AlbumAnimationMode.off);
      await action(container.read(audioPlaybackControllerProvider.notifier));
      await tester.pumpAndSettle();

      return container;
    }

    /// No text anywhere on screen contains [needle].
    ///
    /// Unscoped, unlike a search limited to the bar or the full player: the
    /// Home dashboard's own recent-files list is on screen underneath both of
    /// them (`tester.pumpShell` lands there), and it once showed every file —
    /// audio included — by its name on disk, which would have made an
    /// unscoped search here fail on that list's text regardless of what a fix
    /// in the bar or player did. That gap is closed: the dashboard names
    /// audio by its metadata too, so nothing on screen carries the raw file
    /// name for this to find by accident.
    void expectAbsent(WidgetTester tester, String needle) {
      expect(find.textContaining(needle), findsNothing);
    }

    testWidgets('GivenASingleTrackPlays_WhenShown_ThenNoFileNameIsOnScreen', (
      tester,
    ) async {
      // Tagged on every field a queue label could show, so a leak of any
      // of them — the file name, or the album repeated as a label that
      // means nothing beside a title that already says it — would be
      // caught, not hidden by the fixture being untagged.
      final gateway = FakeCatalogGateway()
        ..addAudio(
          uuid: '1',
          name: 'DISKNAME-01.flac',
          title: 'Airbag',
          artist: 'Radiohead',
          album: 'Kind of Blue',
        );
      final file = aFile(uuid: '1', name: 'DISKNAME-01.flac');

      await playDirect(
        tester,
        gateway: gateway,
        action: (controller) => controller.playTrack(file),
      );

      expectAbsent(tester, 'DISKNAME');
      // No queue label at all for a single track: the bar already shows
      // its title, so a label repeating the album would be noise.
      expect(
        find.descendant(
          of: find.byType(PlaybackBar),
          matching: find.text('Kind of Blue'),
        ),
        findsNothing,
      );

      await openPlayer(tester);

      expectAbsent(tester, 'DISKNAME');
      expect(
        find.descendant(
          of: find.byType(NowPlayingScreen),
          matching: find.text('Kind of Blue'),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'GivenAnUntaggedAlbumPlays_WhenShown_ThenTheUnknownAlbumWordIsUsed',
      (tester) async {
        final gateway = FakeCatalogGateway()
          ..addAudio(uuid: '1', name: 'DISKNAME-01.flac', title: 'Airbag');
        final file = aFile(uuid: '1', name: 'DISKNAME-01.flac');

        await playDirect(
          tester,
          gateway: gateway,
          action: (controller) => controller.playAlbum(file),
        );
        final l10n = messages(tester);

        expectAbsent(tester, 'DISKNAME');
        expect(
          find.descendant(
            of: find.byType(PlaybackBar),
            matching: find.text(l10n.musicUnknownAlbum),
          ),
          findsOneWidget,
        );

        await openPlayer(tester);

        expectAbsent(tester, 'DISKNAME');
        // The full player's title is the queue label, so the unknown-album
        // word appears there too rather than the generic "Player" one.
        expect(
          find.descendant(
            of: find.byType(NowPlayingScreen),
            matching: find.text(l10n.musicUnknownAlbum),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'GivenAnUntaggedArtistPlays_WhenShown_ThenTheUnknownArtistWordIsUsed',
      (tester) async {
        final gateway = FakeCatalogGateway()
          ..addAudio(uuid: '1', name: 'DISKNAME-01.flac', title: 'Airbag');
        final file = aFile(uuid: '1', name: 'DISKNAME-01.flac');

        await playDirect(
          tester,
          gateway: gateway,
          action: (controller) => controller.playArtist(file),
        );
        final l10n = messages(tester);

        expectAbsent(tester, 'DISKNAME');
        expect(
          find.descendant(
            of: find.byType(PlaybackBar),
            matching: find.text(l10n.musicUnknownArtist),
          ),
          findsOneWidget,
        );

        await openPlayer(tester);

        expectAbsent(tester, 'DISKNAME');
        expect(
          find.descendant(
            of: find.byType(NowPlayingScreen),
            matching: find.text(l10n.musicUnknownArtist),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'GivenTheFullPlayerIsOpen_WhenTheCurrentTrackIsShown_ThenItIsTheTitleNotTheFileName',
      (tester) async {
        // The bug this whole group exists to catch had nothing to do with
        // the queue label: the full player's own current-track text once
        // read `current.name` — the file name — directly, unrelated to
        // whether the queue had a label at all.
        final gateway = FakeCatalogGateway()
          ..addAudio(uuid: '1', name: 'DISKNAME-01.flac', title: 'Airbag');
        final file = aFile(uuid: '1', name: 'DISKNAME-01.flac');

        await playDirect(
          tester,
          gateway: gateway,
          action: (controller) => controller.playTrack(file),
        );
        await openPlayer(tester);

        expect(
          find.descendant(
            of: find.byType(NowPlayingScreen),
            matching: find.text('Airbag'),
          ),
          findsOneWidget,
        );
        expectAbsent(tester, 'DISKNAME');
      },
    );
  });

  // Task 7 step 4: the player opens itself for an owed insertion, from
  // wherever playback was started — a shell-level listener rather than
  // anything wired into `playAlbum`/`playArtist`/`playTrack` themselves, so
  // every entry point gets it for free.
  group('opening itself for an owed insertion (Task 7 step 4)', () {
    testWidgets(
      'GivenNothingHasPlayed_WhenATrackIsStarted_ThenThePlayerOpensItself',
      (tester) async {
        await playSomething(tester, mode: AlbumAnimationMode.byYear);

        expect(find.byType(NowPlayingScreen), findsOneWidget);
        // Proves the shell's `ref.listen` push is safe to run when it runs —
        // Task 6 left whether a build-phase call to `insertionShown()` is
        // safe for its caller to settle, and pushing a route from a listener
        // callback is the closest thing to that here. A framework exception
        // (Navigator/setState-during-build) would otherwise pass silently:
        // `pumpAndSettle` does not fail on its own just because a frame threw.
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'GivenARecordIsPlaying_WhenTheNextTrackStarts_ThenThePlayerDoesNotOpen',
      (tester) async {
        final container = await playSomething(
          tester,
          mode: AlbumAnimationMode.byYear,
        );
        // The player already auto-opened for the first track. Acknowledge
        // the insertion the way `AlbumStage.onInserted` does when it plays,
        // then leave the player the way AF-03 already does, before the next
        // track of the same record starts.
        container.read(albumAnimationControllerProvider.notifier).insertionShown();
        await tester.tap(find.byTooltip(closeLabel(tester)));
        await tester.pumpAndSettle();

        await container.read(audioPlaybackControllerProvider.notifier).next();
        await tester.pumpAndSettle();

        expect(find.byType(NowPlayingScreen), findsNothing);
      },
    );

    testWidgets(
      'GivenTheAnimationIsOff_WhenATrackIsStarted_ThenThePlayerDoesNotOpen',
      (tester) async {
        await playSomething(tester, mode: AlbumAnimationMode.off);

        expect(find.byType(NowPlayingScreen), findsNothing);
      },
    );
  });
}
