import 'dart:io';

import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/auth/data/core_auth_gateway.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_ui/features/catalog/data/core_catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/library_sources/data/core_index_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/temporary_catalog.dart';

/// What a scoped index run actually records, against the real core (UC-05,
/// FR-LB-03, alexandria-api #122).
///
/// Every other test of this feature runs against a fake that this application
/// also wrote, so none of them can tell whether the core agrees about what a
/// scope means. The failure that matters is silent in all of them: the wire
/// names could be spelled differently on the two sides, the comma-separated
/// form could be read as one long name, or the argument could arrive as the
/// wrong pointer entirely — and in each case the run succeeds and indexes
/// everything, which looks exactly like a working scope over a folder that
/// happened to hold nothing else.
///
/// The owner's report is the assertion: cover art in a music folder stopped
/// being catalogued. This is the smallest honest version of it.
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

  /// Indexes [root] with [types] and waits for the run to settle.
  ///
  /// Settling is a count that stops changing rather than a run status, because
  /// what this test asserts is an *absence* — and an absence is only
  /// meaningful once the walk is over. Polling until a file appears, the way
  /// the listing-shape test does, would answer the moment the first file
  /// landed and prove nothing about the second.
  Future<void> indexAndSettle(
    CoreClient client,
    String credential,
    String root,
    String? types,
  ) async {
    final start = await client.indexStart(root, credential, null, types);
    expect(
      CoreStatusFamily.indexing.isOk(start.status),
      isTrue,
      reason: 'the run would not start',
    );

    var stable = 0;
    var last = -1;
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (stable < 5) {
      expect(
        DateTime.now().isBefore(deadline),
        isTrue,
        reason: 'the run never settled',
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final count = await client.indexCountFiles();
      stable = count == last ? stable + 1 : 0;
      last = count;
    }
  }

  Future<List<String>> namesOf(
    CoreClient client,
    String credential,
    FileType type,
  ) async {
    final listing = await CoreCatalogGateway(
      client,
    ).listFiles(type: type, credential: credential);
    expect(listing, isA<CatalogListingLoaded>());

    return [
      for (final row in (listing as CatalogListingLoaded).files) row.file.name,
    ];
  }

  test(
    'GivenAFolderScopedToOneType_WhenItIsIndexed_ThenTheOtherTypeIsNotCataloged',
    () async {
      // Two types that classify by extension alone, so the fixtures need no
      // real binary content and the test is about the scope rather than about
      // whether a tag reader liked the file.
      final (client, credential) = await signedInCore();
      catalog.addFixture('note.md', '# a note');
      catalog.addFixture('page.html', '<h1>a page</h1>');

      await indexAndSettle(
        client,
        credential,
        catalog.libraryDirectory.path,
        FileType.text.wireName,
      );

      expect(await namesOf(client, credential, FileType.text), [
        'note.md',
      ], reason: 'the scoped type should have been cataloged');
      expect(
        await namesOf(client, credential, FileType.html),
        isEmpty,
        reason:
            'the core cataloged a type the run was scoped away from — the '
            'scope did not survive the crossing into the core',
      );
    },
  );

  test('GivenNoScope_WhenAFolderIsIndexed_ThenEveryTypeIsCataloged', () async {
    // The other half of the contract, and the one that makes the test above
    // mean something: without it, a scope argument that silently broke
    // *every* run would still pass, because the absence it asserts would be
    // there for the wrong reason.
    final (client, credential) = await signedInCore();
    catalog.addFixture('note.md', '# a note');
    catalog.addFixture('page.html', '<h1>a page</h1>');

    await indexAndSettle(
      client,
      credential,
      catalog.libraryDirectory.path,
      null,
    );

    expect(await namesOf(client, credential, FileType.text), ['note.md']);
    expect(await namesOf(client, credential, FileType.html), ['page.html']);
  });
  test('GivenARunThatReadEverything_WhenItsFailuresAreRead_ThenThereAreNone', () async {
    // The failures call across the boundary (core FR-FC-42). What it pins is
    // the call itself — two consecutive strings, which transposed asks the
    // core about a token — and that a clean run answers an empty list rather
    // than an error the screen would show as "could not ask".
    final (client, credential) = await signedInCore();
    catalog.addFixture('note.md', '# a note');

    final start = await client.indexStart(
      catalog.libraryDirectory.path,
      credential,
      null,
      null,
    );
    expect(CoreStatusFamily.indexing.isOk(start.status), isTrue);

    await indexAndSettle(client, credential, catalog.libraryDirectory.path, null);

    final outcome = await CoreIndexGateway(client).readFailures(
      runId: start.runId,
      credential: credential,
    );

    expect(outcome, isA<RunFailuresRead>());
    expect((outcome as RunFailuresRead).failures, isEmpty);
  });

  test('GivenARunThatNeverRan_WhenItsFailuresAreRead_ThenItIsNotFound', () async {
    // Not an empty list: "failed on nothing" is a different fact from "no
    // such run", and the screen would show the first as a clean scan.
    final (client, credential) = await signedInCore();

    final outcome = await CoreIndexGateway(client).readFailures(
      runId: '00000000-0000-4000-8000-000000000000',
      credential: credential,
    );

    expect(outcome, isA<RunFailuresFailed>());
    expect(
      (outcome as RunFailuresFailed).failure,
      isA<NotFoundFailure>(),
      reason: 'an unknown run did not reach the application as not-found',
    );
  });

}
