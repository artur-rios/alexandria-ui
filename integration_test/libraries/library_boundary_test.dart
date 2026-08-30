import 'dart:io';

import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/auth/data/core_auth_gateway.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_ui/features/catalog/data/core_catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/libraries/data/core_library_gateway.dart';
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
}
