import 'dart:async';
import 'dart:math';

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/domain/music_metadata.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist_gateway.dart';
import 'package:alexandria_ui/features/playback/domain/playback_queue.dart';
import 'package:alexandria_ui/features/playlists/presentation/playlist_detail_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_media_player.dart';
import '../../../support/fake_playback.dart';
import '../../../support/fake_playlist_gateway.dart';
import '../../../support/shell_harness.dart';

/// The playlist detail screen: rendering tracks in order, reordering, and
/// removing entries (playlists design sections 2, 3 and 5).
///
/// The screen is not yet reachable from the Library menu (Task 5/6 wire the
/// entry points that open it), so these tests reach it directly through
/// [PlaylistDetailScreen.show], the same way [FileDetailsView] is opened from
/// a listing row.
void main() {
  const playlistUuid = 'pl-1';

  CatalogFile file(String uuid) => CatalogFile(
    uuid: uuid,
    name: '$uuid.flac',
    path: '/music/$uuid.flac',
    type: FileType.audio,
  );

  PlaylistEntry entry({
    required String uuid,
    required int position,
    String? fileUuid,
    String? title,
    bool missing = false,
  }) => PlaylistEntry(
    uuid: uuid,
    file: file(fileUuid ?? uuid),
    metadata: title == null ? null : MusicMetadata(title: title),
    position: position,
    missing: missing,
  );

  Future<({ProviderContainer container, FakePlaylistGateway gateway})>
  openDetail(
    WidgetTester tester, {
    required PlaylistView view,
    FakePlaylistGateway? gateway,
    Locale? locale,
    List<Override> extraOverrides = const [],
  }) async {
    final theGateway = gateway ?? FakePlaylistGateway();
    theGateway.reads[view.playlist.uuid] = PlaylistRead.loaded(view: view);

    final container = await tester.pumpShell(
      locale: locale,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        playlistGatewayProvider.overrideWithValue(theGateway),
        ...extraOverrides,
      ],
    );

    final context = tester.element(find.byType(ShellScreen));
    unawaited(PlaylistDetailScreen.show(context, view.playlist.uuid));
    await tester.pumpAndSettle();

    return (container: container, gateway: theGateway);
  }

  /// The vertical distance one row occupies, so a drag can be aimed at a
  /// specific destination rather than an arbitrary offset.
  double rowExtent(WidgetTester tester) =>
      tester.getSize(find.byType(ListTile).first).height;

  /// Drags the row whose handle is at [fromIndex] down or up by [rows] rows,
  /// in small steps — a single large jump does not give
  /// `ReorderableListView` enough intermediate frames to register the
  /// reorder.
  Future<void> dragHandle(
    WidgetTester tester, {
    required int fromIndex,
    required int rows,
  }) async {
    final extent = rowExtent(tester);
    final handle = find.byIcon(Icons.drag_handle).at(fromIndex);
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));

    final step = rows.isNegative ? -extent : extent;
    for (var i = 0; i < rows.abs(); i++) {
      await gesture.moveBy(Offset(0, step));
      await tester.pump(const Duration(milliseconds: 100));
    }

    await gesture.up();
    await tester.pumpAndSettle();
  }

  group('rendering', () {
    testWidgets(
      'GivenEntries_WhenTheScreenOpens_ThenTheyRenderInPositionOrderByTitle',
      (tester) async {
        final view = PlaylistView(
          playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [
            entry(uuid: 'e-1', position: 0, title: 'So What'),
            entry(uuid: 'e-2', position: 1, title: 'Freddie Freeloader'),
          ],
        );
        await openDetail(tester, view: view);

        // FR-CT-13: named by metadata, never by the file on disk — the file
        // names above ('e-1.flac') never appear.
        expect(find.text('So What'), findsOneWidget);
        expect(find.text('Freddie Freeloader'), findsOneWidget);
        expect(find.text('e-1.flac'), findsNothing);

        final soWhat = tester.getTopLeft(find.text('So What'));
        final freddie = tester.getTopLeft(find.text('Freddie Freeloader'));
        expect(soWhat.dy, lessThan(freddie.dy));
      },
    );

    testWidgets(
      'GivenAMissingEntry_WhenTheScreenOpens_ThenItRendersGreyedAndListed',
      (tester) async {
        final view = PlaylistView(
          playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [
            entry(uuid: 'e-1', position: 0, title: 'So What'),
            entry(uuid: 'e-2', position: 1, title: 'Gone', missing: true),
          ],
        );
        await openDetail(tester, view: view);

        // Still listed (playlists design section 5) — never dropped.
        expect(find.text('Gone'), findsOneWidget);

        // "Greyed" is the ListTile's own disabled state, which reads its
        // colours from the theme (BR-18 / FR-UX-07) rather than a literal
        // chosen here.
        final missingTile = tester.widget<ListTile>(
          find.ancestor(of: find.text('Gone'), matching: find.byType(ListTile)),
        );
        expect(missingTile.enabled, isFalse);

        final presentTile = tester.widget<ListTile>(
          find.ancestor(
            of: find.text('So What'),
            matching: find.byType(ListTile),
          ),
        );
        expect(presentTile.enabled, isTrue);
      },
    );
  });

  group('removing an entry', () {
    // The same track twice: removing one entry removes THAT entry, addressed
    // by its own uuid, and the other survives (playlists design section 2).
    testWidgets(
      'GivenTheSameTrackTwice_WhenOneIsRemoved_ThenTheOtherSurvives',
      (tester) async {
        final before = PlaylistView(
          playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [
            entry(uuid: 'e-1', position: 0, fileUuid: 'f-1', title: 'So What'),
            entry(uuid: 'e-2', position: 1, fileUuid: 'f-1', title: 'So What'),
          ],
        );
        final gateway = FakePlaylistGateway()
          ..reads[playlistUuid] = PlaylistRead.loaded(view: before);
        final opened = await openDetail(tester, view: before, gateway: gateway);

        // What the core answers once 'e-1' is gone.
        final after = PlaylistView(
          playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [
            entry(uuid: 'e-2', position: 0, fileUuid: 'f-1', title: 'So What'),
          ],
        );
        gateway.reads[playlistUuid] = PlaylistRead.loaded(view: after);

        // The two entries are otherwise identical, so the remove button is
        // reached through the entry's own key rather than by its text.
        final removeButton = find.descendant(
          of: find.byKey(const ValueKey('e-1')),
          matching: find.byIcon(Icons.close),
        );
        await tester.tap(removeButton);
        await tester.pumpAndSettle();

        expect(opened.gateway.entriesRemoved, [
          (uuid: playlistUuid, entryUuid: 'e-1'),
        ]);
        expect(find.byKey(const ValueKey('e-1')), findsNothing);
        expect(find.byKey(const ValueKey('e-2')), findsOneWidget);
      },
    );
  });

  group('reordering', () {
    // The no-op guard lives in the `onReorder` closure itself, at the call
    // site — `reorderDestinationIndex`'s own tests cannot exercise it. This
    // reaches the real closure directly, with the exact index pair a
    // lower-side drop-on-self produces, rather than trying to pin a gesture
    // to Flutter's internal (and unguaranteed) hit-testing thresholds.
    testWidgets(
      'GivenADropThatConvertsToTheSameIndex_WhenOnReorderFires_ThenTheCoreIsNeverCalled',
      (tester) async {
        final before = PlaylistView(
          playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [
            entry(uuid: 'e-1', position: 0, title: 'A'),
            entry(uuid: 'e-2', position: 1, title: 'B'),
            entry(uuid: 'e-3', position: 2, title: 'C'),
            entry(uuid: 'e-4', position: 3, title: 'D'),
          ],
        );
        final gateway = FakePlaylistGateway()
          ..reads[playlistUuid] = PlaylistRead.loaded(view: before);
        final opened = await openDetail(tester, view: before, gateway: gateway);

        final list = tester.widget<ReorderableListView>(
          find.byType(ReorderableListView),
        );
        // (1, 2) is what a lower-side drop-on-self reports: converted via
        // reorderDestinationIndex, it lands back on index 1 — the entry's
        // own position.
        // ignore: deprecated_member_use
        list.onReorder!(1, 2);
        await tester.pump();

        expect(opened.gateway.entriesMoved, isEmpty);
      },
    );

    // The companion case: a real move through the identical path still
    // reaches the core, so the pair above proves the guard blocks only the
    // no-op rather than every reorder.
    testWidgets('GivenAGenuineMove_WhenOnReorderFires_ThenTheCoreIsCalled', (
      tester,
    ) async {
      final before = PlaylistView(
        playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
        entries: [
          entry(uuid: 'e-1', position: 0, title: 'A'),
          entry(uuid: 'e-2', position: 1, title: 'B'),
          entry(uuid: 'e-3', position: 2, title: 'C'),
          entry(uuid: 'e-4', position: 3, title: 'D'),
        ],
      );
      final gateway = FakePlaylistGateway()
        ..reads[playlistUuid] = PlaylistRead.loaded(view: before);
      final opened = await openDetail(tester, view: before, gateway: gateway);

      final list = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      // (1, 3) converts to toIndex 2 — a real destination, not the
      // entry's own index.
      // ignore: deprecated_member_use
      list.onReorder!(1, 3);
      await tester.pumpAndSettle();

      expect(opened.gateway.entriesMoved, [
        (uuid: playlistUuid, entryUuid: 'e-2', toIndex: 2),
      ]);
    });

    // Dragging a track down puts it where it was dropped — the case
    // Flutter's off-by-one breaks: naively passing `newIndex` through would
    // send the core one index too far, and get refused at the boundary.
    testWidgets(
      'GivenAFourTrackPlaylist_WhenTheFirstIsDraggedToTheEnd_ThenTheCoreReceivesTheLastIndex',
      (tester) async {
        final before = PlaylistView(
          playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [
            entry(uuid: 'e-1', position: 0, title: 'A'),
            entry(uuid: 'e-2', position: 1, title: 'B'),
            entry(uuid: 'e-3', position: 2, title: 'C'),
            entry(uuid: 'e-4', position: 3, title: 'D'),
          ],
        );
        final gateway = FakePlaylistGateway()
          ..reads[playlistUuid] = PlaylistRead.loaded(view: before);
        final opened = await openDetail(tester, view: before, gateway: gateway);

        await dragHandle(tester, fromIndex: 0, rows: 3);

        expect(opened.gateway.entriesMoved, [
          (uuid: playlistUuid, entryUuid: 'e-1', toIndex: 3),
        ]);
      },
    );

    // Dragging a track up puts it where it was dropped.
    testWidgets(
      'GivenAFourTrackPlaylist_WhenTheLastIsDraggedToTheStart_ThenTheCoreReceivesIndexZero',
      (tester) async {
        final before = PlaylistView(
          playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [
            entry(uuid: 'e-1', position: 0, title: 'A'),
            entry(uuid: 'e-2', position: 1, title: 'B'),
            entry(uuid: 'e-3', position: 2, title: 'C'),
            entry(uuid: 'e-4', position: 3, title: 'D'),
          ],
        );
        final gateway = FakePlaylistGateway()
          ..reads[playlistUuid] = PlaylistRead.loaded(view: before);
        final opened = await openDetail(tester, view: before, gateway: gateway);

        await dragHandle(tester, fromIndex: 3, rows: -3);

        expect(opened.gateway.entriesMoved, [
          (uuid: playlistUuid, entryUuid: 'e-4', toIndex: 0),
        ]);
      },
    );

    // The screen shows the core's returned order after a move, not a
    // locally computed one: the fake answers an order naive local arithmetic
    // (shifting 'e-1' to the end) would never produce.
    testWidgets(
      'GivenAMove_WhenTheCoreAnswers_ThenTheScreenShowsTheCoresOrder',
      (tester) async {
        final before = PlaylistView(
          playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [
            entry(uuid: 'e-1', position: 0, title: 'A'),
            entry(uuid: 'e-2', position: 1, title: 'B'),
            entry(uuid: 'e-3', position: 2, title: 'C'),
            entry(uuid: 'e-4', position: 3, title: 'D'),
          ],
        );
        final afterMove = PlaylistView(
          playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [
            entry(uuid: 'e-2', position: 0, title: 'B'),
            entry(uuid: 'e-4', position: 1, title: 'D'),
            entry(uuid: 'e-3', position: 2, title: 'C'),
            entry(uuid: 'e-1', position: 3, title: 'A'),
          ],
        );
        final gateway = _ReadsAfterEveryWrite(before: before, after: afterMove);
        await openDetail(tester, view: before, gateway: gateway);

        await dragHandle(tester, fromIndex: 0, rows: 3);

        final titles = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .whereType<String>()
            .where(['A', 'B', 'C', 'D'].contains)
            .toList();
        expect(titles, ['B', 'D', 'C', 'A']);
      },
    );
  });

  group('themes and languages', () {
    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheScreenOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          final view = PlaylistView(
            playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
            entries: [entry(uuid: 'e-1', position: 0, missing: true)],
          );
          await openDetail(tester, view: view, locale: locale);

          expect(
            find.textContaining(RegExp('playlist[A-Z]'), findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });

  group('reopening a playlist', () {
    testWidgets(
      'GivenAPlaylistChangedElsewhere_WhenItIsReopened_ThenTheCoreIsReadAgain',
      (tester) async {
        // The screen promises the playlist is read afresh on open. A family
        // provider is not auto-disposed by default, so without that the
        // first read is cached for the life of the container: a track added
        // from the music area — where `addEntries` deliberately skips
        // reloading this provider — would never appear here, however many
        // times the owner reopened the playlist.
        final view = PlaylistView(
          playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [entry(uuid: 'e-1', position: 0, title: 'So What')],
        );
        final opened = await openDetail(tester, view: view);
        expect(find.text('So What'), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.close),
          ),
        );
        await tester.pumpAndSettle();

        // A track is added from somewhere else entirely.
        opened.gateway.reads[playlistUuid] = PlaylistRead.loaded(
          view: PlaylistView(
            playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
            entries: [
              entry(uuid: 'e-1', position: 0, title: 'So What'),
              entry(uuid: 'e-2', position: 1, title: 'Blue in Green'),
            ],
          ),
        );

        unawaited(
          PlaylistDetailScreen.show(
            tester.element(find.byType(ShellScreen)),
            playlistUuid,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Blue in Green'),
          findsOneWidget,
          reason: 'the reopened screen served a cached copy',
        );
        expect(opened.gateway.readsMade, [playlistUuid, playlistUuid]);
      },
    );
  });

  group('playing', () {
    /// The playback dependencies faked, so the real
    /// [AudioPlaybackController] runs behind the screen's play action rather
    /// than being replaced itself — a test that stubbed the controller could
    /// not tell whether the screen handed it the right tracks.
    List<Override> playbackOverrides() => [
      audioPlayerProvider.overrideWithValue(FakeMediaPlayer()),
      playbackSourceGatewayProvider.overrideWithValue(
        FakePlaybackSourceGateway(),
      ),
      playbackPositionsProvider.overrideWithValue(FakePlaybackPositionStore()),
    ];

    testWidgets(
      'GivenAPlaylist_WhenPlayIsPressed_ThenItsTracksBecomeTheQueueInOrder',
      (tester) async {
        // Design section 6: playing a playlist replaces the queue and plays
        // in order, and the queue carries the playlist's own name for the bar
        // to show.
        final view = PlaylistView(
          playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [
            entry(uuid: 'e-1', position: 0, fileUuid: 'f-1', title: 'So What'),
            entry(uuid: 'e-2', position: 1, fileUuid: 'f-2', title: 'Freddie'),
          ],
        );
        final opened = await openDetail(
          tester,
          view: view,
          extraOverrides: playbackOverrides(),
        );

        await tester.tap(find.byIcon(Icons.play_arrow));
        // Stepped past with bounded pumps, never `pumpAndSettle`: something
        // is playing now, so UC-21's album animation is turning and never
        // settles (see `pumpShell`'s own note on `reduceMotion`).
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final queue = opened.container
            .read(audioPlaybackControllerProvider)
            .queue;
        expect(queue.kind, QueueKind.playlist);
        expect(queue.label, 'Jazz');
        expect(queue.tracks.map((file) => file.uuid), ['f-1', 'f-2']);
      },
    );

    testWidgets(
      'GivenAPlaylist_WhenShuffleIsPressed_ThenItsTracksQueueOutOfOrder',
      (tester) async {
        // FR-PL-06: a way of hearing the playlist, not an edit of it. The
        // stored order is untouched — the entries still render in it, and
        // the next plain play is in order again.
        final view = PlaylistView(
          playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [
            for (final (index, title) in [
              'So What',
              'Freddie',
              'Blue',
              'Flamenco',
            ].indexed)
              entry(
                uuid: 'e-${index + 1}',
                position: index,
                fileUuid: 'f-${index + 1}',
                title: title,
              ),
          ],
        );
        final opened = await openDetail(
          tester,
          view: view,
          extraOverrides: [
            ...playbackOverrides(),
            // Seeded, so the shuffled order is a fact rather than a coin
            // toss: this is the permutation `Random(7)` makes of four.
            shuffleRandomProvider.overrideWithValue(Random(7)),
          ],
        );

        await tester.tap(find.byIcon(Icons.shuffle));
        // Stepped past with bounded pumps, never `pumpAndSettle`: something
        // is playing now, so UC-21's bars are running and never settle.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final queue = opened.container
            .read(audioPlaybackControllerProvider)
            .queue;
        expect(queue.kind, QueueKind.playlist);
        expect(queue.label, 'Jazz');
        expect(queue.tracks.map((file) => file.uuid), [
          'f-2',
          'f-4',
          'f-3',
          'f-1',
        ]);
        expect(
          opened.gateway.entriesMoved,
          isEmpty,
          reason: 'shuffling plays the playlist, it does not rewrite it',
        );
      },
    );

    testWidgets(
      'GivenAMissingEntry_WhenPlayIsPressed_ThenItIsStillHandedToThePlayer',
      (tester) async {
        // The screen does not filter: whether a file can actually be opened
        // is the resolve's answer, not a flag this screen re-decides
        // (design section 5). Skipping happens in the player, which names the
        // file it stepped over; dropping it here would lose that report and
        // would silently disagree with a stale missing flag.
        final view = PlaylistView(
          playlist: const Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [
            entry(
              uuid: 'e-1',
              position: 0,
              fileUuid: 'f-gone',
              title: 'Gone',
              missing: true,
            ),
            entry(uuid: 'e-2', position: 1, fileUuid: 'f-2', title: 'Freddie'),
          ],
        );
        final opened = await openDetail(
          tester,
          view: view,
          extraOverrides: playbackOverrides(),
        );

        await tester.tap(find.byIcon(Icons.play_arrow));
        // Stepped past with bounded pumps, never `pumpAndSettle`: something
        // is playing now, so UC-21's album animation is turning and never
        // settles (see `pumpShell`'s own note on `reduceMotion`).
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final queue = opened.container
            .read(audioPlaybackControllerProvider)
            .queue;
        expect(queue.tracks.map((file) => file.uuid), ['f-gone', 'f-2']);
      },
    );

    testWidgets(
      'GivenAnEmptyPlaylist_WhenTheScreenOpens_ThenThereIsNothingToPlay',
      (tester) async {
        // Nothing to play is not a failure to report — the empty state
        // already says the playlist holds no tracks, and an action that could
        // only do nothing does not belong beside it.
        const view = PlaylistView(
          playlist: Playlist(uuid: playlistUuid, name: 'Jazz'),
          entries: [],
        );
        await openDetail(
          tester,
          view: view,
          extraOverrides: playbackOverrides(),
        );

        expect(find.byIcon(Icons.play_arrow), findsNothing);
      },
    );
  });
}

/// A [FakePlaylistGateway] whose next read answers [after] once any write
/// lands, and [before] until then.
///
/// Standing in for the core's own behaviour: `moveEntry` and `removeEntry`
/// answer no echoed record (playlists design), and the *following* read is
/// the only place a new order or count is ever trusted. This fake commits
/// [after] at that point rather than earlier, so a test cannot pass by
/// reading the write's arguments instead of the screen's next render.
class _ReadsAfterEveryWrite extends FakePlaylistGateway {
  /// Creates a gateway that answers [before] until a write lands, then
  /// [after].
  _ReadsAfterEveryWrite({required PlaylistView before, required this.after}) {
    reads[before.playlist.uuid] = PlaylistRead.loaded(view: before);
  }

  /// What the next read answers once a write has landed.
  final PlaylistView after;

  @override
  Future<PlaylistWrite> moveEntry({
    required String uuid,
    required String entryUuid,
    required int toIndex,
    required String credential,
  }) async {
    final outcome = await super.moveEntry(
      uuid: uuid,
      entryUuid: entryUuid,
      toIndex: toIndex,
      credential: credential,
    );
    reads[uuid] = PlaylistRead.loaded(view: after);
    return outcome;
  }
}
