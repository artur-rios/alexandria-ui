import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/enrichment/application/artist_portrait_backfill_controller.dart';
import 'package:alexandria_ui/features/enrichment/domain/enrichment_gateway.dart';
import 'package:alexandria_ui/features/enrichment/domain/track_enrichment.dart';
import 'package:alexandria_ui/features/playback/domain/music_browse.dart';
import 'package:alexandria_ui/features/shell/application/preferences_controller.dart';
import 'package:alexandria_ui/features/shell/application/preferences_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_enrichment_gateway.dart';

/// The startup pass that gives every artist a face (FR-PL-15, UC-46 step 3).
///
/// The artists list shows what a lookup has cached and fetches nothing while
/// browsing, which is right for a screenful of rows scrolling past services
/// that allow one request a second — and left the list looking half finished,
/// with a face only for the artists whose lyrics somebody had happened to
/// open. This is the other half: one pass, in the background, filling in the
/// ones that have none.
void main() {
  const image = ArtistImage(
    artistName: 'Miles Davis',
    path: '/cache/artist-images/miles.jpg',
  );

  /// A library of two artists, one track each.
  FakeCatalogGateway twoArtists() => FakeCatalogGateway()
    ..addAudio(
      uuid: 'kob-1',
      title: 'So What',
      album: 'Kind of Blue',
      artist: 'Miles Davis',
    )
    ..addAudio(
      uuid: 'bt-1',
      title: 'Blue Train',
      album: 'Blue Train',
      artist: 'John Coltrane',
    );

  ProviderContainer buildContainer(
    FakeCatalogGateway catalog,
    FakeEnrichmentGateway enrichment, {
    bool musicLookupEnabled = true,
    bool signedIn = true,
  }) {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        catalogGatewayProvider.overrideWithValue(catalog),
        enrichmentGatewayProvider.overrideWithValue(enrichment),
        preferencesControllerProvider.overrideWith(
          () => _FixedPreferences(
            PreferencesState(musicLookupEnabled: musicLookupEnabled),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    if (signedIn) {
      container
          .read(sessionControllerProvider.notifier)
          .establish(FakeAuthGateway.defaultSession);
    }

    return container;
  }

  /// Starts the pass the way the shell does — by holding the provider — and
  /// lets it run to the end.
  Future<void> run(ProviderContainer container) async {
    final subscription = container.listen(
      artistPortraitBackfillProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    await container.read(musicLibraryProvider.future);
    container.read(artistPortraitBackfillProvider);
    // The pass starts from a microtask off the build that asked for it, and
    // every artist is a read and possibly a run: turned over rather than
    // awaited, because nothing hands a caller a future for a background job.
    for (var turn = 0; turn < 16; turn++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test(
    'GivenArtistsWithNoPhotograph_WhenTheAppStarts_ThenEachIsLookedUp',
    () async {
      final enrichment = FakeEnrichmentGateway();
      final container = buildContainer(twoArtists(), enrichment);

      await run(container);

      expect(
        enrichment.runs.whereType<EnrichmentScopeFile>().map(
          (scope) => scope.fileUuid,
        ),
        containsAll(<String>['kob-1', 'bt-1']),
      );
    },
  );

  test(
    'GivenAPhotographAlreadyCached_WhenTheAppStarts_ThenNoLookupIsMade',
    () async {
      // A read is a database call; a run is a request to somebody else's
      // server. After the first session most of a library is answered, and a
      // pass that asked anyway would spend an hour re-fetching pictures it
      // already holds.
      final enrichment = FakeEnrichmentGateway(
        enrichment: const TrackEnrichment(artistImage: image),
      );
      final container = buildContainer(twoArtists(), enrichment);

      await run(container);

      expect(enrichment.reads, hasLength(2));
      expect(enrichment.runs, isEmpty);
    },
  );

  test(
    'GivenTheLookupIsSwitchedOff_WhenTheAppStarts_ThenNothingIsAsked',
    () async {
      // Off means off (FR-UX-13). A background pass is exactly the kind of
      // traffic the preference exists to stop.
      final enrichment = FakeEnrichmentGateway();
      final container = buildContainer(
        twoArtists(),
        enrichment,
        musicLookupEnabled: false,
      );

      await run(container);

      expect(enrichment.reads, isEmpty);
      expect(enrichment.runs, isEmpty);
    },
  );

  test('GivenNoSession_WhenTheAppStarts_ThenNothingIsAsked', () async {
    // FR-AU-07: no session, no call.
    final enrichment = FakeEnrichmentGateway();
    final container = buildContainer(twoArtists(), enrichment, signedIn: false);

    await run(container);

    expect(enrichment.reads, isEmpty);
    expect(enrichment.runs, isEmpty);
  });

  test('GivenTheFirstLookupFails_WhenTheAppStarts_ThenThePassStops', () async {
    // A machine with no network at startup would otherwise walk the whole
    // library discovering it is offline, one failed request per artist.
    final enrichment = FakeEnrichmentGateway()
      ..runOutcome = const EnrichmentRunOutcome.failed(
        failure: Failure.serviceUnavailable(
          family: CoreStatusFamily.enrichment,
          code: 3,
        ),
      );
    final container = buildContainer(twoArtists(), enrichment);

    await run(container);

    expect(enrichment.runs, hasLength(1));
  });

  test(
    'GivenAPassThatFindsAPhotograph_WhenItLands_ThenTheRowsReadItBack',
    () async {
      // What makes a face appear under whoever is looking at the list: the
      // rows watch the cache by key, and nothing else would tell them the
      // read they made a moment ago has something behind it now.
      final enrichment = _FindsOnRun(
        found: const TrackEnrichment(artistImage: image),
      );
      final container = buildContainer(twoArtists(), enrichment);

      await run(container);

      final library = await container.read(musicLibraryProvider.future);
      final key = artistPortraitKeyFor(artistsIn(library.entries).first);
      final read = await container.read(
        trackEnrichmentControllerProvider(key!).future,
      );

      expect(read.artistImage, image);
    },
  );
}

/// A gateway with nothing until a run asks for it, and something after.
class _FindsOnRun extends FakeEnrichmentGateway {
  _FindsOnRun({required this.found});

  /// What the cache holds once a run has finished.
  final TrackEnrichment found;

  @override
  Future<EnrichmentRunOutcome> run({
    required EnrichmentScope scope,
    required String credential,
  }) async {
    enrichment = found;

    return super.run(scope: scope, credential: credential);
  }
}

/// A [PreferencesController] holding a fixed state — the same seam the other
/// enrichment tests use.
class _FixedPreferences extends PreferencesController {
  _FixedPreferences(this._state);

  final PreferencesState _state;

  @override
  PreferencesState build() => _state;
}
