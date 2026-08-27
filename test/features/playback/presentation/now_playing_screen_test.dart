import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/core/theme/breakpoints.dart';
import 'package:alexandria_ui/features/playback/application/album_animation_controller.dart';
import 'package:alexandria_ui/features/playback/application/audio_playback_controller.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:alexandria_ui/features/playback/domain/media_player.dart';
import 'package:alexandria_ui/features/playback/domain/playback_queue.dart';
import 'package:alexandria_ui/features/playback/presentation/album_stage.dart';
import 'package:alexandria_ui/features/playback/presentation/album_visor.dart';
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
  /// The stage repeats for as long as audio plays, so `pumpAndSettle` never
  /// returns once a medium is on screen and spinning — which is the point of
  /// it, and exactly why this file does not lean on `pumpAndSettle` past the
  /// point playback starts.
  Future<void> settle(WidgetTester tester) async {
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Signs in and plays a track of Miles Davis's "Kind of Blue" from the
  /// music area (UC-46), as an album unless [asTrack] says otherwise — the
  /// real path an owner takes, and now the only one: the rows play on tap
  /// rather than opening a details dialog with play buttons on it.
  ///
  /// [mode] defaults to off: most of the groups built on this helper are
  /// about the screen's own behaviour once it is open by hand, not about
  /// Task 7 step 4's auto-open, and leaving the animation on by default would
  /// make every one of them race the shell's own listener for which route
  /// gets there first (Finding 5). The groups that want the auto-open ask
  /// for it explicitly, by name, and know to expect the screen already open
  /// when `play` returns.
  Future<({ProviderContainer container, FakeMediaPlayer player})> play(
    WidgetTester tester, {
    bool asTrack = false,
    int year = 1959,
    Size surfaceSize = const Size(1440, 1000),
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    AlbumAnimationMode mode = AlbumAnimationMode.off,
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
        .setAlbumAnimation(mode);

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

  /// Opens the full player from the bar (main flow step 2).
  ///
  /// Always taps the button — never skips it, and asserts first that the
  /// player is not already open — so a caller's assumption about which
  /// route got the screen open is never silently wrong (Finding 5). Waits
  /// with [settle] rather than `pumpAndSettle`: whether the stage that
  /// appears here spins for real depends on the caller's own choice of
  /// `AlbumAnimationMode` and motion setting, not on anything this helper
  /// controls, so it cannot assume settling is safe.
  Future<void> openPlayer(WidgetTester tester) async {
    expect(
      find.byType(NowPlayingScreen),
      findsNothing,
      reason:
          'openPlayer taps the bar\'s own button; if the player is already '
          'open, something opened it before this call did — most likely '
          'Task 7 step 4\'s auto-open, for a caller playing under a mode '
          'that owes an insertion.',
    );

    await tester.tap(
      find.descendant(
        of: find.byType(PlaybackBar),
        matching: find.byIcon(Icons.expand_less),
      ),
    );
    await settle(tester);
  }

  /// Signs in and starts an album of two tracks playing under [mode] and
  /// [reduceMotion].
  Future<ProviderContainer> playSomething(
    WidgetTester tester, {
    AlbumAnimationMode mode = AlbumAnimationMode.off,
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
        .setAlbumAnimation(mode);
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
        // AF-02: closing the player is not stopping playback.
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

    testWidgets(
      'GivenTheQueueEndsWithThePlayerOpen_WhenItDoes_ThenTheStageIsGone',
      (tester) async {
        // Restores coverage lost across the branch's test shuffles
        // (Finding 6): `AlbumVisor`'s own equivalent
        // (`GivenNothingPlaying_WhenTheBarIsShown_ThenThereIsNoVisor`) exists,
        // but the screen's had gone missing. `showsAnimation` requires
        // `current != null`, so stopping the queue while the player is open
        // has to take the stage away, not leave it drawing over nothing.
        final container = await playSomething(
          tester,
          mode: AlbumAnimationMode.byYear,
        );
        expect(find.byType(NowPlayingScreen), findsOneWidget);
        expect(find.byType(AlbumStage), findsOneWidget);

        await container.read(audioPlaybackControllerProvider.notifier).stop();
        await settle(tester);

        expect(find.byType(NowPlayingScreen), findsOneWidget);
        expect(find.byType(AlbumStage), findsNothing);
      },
    );

    testWidgets(
      'GivenSomethingPlaying_WhenTheScreenAndTheVisorAreBothShown_ThenTheyShowTheSameMedium',
      (tester) async {
        // Finding 6: nothing previously asserted the visor and the stage
        // agree on which medium is turning, as a pair rather than as two
        // fixtures that happen to use the same one. The bar's own route stays
        // in the tree beneath the pushed `NowPlayingScreen` (Flutter does not
        // remove a covered route until it is popped), so both `AlbumVisor`
        // and `AlbumStage` are reachable from the same pumped tree at once.
        await playSomething(tester, mode: AlbumAnimationMode.byYear);
        expect(find.byType(NowPlayingScreen), findsOneWidget);

        final stageMedium = tester
            .widgetList<AlbumStage>(find.byType(AlbumStage))
            .single
            .medium;
        // The visor draws no `AlbumMedium` of its own to compare against
        // directly, so its label — the same words `AlbumStage._label` uses
        // for the same medium — stands in for it: if the two widgets ever
        // disagreed about which medium is playing, they would announce
        // different labels for the one record on screen.
        final l10n = messages(tester);
        final expectedLabel = switch (stageMedium) {
          AlbumMedium.vinyl => l10n.albumMediumVinyl,
          AlbumMedium.tape => l10n.albumMediumTape,
          AlbumMedium.disc => l10n.albumMediumDisc,
        };

        /// The `Semantics` inside [finder] that actually carries a label —
        /// both `AlbumStage` and `AlbumVisor` wrap their own drawing in one,
        /// returned from their own `build`, so it is a descendant of the
        /// widget, not an ancestor of it.
        String? labelOf(Finder finder) => tester
            .widgetList<Semantics>(
              find.descendant(of: finder, matching: find.byType(Semantics)),
            )
            .map((widget) => widget.properties.label)
            .firstWhere((label) => label != null, orElse: () => null);

        expect(labelOf(find.byType(AlbumStage)), expectedLabel);
        expect(labelOf(find.byType(AlbumVisor)), expectedLabel);
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
  // with real motion, and playback still runs.
  // Finding 11: `_minimumStageSize` is correct defensive code, but cannot
  // trigger at the 1024x640 floor NFR-07 enforces on the real window — the
  // group below proves the path is reachable and behaves the way AF-01
  // (Use Case Specification Document, UC-21) describes, at a surface no
  // owner can actually reach but a test can still lay the screen out at.
  //
  // Pumps `NowPlayingScreen` on its own, over fixed controllers, inside a
  // `SizedBox` — not `pumpShell` resized down: the shell's own navigation
  // cannot lay out at 1024x350 at all, so neither an owner nor `play`'s own
  // tap-through-the-library helper could ever reach a stage this small by
  // way of it, and a `SizedBox` constrains the actual render tree in a way a
  // physical view resize applied to an already-built route did not reliably
  // do (confirmed: the route's own `LayoutBuilder` never re-ran against the
  // new size).
  group('below the stage floor (Finding 11, AF-01)', () {
    Future<void> pumpBelowFloor(WidgetTester tester) async {
      final audioController = _FixedAudioPlaybackController(
        AudioPlaybackState(
          queue: PlaybackQueue(
            tracks: [aFile(uuid: 'kob-1', name: 'So What.flac')],
            kind: QueueKind.album,
            label: 'Kind of Blue',
          ),
          stage: AudioStage.playing,
          status: const PlaybackStatus(isPlaying: true),
        ),
      );
      final animationController = _FixedAlbumAnimationController(
        const AlbumAnimationState(medium: AlbumMedium.vinyl),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioPlaybackControllerProvider.overrideWith(() => audioController),
            albumAnimationControllerProvider.overrideWith(
              () => animationController,
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: const [AlbumPalette.standard]),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            // Short enough that `_reservedForTextAndControls` (260) leaves
            // under `_minimumStageSize` (160) of the height for the stage —
            // well below anything NFR-07 lets the real window reach.
            home: const Center(
              child: SizedBox(
                width: 1024,
                height: 350,
                child: NowPlayingScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
      'GivenASurfaceBelowTheStageFloor_WhenTheFullPlayerOpens_ThenTheStageHides',
      (tester) async {
        await pumpBelowFloor(tester);

        expect(find.byType(NowPlayingScreen), findsOneWidget);
        expect(find.byType(AlbumStage), findsNothing);
      },
    );

    testWidgets(
      'GivenASurfaceBelowTheStageFloor_WhenTheFullPlayerOpens_ThenTheRestStillShowsWithoutOverflowing',
      (tester) async {
        // AF-01: "the application hides the stage and keeps the rest of the
        // player; the screen scrolls to reach the transport controls instead
        // of overflowing." The title and the transport are what "the rest of
        // the player" names — both still have to be reachable, and nothing
        // may have overflowed to get there.
        await pumpBelowFloor(tester);

        // The queue's own label — never the track's title, which this
        // harness's fixed controllers leave unresolved (no catalog behind
        // them) and so falls back to the generic "untitled" word; the label
        // is what proves the rest of the player laid out and read state
        // correctly regardless.
        expect(find.text('Kind of Blue'), findsOneWidget);
        expect(find.byIcon(Icons.pause_circle), findsOneWidget);
        expect(find.byIcon(Icons.skip_next), findsOneWidget);
        // An overflowing `Column`/`Row` throws during layout or paint, which
        // the test binding records rather than letting the widget tree
        // silently clip or crash — reaching here with nothing recorded is
        // what "without overflowing" means for this test.
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('the minimum window', () {
    testWidgets(
      'GivenTheMinimumWindow_WhenTheFullPlayerOpens_ThenTheStageIsStillShown',
      (tester) async {
        await play(
          tester,
          mode: AlbumAnimationMode.byYear,
          surfaceSize: Breakpoint.minimumWindowSize,
        );
        // The album's first play owes an insertion, so the auto-open
        // (Task 7 step 4) already has the player open here — real motion is
        // running underneath it, which is the point of this group.
        expect(find.byType(NowPlayingScreen), findsOneWidget);

        expect(find.byType(AlbumStage), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheMinimumWindow_WhenTheFullPlayerOpens_ThenItStillPlays',
      (tester) async {
        final playing = await play(
          tester,
          mode: AlbumAnimationMode.byYear,
          surfaceSize: Breakpoint.minimumWindowSize,
        );
        expect(find.byType(NowPlayingScreen), findsOneWidget);

        expect(playing.player.opened, hasLength(1));
        expect(find.byIcon(Icons.pause_circle), findsOneWidget);
      },
    );
  });

  // A track is a record too (design §1): the animation belongs to whatever
  // is playing, a single track from the Songs list included.
  group('a single track', () {
    testWidgets(
      'GivenOneTrackPlays_WhenItStarts_ThenTheAnimationShowsAndThePlayerOpens',
      (tester) async {
        // The owner's own report: playing a single track from the Songs
        // list showed no animation and opened no player. The first play of
        // any queue owes an insertion (Task 7 step 4's auto-open), and a
        // track queue is no longer excluded from owing one.
        await play(tester, asTrack: true, mode: AlbumAnimationMode.byYear);

        expect(find.byType(NowPlayingScreen), findsOneWidget);
        expect(find.byType(AlbumStage), findsOneWidget);
      },
    );

    testWidgets(
      'GivenOneTrackPlays_WhenTheOwnerOpensThePlayerManually_ThenItStillPlays',
      (tester) async {
        // The animation turned off, so nothing auto-opens the player and
        // `openPlayer` below is unambiguous: this is what proves the
        // transport still works for a lone track regardless of whether the
        // animation is drawn.
        await play(tester, asTrack: true, mode: AlbumAnimationMode.off);

        await openPlayer(tester);

        expect(find.byIcon(Icons.pause_circle), findsOneWidget);
      },
    );
  });

  // AF-02: the owner goes elsewhere.
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
        await play(tester, mode: AlbumAnimationMode.byYear);
        // The album's first play owes an insertion, so the auto-open
        // (Task 7 step 4) already has the player open here.
        expect(find.byType(NowPlayingScreen), findsOneWidget);
        await tester.tap(find.byTooltip(closeLabel(tester)));
        // Not `pumpAndSettle`: closing the full player leaves the bar on
        // screen, and `AlbumVisor` (Task 8) now spins in it for as long as
        // this record keeps playing — exactly the reason every other wait in
        // this file past the point playback starts already uses [settle].
        // Called twice: one [settle] run is 300ms, exactly the pop route's
        // own transition duration, and a single run leaves the close too
        // close to that edge to reliably land after it finishes.
        await settle(tester);
        await settle(tester);

        // Closed now, so `openPlayer` is unambiguous again: this is a
        // deliberate, manual reopen, not a race with another auto-open.
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
        // nothing else in this test would fail because of it.
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
        // then leave the player the way AF-02 already does, before the next
        // track of the same record starts.
        container
            .read(albumAnimationControllerProvider.notifier)
            .insertionShown();
        await tester.tap(find.byTooltip(closeLabel(tester)));
        await settle(tester);

        await container.read(audioPlaybackControllerProvider.notifier).next();
        await settle(tester);

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

    testWidgets('GivenALoneTrackStarts_WhenItPlays_ThenThePlayerOpensItself', (
      tester,
    ) async {
      // A track is a record too (design §1): the shell's auto-open reads
      // the very same `insertionOwed` edge whichever kind of queue crossed
      // it, so a lone track's first play opens the player exactly as an
      // album's or an artist's already does.
      final gateway = FakeCatalogGateway()
        ..addAudio(
          uuid: 'loose-1',
          title: 'Naima',
          artist: 'John Coltrane',
          year: 2001,
        );
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
          .setAlbumAnimation(AlbumAnimationMode.byYear);

      await container
          .read(audioPlaybackControllerProvider.notifier)
          .playTrack(aFile(uuid: 'loose-1'));
      await settle(tester);

      expect(find.byType(NowPlayingScreen), findsOneWidget);
    });

    testWidgets(
      'GivenALoneTrackPlayedFirst_WhenAnAlbumStarts_ThenThePlayerOpensItselfAgain',
      (tester) async {
        // Before this fix, a lone track never drew a stage at all — nothing
        // showed one for `QueueKind.track` — so nothing ever called
        // `insertionShown()` for it, and `insertionOwed` stuck at `true`
        // through whatever played next (Finding 1's recovery case). Now a
        // lone track is a record like any other: its own insertion is shown
        // and acknowledged the ordinary way, closing the player the way
        // AF-02 already does, so the album that follows crosses a fresh edge
        // of its own rather than finding the flag already stuck `true`.
        final gateway = FakeCatalogGateway()
          ..addAudio(
            uuid: 'loose-1',
            title: 'Naima',
            artist: 'John Coltrane',
            year: 2001,
          )
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
            .setAlbumAnimation(AlbumAnimationMode.byYear);

        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playTrack(aFile(uuid: 'loose-1'));
        await settle(tester);
        expect(find.byType(NowPlayingScreen), findsOneWidget);

        container
            .read(albumAnimationControllerProvider.notifier)
            .insertionShown();
        await tester.tap(find.byTooltip(closeLabel(tester)));
        // Two runs, as `GivenTheOwnerReopensThePlayer...` above already
        // documents: one `settle` run is 300ms, exactly the pop route's own
        // transition duration, and a single run leaves the close too close to
        // that edge to reliably land after it finishes.
        await settle(tester);
        await settle(tester);
        expect(find.byType(NowPlayingScreen), findsNothing);

        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playAlbum(aFile(uuid: 'kob-1'));
        await settle(tester);

        expect(find.byType(NowPlayingScreen), findsOneWidget);
      },
    );

    testWidgets(
      'GivenMotionIsReduced_WhenTheInsertionIsSeated_ThenNothingStaysOwed',
      (tester) async {
        // Finding 1's other half: under reduced motion, `AlbumStage` never
        // calls `onInserted` (`album_stage.dart`'s own guard — nothing
        // "finished playing" when nothing played), so `NowPlayingScreen`'s
        // own acknowledgement is what has to clear the flag instead.
        final container = await playSomething(
          tester,
          mode: AlbumAnimationMode.byYear,
          reduceMotion: true,
        );

        expect(find.byType(NowPlayingScreen), findsOneWidget);
        expect(
          container.read(albumAnimationControllerProvider).insertionOwed,
          isFalse,
        );
      },
    );

    /// Two two-track albums by different artists, both eligible for the
    /// animation, so a test can move from one to the other without the
    /// second's `playAlbum` racing a gateway swap.
    FakeCatalogGateway twoAlbumsGateway() => FakeCatalogGateway()
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
      )
      ..addAudio(
        uuid: 'bt-1',
        title: 'Blue Train',
        artist: 'John Coltrane',
        album: 'Blue Train',
        year: 1957,
        track: 1,
      )
      ..addAudio(
        uuid: 'bt-2',
        title: 'Moment\'s Notice',
        artist: 'John Coltrane',
        album: 'Blue Train',
        year: 1957,
        track: 2,
      );

    /// Signs in over [twoAlbumsGateway] under [mode] and [reduceMotion], and
    /// returns the container without playing anything yet — the two tests
    /// below each play the two albums in their own order.
    Future<ProviderContainer> pumpTwoAlbums(
      WidgetTester tester, {
      required AlbumAnimationMode mode,
      bool reduceMotion = false,
    }) async {
      final container = await tester.pumpShell(
        reduceMotion: reduceMotion,
        extraOverrides: <Override>[
          catalogGatewayProvider.overrideWithValue(twoAlbumsGateway()),
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
      return container;
    }

    testWidgets(
      'GivenThePlayerIsClosedMidInsertion_WhenAnotherAlbumStarts_ThenThePlayerOpensItself',
      (tester) async {
        // Finding 1: closing the route while `AlbumStage`'s insertion is
        // still running disposes the stage before `onInserted` ever fires, so
        // nothing clears `insertionOwed` for the interrupted album. Before
        // the fix this left the flag permanently `true` — `owedIdentity`
        // still pointed at the interrupted album, and a listener keyed on
        // the bare boolean never saw it change — so no later album could ever
        // re-open the player for the rest of the session. Run against the
        // pre-fix `shell_screen.dart` (edge-triggering on `insertionOwed`
        // alone), this test fails: the boolean is `true` both before and
        // after the second album starts, so the `!(previous?.insertionOwed
        // ?? false)` guard never lets the second push through.
        final container = await pumpTwoAlbums(
          tester,
          mode: AlbumAnimationMode.byYear,
        );
        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playAlbum(aFile(uuid: 'kob-1'));
        await settle(tester);
        expect(find.byType(NowPlayingScreen), findsOneWidget);

        // Well short of `AlbumStage.insertionDuration` (4.4s): the case is
        // still on its way in, not seated, when the route closes.
        await tester.pump(const Duration(milliseconds: 700));
        await tester.tap(find.byTooltip(closeLabel(tester)));
        // Two runs, as `GivenTheOwnerReopensThePlayer...` above already
        // documents: one `settle` run is 300ms, exactly the pop route's own
        // transition duration, and a single run leaves the close too close
        // to that edge to reliably land after it finishes.
        await settle(tester);
        await settle(tester);
        expect(find.byType(NowPlayingScreen), findsNothing);

        // A different record — not the next track of the one that was
        // interrupted, which correctly owes nothing more.
        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playAlbum(aFile(uuid: 'bt-1'));
        await settle(tester);

        expect(find.byType(NowPlayingScreen), findsOneWidget);
      },
    );

    testWidgets(
      'GivenThePlayerIsAlreadyOpen_WhenAnotherAlbumStarts_ThenOnlyOneScreenShows',
      (tester) async {
        // Finding 3: `shell_screen.dart`'s own push was unconditional, so an
        // album started while the auto-opened player is still on screen
        // stacked a second `NowPlayingScreen` route on top of the first —
        // the owner would then have to close it twice, and the buried
        // stage's tickers would keep running underneath. Starting a second,
        // different album while the first's player is still open must still
        // leave exactly one screen on the stack.
        final container = await pumpTwoAlbums(
          tester,
          mode: AlbumAnimationMode.byYear,
        );
        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playAlbum(aFile(uuid: 'kob-1'));
        await settle(tester);
        expect(find.byType(NowPlayingScreen), findsOneWidget);
        // Let the first insertion finish so the second album's own insertion
        // is a clean, independent owed-insertion edge.
        await tester.pump(AlbumStage.insertionDuration);
        await settle(tester);

        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playAlbum(aFile(uuid: 'bt-1'));
        await settle(tester);

        expect(find.byType(NowPlayingScreen), findsOneWidget);
      },
    );

    testWidgets(
      'GivenMotionIsReduced_WhenTheAlbumChangesWithThePlayerOpen_ThenNothingStaysOwed',
      (tester) async {
        // Finding 5: reduced motion means `AlbumStage` never calls
        // `onInserted` for *any* insertion, including one that becomes newly
        // owed while the stage stays mounted across an album change — the
        // player already open, a different record starting under it. The
        // only thing that can clear that owed insertion is
        // `NowPlayingScreen`'s own post-frame acknowledgement, and until now
        // nothing exercised it past the screen's first build.
        final container = await pumpTwoAlbums(
          tester,
          mode: AlbumAnimationMode.byYear,
          reduceMotion: true,
        );
        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playAlbum(aFile(uuid: 'kob-1'));
        await settle(tester);
        expect(find.byType(NowPlayingScreen), findsOneWidget);
        expect(
          container.read(albumAnimationControllerProvider).insertionOwed,
          isFalse,
        );

        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playAlbum(aFile(uuid: 'bt-1'));
        await settle(tester);

        expect(find.byType(NowPlayingScreen), findsOneWidget);
        expect(
          container.read(albumAnimationControllerProvider).insertionOwed,
          isFalse,
        );
      },
    );

    testWidgets(
      'GivenMotionIsNotReduced_WhenTheInsertionPlaysThrough_ThenNoExceptionIsThrown',
      (tester) async {
        // Finding 3: the build-phase question Task 6 left open is about
        // `AlbumStage`'s own status listener firing from a genuine animation
        // completion — a path only reachable with real motion running, which
        // reduced-motion coverage elsewhere in this file cannot exercise.
        final container = await playSomething(
          tester,
          mode: AlbumAnimationMode.byYear,
        );
        expect(find.byType(NowPlayingScreen), findsOneWidget);

        // Jumps the insertion's controller to completed in one step — the
        // test binding's clock is simulated, so this does not take 4.4 real
        // seconds — which is what drives `AlbumStage`'s status listener to
        // call `onInserted` (wired to `insertionShown()`) from a real
        // animation frame rather than from a build.
        await tester.pump(AlbumStage.insertionDuration);
        await settle(tester);

        expect(tester.takeException(), isNull);
        expect(
          container.read(albumAnimationControllerProvider).insertionOwed,
          isFalse,
        );
      },
    );
  });

  group('the case names the record (UC-46, FR-CT-13)', () {
    testWidgets(
      'GivenAGuestTrack_WhenThePlayerIsOpen_ThenTheCaseNamesTheAlbumArtist',
      (tester) async {
        // The case is the record's sleeve, so it is typeset with whose record
        // it is. Typeset with the current track's performer instead, a
        // compilation would re-letter its own case between two tracks of one
        // sleeve, and a guest appearance would put the guest's name on the
        // host's record.
        final catalog = FakeCatalogGateway()
          ..addAudio(
            uuid: 'comp-1',
            title: 'One',
            artist: 'First Performer',
            albumArtist: 'Various Artists',
            album: "Now That's Music",
            year: 1959,
            track: 1,
          )
          ..addAudio(
            uuid: 'comp-2',
            title: 'Two',
            artist: 'Second Performer',
            albumArtist: 'Various Artists',
            album: "Now That's Music",
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
            .setAlbumAnimation(AlbumAnimationMode.byYear);

        // The second track, whose performer is not the record's artist: it is
        // where the two tags disagree, so it is the only track that can tell
        // which of them the case was typeset with.
        await container
            .read(audioPlaybackControllerProvider.notifier)
            .playTrack(aFile(uuid: 'comp-2'));
        await settle(tester);

        // The insertion opens the player itself; where it has not, it is
        // opened from the bar the way an owner would.
        if (find.byType(NowPlayingScreen).evaluate().isEmpty) {
          await tester.tap(find.byIcon(Icons.expand_less));
          await settle(tester);
        }

        // Every stage in the tree, not one of them: the pushed route and the
        // bar's own route beneath it can both be mounted mid-transition, and
        // a case typeset with the performer on either of them is the defect
        // this pins.
        final stages = tester.widgetList<AlbumStage>(find.byType(AlbumStage));
        expect(stages, isNotEmpty);
        expect(
          stages.map((stage) => stage.artist).toSet(),
          {'Various Artists'},
        );
        expect(stages.map((stage) => stage.title).toSet(), {
          "Now That's Music",
        });
      },
    );
  });
}

/// An [AudioPlaybackController] that answers with a fixed state — mirrors
/// `album_visor_test.dart`'s own fixture, used here for Finding 11's
/// below-the-floor group, which needs a stage-sized surface `pumpShell`'s
/// own real navigation cannot lay out at all.
class _FixedAudioPlaybackController extends AudioPlaybackController {
  _FixedAudioPlaybackController(this._state);

  final AudioPlaybackState _state;

  @override
  AudioPlaybackState build() => _state;


}

/// An [AlbumAnimationController] that answers with a fixed state — mirrors
/// `album_visor_test.dart`'s own fixture.
class _FixedAlbumAnimationController extends AlbumAnimationController {
  _FixedAlbumAnimationController(this._state);

  final AlbumAnimationState _state;

  @override
  AlbumAnimationState build() => _state;

}
