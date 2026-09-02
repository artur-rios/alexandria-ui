import 'dart:math';

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/domain/view_layout.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_run.dart';
import 'package:alexandria_ui/features/playback/domain/playback_queue.dart';
import 'package:alexandria_ui/features/playback/presentation/music_library_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/async_state_view.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Riverpod 3 moved `Override` out of the main export surface; see
// test/support/test_container.dart for the same import.
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_media_player.dart';
import '../../../support/fake_playback.dart';
import '../../../support/shell_harness.dart';

/// Browsing the music library (UC-46, FR-CT-13).
void main() {
  AppLocalizations localizations(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// Signs in, lands on the shell, and opens the music area over [gateway].
  ///
  /// Returns the container so a test that needs to drive something else
  /// afterwards — an index run finishing, for instance — has a handle on it.
  Future<ProviderContainer> openMusic(
    WidgetTester tester, {
    required FakeCatalogGateway gateway,
    List<Override> extraOverrides = const [],
  }) async {
    final container = await tester.pumpShell(
      extraOverrides: [
        catalogGatewayProvider.overrideWithValue(gateway),
        ...extraOverrides,
      ],
    );

    container.read(shellControllerProvider.notifier).go(ShellDestination.music);
    await tester.pumpAndSettle();

    return container;
  }

  /// Two artists, three tracks, and file names that would be unmistakable if
  /// any of them ever reached the screen.
  FakeCatalogGateway libraryOfThree() => FakeCatalogGateway()
    ..addAudio(
      uuid: '1',
      name: 'DISKNAME-01.flac',
      title: 'Airbag',
      artist: 'Radiohead',
      album: 'OK',
      track: 1,
    )
    ..addAudio(
      uuid: '2',
      name: 'DISKNAME-02.flac',
      title: 'Karma',
      artist: 'Radiohead',
      album: 'OK',
      track: 2,
    )
    ..addAudio(
      uuid: '3',
      name: 'DISKNAME-03.flac',
      title: 'Roads',
      artist: 'Portishead',
      album: 'Dummy',
      track: 1,
    );

  group('the views (main flow step 2)', () {
    testWidgets('GivenTheMusicArea_WhenItOpens_ThenItListsTheArtists', (
      tester,
    ) async {
      await openMusic(tester, gateway: libraryOfThree());

      expect(find.text('Radiohead'), findsOneWidget);
      expect(find.text('Portishead'), findsOneWidget);
    });

    testWidgets('GivenTheMusicArea_WhenItOpens_ThenNoFileNameIsShown', (
      tester,
    ) async {
      // FR-CT-13, asserted the only way that means anything: a name that
      // would be unmistakable if the view ever fell back to it.
      await openMusic(tester, gateway: libraryOfThree());

      expect(find.textContaining('DISKNAME'), findsNothing);
    });

    testWidgets(
      'GivenTheArtistsView_WhenAlbumsAreChosen_ThenTheAlbumsAreListed',
      (tester) async {
        await openMusic(tester, gateway: libraryOfThree());
        final l10n = localizations(tester);

        await tester.tap(find.text(l10n.musicViewAlbums));
        await tester.pumpAndSettle();

        expect(find.textContaining('Dummy'), findsOneWidget);
        expect(find.textContaining('OK'), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheArtistsView_WhenSongsAreChosen_ThenEveryTrackIsListed',
      (tester) async {
        await openMusic(tester, gateway: libraryOfThree());
        final l10n = localizations(tester);

        await tester.tap(find.text(l10n.musicViewSongs));
        await tester.pumpAndSettle();

        for (final title in ['Airbag', 'Karma', 'Roads']) {
          expect(find.textContaining(title), findsOneWidget, reason: title);
        }
      },
    );
  });

  group('drilling in (main flow step 3)', () {
    testWidgets('GivenTheArtists_WhenOneIsOpened_ThenOnlyTheirAlbumsAreShown', (
      tester,
    ) async {
      await openMusic(tester, gateway: libraryOfThree());

      await tester.tap(find.text('Radiohead'));
      await tester.pumpAndSettle();

      expect(find.textContaining('OK'), findsOneWidget);
      expect(find.textContaining('Dummy'), findsNothing);
    });

    testWidgets(
      'GivenAnArtistsAlbums_WhenOneIsOpened_ThenItsTracksComeInTrackOrder',
      (tester) async {
        await openMusic(tester, gateway: libraryOfThree());

        await tester.tap(find.text('Radiohead'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('OK'));
        await tester.pumpAndSettle();

        final airbag = tester.getTopLeft(find.textContaining('Airbag')).dy;
        final karma = tester.getTopLeft(find.textContaining('Karma')).dy;
        expect(airbag, lessThan(karma));
      },
    );

    testWidgets(
      'GivenAnAlbumOpenedFromAlbums_WhenItIsShown_ThenTheCrumbNamesItsArtist',
      (tester) async {
        // Whose record it is, is a fact about the record rather than about
        // how it was reached. Reached from Albums no artist was drilled
        // through, and the rows inside an ordinary single-artist record name
        // no performer of their own (`music_rows.dart`) — so without this
        // crumb the artist appears nowhere on the screen.
        await openMusic(tester, gateway: libraryOfThree());
        final l10n = localizations(tester);

        await tester.tap(find.text(l10n.musicViewAlbums));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('OK'));
        await tester.pumpAndSettle();

        // The track list is open, so the albums list's own row subtitle is
        // gone: this can only be the crumb.
        expect(find.textContaining('Airbag'), findsOneWidget);
        expect(find.text('Radiohead'), findsOneWidget);
        // Plain text, not a control: no artist's list of albums was visited
        // on this path, so there is nothing to go back to.
        expect(
          find.ancestor(
            of: find.text('Radiohead'),
            matching: find.byType(TextButton),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'GivenAnAlbumOpenedFromAnArtist_WhenTheArtistCrumbIsTapped_ThenTheirAlbumsReturn',
      (tester) async {
        // The other path keeps the control it always had: this crumb was
        // drilled through, so it leads back to where the owner has been.
        await openMusic(tester, gateway: libraryOfThree());

        await tester.tap(find.text('Radiohead'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('OK'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.ancestor(
            of: find.text('Radiohead'),
            matching: find.byType(TextButton),
          ),
        );
        await tester.pumpAndSettle();

        // Back on that artist's albums, not at the top of the view.
        expect(find.textContaining('OK'), findsOneWidget);
        expect(find.text('Portishead'), findsNothing);
      },
    );

    testWidgets(
      'GivenAnOpenAlbum_WhenTheRootCrumbIsTapped_ThenTheArtistsReturn',
      (tester) async {
        await openMusic(tester, gateway: libraryOfThree());
        final l10n = localizations(tester);

        await tester.tap(find.text('Radiohead'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('OK'));
        await tester.pumpAndSettle();
        // Scoped to the area: the root crumb reads the same word the
        // breadcrumb always has ("Music library"), which is deliberately
        // distinct from the navigation panel's own "Music" label — but
        // scoping the finder is what makes this test robust to either
        // string, rather than depending on that distinction holding.
        await tester.tap(
          find.descendant(
            of: find.byType(MusicLibraryView),
            matching: find.text(l10n.musicBreadcrumbRoot),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Portishead'), findsOneWidget);
      },
    );
  });

  group('what carries no tags (AF-01)', () {
    testWidgets(
      'GivenAnUntaggedFile_WhenTheArtistsAreListed_ThenItIsUnderUnknownArtistLast',
      (tester) async {
        final gateway = libraryOfThree()
          ..addAudio(uuid: '4', name: 'DISKNAME-04.flac');
        await openMusic(tester, gateway: gateway);
        final l10n = localizations(tester);

        final unknown = tester
            .getTopLeft(find.text(l10n.musicUnknownArtist))
            .dy;
        expect(
          unknown,
          greaterThan(tester.getTopLeft(find.text('Radiohead')).dy),
        );
      },
    );

    testWidgets(
      'GivenAnUntitledTrack_WhenTheSongsAreListed_ThenItReadsUnknownTitle',
      (tester) async {
        final gateway = libraryOfThree()
          ..addAudio(uuid: '4', name: 'DISKNAME-04.flac');
        await openMusic(tester, gateway: gateway);
        final l10n = localizations(tester);

        await tester.tap(find.text(l10n.musicViewSongs));
        await tester.pumpAndSettle();

        expect(find.textContaining(l10n.musicUnknownTitle), findsOneWidget);
        expect(find.textContaining('DISKNAME'), findsNothing);
      },
    );
  });

  group('loading and emptiness', () {
    testWidgets(
      'GivenTheAreaHasLoaded_WhenItIsShown_ThenNoProgressLineAppears',
      (tester) async {
        // The library now resolves in one gateway call, so there is nothing
        // "so far" to report — the progress line this area used to show
        // while metadata was still arriving one file at a time is gone. Its
        // exact wording ("Reading metadata: N of M") is what a regression
        // back to it would look like on screen; a track's own number (shown
        // as "1", "2" in the album view) is not this, so the check is on the
        // phrase's shape rather than on digits appearing at all.
        await openMusic(tester, gateway: libraryOfThree());

        expect(find.textContaining(RegExp(r'\d+ of \d+')), findsNothing);
      },
    );

    testWidgets(
      'GivenNoAudioFiles_WhenTheAreaIsShown_ThenItSaysTheLibraryIsEmpty',
      (tester) async {
        await openMusic(tester, gateway: FakeCatalogGateway());
        final l10n = localizations(tester);

        expect(find.text(l10n.musicEmpty), findsOneWidget);
      },
    );
  });

  group('the listing fails', () {
    testWidgets(
      'GivenTheListingFails_WhenTheAreaIsShown_ThenAMessageAndRetryAppear',
      (tester) async {
        // The one failure the domain actually models must never read as
        // "nothing is catalogued yet" — that would be a lie, and every other
        // type shows a failure view with a retry for exactly this.
        final gateway = FakeCatalogGateway()..failListing();
        await openMusic(tester, gateway: gateway);
        final l10n = localizations(tester);

        expect(find.byType(ShellFailureView), findsOneWidget);
        expect(find.text(l10n.retry), findsOneWidget);
        expect(find.text(l10n.musicEmpty), findsNothing);
      },
    );
  });

  group(
    'a run finishes while the area is open (bug: catalog never refreshes)',
    () {
      // The reported bug: an owner indexes a folder full of music, the run
      // reports done, and the Music tab keeps showing the empty library it
      // resolved before the run — nothing tells it the catalog changed.
      // `musicLibraryProvider` is watched here (the area is open) precisely
      // because that is what distinguishes this from a listing tab, which
      // re-lists on every navigation anyway.
      testWidgets(
        'GivenTheMusicAreaIsOpenAndEmpty_WhenAnIndexRunFinishes_ThenTheNewTracksAppear',
        (tester) async {
          final catalogGateway = FakeCatalogGateway();
          final indexGateway = FakeIndexGateway();

          // No run outstanding yet at launch, so the shell's activity strip has
          // nothing to animate and sign-in's own `pumpAndSettle` can still
          // settle.
          final container = await openMusic(
            tester,
            gateway: catalogGateway,
            extraOverrides: [
              indexGatewayProvider.overrideWithValue(indexGateway),
              // Long enough that no timer fires during the test: the run
              // ending is observed by calling refresh directly, the same way
              // the poller itself would call it.
              runPollIntervalProvider.overrideWithValue(
                const Duration(hours: 1),
              ),
            ],
          );
          final l10n = localizations(tester);

          // Before the run: nothing catalogued yet, so the area is empty.
          expect(find.text(l10n.musicEmpty), findsOneWidget);

          // The folder starts being indexed — a run is now outstanding.
          indexGateway.activeRunsOutcome = ActiveRunsOutcome.read(
            runs: [
              IndexRun(
                runId: indexGateway.runId,
                root: '/home/owner/music',
                status: IndexRunStatus.running,
              ),
            ],
          );
          await container.read(activeRunsControllerProvider.notifier).refresh();
          // Pumped rather than settled: the running indicator in the shell's
          // activity strip is an animation that never idles on its own.
          await tester.pump();

          // The run finishes and leaves audio behind in the catalog — the
          // scan itself is what added it, not this test reaching around it.
          catalogGateway.addAudio(
            uuid: '1',
            title: 'Airbag',
            artist: 'Radiohead',
          );
          indexGateway.activeRunsOutcome = const ActiveRunsOutcome.read(
            runs: [],
          );

          // What the poller does on its own schedule, driven directly rather
          // than waiting out a timer.
          await container.read(activeRunsControllerProvider.notifier).refresh();
          // Two bounded pumps rather than `pumpAndSettle`: the outcome banner
          // this transition also raises clears itself on a timer that would
          // otherwise never elapse. One frame to flush the refetch's Future,
          // one more so the rebuilt list actually paints.
          await tester.pump();
          await tester.pump();

          expect(find.text(l10n.musicEmpty), findsNothing);
          expect(find.text('Radiohead'), findsOneWidget);
        },
      );
    },
  );

  group('rows or tiles (FR-CT-03)', () {
    testWidgets(
      'GivenTheMusicArea_WhenTilesAreChosen_ThenTheListBecomesAGrid',
      (tester) async {
        final container = await openMusic(tester, gateway: libraryOfThree());
        final l10n = localizations(tester);

        await tester.tap(find.byIcon(Icons.grid_view_outlined));
        await tester.pumpAndSettle();

        expect(find.byType(GridView), findsOneWidget);
        expect(container.read(musicLayoutControllerProvider), ViewLayout.grid);
        // The same artists, drawn differently — a layout switch is never a
        // change of what is on screen.
        expect(find.text('Radiohead'), findsOneWidget);
        expect(find.text(l10n.musicViewArtists), findsOneWidget);
      },
    );

    testWidgets('GivenTilesAreChosen_WhenTheOwnerDrillsIn_ThenTheTilesStay', (
      tester,
    ) async {
      // One choice for the area, not one per level: a layout that reset on
      // the way into a record would be a setting re-made at every step.
      await openMusic(tester, gateway: libraryOfThree());

      await tester.tap(find.byIcon(Icons.grid_view_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Radiohead'));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });
  });

  group('playing everything in an order nobody chose (FR-PL-06)', () {
    testWidgets(
      'GivenTheMusicArea_WhenShuffleEverythingIsPressed_ThenTheWholeLibraryQueues',
      (tester) async {
        // An owner who wants something to play is not browsing: making them
        // pick a record first would be asking the question they opened this
        // to avoid.
        final container = await openMusic(
          tester,
          gateway: libraryOfThree(),
          extraOverrides: [
            audioPlayerProvider.overrideWithValue(FakeMediaPlayer()),
            playbackSourceGatewayProvider.overrideWithValue(
              FakePlaybackSourceGateway(),
            ),
            playbackPositionsProvider.overrideWithValue(
              FakePlaybackPositionStore(),
            ),
            // Seeded, so the order is a fact rather than a coin toss.
            shuffleRandomProvider.overrideWithValue(Random(7)),
          ],
        );
        final l10n = localizations(tester);

        // Narrowed by its tooltip: every artist row carries a shuffle of its
        // own, so the glyph alone matches a screenful of buttons.
        await tester.tap(
          find.ancestor(
            of: find.byTooltip(l10n.audioShuffleAll),
            matching: find.byType(IconButton),
          ),
        );
        // Bounded pumps rather than `pumpAndSettle`: something is playing
        // now, and the player's bars never idle.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final queue = container.read(audioPlaybackControllerProvider).queue;
        expect(queue.kind, QueueKind.playlist);
        expect(queue.label, l10n.audioShuffleAllLabel);
        expect(queue.tracks.map((file) => file.uuid), ['1', '3', '2']);
      },
    );
  });
}
