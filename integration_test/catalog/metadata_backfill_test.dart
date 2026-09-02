import 'dart:io';

import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/core/bindings/core_environment.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/features/auth/data/core_auth_gateway.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_ui/features/catalog/data/core_catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/flac_fixture.dart';
import '../support/temporary_catalog.dart';

/// What the catalog says a track is by, across the real FFI boundary
/// (UC-46, FR-CT-13).
///
/// The artists area groups by the record's own artist and falls back to the
/// track's performer when the catalog holds no album artist — so what the
/// core answers here decides whether a record with guests on it appears once
/// or once per guest. Every unit test of that grouping runs against a fake
/// this application also wrote, and a fake cannot tell whether the tag ever
/// reached the catalog at all.
///
/// It did not, for a long time and for a reason no client could see:
/// extraction ran only at first index, so a row written before the core
/// could read `ALBUMARTIST` held nothing there for the rest of its life —
/// a re-index skips a path already catalogued, and a refresh compared size
/// and mtime without opening the file. The core repairs that now, and this
/// is where the repair is exercised through the same gateways the
/// application uses.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = 'owner@example.com';
  const password = 'correct horse battery staple';

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

  Future<(CoreClient, String)> signedInCore() async {
    final client = await FfiCoreClient.load(libraryPath);
    addTearDown(client.dispose);

    final status = await client.initialize(
      catalog.databasePath,
      musicLookup: MusicLookup.off,
    );
    expect(CoreStatusFamily.indexing.isOk(status), isTrue);

    final outcome = await CoreAuthGateway(client).register(
      email: email,
      password: password,
      passwordConfirmation: password,
    );
    expect(outcome, isA<AuthenticatedOutcome>());

    return (client, (outcome as AuthenticatedOutcome).session.credential);
  }

  /// What the catalog holds for the one track in the library.
  Future<Map<String, String>> theTrack(
    CoreClient client,
    String credential,
  ) async {
    final listing = await CoreCatalogGateway(
      client,
    ).listFiles(type: FileType.audio, credential: credential);
    expect(listing, isA<CatalogListingLoaded>());

    return (listing as CatalogListingLoaded).files.single.metadata;
  }

  test(
    'GivenATrackRetagged_WhenTheLibraryIsRefreshed_ThenTheCatalogReadsItAgain',
    () async {
      final (client, credential) = await signedInCore();
      final track = File('${catalog.libraryDirectory.path}/guest.flac')
        ..writeAsBytesSync(
          taggedFlac(
            tags: {
              'TITLE': 'A Guest Spot',
              'ARTIST': 'The Guest',
              'ALBUM': 'Their Record',
            },
          ),
        );

      final started = await client.indexStart(
        catalog.libraryDirectory.path,
        credential,
      );
      expect(CoreStatusFamily.indexing.isOk(started.status), isTrue);

      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (await client.indexCountFiles() < 1) {
        expect(
          DateTime.now().isBefore(deadline),
          isTrue,
          reason: 'the run never catalogued the fixture',
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      // The tags the file was indexed with: a performer and no album artist,
      // which is what leaves the artists area listing the performer.
      //
      // Polled for the same reason the refresh below is, and it took a
      // Windows runner to show why: `indexCountFiles` answers as soon as the
      // run has *counted* a file, which is not the same moment its tags have
      // been read and written. Asserting straight off that count passed on
      // every Linux run and lost the race on a slower machine, reading a row
      // that existed with nothing in it yet.
      final tagged = DateTime.now().add(const Duration(seconds: 30));
      Map<String, String> asIndexed = await theTrack(client, credential);
      while (asIndexed['artist'] == null) {
        expect(
          DateTime.now().isBefore(tagged),
          isTrue,
          reason:
              'the run never read the fixture: the catalog holds $asIndexed',
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
        asIndexed = await theTrack(client, credential);
      }

      expect(asIndexed['artist'], 'The Guest');
      expect(asIndexed['albumArtist'], isNull);

      // The owner tags the record properly.
      track.writeAsBytesSync(
        taggedFlac(
          tags: {
            'TITLE': 'A Guest Spot',
            'ARTIST': 'The Guest',
            'ALBUM': 'Their Record',
            'ALBUMARTIST': 'The Host',
          },
        ),
      );

      final refresh = await client.indexRefreshStart(credential, null);
      expect(CoreStatusFamily.indexing.isOk(refresh.status), isTrue);

      // Polled rather than slept on: the refresh runs in the background on
      // the core's own runtime, and how long it takes is the machine's
      // business.
      final refreshed = DateTime.now().add(const Duration(seconds: 30));
      Map<String, String> metadata = await theTrack(client, credential);
      while (metadata['albumArtist'] == null) {
        expect(
          DateTime.now().isBefore(refreshed),
          isTrue,
          reason:
              'the refresh never re-read the file: the catalog still holds '
              '$metadata',
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
        metadata = await theTrack(client, credential);
      }

      expect(metadata['albumArtist'], 'The Host');
      expect(
        metadata['title'],
        'A Guest Spot',
        reason: 'filling gaps must not disturb what the row already held',
      );
    },
  );
}
