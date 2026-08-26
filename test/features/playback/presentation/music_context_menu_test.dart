import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/presentation/file_details_view.dart';
import 'package:alexandria_ui/features/catalog/presentation/music_metadata_form.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:alexandria_ui/features/playback/domain/playback_queue.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_media_player.dart';
import '../../../support/fake_playback.dart';
import '../../../support/shell_harness.dart';

/// A track's own actions (UC-46, FR-CT-14).
void main() {
  AppLocalizations localizations(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// Opens the songs view over a one-track library.
  Future<ProviderContainer> openSongs(WidgetTester tester) async {
    final gateway = FakeCatalogGateway()
      ..addAudio(
        uuid: '1',
        name: 'DISKNAME-01.flac',
        title: 'Airbag',
        artist: 'Radiohead',
        album: 'OK',
      );

    final container = await tester.pumpShell(
      extraOverrides: [
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
    // This file is about the row menu's five actions (UC-46, FR-CT-14), not
    // about UC-21's animation — `now_playing_screen_test.dart` owns that.
    // Left at its untouched default, choosing "Play album" or "Play artist"
    // below would owe an insertion and the shell's own auto-open listener
    // (Task 7) would push that screen over this one mid-test.
    await container
        .read(preferencesControllerProvider.notifier)
        .setAlbumAnimation(AlbumAnimationMode.off);

    container
        .read(shellControllerProvider.notifier)
        .go(ShellDestination.music);
    await tester.pumpAndSettle();

    await tester.tap(find.text(localizations(tester).musicViewSongs));
    await tester.pumpAndSettle();

    return container;
  }

  /// Opens the row's menu by right-clicking it.
  Future<void> rightClickRow(WidgetTester tester) async {
    await tester.tapAt(
      tester.getCenter(find.text('Airbag')),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'GivenATrackRow_WhenItIsRightClicked_ThenTheMenuOffersItsFiveActions',
    (tester) async {
      await openSongs(tester);
      final l10n = localizations(tester);

      await rightClickRow(tester);

      for (final label in [
        l10n.audioPlay,
        l10n.audioPlayAlbum,
        l10n.audioPlayArtist,
        l10n.detailsTitle,
        l10n.detailsEditMetadata,
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    },
  );

  testWidgets(
    'GivenATrackRow_WhenItsActionsButtonIsTapped_ThenTheSameMenuOpens',
    (tester) async {
      // The right mouse button is not the only way in: the button is what
      // makes the menu reachable from the keyboard.
      await openSongs(tester);
      final l10n = localizations(tester);

      await tester.tap(find.byTooltip(l10n.musicRowActions));
      await tester.pumpAndSettle();

      expect(find.text(l10n.detailsTitle), findsOneWidget);
    },
  );

  testWidgets(
    'GivenTheMenu_WhenDetailsAreChosen_ThenTheDetailsDialogOpens',
    (tester) async {
      await openSongs(tester);
      final l10n = localizations(tester);

      await rightClickRow(tester);
      await tester.tap(find.text(l10n.detailsTitle));
      await tester.pumpAndSettle();

      expect(find.byType(FileDetailsView), findsOneWidget);
    },
  );

  testWidgets(
    'GivenTheMenu_WhenEditingMetadataIsChosen_ThenTheFormOpens',
    (tester) async {
      await openSongs(tester);
      final l10n = localizations(tester);

      await rightClickRow(tester);
      await tester.tap(find.text(l10n.detailsEditMetadata));
      await tester.pumpAndSettle();

      expect(find.byType(MusicMetadataForm), findsOneWidget);
    },
  );

  testWidgets(
    'GivenTheMenu_WhenPlayAlbumIsChosen_ThenTheAlbumIsQueued',
    (tester) async {
      final container = await openSongs(tester);
      final l10n = localizations(tester);

      await rightClickRow(tester);
      await tester.tap(find.text(l10n.audioPlayAlbum));
      await tester.pumpAndSettle();

      final state = container.read(audioPlaybackControllerProvider);
      expect(state.queue.kind, QueueKind.album);
      expect(state.current?.uuid, '1');
    },
  );

  testWidgets('GivenTheMenu_WhenPlayIsChosen_ThenTheTrackAlonePlays', (
    tester,
  ) async {
    final container = await openSongs(tester);
    final l10n = localizations(tester);

    await rightClickRow(tester);
    await tester.tap(find.text(l10n.audioPlay));
    await tester.pumpAndSettle();

    final state = container.read(audioPlaybackControllerProvider);
    expect(state.queue.kind, QueueKind.track);
    expect(state.queue.tracks, hasLength(1));
    expect(state.current?.uuid, '1');
  });

  testWidgets(
    'GivenTheMenu_WhenPlayArtistIsChosen_ThenTheArtistIsQueued',
    (tester) async {
      final container = await openSongs(tester);
      final l10n = localizations(tester);

      await rightClickRow(tester);
      await tester.tap(find.text(l10n.audioPlayArtist));
      await tester.pumpAndSettle();

      final state = container.read(audioPlaybackControllerProvider);
      expect(state.queue.kind, QueueKind.artist);
      expect(state.current?.uuid, '1');
    },
  );
}
