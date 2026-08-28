import 'dart:io';

import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/features/auth/data/core_auth_gateway.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_ui/features/catalog/data/core_catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/playlists/data/core_playlist_gateway.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist.dart';
import 'package:alexandria_ui/features/playlists/domain/playlist_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/temporary_catalog.dart';

/// One playlist's whole life against the real core, over the real FFI
/// (playlists design, UC-49).
///
/// Every other test of this feature runs against a fake this application also
/// wrote, so none of them can tell whether the core agrees — about a wire
/// name, about which uuid addresses an entry, or about what "move to index 0"
/// renumbers.
///
/// **Every one of the eight calls appears here, and that is not decoration.**
/// `core_isolate.dart`'s switch cases map `arguments[n]` onto positional
/// native parameters, and nothing in the unit suite can reach that mapping —
/// it needs a loaded native library. Several of these calls take two or three
/// consecutive `String` parameters, so a transposition inside a `case`
/// compiles cleanly, passes every unit test, and fails only at run time. This
/// is the sole automated cover for that layer, and a lifecycle that skipped
/// `rename`, `delete` or the browse would leave those calls' argument order
/// checked by nothing at all.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = 'owner@example.com';
  const password = 'correct horse battery staple';
  const playlistName = 'Road Trip';
  const renamedTo = 'Long Drive';

  /// The fixture tracks, in the order they are written and indexed.
  ///
  /// `.flac` because the core classifies by extension alone
  /// (`catalog/classify.rs`), and `add_entries` refuses a file that is not
  /// audio — so a text fixture would be rejected for a reason that has
  /// nothing to do with what this test is about.
  const trackNames = ['one.flac', 'two.flac', 'three.flac', 'four.flac'];

  late TemporaryCatalog catalog;
  late String libraryPath;

  setUpAll(() {
    expect(
      Platform.isWindows || Platform.isLinux,
      isTrue,
      reason: 'IR-01 configures no other target',
    );

    final resolved = resolveRealCoreLibrary();
    expect(resolved, isNotNull, reason: missingCoreReason);
    libraryPath = resolved!;
  });

  setUp(() => catalog = TemporaryCatalog.create());
  tearDown(() => catalog.dispose());

  /// A core initialized against this run's throwaway database, with an account
  /// registered and its credential returned.
  Future<(CoreClient, String)> signedInCore() async {
    final client = await FfiCoreClient.load(libraryPath);
    addTearDown(client.dispose);

    final status = await client.initialize(catalog.databasePath);
    expect(CoreStatusFamily.indexing.isOk(status), isTrue);

    final outcome = await CoreAuthGateway(client).register(
      email: email,
      password: password,
      passwordConfirmation: password,
    );
    expect(outcome, isA<AuthenticatedOutcome>());

    return (client, (outcome as AuthenticatedOutcome).session.credential);
  }

  /// Indexes the fixture library and waits until every track is catalogued.
  ///
  /// Waits for the exact count rather than "at least one": the playlist below
  /// is built out of four files, and a run polled only until the first one
  /// landed would leave the rest to be found by chance.
  Future<void> indexAndSettle(CoreClient client, String credential) async {
    final start = await client.indexStart(
      catalog.libraryDirectory.path,
      credential,
    );
    expect(
      CoreStatusFamily.indexing.isOk(start.status),
      isTrue,
      reason: 'the run would not start',
    );

    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (await client.indexCountFiles() < trackNames.length) {
      expect(
        DateTime.now().isBefore(deadline),
        isTrue,
        reason: 'the run never catalogued every fixture',
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  /// The catalogued tracks' file uuids, keyed by file name.
  ///
  /// Keyed rather than positional: an index run makes no promise about the
  /// order it walks a directory in, and a test that assumed one would fail
  /// somewhere else for a reason that has nothing to do with playlists.
  Future<Map<String, String>> trackUuids(
    CoreClient client,
    String credential,
  ) async {
    final listing = await CoreCatalogGateway(
      client,
    ).listFiles(type: LibraryType.audio, credential: credential);
    expect(listing, isA<CatalogListingLoaded>());

    return {
      for (final row in (listing as CatalogListingLoaded).files)
        row.file.name: row.file.uuid,
    };
  }

  test(
    'GivenARealCore_WhenAPlaylistIsLivedThrough_ThenEveryCallAgreesAcrossTheBoundary',
    () async {
      final (client, credential) = await signedInCore();
      for (final name in trackNames) {
        catalog.addFixture(name);
      }
      await indexAndSettle(client, credential);

      final files = await trackUuids(client, credential);
      expect(
        files.keys,
        containsAll(trackNames),
        reason: 'the fixtures were not all catalogued as audio',
      );

      final gateway = CorePlaylistGateway(client);

      /// The playlist as the core currently holds it.
      Future<PlaylistView> readBack(String uuid) async {
        final read = await gateway.read(uuid: uuid, credential: credential);
        expect(read, isA<PlaylistReadLoaded>());
        return (read as PlaylistReadLoaded).view;
      }

      /// Every playlist the core holds.
      Future<List<Playlist>> browse() async {
        final browsed = await gateway.browse(credential: credential);
        expect(browsed, isA<PlaylistBrowseLoaded>());
        return (browsed as PlaylistBrowseLoaded).playlists;
      }

      // ---- create, and find it in the listing -------------------------
      expect(
        await gateway.create(name: playlistName, credential: credential),
        isA<PlaylistWriteDone>(),
      );

      final created = await browse();
      expect(created, hasLength(1));
      expect(created.single.name, playlistName);
      final uuid = created.single.uuid;

      // ---- add four tracks in one call --------------------------------
      expect(
        await gateway.addEntries(
          uuid: uuid,
          fileUuids: [for (final name in trackNames) files[name]!],
          credential: credential,
        ),
        isA<PlaylistWriteDone>(),
      );

      var view = await readBack(uuid);
      expect(
        [for (final entry in view.entries) entry.file.name],
        trackNames,
        reason: 'the batch did not arrive in the order it was sent',
      );
      expect([for (final entry in view.entries) entry.position], [0, 1, 2, 3]);

      // ---- move the last to the front ---------------------------------
      // The single assertion this whole file exists to make: the destination
      // sent is a plain index, and the core renumbers the affected span.
      expect(
        await gateway.moveEntry(
          uuid: uuid,
          entryUuid: view.entries.last.uuid,
          toIndex: 0,
          credential: credential,
        ),
        isA<PlaylistWriteDone>(),
      );

      view = await readBack(uuid);
      expect([for (final entry in view.entries) entry.file.name], [
        'four.flac',
        'one.flac',
        'two.flac',
        'three.flac',
      ], reason: 'the core put the entry somewhere other than index 0');
      expect([for (final entry in view.entries) entry.position], [0, 1, 2, 3]);

      // ---- remove what is now the second ------------------------------
      // Addressed by the entry's own uuid, never by its position and never by
      // the file it points at (design section 2).
      expect(
        await gateway.removeEntry(
          uuid: uuid,
          entryUuid: view.entries[1].uuid,
          credential: credential,
        ),
        isA<PlaylistWriteDone>(),
      );

      view = await readBack(uuid);
      expect([for (final entry in view.entries) entry.file.name], [
        'four.flac',
        'two.flac',
        'three.flac',
      ]);
      expect(
        [for (final entry in view.entries) entry.position],
        [0, 1, 2],
        reason: 'positions are contiguous after a removal (design section 3)',
      );

      // ---- the same track twice ---------------------------------------
      // The core allows it on purpose, and each occurrence is its own entry
      // with its own uuid — which is the whole reason an entry is not
      // addressed by its file (design section 2).
      final twice = files['two.flac']!;
      expect(
        await gateway.addEntries(
          uuid: uuid,
          fileUuids: [twice, twice],
          credential: credential,
        ),
        isA<PlaylistWriteDone>(),
      );

      view = await readBack(uuid);
      final ofThatTrack = [
        for (final entry in view.entries)
          if (entry.file.uuid == twice) entry,
      ];
      expect(
        ofThatTrack,
        hasLength(3),
        reason: 'the core refused a duplicate it is meant to allow',
      );
      expect(
        {for (final entry in ofThatTrack) entry.uuid},
        hasLength(3),
        reason: 'two occurrences of one track came back sharing a uuid',
      );

      // ---- rename ------------------------------------------------------
      expect(
        await gateway.rename(
          uuid: uuid,
          name: renamedTo,
          credential: credential,
        ),
        isA<PlaylistWriteDone>(),
      );
      expect((await browse()).single.name, renamedTo);
      expect((await readBack(uuid)).playlist.name, renamedTo);

      // ---- delete ------------------------------------------------------
      expect(
        await gateway.delete(uuid: uuid, credential: credential),
        isA<PlaylistWriteDone>(),
      );
      expect(await browse(), isEmpty);
    },
  );
}
