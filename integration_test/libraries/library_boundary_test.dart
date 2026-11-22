import 'dart:io';

import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/catalog/data/core_catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/domain/listing_view.dart';
import 'package:alexandria_ui/features/indexing/data/core_index_gateway.dart';
import 'package:alexandria_ui/features/indexing/domain/index_gateway.dart';
import 'package:alexandria_ui/features/indexing/domain/index_run.dart';
import 'package:alexandria_ui/features/libraries/data/core_library_gateway.dart';
import 'package:alexandria_ui/features/lifecycle/data/core_lifecycle_gateway.dart';
import 'package:alexandria_ui/features/lifecycle/domain/lifecycle_gateway.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/library_runs.dart';
import '../support/temporary_catalog.dart';

/// A library's whole life against the real core, over the real FFI
/// (libraries design).
///
/// Every unit test of this feature runs against a fake this application also
/// wrote, so none of them can tell whether the two sides agree — about the
/// wire names, about what "overlapping" means, or about the argument order.
/// `alexandria_library_browse` takes **two consecutive strings**: a uuid and
/// a folder path. Transpose them and it compiles, passes every unit test, and
/// answers an empty folder at run time — which looks exactly like a library
/// nobody has indexed into yet.
///
/// It also proves what the 0.6.0 core changed: a library is the only way
/// into the catalog, its files are listed in their type panels like any
/// others, and removing it takes them out of the catalog. No fake can show
/// that, because it lives in the core's own queries.
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

  Future<CoreClient> initializedCore() async {
    final client = await FfiCoreClient.load(libraryPath);
    addTearDown(client.dispose);

    final status = await client.initialize(catalog.databasePath);
    expect(CoreStatusFamily.indexing.isOk(status), isTrue);

    return client;
  }

  test('GivenALibrary_WhenItsTypeIsListed_ThenItsFilesAreListed', () async {
    // Every file belongs to a library now, so the type panel lists them —
    // each row saying which library it is in.
    final client = await initializedCore();
    catalog.addFixture('class-01/lecture.md', '# a lecture');
    catalog.addFixture('class-01/handout.md', '# a handout');
    final library = await addLibraryAndSettle(
      client,
      root: catalog.libraryDirectory.path,
    );

    final listing = await CoreCatalogGateway(
      client,
    ).listFiles(type: FileType.text);
    final files = (listing as CatalogListingLoaded).files;

    expect(files.map((row) => row.file.name).toSet(), {
      'lecture.md',
      'handout.md',
    });
    expect(files.map((row) => row.libraryUuid).toSet(), {
      library.uuid,
    }, reason: 'a row did not say which library it belongs to');
  });

  test(
    'GivenALibrary_WhenBrowsed_ThenItsTreeComesBackOneLevelAtATime',
    () async {
      // Also what pins `libraryBrowse`'s three arguments: transposed, the uuid
      // is read as a folder path and this answers an empty top level.
      final client = await initializedCore();
      catalog.addFixture('class-01/lecture.md', '# a lecture');
      catalog.addFixture('syllabus.md', '# the syllabus');
      final library = await addLibraryAndSettle(
        client,
        root: catalog.libraryDirectory.path,
      );

      final libraries = CoreLibraryGateway(client);
      final top = await libraries.read(uuid: library.uuid, path: '');
      final listing = (top as LibraryReadLoaded).listing;

      expect(listing.library.name, 'Course');
      expect(listing.folders.map((folder) => folder.name), [
        'class-01',
      ], reason: 'the class folder was not seen at the top level');
      expect(listing.files.map((entry) => entry.file.name), [
        'syllabus.md',
      ], reason: 'a file from a subfolder leaked into the top level');

      final inside = await libraries.read(uuid: library.uuid, path: 'class-01');
      expect(
        (inside as LibraryReadLoaded).listing.files.map((e) => e.file.name),
        ['lecture.md'],
      );
    },
  );

  test('GivenAnOverlappingFolder_WhenAdded_ThenTheCoreRefusesIt', () async {
    // A file in two libraries means two answers to "where does this appear".
    final client = await initializedCore();
    catalog.addFixture('class-01/lecture.md', '# a lecture');
    await addLibraryAndSettle(client, root: catalog.libraryDirectory.path);

    final nested = await CoreLibraryGateway(client).register(
      name: 'Week one',
      rootPath: '${catalog.libraryDirectory.path}/class-01',
    );

    expect(
      (nested as LibraryRegistrationFailed).failure,
      isA<ConflictFailure>(),
      reason: 'the core allowed a library inside a library',
    );
  });

  test(
    'GivenAMissingFolder_WhenAdded_ThenTheCoreRefusesItAndStoresNothing',
    () async {
      final client = await initializedCore();
      final libraries = CoreLibraryGateway(client);

      final refused = await libraries.register(
        name: 'Nowhere',
        rootPath: '${catalog.libraryDirectory.path}-not-there',
      );

      expect(
        (refused as LibraryRegistrationFailed).failure,
        isA<InvalidInputFailure>(),
      );
      final browsed = await libraries.browse();
      expect((browsed as LibraryBrowseLoaded).libraries, isEmpty);
    },
  );

  test('GivenALibrary_WhenRemoved_ThenItsFilesLeaveTheCatalog', () async {
    // On the 0.6.0 core a file is in the catalog only by being in a library,
    // so removing the library removes its records. Files on disk stay.
    final client = await initializedCore();
    final lecture = catalog.addFixture('class-01/lecture.md', '# a lecture');
    final library = await addLibraryAndSettle(
      client,
      root: catalog.libraryDirectory.path,
    );

    final removed = await CoreLibraryGateway(client).remove(uuid: library.uuid);
    expect(removed, isA<LibraryWriteDone>());

    final listing = await CoreCatalogGateway(
      client,
    ).listFiles(type: FileType.text);
    expect(
      (listing as CatalogListingLoaded).files,
      isEmpty,
      reason: 'a removed library left its files in the catalog',
    );
    expect(lecture.existsSync(), isTrue, reason: 'a file on disk was touched');
  });

  test(
    'GivenAMovedFolder_WhenTheRootIsCorrected_ThenTheSameRecordsFollow',
    () async {
      // What pins `libraryMove`'s three consecutive strings: transposed, the
      // JSON body is read as the uuid and nothing moves. And what no fake can
      // show — that the core rewrites the stored paths, so the library is
      // browsable at its new root without a re-index.
      final client = await initializedCore();
      catalog.addFixture('class-01/lecture.md', '# a lecture');
      final library = await addLibraryAndSettle(
        client,
        root: catalog.libraryDirectory.path,
      );

      final libraries = CoreLibraryGateway(client);
      final before = await libraries.read(uuid: library.uuid, path: 'class-01');
      final was = (before as LibraryReadLoaded).listing.files.single.file.uuid;

      // A folder that need not exist: the record is being corrected, and the
      // walk is what answers whether the path is there.
      final moved = await libraries.move(
        uuid: library.uuid,
        rootPath: '${catalog.libraryDirectory.path}-moved',
      );
      expect(moved, isA<LibraryWriteDone>());

      final after = await libraries.read(uuid: library.uuid, path: 'class-01');
      final listing = (after as LibraryReadLoaded).listing;

      expect(
        listing.library.rootPath,
        '${catalog.libraryDirectory.path}-moved',
        reason: 'the library did not move',
      );
      expect(
        listing.files.single.file.uuid,
        was,
        reason:
            'the move replaced the record instead of correcting it — every '
            'watchlist place and reading position pointing at it is now dead',
      );
    },
  );

  test(
    'GivenAnOccupiedFolder_WhenALibraryMovesOnto_ThenTheCoreRefusesIt',
    () async {
      // The conflict the screen has its own sentence for. Asserted against the
      // real core because the status has to survive the crossing to be the one
      // the application shows.
      final client = await initializedCore();
      catalog.addFixture('class-01/lecture.md', '# a lecture');
      final photos = Directory('${catalog.libraryDirectory.path}-photos')
        ..createSync();
      final course = await addLibraryAndSettle(
        client,
        root: catalog.libraryDirectory.path,
      );
      await addLibraryAndSettle(client, root: photos.path, name: 'Photos');

      final refused = await CoreLibraryGateway(
        client,
      ).move(uuid: course.uuid, rootPath: '${photos.path}/2024');

      expect(
        (refused as LibraryWriteFailed).failure,
        isA<ConflictFailure>(),
        reason: 'the overlap did not reach the application as a conflict',
      );
    },
  );

  test('GivenAnIndexedLibrary_WhenScannedAgain_ThenANewRunCompletes', () async {
    final client = await initializedCore();
    catalog.addFixture('class-01/lecture.md', '# a lecture');
    final library = await addLibraryAndSettle(
      client,
      root: catalog.libraryDirectory.path,
    );
    catalog.addFixture('class-02/lecture.md', '# another lecture');

    final started = await CoreIndexGateway(
      client,
    ).startLibraryIndex(uuid: library.uuid);
    final run = await settleRun(client, (started as IndexStarted).runId);

    expect(run.status, IndexRunStatus.complete);
    expect(run.libraryUuid, library.uuid);
    final listing = await CoreCatalogGateway(
      client,
    ).listFiles(type: FileType.text);
    expect((listing as CatalogListingLoaded).files, hasLength(2));
  });

  test('GivenAnUnknownLibrary_WhenScanned_ThenTheCoreSaysNotFound', () async {
    // What pins the new status code across the boundary: an unknown library
    // reaches the application as not found, not as a generic failure.
    final client = await initializedCore();

    final refused = await CoreIndexGateway(
      client,
    ).startLibraryIndex(uuid: '00000000-0000-4000-8000-000000000000');

    expect((refused as IndexStartFailed).failure, isA<NotFoundFailure>());
  });

  test(
    'GivenADeletedLibraryFile_WhenTheReviewReadsTheCore_ThenItIsThere',
    () async {
      // A deleted library file appears in no type panel and not in its own
      // library either — `list_in_library` answers only active files. Without
      // this it could be restored from nowhere.
      final client = await initializedCore();
      catalog.addFixture('class-01/lecture.md', '# a lecture');
      await addLibraryAndSettle(client, root: catalog.libraryDirectory.path);

      final gateway = CoreCatalogGateway(client);
      final listed = await gateway.listFiles(type: FileType.text);
      final uuid = (listed as CatalogListingLoaded).files.single.file.uuid;

      final deleted = await CoreLifecycleGateway(
        client,
      ).softDeleteFile(uuid: uuid);
      expect(deleted, isA<LifecycleWriteDone>());

      final review = await gateway.listFiles(
        type: FileType.text,
        lifecycle: LifecycleFilter.deleted,
      );

      expect(
        (review as CatalogListingLoaded).files.map((row) => row.file.uuid),
        [uuid],
        reason: 'the owner could not have got this file back',
      );
    },
  );
}
