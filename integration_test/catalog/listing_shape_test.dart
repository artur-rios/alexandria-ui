import 'dart:io';

import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/features/auth/data/core_auth_gateway.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_ui/features/catalog/data/core_catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/temporary_catalog.dart';

/// The shape the core actually answers a listing in (UC-03, FR-FC-12,
/// IR-14).
///
/// This is the one test in either repository that checks the *contract between
/// them*. The core's own suite proves it emits a full record per row; this
/// application's own suite proves it can parse one, against a fake that this
/// application also wrote. Neither notices if the two disagree — and when they
/// do, nothing throws: `listFiles` answers an unreadable listing, and the
/// interface shows an empty library and a retry, which is exactly what a
/// working core with nothing in it looks like.
///
/// That failure mode is why this exists. A field renamed on one side of the
/// boundary is invisible to both suites and silent in the interface.
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

  /// Indexes [root] and waits for the catalog to hold something.
  ///
  /// Polled rather than awaited: an index run is asynchronous, and the run's
  /// own status call is a second contract this test has no reason to depend
  /// on. What it needs is a catalog with a file in it.
  Future<void> indexAndSettle(
    CoreClient client,
    String credential,
    String root,
  ) async {
    final start = await client.indexStart(root, credential);
    expect(
      CoreStatusFamily.indexing.isOk(start.status),
      isTrue,
      reason: 'the run would not start',
    );

    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (await client.indexCountFiles() < 1) {
      expect(
        DateTime.now().isBefore(deadline),
        isTrue,
        reason: 'the run never catalogued the fixture',
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  test(
    'GivenAnIndexedLibrary_WhenItIsListed_ThenThisApplicationCanParseTheAnswer',
    () async {
      // The assertion that matters is `loaded`, not the count: an answer this
      // application cannot parse comes back as a failure rather than as an
      // exception, so a listing that is merely *not* loaded is the whole bug.
      final (client, credential) = await signedInCore();
      catalog.addFixture('note.md', '# a note');
      await indexAndSettle(client, credential, catalog.libraryDirectory.path);

      final listing = await CoreCatalogGateway(client).listFiles(
        type: LibraryType.text,
        credential: credential,
      );

      expect(
        listing,
        isA<CatalogListingLoaded>(),
        reason:
            'the core answered a shape this application could not read — the '
            'two sides of the FFI boundary have drifted apart',
      );
      expect((listing as CatalogListingLoaded).files, isNotEmpty);
    },
  );

  test(
    'GivenAnIndexedLibrary_WhenItIsListed_ThenEachRowCarriesItsOwnFile',
    () async {
      // The listing element is the same record a single-file lookup answers
      // (FR-FC-12): the file, its metadata, and the extracted scalars. What is
      // checked here is that the file half arrives intact — a row parsed from
      // the wrong nesting would leave it null and the row would be dropped
      // silently.
      final (client, credential) = await signedInCore();
      catalog.addFixture('note.md', '# a note');
      await indexAndSettle(client, credential, catalog.libraryDirectory.path);

      final listing = await CoreCatalogGateway(client).listFiles(
        type: LibraryType.text,
        credential: credential,
      );

      final row = (listing as CatalogListingLoaded).files.single;
      expect(row.file.name, 'note.md');
      expect(row.file.path, contains('note.md'));
      expect(row.file.type, LibraryType.text);
    },
  );
}
