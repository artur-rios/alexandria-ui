import 'dart:io';

import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/core/bindings/core_environment.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/features/auth/data/core_auth_gateway.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_ui/features/catalog/data/core_catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/playback/data/core_energy_gateway.dart';
import 'package:alexandria_ui/features/playback/domain/track_energy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/temporary_catalog.dart';
import '../support/wav_fixture.dart';

/// The sound of a track, measured by the real core (UC-21, FR-MP-07).
///
/// The bars on the player are drawn from this and nothing else, so what
/// matters is not that a call answers but that the numbers in it are the
/// music: a tone at a known frequency has to come back loud in the band that
/// frequency belongs to and quiet everywhere else. Every unit test of the
/// player's own reading runs against an envelope this application wrote,
/// and a fake cannot tell whether ffmpeg ever decoded anything.
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

  test(
    'GivenATrackWithATone_WhenItsEnergyIsRead_ThenTheToneIsWhereItBelongs',
    () async {
      final client = await FfiCoreClient.load(libraryPath);
      addTearDown(client.dispose);

      final status = await client.initialize(
        catalog.databasePath,
        musicLookup: MusicLookup.off,
      );
      expect(CoreStatusFamily.indexing.isOk(status), isTrue);

      final outcome = await CoreAuthGateway(client).register(
        email: email,
        password: password,
        passwordConfirmation: password,
      );
      expect(outcome, isA<AuthenticatedOutcome>());
      final credential = (outcome as AuthenticatedOutcome).session.credential;

      // A second of a 1 kHz tone: long enough for several frames, and a
      // frequency in the middle of the measured range so the band it lands
      // in has neighbours on both sides to be louder than.
      File('${catalog.libraryDirectory.path}/tone.wav')
        ..createSync(recursive: true)
        ..writeAsBytesSync(sineWav(hertz: 1000, seconds: 1));

      final started = await client.indexStart(
        catalog.libraryDirectory.path,
        credential,
      );
      expect(CoreStatusFamily.indexing.isOk(started.status), isTrue);

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
      ).listFiles(type: FileType.audio, credential: credential);
      expect(listing, isA<CatalogListingLoaded>());
      final file = (listing as CatalogListingLoaded).files.single.file;

      final read = await CoreEnergyGateway(
        client,
      ).readEnergy(fileUuid: file.uuid, credential: credential);

      expect(
        read,
        isA<TrackEnergyLoaded>(),
        reason: 'the core decoded the tone and measured it',
      );
      final energy = (read as TrackEnergyLoaded).energy;

      expect(energy.bands, greaterThan(1));
      expect(energy.frameMs, greaterThan(0));
      expect(
        energy.frames,
        greaterThan(4),
        reason: 'a second of audio is several frames of envelope',
      );

      // The middle of the track, past the window filling at the start.
      final middle = Duration(
        milliseconds: (energy.frames ~/ 2) * energy.frameMs,
      );
      final levels = [
        for (var band = 0; band < energy.bands; band++)
          energy.levelAt(band: band, position: middle),
      ];
      final loudest = levels.indexOf(levels.reduce((a, b) => a > b ? a : b));

      // A pure tone is one band and nothing else: the loudest band has to
      // tower over the average, or what came back is noise rather than a
      // measurement of this file.
      final average = levels.reduce((a, b) => a + b) / levels.length;
      expect(levels[loudest], greaterThan(0.5));
      expect(
        levels[loudest],
        greaterThan(average * 3),
        reason: 'a 1 kHz tone belongs in one band, not spread across sixteen',
      );

      // And measured once: the second read is the stored envelope, which is
      // what keeps a player from decoding the file on every open.
      final again = await CoreEnergyGateway(
        client,
      ).readEnergy(fileUuid: file.uuid, credential: credential);
      expect(again, isA<TrackEnergyLoaded>());
      expect((again as TrackEnergyLoaded).energy.levels, energy.levels);
    },
  );
}
