import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/domain/music_metadata.dart';
import 'package:alexandria_ui/features/catalog/presentation/file_details_view.dart';
import 'package:alexandria_ui/features/playback/presentation/player_bar.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_media_player.dart';
import '../../../support/fake_playback.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/shell_harness.dart';

/// The music playing, docked under whatever the owner browses
/// (libraries-only design §6).
void main() {
  final first = aFile(
    uuid: 'first',
    name: '01 - a.flac',
    type: FileType.audio,
    tags: const MusicMetadata(
      title: 'First',
      artist: 'Band',
      album: 'Record',
      track: 1,
    ),
  );
  final second = aFile(
    uuid: 'second',
    name: '02 - b.flac',
    type: FileType.audio,
    tags: const MusicMetadata(
      title: 'Second',
      artist: 'Band',
      album: 'Record',
      track: 2,
    ),
  );

  Future<({ProviderContainer container, FakeMediaPlayer player})> openMusic(
    WidgetTester tester,
  ) async {
    final player = FakeMediaPlayer();
    final catalog = FakeCatalogGateway(
      listings: {
        FileType.audio: loadedDetails([second, first]),
      },
    );
    for (final file in [first, second]) {
      catalog.details[file.uuid] = FileDetailsOutcome.read(
        details: FileDetails(file: file),
      );
    }

    final container = await tester.pumpShell(
      surfaceSize: const Size(1440, 1000),
      settings: InMemorySettingsStore(rechecksAtStartup: false),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(catalog),
        audioPlayerProvider.overrideWithValue(player),
        playbackSourceGatewayProvider.overrideWithValue(
          FakePlaybackSourceGateway()..pathFor = (uuid) => '/music/$uuid',
        ),
        coverGatewayProvider.overrideWithValue(FakeCoverGateway()),
      ],
    );

    await tester.openFolderHolding(FileType.audio);

    return (container: container, player: player);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  Finder inBar(Finder finder) =>
      find.descendant(of: find.byType(PlayerBar), matching: finder);

  testWidgets('GivenNothingLoaded_WhenTheShellShows_ThenNoBar', (tester) async {
    await openMusic(tester);

    expect(inBar(find.byType(Slider)), findsNothing);
  });

  testWidgets(
    'GivenATrackTapped_WhenItPlays_ThenTheBarShowsTitleAndArtistAndPlaysThroughTheFolder',
    (tester) async {
      final opened = await openMusic(tester);

      await tester.tap(find.text('First'));
      await tester.pumpAndSettle();

      expect(inBar(find.text('First')), findsOneWidget);
      expect(inBar(find.text('Band · Record')), findsOneWidget);
      expect(inBar(find.byIcon(Icons.music_note_outlined)), findsOneWidget);
      expect(opened.player.opened, ['/music/first']);
      expect(
        opened.container
            .read(audioPlaybackControllerProvider)
            .queue
            .map((file) => file.uuid),
        ['first', 'second'],
        reason: 'the queue is the folder\'s tracks, in the order shown',
      );
    },
  );

  testWidgets('GivenTheBar_WhenNextTapped_ThenTheNextTrackPlays', (
    tester,
  ) async {
    final opened = await openMusic(tester);
    await tester.tap(find.text('First'));
    await tester.pumpAndSettle();

    await tester.tap(inBar(find.byTooltip(messages(tester).playerNext)));
    await tester.pumpAndSettle();

    expect(opened.player.opened.last, '/music/second');
    expect(inBar(find.text('Second')), findsOneWidget);
  });

  testWidgets('GivenTheBar_WhenCloseTapped_ThenPlaybackStops', (tester) async {
    final opened = await openMusic(tester);
    await tester.tap(find.text('First'));
    await tester.pumpAndSettle();

    await tester.tap(inBar(find.byTooltip(messages(tester).playerClose)));
    await tester.pumpAndSettle();

    expect(opened.player.stopCount, 1);
    expect(inBar(find.byType(Slider)), findsNothing);
  });

  testWidgets('GivenTheBar_WhenTitleTapped_ThenDetailsOpen', (tester) async {
    await openMusic(tester);
    await tester.tap(find.text('First'));
    await tester.pumpAndSettle();

    await tester.tap(inBar(find.text('First')));
    await tester.pumpAndSettle();

    expect(find.byType(FileDetailsView), findsOneWidget);
  });
}
