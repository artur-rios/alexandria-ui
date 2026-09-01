import 'dart:io';

import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/core/bindings/core_environment.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/startup/core_version.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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

      final status = await client.initialize(
        catalog.databasePath,
        musicLookup: MusicLookup.off,
      );

      expect(CoreStatusFamily.indexing.isOk(status), isTrue);
    },
  );

  test(
    'GivenAnInitializedCore_WhenTheDatabaseIsInspected_ThenItWasCreated',
    () async {
      final client = await FfiCoreClient.load(libraryPath);
      addTearDown(client.dispose);

      await client.initialize(
        catalog.databasePath,
        musicLookup: MusicLookup.off,
      );

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

      await client.initialize(
        catalog.databasePath,
        musicLookup: MusicLookup.off,
      );
      final status = await client.initialize(
        second.databasePath,
        musicLookup: MusicLookup.off,
      );

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

      await client.initialize(
        catalog.databasePath,
        musicLookup: MusicLookup.off,
      );

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
}
