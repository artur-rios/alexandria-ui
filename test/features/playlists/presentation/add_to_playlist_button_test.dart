import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist.dart';
import 'package:alexandria_ui/features/playlists/presentation/add_to_playlist_button.dart';
import 'package:alexandria_ui/features/playlists/presentation/playlists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_playlist_gateway.dart';

/// [AddToPlaylistButton]'s own behaviour, apart from any one screen that
/// embeds it (Task 5).
///
/// Album- and artist-order coverage lives here at the widget's own level —
/// [fileUuids] sent exactly as given, in one call — and again end to end from
/// `MusicGroupList` in `music_rows_test.dart`, which is what proves the two
/// agree. The track-menu and now-playing entry points are each covered where
/// they live, in `music_rows_test.dart` and `now_playing_screen_test.dart`.
void main() {
  const jazz = Playlist(uuid: 'p-1', name: 'Jazz');

  /// A container signed in, with [gateway] behind the playlists it lists.
  ProviderContainer buildContainer(FakePlaylistGateway gateway) {
    final container = ProviderContainer(
      overrides: [playlistGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);

    return container;
  }

  /// Pumps [child] over [container] inside a real `MaterialApp`, so a
  /// `PopupMenuButton`'s overlay and `PlaylistsScreen.show`'s pushed route
  /// both have a `Navigator` to work with.
  Future<void> pumpButton(
    WidgetTester tester,
    ProviderContainer container,
    Widget child,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Center(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('a whole album or artist (entry point 2, BR-02)', () {
    testWidgets(
      'GivenSeveralTracks_WhenAPlaylistIsChosen_ThenTheyAreAllSentInOrderInOneCall',
      (tester) async {
        final gateway = FakePlaylistGateway(playlists: [jazz]);
        final container = buildContainer(gateway);

        await pumpButton(
          tester,
          container,
          const AddToPlaylistButton(fileUuids: ['a1', 'a2', 'a3']),
        );

        await tester.tap(find.byIcon(Icons.playlist_add));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Jazz'));
        await tester.pumpAndSettle();

        // One call for the whole batch, not one per track — an album either
        // enters the playlist whole or not at all.
        expect(gateway.entriesAdded, hasLength(1));
        expect(gateway.entriesAdded.single.uuid, 'p-1');
        expect(gateway.entriesAdded.single.fileUuids, ['a1', 'a2', 'a3']);
      },
    );

    testWidgets(
      'GivenTheSameFileTwiceInOneBatch_WhenSent_ThenTheDuplicateReachesTheCoreIntact',
      (tester) async {
        // A batch can itself repeat a file — an album's own tags could list
        // one twice, or a caller could hand this widget the same uuid more
        // than once. BR-02 says the core owns that decision; a `.toSet()`
        // slipped into `_addTo` or `PlaylistsForm.addEntries` would silently
        // take it instead, and every other fixture in this file uses
        // distinct uuids, so nothing else here would catch that regression.
        final gateway = FakePlaylistGateway(playlists: [jazz]);
        final container = buildContainer(gateway);

        await pumpButton(
          tester,
          container,
          const AddToPlaylistButton(fileUuids: ['a1', 'a1', 'a2']),
        );

        await tester.tap(find.byIcon(Icons.playlist_add));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Jazz'));
        await tester.pumpAndSettle();

        expect(gateway.entriesAdded, hasLength(1));
        expect(gateway.entriesAdded.single.fileUuids, ['a1', 'a1', 'a2']);
      },
    );
  });

  group('a track already in the playlist (BR-02)', () {
    testWidgets(
      'GivenATrackAlreadyAdded_WhenItIsAddedAgain_ThenASecondEntryIsSent',
      (tester) async {
        // The core allows duplicates deliberately — a set can open and close
        // with the same song — so the button must never invent a refusal it
        // does not have, and must never filter the file out before sending.
        final gateway = FakePlaylistGateway(playlists: [jazz]);
        final container = buildContainer(gateway);

        await pumpButton(
          tester,
          container,
          const AddToPlaylistButton(fileUuids: ['a1']),
        );

        for (var attempt = 0; attempt < 2; attempt++) {
          await tester.tap(find.byIcon(Icons.playlist_add));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Jazz'));
          await tester.pumpAndSettle();
        }

        // Field-by-field, not a list-literal comparison: a record's `==`
        // compares a `List<String>` field by reference, so a fresh list
        // literal would never match regardless of its contents.
        expect(gateway.entriesAdded, hasLength(2));
        for (final entry in gateway.entriesAdded) {
          expect(entry.uuid, 'p-1');
          expect(entry.fileUuids, ['a1']);
        }
      },
    );
  });

  group('no playlists yet', () {
    testWidgets(
      'GivenNoPlaylists_WhenTheMenuIsOpened_ThenItOffersToCreateOneRatherThanBeingEmpty',
      (tester) async {
        final gateway = FakePlaylistGateway(playlists: const []);
        final container = buildContainer(gateway);

        await pumpButton(
          tester,
          container,
          const AddToPlaylistButton(fileUuids: ['a1']),
        );

        await tester.tap(find.byIcon(Icons.playlist_add));
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(AddToPlaylistButton)),
        );
        expect(find.text(l10n.playlistAddCreateOne), findsOneWidget);

        await tester.tap(find.text(l10n.playlistAddCreateOne));
        await tester.pumpAndSettle();

        expect(find.byType(PlaylistsScreen), findsOneWidget);
        // The dead end this replaces: nothing was ever sent to the core for
        // a playlist that does not exist yet.
        expect(gateway.entriesAdded, isEmpty);
      },
    );
  });
}
