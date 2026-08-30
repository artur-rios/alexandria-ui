import 'dart:io';

import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/auth/data/core_auth_gateway.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_ui/features/catalog/data/core_catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/domain/listing_view.dart';
import 'package:alexandria_ui/features/libraries/data/core_library_gateway.dart';
import 'package:alexandria_ui/features/lifecycle/data/core_lifecycle_gateway.dart';
import 'package:alexandria_ui/features/lifecycle/domain/lifecycle_gateway.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/temporary_catalog.dart';

/// A library's whole life against the real core, over the real FFI
/// (libraries design).
///
/// Every unit test of this feature runs against a fake this application also
/// wrote, so none of them can tell whether the two sides agree — about the
/// wire names, about what "overlapping" means, or about the argument order.
/// `alexandria_library_browse` takes **three consecutive strings**: a uuid,
/// a folder path and a token. Transpose any two and it compiles, passes
/// every unit test, and answers an empty folder at run time — which looks
/// exactly like a library nobody has indexed into yet.
///
/// It also proves the thing the whole feature is for: that a file under a
/// library stops appearing in its type panel. No fake can show that, because
/// the exclusion lives in the core's own query.
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

  /// Indexes the fixture library and waits for every file to be catalogued.
  Future<void> indexAndSettle(
    CoreClient client,
    String credential,
    int expected,
  ) async {
    final start = await client.indexStart(
      catalog.libraryDirectory.path,
      credential,
    );
    expect(CoreStatusFamily.indexing.isOk(start.status), isTrue);

    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (await client.indexCountFiles() < expected) {
      expect(
        DateTime.now().isBefore(deadline),
        isTrue,
        reason: 'the run never catalogued every fixture',
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  test(
    'GivenARealCore_WhenAFolderIsMadeALibrary_ThenItsFilesLeaveTheTypePanel',
    () async {
      // The point of the whole feature, and the one thing no fake can show:
      // the exclusion lives in the core's own listing query.
      final (client, credential) = await signedInCore();
      final lecture = catalog.libraryDirectory.path;
      catalog.addFixture('class-01/lecture.md', '# a lecture');
      catalog.addFixture('class-01/handout.md', '# a handout');
      await indexAndSettle(client, credential, 2);

      final libraries = CoreLibraryGateway(client);
      final registered = await libraries.register(
        name: 'Course',
        rootPath: lecture,
        credential: credential,
      );
      expect(registered, isA<LibraryWriteDone>());

      final listing = await CoreCatalogGateway(
        client,
      ).listFiles(type: FileType.text, credential: credential);

      expect(
        (listing as CatalogListingLoaded).files,
        isEmpty,
        reason: 'a library file was still listed in its type panel',
      );
    },
  );

  test('GivenALibrary_WhenBrowsed_ThenItsTreeComesBackOneLevelAtATime', () async {
    // Also what pins `libraryBrowse`'s three arguments: transposed, the uuid
    // is read as a folder path and this answers an empty top level.
    final (client, credential) = await signedInCore();
    catalog.addFixture('class-01/lecture.md', '# a lecture');
    catalog.addFixture('syllabus.md', '# the syllabus');
    await indexAndSettle(client, credential, 2);

    final libraries = CoreLibraryGateway(client);
    await libraries.register(
      name: 'Course',
      rootPath: catalog.libraryDirectory.path,
      credential: credential,
    );
    final browsed = await libraries.browse(credential: credential);
    final uuid = (browsed as LibraryBrowseLoaded).libraries.single.uuid;

    final top = await libraries.read(
      uuid: uuid,
      path: '',
      credential: credential,
    );
    final listing = (top as LibraryReadLoaded).listing;

    expect(listing.library.name, 'Course');
    expect(
      listing.folders.map((folder) => folder.name),
      ['class-01'],
      reason: 'the class folder was not seen at the top level',
    );
    expect(
      listing.files.map((entry) => entry.file.name),
      ['syllabus.md'],
      reason: 'a file from a subfolder leaked into the top level',
    );

    final inside = await libraries.read(
      uuid: uuid,
      path: 'class-01',
      credential: credential,
    );
    expect(
      (inside as LibraryReadLoaded).listing.files.map((e) => e.file.name),
      ['lecture.md'],
    );
  });

  test('GivenAnOverlappingFolder_WhenRegistered_ThenTheCoreRefusesIt', () async {
    // A file in two libraries means two answers to "where does this appear".
    final (client, credential) = await signedInCore();
    final libraries = CoreLibraryGateway(client);
    await libraries.register(
      name: 'Course',
      rootPath: catalog.libraryDirectory.path,
      credential: credential,
    );

    final nested = await libraries.register(
      name: 'Week one',
      rootPath: '${catalog.libraryDirectory.path}/class-01',
      credential: credential,
    );

    expect(
      (nested as LibraryWriteFailed).failure,
      isA<ConflictFailure>(),
      reason: 'the core allowed a library inside a library',
    );
  });

  test('GivenALibrary_WhenRemoved_ThenItsFilesComeBack', () async {
    // Marking a folder empties part of a panel and that is not visible until
    // afterwards, so the way back has to restore rather than delete.
    final (client, credential) = await signedInCore();
    catalog.addFixture('class-01/lecture.md', '# a lecture');
    await indexAndSettle(client, credential, 1);

    final libraries = CoreLibraryGateway(client);
    await libraries.register(
      name: 'Course',
      rootPath: catalog.libraryDirectory.path,
      credential: credential,
    );
    final browsed = await libraries.browse(credential: credential);
    final uuid = (browsed as LibraryBrowseLoaded).libraries.single.uuid;

    await libraries.remove(uuid: uuid, credential: credential);

    final listing = await CoreCatalogGateway(
      client,
    ).listFiles(type: FileType.text, credential: credential);
    expect(
      (listing as CatalogListingLoaded).files,
      hasLength(1),
      reason: 'removing a library lost its files',
    );
  });

  test('GivenAMovedFolder_WhenTheRootIsCorrected_ThenTheSameRecordsFollow', () async {
    // What pins `libraryMove`'s three consecutive strings: transposed, the
    // JSON body is read as the uuid and nothing moves. And what no fake can
    // show — that the core rewrites the stored paths, so the library is
    // browsable at its new root without a re-index.
    final (client, credential) = await signedInCore();
    catalog.addFixture('class-01/lecture.md', '# a lecture');
    await indexAndSettle(client, credential, 1);

    final libraries = CoreLibraryGateway(client);
    await libraries.register(
      name: 'Course',
      rootPath: catalog.libraryDirectory.path,
      credential: credential,
    );
    final browsed = await libraries.browse(credential: credential);
    final library = (browsed as LibraryBrowseLoaded).libraries.single;

    final before = await libraries.read(
      uuid: library.uuid,
      path: 'class-01',
      credential: credential,
    );
    final was = (before as LibraryReadLoaded).listing.files.single.file.uuid;

    // A folder that need not exist: the record is being corrected, and the
    // walk is what answers whether the path is there.
    final moved = await libraries.move(
      uuid: library.uuid,
      rootPath: '${catalog.libraryDirectory.path}-moved',
      credential: credential,
    );
    expect(moved, isA<LibraryWriteDone>());

    final after = await libraries.read(
      uuid: library.uuid,
      path: 'class-01',
      credential: credential,
    );
    final listing = (after as LibraryReadLoaded).listing;

    expect(
      listing.library.rootPath,
      '${catalog.libraryDirectory.path}-moved',
      reason: 'the library did not move',
    );
    expect(
      listing.files.single.file.uuid,
      was,
      reason: 'the move replaced the record instead of correcting it — every '
          'watchlist place and reading position pointing at it is now dead',
    );
  });

  test('GivenAnOccupiedFolder_WhenALibraryMovesOnto_ThenTheCoreRefusesIt', () async {
    // The conflict the screen has its own sentence for. Asserted against the
    // real core because the status has to survive the crossing to be the one
    // the application shows.
    final (client, credential) = await signedInCore();
    catalog.addFixture('class-01/lecture.md', '# a lecture');
    await indexAndSettle(client, credential, 1);

    final libraries = CoreLibraryGateway(client);
    await libraries.register(
      name: 'Course',
      rootPath: catalog.libraryDirectory.path,
      credential: credential,
    );
    await libraries.register(
      name: 'Photos',
      rootPath: '${catalog.libraryDirectory.path}-photos',
      credential: credential,
    );
    final browsed = await libraries.browse(credential: credential);
    final course = (browsed as LibraryBrowseLoaded).libraries.firstWhere(
      (library) => library.name == 'Course',
    );

    final refused = await libraries.move(
      uuid: course.uuid,
      rootPath: '${catalog.libraryDirectory.path}-photos/2024',
      credential: credential,
    );

    expect(refused, isA<LibraryWriteFailed>());
    expect(
      (refused as LibraryWriteFailed).failure,
      isA<ConflictFailure>(),
      reason: 'the overlap did not reach the application as a conflict',
    );
  });

  CoreLibraryGateway libraryGatewayOf(CoreClient client) =>
      CoreLibraryGateway(client);

  test('GivenALibraryFile_WhenTheCatalogIsSearched_ThenTheRealCoreAnswersIt', () async {
    // The claim the requirements make and the code did not keep: a library
    // narrows where a file is *listed*, never what can be *found*. Asserted
    // against the real core because the exclusion lives in its query, and
    // both halves are here — reaching in finds the file, and the ordinary
    // listing still does not.
    final (client, credential) = await signedInCore();
    catalog.addFixture('class-01/lecture.md', '# a lecture');
    await indexAndSettle(client, credential, 1);

    final libraries = CoreLibraryGateway(client);
    await libraries.register(
      name: 'Course',
      rootPath: catalog.libraryDirectory.path,
      credential: credential,
    );

    final gateway = CoreCatalogGateway(client);
    final panel = await gateway.listFiles(
      type: FileType.text,
      credential: credential,
    );
    expect(
      (panel as CatalogListingLoaded).files,
      isEmpty,
      reason: 'the type panel listed a library file',
    );

    final everywhere = await gateway.listFiles(
      type: FileType.text,
      credential: credential,
      includeLibraries: true,
    );
    final found = (everywhere as CatalogListingLoaded).files;

    expect(
      found.map((row) => row.file.name),
      ['lecture.md'],
      reason: 'a library file could not be found at all, so search cannot',
    );
    expect(
      found.single.libraryUuid,
      isNotNull,
      reason: 'the row did not say it belongs to a library, which is what '
          'the dashboard needs in order to leave it out',
    );
  });

  test('GivenADeletedLibraryFile_WhenTheReviewReadsTheCore_ThenItIsThere', () async {
    // The worse half: a deleted library file appears in no type panel, and
    // not in its own library either — `list_in_library` answers only active
    // files. Without this it could be restored from nowhere.
    final (client, credential) = await signedInCore();
    catalog.addFixture('class-01/lecture.md', '# a lecture');
    await indexAndSettle(client, credential, 1);

    final gateway = CoreCatalogGateway(client);
    final listed = await gateway.listFiles(
      type: FileType.text,
      credential: credential,
    );
    final uuid = (listed as CatalogListingLoaded).files.single.file.uuid;

    await libraryGatewayOf(client).register(
      name: 'Course',
      rootPath: catalog.libraryDirectory.path,
      credential: credential,
    );
    final deleted = await CoreLifecycleGateway(client).softDeleteFile(
      uuid: uuid,
      credential: credential,
    );
    expect(deleted, isA<LifecycleWriteDone>());

    final review = await gateway.listFiles(
      type: FileType.text,
      credential: credential,
      lifecycle: LifecycleFilter.deleted,
      includeLibraries: true,
    );

    expect(
      (review as CatalogListingLoaded).files.map((row) => row.file.uuid),
      [uuid],
      reason: 'the owner could not have got this file back',
    );
  });
}
