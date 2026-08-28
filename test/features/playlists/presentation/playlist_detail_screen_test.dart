import 'dart:async';

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/catalog/domain/music_metadata.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist_gateway.dart';
import 'package:alexandria_ui/features/playlists/presentation/playlist_detail_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

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

  CatalogFile file(String uuid) =>
      CatalogFile(uuid: uuid, name: '$uuid.flac', path: '/music/$uuid.flac', type: LibraryType.audio);

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
  }) async {
    final theGateway = gateway ?? FakePlaylistGateway();
    theGateway.reads[view.playlist.uuid] = PlaylistRead.loaded(view: view);

    final container = await tester.pumpShell(
      locale: locale,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        playlistGatewayProvider.overrideWithValue(theGateway),
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
          find.ancestor(
            of: find.text('Gone'),
            matching: find.byType(ListTile),
          ),
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
        final opened = await openDetail(
          tester,
          view: before,
          gateway: gateway,
        );

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
        final opened = await openDetail(
          tester,
          view: before,
          gateway: gateway,
        );

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
        final opened = await openDetail(
          tester,
          view: before,
          gateway: gateway,
        );

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
