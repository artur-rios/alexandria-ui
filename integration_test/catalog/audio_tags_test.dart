import 'dart:io';

import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/features/auth/data/core_auth_gateway.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_ui/features/catalog/data/core_catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../support/library_runs.dart';
import '../support/temporary_catalog.dart';

/// Audio's tags as the real core reads and answers them (core 0.6.0).
///
/// The Music panel names a track by its title and orders an album by its
/// track numbers, all from the listing's rows. Whether those rows carry the
/// tags at all — and under the names this application reads — is a contract
/// only the real core can answer. The fixture is a one-second FLAC tagged by
/// ffmpeg.
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

  test(
    'GivenATaggedAudioFile_WhenItsLibraryIsIndexed_ThenItsTagsAreListed',
    () async {
      final (client, credential) = await signedInCore();
      File('integration_test/fixtures/tagged.flac').copySync(
        p.join(catalog.libraryDirectory.path, 'tagged.flac'),
      );
      await addLibraryAndSettle(
        client,
        credential,
        root: catalog.libraryDirectory.path,
      );

      final listing = await CoreCatalogGateway(
        client,
      ).listFiles(type: FileType.audio, credential: credential);
      final file = (listing as CatalogListingLoaded).files.single.file;

      expect(file.type, FileType.audio);
      expect(file.tags?.title, 'Fixture Song');
      expect(file.tags?.artist, 'Fixture Band');
      expect(file.tags?.album, 'Fixture Record');
      expect(file.tags?.track, 3);
      expect(file.durationSeconds, closeTo(1, 0.2));
    },
  );
}
