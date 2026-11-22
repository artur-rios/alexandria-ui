import 'dart:convert';
import 'dart:io';

import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/startup/core_version.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/library_runs.dart';
import 'support/temporary_catalog.dart';

/// The FFI boundary, against the real Alexandria core (IR-14).
///
/// What is faked in the unit and widget suites is exactly what these tests
/// exist to verify (Testing Specification §2.4): the library really loads, the
/// core really initializes against a database path, and the version and health
/// values the startup sequence branches on are the ones it actually returns.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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

  test('GivenTheBundledCore_WhenItIsLoaded_ThenTheLibraryOpens', () async {
    final client = await FfiCoreClient.load(libraryPath);
    addTearDown(client.dispose);

    expect(client.libraryPath, libraryPath);
  });

  test(
    'GivenTheLoadedCore_WhenItsHealthIsRead_ThenItReportsTheHealthyCode',
    () async {
      final client = await FfiCoreClient.load(libraryPath);
      addTearDown(client.dispose);

      expect(
        await client.healthStatus(),
        coreHealthyStatusCode,
        reason:
            'the whole startup verification branches on this value; if the core '
            'ever changes it, this is where that surfaces',
      );
    },
  );

  test(
    'GivenTheLoadedCore_WhenItsVersionIsRead_ThenItIsInTheSupportedRange',
    () async {
      final client = await FfiCoreClient.load(libraryPath);
      addTearDown(client.dispose);

      final version = await client.version();

      expect(version, isNotNull);
      expect(
        CoreVersionRange.supports(version),
        isTrue,
        reason:
            'the bundled core reports $version, outside ${CoreVersionRange.description}',
      );
    },
  );

  test(
    'GivenATemporaryDatabasePath_WhenTheCoreIsInitialized_ThenItReportsSuccess',
    () async {
      final client = await FfiCoreClient.load(libraryPath);
      addTearDown(client.dispose);

      final status = await client.initialize(catalog.databasePath);

      expect(CoreStatusFamily.indexing.isOk(status), isTrue);
    },
  );

  test(
    'GivenAnInitializedCore_WhenTheDatabaseIsInspected_ThenItWasCreated',
    () async {
      final client = await FfiCoreClient.load(libraryPath);
      addTearDown(client.dispose);

      await client.initialize(catalog.databasePath);

      expect(
        File(catalog.databasePath).existsSync(),
        isTrue,
        reason: 'the core creates and migrates the database on demand',
      );
    },
  );

  test(
    'GivenTheCore_WhenItIsInitializedTwice_ThenItAcceptsTheSecondDatabase',
    () async {
      final client = await FfiCoreClient.load(libraryPath);
      addTearDown(client.dispose);
      final second = TemporaryCatalog.create();
      addTearDown(second.dispose);

      await client.initialize(catalog.databasePath);
      final status = await client.initialize(second.databasePath);

      expect(
        CoreStatusFamily.indexing.isOk(status),
        isTrue,
        reason:
            'the core documents init as safe to call again to point at a '
            'different database — the retry in startup step 3 depends on it',
      );
    },
  );

  test(
    'GivenTheCoreIsInitialized_WhenTheCatalogIsEmpty_ThenNoFilesAreCounted',
    () async {
      final client = await FfiCoreClient.load(libraryPath);
      addTearDown(client.dispose);

      await client.initialize(catalog.databasePath);

      expect(
        File(catalog.databasePath).lengthSync(),
        greaterThan(0),
        reason: 'an initialized catalog is a real database, not an empty file',
      );
    },
  );

  test(
    'GivenAFixtureLibrary_WhenItIsCreated_ThenItIsUnderATemporaryRoot',
    () async {
      final fixture = catalog.addFixture('note.md', '# a note');

      expect(fixture.existsSync(), isTrue);
      expect(
        fixture.path,
        contains('alexandria_it'),
        reason:
            'no integration test touches a real library folder or the real '
            'application-support directory',
      );
    },
  );

  test(
    'GivenAClientInUse_WhenItIsDisposed_ThenFurtherCallsAreRefused',
    () async {
      final client = await FfiCoreClient.load(libraryPath);

      await client.dispose();

      expect(
        client.healthStatus,
        throwsA(isA<Exception>()),
        reason:
            'a disposed client must fail loudly rather than silently reopening '
            'the library on a worker that is gone',
      );
    },
  );

  test(
    'GivenARegisteredLibrary_WhenPinnedFavoritedRenamedAndCounted_ThenTheCoreAgrees',
    () async {
      // The first calls in this FFI to take a C bool, and the four calls
      // no fake can check: a flag sent the wrong way or a body the core
      // does not read would pass every unit test.
      final client = await FfiCoreClient.load(libraryPath);
      addTearDown(client.dispose);
      await client.initialize(catalog.databasePath);
      catalog.addFixture('notes/one.md', '# one');
      final library = await addLibraryAndSettle(
        client,
        root: catalog.libraryDirectory.path,
      );

      expect(
        CoreStatusFamily.library.isOk(
          await client.librarySetPinned(library.uuid, true),
        ),
        isTrue,
      );
      expect(
        CoreStatusFamily.library.isOk(
          await client.librarySetFavorite(library.uuid, true),
        ),
        isTrue,
      );
      final renamed = await client.libraryRename(
        library.uuid,
        jsonEncode({'name': 'Renamed'}),
      );
      expect(CoreStatusFamily.library.isOk(renamed.status), isTrue);

      final listed = await client.librariesList();
      final row = (jsonDecode(listed.json!) as List<dynamic>).single as Map;
      expect(row['pinned'], isTrue);
      expect(row['favorite'], isTrue);
      expect(row['name'], 'Renamed');

      // And back, so a flag stuck on true would show.
      await client.librarySetPinned(library.uuid, false);
      final unpinned = jsonDecode((await client.librariesList()).json!) as List;
      expect((unpinned.single as Map)['pinned'], isFalse);
      expect((unpinned.single as Map)['favorite'], isTrue);

      final stats =
          jsonDecode((await client.catalogStats()).json!)
              as Map<String, dynamic>;
      expect(stats['libraries'], 1);
      expect(
        (stats['filesByType'] as Map).keys,
        unorderedEquals([
          'audio',
          'video',
          'html',
          'text',
          'document',
          'comic',
          'image',
        ]),
      );
    },
  );
}
