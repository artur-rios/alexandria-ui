import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/enrichment/domain/enrichment_gateway.dart';
import 'package:alexandria_ui/features/enrichment/domain/track_enrichment.dart';
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

  /// A library of [count] artists, one track each.
  FakeCatalogGateway manyArtists(int count) {
    final gateway = FakeCatalogGateway();
    for (var index = 0; index < count; index++) {
      gateway.addAudio(
        uuid: 'track-$index',
        title: 'Track $index',
        album: 'Record $index',
        artist: 'Artist $index',
      );
    }

    return gateway;
  }

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
    'GivenArtistsWithNoPhotograph_WhenTheAppStarts_ThenEachIsLookedUpByName',
    () async {
      // By the name the artists list shows, which is the whole correction:
      // the pass used to ask for one *track* of theirs to be enriched, which
      // stored the picture under whatever that file was tagged with — and a
      // list grouped by the record's artist then asked for a name nobody had
      // written. Fetched, paid for, and never shown.
      final enrichment = FakeEnrichmentGateway();
      final container = buildContainer(twoArtists(), enrichment);

      await run(container);

      expect(
        enrichment.artistImageFetches,
        containsAll(<String>['Miles Davis', 'John Coltrane']),
      );
    },
  );

  test(
    'GivenAPhotographAlreadyStored_WhenTheAppStarts_ThenNoLookupIsMade',
    () async {
      // A read is a database call; a lookup is a request to somebody else's
      // server. After the first session most of a library is answered, and a
      // pass that asked anyway would spend an hour re-fetching pictures it
      // already holds.
      final enrichment = FakeEnrichmentGateway()
        ..artistImages['Miles Davis'] = const ArtistImage(
          artistName: 'Miles Davis',
          path: '/cache/artist-images/miles.jpg',
        )
        ..artistImages['John Coltrane'] = const ArtistImage(
          artistName: 'John Coltrane',
          path: '/cache/artist-images/coltrane.jpg',
        );
      final container = buildContainer(twoArtists(), enrichment);

      await run(container);

      expect(enrichment.artistImageReads, hasLength(2));
      expect(enrichment.artistImageFetches, isEmpty);
    },
  );

  test(
    'GivenOneArtistHasNoPicture_WhenTheAppStarts_ThenTheNextIsStillAsked',
    () async {
      // One artist missing from the services says nothing about the next.
      // The pass used to stop at the first thing that was not a success,
      // which meant a library whose first artist was unknown got no pictures
      // at all and nothing said why.
      final enrichment = FakeEnrichmentGateway()
        ..artistLookups['John Coltrane'] = ArtistImageLookup.nothing
        ..artistLookups['Miles Davis'] = ArtistImageLookup.found;
      final container = buildContainer(twoArtists(), enrichment);

      await run(container);

      expect(
        enrichment.artistImageFetches,
        containsAll(<String>['Miles Davis', 'John Coltrane']),
      );
    },
  );

  test(
    'GivenNothingCanBeReached_WhenTheAppStarts_ThenThePassGivesUp',
    () async {
      // Three unreachable lookups in a row is not one artist's problem, it is
      // the network's — and a machine with no connection should not walk a
      // library of five hundred artists discovering that five hundred times.
      final enrichment = FakeEnrichmentGateway()
        ..artistLookupOutcome = ArtistImageLookup.unavailable;
      final container = buildContainer(manyArtists(6), enrichment);

      await run(container);

      expect(enrichment.artistImageFetches, hasLength(3));
      expect(
        container.read(artistPortraitBackfillProvider).stopped,
        isTrue,
        reason:
            'the pass says it gave up, so the strip can stop claiming it is '
            'working',
      );
    },
  );

  test('GivenAPassRan_WhenItIsRead_ThenItSaysHowFarItGot', () async {
    // The indication the owner sees (FR-PL-15): a picture arriving an hour
    // into a session is inexplicable unless something says a pass is under
    // way.
    final enrichment = FakeEnrichmentGateway()
      ..artistLookupOutcome = ArtistImageLookup.found;
    final container = buildContainer(twoArtists(), enrichment);

    await run(container);
    final state = container.read(artistPortraitBackfillProvider);

    expect(state.total, 2);
    expect(state.considered, 2);
    expect(state.fetched, 2);
    expect(state.isRunning, isFalse, reason: 'it has finished');
    expect(state.progress, 1.0);
  });

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

      expect(enrichment.artistImageReads, isEmpty);
      expect(enrichment.artistImageFetches, isEmpty);
    },
  );

  test('GivenNoSession_WhenTheAppStarts_ThenNothingIsAsked', () async {
    // FR-AU-07: no session, no call.
    final enrichment = FakeEnrichmentGateway();
    final container = buildContainer(twoArtists(), enrichment, signedIn: false);

    await run(container);

    expect(enrichment.artistImageReads, isEmpty);
    expect(enrichment.artistImageFetches, isEmpty);
  });

  test(
    'GivenAPassThatFindsAPhotograph_WhenItLands_ThenTheRowsReadItBack',
    () async {
      // What makes a face appear under whoever is looking at the list: the
      // rows watch the core's storage by *name*, and nothing else would tell
      // them the read they made a moment ago has something behind it now.
      final enrichment = FakeEnrichmentGateway()
        ..artistLookupOutcome = ArtistImageLookup.found;
      final container = buildContainer(twoArtists(), enrichment);

      await run(container);

      final read = await container.read(
        artistImageControllerProvider('Miles Davis').future,
      );

      expect(read, isNotNull);
      expect(read!.artistName, 'Miles Davis');
    },
  );
}

/// A [PreferencesController] holding a fixed state — the same seam the other
/// enrichment tests use.
class _FixedPreferences extends PreferencesController {
  _FixedPreferences(this._state);

  final PreferencesState _state;

  @override
  PreferencesState build() => _state;
}
