import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/playback/application/audio_playback_controller.dart';
import 'package:alexandria_ui/features/playback/presentation/album_player_screen.dart';
import 'package:alexandria_ui/features/playback/presentation/album_stage.dart';
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
/// Split out of what was `album_animation_test.dart`: that file's coverage
/// of `AlbumAnimation` itself moved into Task 5's own
/// `album_stage_test.dart`, but these groups were never about that widget —
/// they are about what this screen does when there is no room for a medium
/// (AF-01), when the queue is a single track (AF-02), about leaving and
/// returning to the player (AF-03), and about the screen never leaking a raw
/// file name onto the page (FR-CT-13). `AlbumPlayerScreen` is replaced
/// wholesale by `now_playing_screen.dart` in a later task; until then, this
/// is what keeps it covered.
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

  /// Pumps a few frames without waiting for the tree to settle.
  ///
  /// The stage repeats for as long as audio plays, so `pumpAndSettle` never
  /// returns once the medium is on screen — which is the point of it.
  Future<void> settle(WidgetTester tester) async {
    for (var frame = 0; frame < 4; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Opens the full player from the bar (main flow step 2).
  Future<void> openPlayer(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(PlaybackBar),
        matching: find.byIcon(Icons.expand_less),
      ),
    );
    await settle(tester);
  }

  // AF-01: the window is too small.
  group('a window with no room for it', () {
    testWidgets(
      'GivenTheMinimumWindow_WhenTheFullPlayerOpens_ThenItIsCompact',
      (tester) async {
        await play(tester, surfaceSize: const Size(1024, 700));

        await openPlayer(tester);

        expect(find.byType(AlbumStage), findsNothing);
      },
    );

    // Playback is unaffected.
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

      await tester.tap(find.text(messages(tester).preferencesClose));
      await settle(tester);

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
        await tester.tap(find.text(messages(tester).preferencesClose));
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
          of: find.byType(AlbumPlayerScreen),
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
            of: find.byType(AlbumPlayerScreen),
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
            of: find.byType(AlbumPlayerScreen),
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
            of: find.byType(AlbumPlayerScreen),
            matching: find.text('Airbag'),
          ),
          findsOneWidget,
        );
        expectAbsent(tester, 'DISKNAME');
      },
    );
  });
}
