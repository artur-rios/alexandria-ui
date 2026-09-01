import 'dart:convert';
import 'dart:io';

import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/core/bindings/core_environment.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/features/auth/data/core_auth_gateway.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/temporary_catalog.dart';

/// That the owner's music-lookup choice actually reaches the real core
/// (music enrichment design).
///
/// A file of its own, and it has to be. The variables the core reads are the
/// *process's* environment, and this application only ever sets one that is
/// not already set — so whichever configuration a test process applies
/// first is the one every core loaded in it afterwards sees. The opposite
/// case (an installation with the lookup off, which is the core's own
/// default) is asserted in `enrichment_boundary_test.dart`, which runs in
/// its own process and never asks for anything else.
///
/// **Nothing here reaches the network.** Availability is read back through
/// `alexandria_settings_json`, which answers from the settings the core was
/// started with — the very check the core makes before it would send a
/// request — so this proves the wiring without troubling MusicBrainz.
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

  Future<(CoreClient, String)> signedInCore({
    required MusicLookup musicLookup,
  }) async {
    final client = await FfiCoreClient.load(libraryPath);
    addTearDown(client.dispose);

    final status = await client.initialize(
      catalog.databasePath,
      musicLookup: musicLookup,
    );
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
    'GivenTheApplicationsOwnConfiguration_WhenTheCoreIsAsked_ThenLookupIsAvailable',
    () async {
      // The end of the wire, and the one assertion that would have caught
      // the defect this closes: the application used to initialize the core
      // saying nothing about `[metadata]`, so the core took its own
      // default — off — and refused every lookup the owner asked for, with
      // nothing anywhere in the interface to turn it on.
      //
      // Proven through `alexandria_settings_json`, so nothing here reaches
      // the network: the core answers it from the settings it was started
      // with, and it is exactly the check
      // `MetadataSettings::unavailable_reason` makes before any request.
      final (client, credential) = await signedInCore(
        musicLookup: const MusicLookup(
          enabled: true,
          contact: defaultMusicLookupContact,
        ),
      );

      final response = await client.settings(credential);
      expect(CoreStatusFamily.settings.isOk(response.status), isTrue);
      final metadata =
          (jsonDecode(response.json!) as Map<String, dynamic>)['metadata']
              as Map<String, dynamic>;

      expect(
        metadata['available'],
        isTrue,
        reason:
            'the variables the application sets before initialization did '
            'not reach the core, or it reads different ones: ${response.json}',
      );
      expect(metadata['unavailableReason'], isNull);
    },
  );
}
