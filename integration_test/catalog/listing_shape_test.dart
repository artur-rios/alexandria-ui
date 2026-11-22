import 'dart:io';

import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/features/catalog/data/core_catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/library_runs.dart';
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

  /// A core initialized against this run's throwaway database.
  Future<CoreClient> initializedCore() async {
    final client = await FfiCoreClient.load(libraryPath);
    addTearDown(client.dispose);

    final status = await client.initialize(catalog.databasePath);
    expect(CoreStatusFamily.indexing.isOk(status), isTrue);

    return client;
  }

  test(
    'GivenAnIndexedLibrary_WhenItIsListed_ThenThisApplicationCanParseTheAnswer',
    () async {
      // The assertion that matters is `loaded`, not the count: an answer this
      // application cannot parse comes back as a failure rather than as an
      // exception, so a listing that is merely *not* loaded is the whole bug.
      final client = await initializedCore();
      catalog.addFixture('note.md', '# a note');
      await addLibraryAndSettle(client, root: catalog.libraryDirectory.path);

      final listing = await CoreCatalogGateway(
        client,
      ).listFiles(type: FileType.text);

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
      final client = await initializedCore();
      catalog.addFixture('note.md', '# a note');
      await addLibraryAndSettle(client, root: catalog.libraryDirectory.path);

      final listing = await CoreCatalogGateway(
        client,
      ).listFiles(type: FileType.text);

      final row = (listing as CatalogListingLoaded).files.single;
      expect(row.file.name, 'note.md');
      expect(row.file.path, contains('note.md'));
      expect(row.file.type, FileType.text);
    },
  );
}
