import 'dart:io';

import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/auth/data/core_auth_gateway.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_ui/features/catalog/data/core_catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/enrichment/data/core_enrichment_gateway.dart';
import 'package:alexandria_ui/features/enrichment/domain/enrichment_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/temporary_catalog.dart';

/// The enrichment calls across the real FFI boundary (music enrichment
/// design).
///
/// Every unit test of this feature runs against a fake this application also
/// wrote, so none of them can tell whether the two sides agree. The failure
/// that matters is silent in all of them: `core_isolate.dart`'s switch cases
/// map `arguments[n]` onto positional native parameters, and
/// `alexandria_enrichment_read_track` takes **three consecutive strings** —
/// a uuid, an artist name and a token. Transpose any two and it compiles,
/// passes every unit test, and misbehaves only at run time.
///
/// **Nothing here reaches the network, and that is deliberate.** The lookup
/// itself is left unconfigured, which is the shipped default — so a run is
/// refused before a single request leaves the machine. A suite that called
/// MusicBrainz would be slow, flaky, and rude to a service that rate-limits
/// to one request per second, and it would prove nothing this does not.
///
/// What makes these assertions catch a transposition is that each argument
/// is answered *differently*: a malformed uuid is invalid input, a bad token
/// is unauthorized, and a well-formed call to an unconfigured installation
/// is unavailable. Passing the right thing in the wrong slot turns one into
/// another.
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

  /// A catalogued audio file's uuid, so the read has a real row to address.
  Future<String> anIndexedTrack(CoreClient client, String credential) async {
    catalog.addFixture('so-what.flac');

    final start = await client.indexStart(
      catalog.libraryDirectory.path,
      credential,
    );
    expect(CoreStatusFamily.indexing.isOk(start.status), isTrue);

    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (await client.indexCountFiles() < 1) {
      expect(
        DateTime.now().isBefore(deadline),
        isTrue,
        reason: 'the run never catalogued the fixture',
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    final listing = await CoreCatalogGateway(
      client,
    ).listFiles(type: LibraryType.audio, credential: credential);
    expect(listing, isA<CatalogListingLoaded>());

    return (listing as CatalogListingLoaded).files.single.file.uuid;
  }

  test(
    'GivenARealCore_WhenATrackIsRead_ThenTheApplicationCanParseTheAnswer',
    () async {
      // The uuid is in the first slot and the artist in the second. Swap
      // them and the artist name is parsed as a uuid, which fails — so a
      // *loaded* answer is what proves the order, not merely a non-null one.
      final (client, credential) = await signedInCore();
      final fileUuid = await anIndexedTrack(client, credential);

      final read = await CoreEnrichmentGateway(client).readTrack(
        fileUuid: fileUuid,
        artistName: 'Miles Davis',
        credential: credential,
      );

      expect(
        read,
        isA<TrackEnrichmentReadLoaded>(),
        reason:
            'the core answered a shape this application could not read, or '
            'the arguments arrived in the wrong order',
      );
      // Nothing has been looked up, so both halves are absent. A state, not
      // a failure — and the only honest answer for a library that has never
      // run enrichment.
      expect((read as TrackEnrichmentReadLoaded).enrichment.isEmpty, isTrue);
    },
  );

  test('GivenAMalformedUuid_WhenATrackIsRead_ThenItIsInvalidInput', () async {
    // The other half of the pair above, and what gives it its teeth: this
    // is the answer the first test would get if the uuid and the artist
    // were swapped. Asserting both pins the order rather than the shape.
    final (client, credential) = await signedInCore();

    final read = await CoreEnrichmentGateway(client).readTrack(
      fileUuid: 'not-a-uuid',
      artistName: 'Miles Davis',
      credential: credential,
    );

    expect(
      (read as TrackEnrichmentReadFailed).failure,
      isA<InvalidInputFailure>(),
    );
  });

  test('GivenARejectedToken_WhenATrackIsRead_ThenItIsUnauthorized', () async {
    // The third slot. A token in the wrong position authenticates nothing,
    // so this is what a transposition involving it looks like.
    final (client, credential) = await signedInCore();
    final fileUuid = await anIndexedTrack(client, credential);

    final read = await CoreEnrichmentGateway(client).readTrack(
      fileUuid: fileUuid,
      artistName: 'Miles Davis',
      credential: 'not-a-session',
    );

    expect(
      (read as TrackEnrichmentReadFailed).failure,
      isA<UnauthorizedFailure>(),
    );
  });

  test(
    'GivenAnUnconfiguredInstallation_WhenARunIsStarted_ThenItIsRefusedNotAttempted',
    () async {
      // The default this feature ships with, asserted against the real core
      // rather than trusted: with no `[metadata]` configuration, a run is
      // refused before a single request leaves the machine.
      //
      // It also pins `alexandria_enrichment_run`'s two arguments. A
      // well-formed scope with a valid token is the only combination that
      // answers *unavailable* — swap them and the token is parsed as a
      // scope, or the scope is offered as a token, and the answer changes.
      final (client, credential) = await signedInCore();

      final outcome = await CoreEnrichmentGateway(client).run(
        scope: const EnrichmentScope.pending(),
        credential: credential,
      );

      expect(
        (outcome as EnrichmentRunFailed).failure,
        isA<ConfigurationFailure>(),
        reason:
            'an unconfigured installation either attempted the lookup or '
            'reported it as something the owner did wrong',
      );
    },
  );

  test('GivenARejectedToken_WhenARunIsStarted_ThenItIsUnauthorized', () async {
    final (client, _) = await signedInCore();

    final outcome = await CoreEnrichmentGateway(client).run(
      scope: const EnrichmentScope.pending(),
      credential: 'not-a-session',
    );

    expect(
      (outcome as EnrichmentRunFailed).failure,
      isA<UnauthorizedFailure>(),
    );
  });
}
