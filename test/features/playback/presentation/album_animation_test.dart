import 'dart:async';

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/catalog/presentation/file_details_view.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:alexandria_ui/features/playback/presentation/album_animation.dart';
import 'package:alexandria_ui/features/playback/presentation/album_player_screen.dart';
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

/// The album playback animation (UC-21, FR-PL-07, BR-21).
void main() {
  final blue1 = aFile(uuid: 'blue-1', name: 'So What.flac');
  final blue2 = aFile(uuid: 'blue-2', name: 'Blue in Green.flac');

  /// Signs in and plays [file], as an album unless [asTrack] says otherwise.
  Future<({ProviderContainer container, FakeMediaPlayer player})> play(
    WidgetTester tester, {
    bool asTrack = false,
    String year = '1959',
    Size surfaceSize = const Size(1440, 1000),
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final catalog = FakeCatalogGateway(
      listings: {
        LibraryType.audio: CatalogListing.loaded(files: [blue1, blue2]),
      },
    );
    for (final file in [blue1, blue2]) {
      catalog.details[file.uuid] = FileDetailsOutcome.read(
        details: FileDetails(
          file: file,
          metadata: {
            'album': 'Kind of Blue',
            'artist': 'Miles Davis',
            'year': year,
          },
        ),
      );
    }

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

    // Opens the details dialog directly rather than reaching it through a
    // listing: UC-46 gave audio its own browsing area (Task 4), whose rows
    // play a track or an album on tap rather than opening this dialog, so
    // this is how a test now reaches the play buttons it drives.
    final context = tester.element(find.byType(ShellScreen));
    container.read(openFileProvider.notifier).open(blue1.uuid);
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => const FileDetailsView(),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    await tester.tap(
      find.text(asTrack ? l10n.audioPlay : l10n.audioPlayAlbum).last,
    );
    await tester.pumpAndSettle();

    return (container: container, player: player);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// Pumps a few frames without waiting for the tree to settle.
  ///
  /// The animation repeats for as long as audio plays, so `pumpAndSettle`
  /// never returns once the medium is on screen — which is the point of it.
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

  group('which medium is shown', () {
    test('GivenAnAlbumFromTheVinylEra_WhenItPlays_ThenItIsARecord', () {
      expect(mediumForYear(1959), AlbumMedium.vinyl);
      expect(mediumForYear(1984), AlbumMedium.vinyl);
    });

    test('GivenAnAlbumFromTheCassetteEra_WhenItPlays_ThenItIsATape', () {
      expect(mediumForYear(1985), AlbumMedium.tape);
      expect(mediumForYear(1991), AlbumMedium.tape);
    });

    test('GivenAnAlbumFromTheDiscEra_WhenItPlays_ThenItIsADisc', () {
      expect(mediumForYear(1992), AlbumMedium.disc);
      expect(mediumForYear(2026), AlbumMedium.disc);
    });

    // A medium that changed between two plays of the same record would read
    // as a bug.
    test('GivenNoYear_WhenItPlays_ThenItIsADisc', () {
      expect(mediumForYear(null), AlbumMedium.disc);
    });
  });

  group('the main flow', () {
    // Steps 1 and 2.
    testWidgets(
      'GivenAnAlbumPlays_WhenTheFullPlayerOpens_ThenTheMediumIsShown',
      (tester) async {
        await play(tester);

        await openPlayer(tester);

        expect(find.byType(AlbumAnimation), findsOneWidget);
      },
    );

    testWidgets('GivenAnAlbumFrom1959_WhenTheFullPlayerOpens_ThenItIsARecord', (
      tester,
    ) async {
      await play(tester);
      await openPlayer(tester);

      expect(
        tester.widget<AlbumAnimation>(find.byType(AlbumAnimation)).medium,
        AlbumMedium.vinyl,
      );
    });

    testWidgets('GivenAnAlbumFrom2001_WhenTheFullPlayerOpens_ThenItIsADisc', (
      tester,
    ) async {
      await play(tester, year: '2001');
      await openPlayer(tester);

      expect(
        tester.widget<AlbumAnimation>(find.byType(AlbumAnimation)).medium,
        AlbumMedium.disc,
      );
    });

    // Step 3: it turns while audio plays.
    testWidgets('GivenAudioIsPlaying_WhenTheMediumIsShown_ThenItTurns', (
      tester,
    ) async {
      final playing = await play(tester);
      playing.player.reportPosition(const Duration(seconds: 2));
      await settle(tester);
      await openPlayer(tester);

      expect(
        tester.widget<AlbumAnimation>(find.byType(AlbumAnimation)).isPlaying,
        isTrue,
      );
      // Scoped: the dialog has a transition of its own, and it is not this.
      expect(
        find.descendant(
          of: find.byType(AlbumAnimation),
          matching: find.byType(RotationTransition),
        ),
        findsOneWidget,
      );
    });

    // Steps 4 and 5: the motion stops with the audio and continues with it.
    testWidgets('GivenPlaybackIsPaused_WhenTheMediumIsShown_ThenItHolds', (
      tester,
    ) async {
      final playing = await play(tester);
      playing.player.reportPosition(const Duration(seconds: 2));
      await settle(tester);
      await openPlayer(tester);

      await tester.tap(find.byIcon(Icons.pause_circle));
      await settle(tester);

      expect(
        tester.widget<AlbumAnimation>(find.byType(AlbumAnimation)).isPlaying,
        isFalse,
      );
    });

    testWidgets('GivenPausedPlayback_WhenItResumes_ThenTheMotionContinues', (
      tester,
    ) async {
      final playing = await play(tester);
      playing.player.reportPosition(const Duration(seconds: 2));
      await settle(tester);
      await openPlayer(tester);

      await tester.tap(find.byIcon(Icons.pause_circle));
      await settle(tester);
      await tester.tap(find.byIcon(Icons.play_circle));
      await settle(tester);

      expect(
        tester.widget<AlbumAnimation>(find.byType(AlbumAnimation)).isPlaying,
        isTrue,
      );
    });

    // Step 6: the queue ends and the animation ends with it.
    testWidgets('GivenTheQueueEnds_WhenPlaybackStops_ThenTheAnimationIsGone', (
      tester,
    ) async {
      final playing = await play(tester);
      await openPlayer(tester);

      await tester.tap(find.text(messages(tester).preferencesClose));
      await settle(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(PlaybackBar),
          matching: find.byIcon(Icons.stop),
        ),
      );
      await settle(tester);

      // Nothing is playing, so there is no full player to open and nothing
      // turning anywhere.
      expect(find.byType(AlbumAnimation), findsNothing);
      expect(
        find.descendant(
          of: find.byType(PlaybackBar),
          matching: find.byIcon(Icons.expand_less),
        ),
        findsNothing,
      );
      expect(playing.player.stopCount, 1);
    });
  });

  // AF-01: the window is too small.
  group('a window with no room for it', () {
    testWidgets(
      'GivenTheMinimumWindow_WhenTheFullPlayerOpens_ThenItIsCompact',
      (tester) async {
        await play(tester, surfaceSize: const Size(1024, 700));

        await openPlayer(tester);

        expect(find.byType(AlbumAnimation), findsNothing);
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

        expect(find.byType(AlbumAnimation), findsNothing);
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
          matching: find.text('So What.flac'),
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

        expect(find.byType(AlbumAnimation), findsOneWidget);
      },
    );
  });

  // AF-04: the system asked for reduced motion.
  group('reduced motion', () {
    testWidgets('GivenReducedMotion_WhenTheMediumIsShown_ThenItDoesNotTurn', (
      tester,
    ) async {
      // Set on the platform rather than on a MediaQuery of the test's own, so
      // what is exercised is the path the running application takes.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await play(tester);
      await openPlayer(tester);

      // The medium is still shown, on its player, and only the motion goes.
      expect(find.byType(AlbumAnimation), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlbumAnimation),
          matching: find.byType(RotationTransition),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'GivenReducedMotion_WhenTheMediumIsShown_ThenPlaybackIsUnaffected',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );

        final playing = await play(tester);
        await openPlayer(tester);

        expect(playing.player.opened, hasLength(1));
        expect(playing.player.stopCount, 0);
      },
    );
  });

  group('themes and languages', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheFullPlayerOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await play(tester, themeMode: themeMode);
          await openPlayer(tester);

          expect(
            Theme.of(tester.element(find.byType(AlbumPlayerScreen))).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheFullPlayerOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          await play(tester, locale: locale);
          await openPlayer(tester);

          expect(
            find.textContaining(
              RegExp('(audio|album)[A-Z]'),
              findRichText: true,
            ),
            findsNothing,
          );
        },
      );
    }
  });
}
