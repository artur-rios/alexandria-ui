import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/playback/presentation/music_library_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/async_state_view.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/shell_harness.dart';

/// Browsing the music library (UC-46, FR-CT-13).
void main() {
  AppLocalizations localizations(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// Signs in, lands on the shell, and opens the music area over [gateway].
  Future<void> openMusic(
    WidgetTester tester, {
    required FakeCatalogGateway gateway,
  }) async {
    final container = await tester.pumpShell(
      extraOverrides: [catalogGatewayProvider.overrideWithValue(gateway)],
    );

    container.read(shellControllerProvider.notifier).go(ShellDestination.music);
    await tester.pumpAndSettle();
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
}
