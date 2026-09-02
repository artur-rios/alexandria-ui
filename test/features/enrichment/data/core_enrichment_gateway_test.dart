import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/enrichment/data/core_enrichment_gateway.dart';
import 'package:alexandria_ui/features/enrichment/domain/enrichment_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_core_client.dart';

/// Reading and running enrichment over the core's calls (music enrichment
/// design).
void main() {
  const credential = 'session-1';
  const fileUuid = 'f-1';

  ({FakeCoreClient core, CoreEnrichmentGateway gateway}) build(
    String? json, {
    int status = ENRICHMENT_OK,
  }) {
    final core = FakeCoreClient()
      ..enrichmentResponse = (status: status, json: json);
    return (core: core, gateway: CoreEnrichmentGateway(core));
  }

  group('reading one track', () {
    test('GivenBothHalves_WhenRead_ThenBothArriveParsed', () async {
      final built = build('''
        {
          "artistImage": {
            "artistName": "Miles Davis",
            "imagePath": "/cache/artist-images/mb-1.jpg",
            "sourceUrl": "https://commons.example/portrait.jpg"
          },
          "lyrics": {
            "plain": "first line\\nsecond line",
            "source": "lrclib"
          }
        }
      ''');

      final read = await built.gateway.readTrack(
        fileUuid: fileUuid,
        artistName: 'Miles Davis',
        credential: credential,
      );

      final enrichment = (read as TrackEnrichmentReadLoaded).enrichment;
      expect(enrichment.artistImage?.path, '/cache/artist-images/mb-1.jpg');
      expect(enrichment.lyrics?.lines, ['first line', 'second line']);
      expect(enrichment.lyrics?.source, 'lrclib');
    });

    test(
      'GivenTheArtistName_WhenRead_ThenItIsSentInTheRightPosition',
      () async {
        // `enrichmentReadTrack` takes three consecutive strings, so a
        // transposition compiles and misbehaves silently — the uuid would be
        // searched for as an artist name and nothing would ever be found.
        final built = build('{}');

        await built.gateway.readTrack(
          fileUuid: fileUuid,
          artistName: 'Miles Davis',
          credential: credential,
        );

        expect(built.core.enrichmentReadCalls, [
          (uuid: fileUuid, artist: 'Miles Davis', token: credential),
        ]);
      },
    );

    test('GivenNoArtist_WhenRead_ThenNoImageIsAskedFor', () async {
      // The core reads an empty name as "no image wanted", which is the same
      // thing its own NULL means — there is no third state to carry.
      final built = build('{}');

      await built.gateway.readTrack(fileUuid: fileUuid, credential: credential);

      expect(built.core.enrichmentReadCalls.single.artist, '');
    });

    test('GivenNothingStored_WhenRead_ThenItIsEmptyRatherThanFailed', () async {
      // Most of a real library. A state, not a failure.
      final built = build('{"artistImage": null, "lyrics": null}');

      final read = await built.gateway.readTrack(
        fileUuid: fileUuid,
        credential: credential,
      );

      expect((read as TrackEnrichmentReadLoaded).enrichment.isEmpty, isTrue);
    });

    test(
      'GivenAnImageRowWithNoPath_WhenRead_ThenThereIsNothingToShow',
      () async {
        // A row can record that a lookup happened and concluded nothing — the
        // artist was not found, or the match scored too low. There is no
        // picture to draw for that.
        final built = build(
          '{"artistImage": {"artistName": "Nobody", "imagePath": null}}',
        );

        final read = await built.gateway.readTrack(
          fileUuid: fileUuid,
          artistName: 'Nobody',
          credential: credential,
        );

        expect(
          (read as TrackEnrichmentReadLoaded).enrichment.artistImage,
          isNull,
        );
      },
    );

    test('GivenBlankLyrics_WhenRead_ThenThereAreNoneToShow', () async {
      final built = build('{"lyrics": {"plain": "   ", "synced": null}}');

      final read = await built.gateway.readTrack(
        fileUuid: fileUuid,
        credential: credential,
      );

      expect((read as TrackEnrichmentReadLoaded).enrichment.lyrics, isNull);
    });

    test('GivenWindowsLineEndings_WhenRead_ThenTheLinesSplitCleanly', () async {
      // The text is whatever a contributor typed, and a file that travelled
      // through Windows carries CRLF — left alone it becomes a stray
      // carriage return at the end of every rendered line.
      final built = build('{"lyrics": {"plain": "first\\r\\nsecond"}}');

      final read = await built.gateway.readTrack(
        fileUuid: fileUuid,
        credential: credential,
      );

      expect((read as TrackEnrichmentReadLoaded).enrichment.lyrics?.lines, [
        'first',
        'second',
      ]);
    });

    test(
      'GivenAMalformedPayload_WhenRead_ThenItFailsRatherThanThrows',
      () async {
        final built = build('not json at all');

        final read = await built.gateway.readTrack(
          fileUuid: fileUuid,
          credential: credential,
        );

        expect(read, isA<TrackEnrichmentReadFailed>());
      },
    );

    test(
      'GivenTheCoreRejectsTheSession_WhenRead_ThenItIsUnauthorized',
      () async {
        final built = build(null, status: ENRICHMENT_ERR_UNAUTHORIZED);

        final read = await built.gateway.readTrack(
          fileUuid: fileUuid,
          credential: credential,
        );

        expect(
          (read as TrackEnrichmentReadFailed).failure,
          isA<UnauthorizedFailure>(),
        );
      },
    );
  });

  group('running enrichment', () {
    test('GivenTheSweep_WhenRun_ThenAnEmptyScopeIsSent', () async {
      // The core reads an absent body as the sweep, and an empty string is
      // what "everything not yet looked up" actually is.
      final built = build('{"considered": 0}');

      await built.gateway.run(
        scope: const EnrichmentScope.pending(),
        credential: credential,
      );

      expect(built.core.enrichmentRunCalls.single.scopeJson, '');
    });

    test('GivenOneTrack_WhenRun_ThenItsUuidIsScoped', () async {
      final built = build('{"considered": 2}');

      await built.gateway.run(
        scope: const EnrichmentScope.file(fileUuid),
        credential: credential,
      );

      expect(
        built.core.enrichmentRunCalls.single.scopeJson,
        '{"fileUuid":"f-1"}',
      );
    });

    test('GivenOneArtist_WhenRun_ThenTheirNameIsScoped', () async {
      final built = build('{"considered": 9}');

      await built.gateway.run(
        scope: const EnrichmentScope.artist('Miles Davis'),
        credential: credential,
      );

      expect(
        built.core.enrichmentRunCalls.single.scopeJson,
        '{"artist":"Miles Davis"}',
      );
    });

    test('GivenARun_WhenItFinishes_ThenTheCountsComeBack', () async {
      final built = build(
        '{"considered": 10, "found": 4, "notFound": 3, "rejected": 1,'
        ' "failed": 1, "skipped": 1}',
      );

      final outcome = await built.gateway.run(
        scope: const EnrichmentScope.pending(),
        credential: credential,
      );

      final report = (outcome as EnrichmentRunDone).report;
      expect(report.considered, 10);
      expect(report.found, 4);
      expect(report.failed, 1);
    });

    test(
      'GivenEnrichmentIsSwitchedOff_WhenRun_ThenItReadsAsConfiguration',
      () async {
        // Not the owner's mistake: the request was well formed and this
        // installation has not turned the feature on. A surface that saw an
        // invalid input would blame them for it.
        final built = build(null, status: ENRICHMENT_ERR_UNAVAILABLE);

        final outcome = await built.gateway.run(
          scope: const EnrichmentScope.pending(),
          credential: credential,
        );

        expect(
          (outcome as EnrichmentRunFailed).failure,
          isA<ConfigurationFailure>(),
        );
      },
    );
  });

  group("one artist's photograph, by name (FR-PL-15)", () {
    test('GivenAStoredPicture_WhenReadByName_ThenItComesBack', () async {
      // The read an artists list makes once per row: by the name the row
      // shows, never by a file, because the list is grouped by a name no
      // single file may be tagged with.
      final core = FakeCoreClient()
        ..artistImageResponse = (
          status: ENRICHMENT_OK,
          json:
              '{"artistName":"Miles Davis",'
              '"imagePath":"/cache/artist-images/mb-1.jpg",'
              '"sourceUrl":"https://commons.example/Miles"}',
        );

      final image = await CoreEnrichmentGateway(
        core,
      ).readArtistImage(artistName: 'Miles Davis', credential: credential);

      expect(image?.path, '/cache/artist-images/mb-1.jpg');
      expect(image?.sourceUrl, 'https://commons.example/Miles');
      expect(core.artistImageReads.single.name, 'Miles Davis');
    });

    test(
      'GivenNobodyHasLookedThemUp_WhenReadByName_ThenNothingComesBack',
      () async {
        // Not found is the ordinary answer here, not a failure: most of a
        // library has never been looked up, and a list has nothing different
        // to draw for "never asked" and "asked, nothing found".
        final core = FakeCoreClient()
          ..artistImageResponse = (
            status: ENRICHMENT_ERR_NOT_FOUND,
            json: null,
          );

        final image = await CoreEnrichmentGateway(
          core,
        ).readArtistImage(artistName: 'Nobody', credential: credential);

        expect(image, isNull);
      },
    );

    test('GivenALookupFindsOne_WhenFetched_ThenItSaysSo', () async {
      final core = FakeCoreClient()
        ..artistImageFetchResponse = (
          status: ENRICHMENT_OK,
          json:
              '{"artistName":"Miles Davis",'
              '"imagePath":"/cache/artist-images/mb-1.jpg"}',
        );

      final outcome = await CoreEnrichmentGateway(
        core,
      ).fetchArtistImage(artistName: 'Miles Davis', credential: credential);

      expect(outcome, ArtistImageLookup.found);
      expect(core.artistImageFetches.single.name, 'Miles Davis');
    });

    test('GivenTheServicesHaveNobody_WhenFetched_ThenItSettles', () async {
      // A row with no picture is a settled answer, and the caller reads it
      // as one: the services have been asked, so nothing asks again.
      final core = FakeCoreClient()
        ..artistImageFetchResponse = (
          status: ENRICHMENT_OK,
          json: '{"artistName":"Nobody","outcome":"notFound"}',
        );

      final outcome = await CoreEnrichmentGateway(
        core,
      ).fetchArtistImage(artistName: 'Nobody', credential: credential);

      expect(outcome, ArtistImageLookup.nothing);
    });

    test('GivenTheCoreRefuses_WhenFetched_ThenItIsUnavailable', () async {
      // Switched off, unreachable, or refused: all three are "could not ask",
      // which is what makes a pass give up rather than walk a whole library
      // discovering it is offline.
      final core = FakeCoreClient()
        ..artistImageFetchResponse = (
          status: ENRICHMENT_ERR_UNAVAILABLE,
          json: null,
        );

      final outcome = await CoreEnrichmentGateway(
        core,
      ).fetchArtistImage(artistName: 'Miles Davis', credential: credential);

      expect(outcome, ArtistImageLookup.unavailable);
    });
  });
}
