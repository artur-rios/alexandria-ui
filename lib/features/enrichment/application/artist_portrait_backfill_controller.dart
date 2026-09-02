import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../auth/application/session_state.dart';
import '../../playback/domain/music_browse.dart';
import '../domain/enrichment_gateway.dart';
import 'track_enrichment_controller.dart';

/// The enrichment key an artist's photograph is read under.
///
/// Shared by the artists list and by the pass below, and that sharing is the
/// point: enrichment is keyed by *file*, so a row and the pass that fills it
/// have to name the same representative track or the pass would fetch a
/// picture the row never looks for. `null` for the untagged group, which is
/// the files that name no artist rather than an artist.
TrackEnrichmentKey? artistPortraitKeyFor(MusicGroup group) {
  final name = group.name;
  if (name == null || group.entries.isEmpty) return null;

  return (fileUuid: group.entries.first.file.uuid, artistName: name);
}

/// How far the pass through the library's artists has got (FR-PL-15).
class ArtistPortraitBackfill {
  /// Creates a state.
  const ArtistPortraitBackfill({
    this.isRunning = false,
    this.fetched = 0,
    this.remaining = 0,
  });

  /// Whether a lookup is in flight right now.
  final bool isRunning;

  /// How many artists this session has fetched a photograph for.
  final int fetched;

  /// How many artists the pass has still to reach.
  final int remaining;
}

/// Fetches the photograph of every artist that has none, once, at startup
/// (FR-PL-15, UC-46 step 3).
///
/// The artists list shows the picture a lookup has cached and never fetches
/// one itself — a screenful of rows scrolling past would be dozens of
/// requests a second against services that allow one. That rule is right for
/// *browsing* and it left the list looking half-finished: a face appeared for
/// an artist whose lyrics somebody had opened, and nowhere else. This is the
/// other half of it. One pass, from the top of the library, one artist at a
/// time, off the interface's critical path entirely — it starts when the
/// library has loaded and gets on with it in the background, and every
/// picture it lands makes a row change under whoever is looking at it.
///
/// One lookup per *artist*, scoped to a single track of theirs, rather than
/// [EnrichmentScopeArtist], which would fetch the lyrics of every track they
/// appear on: what is missing here is one photograph, and the lyrics of a
/// whole discography is minutes of somebody else's rate limit for something
/// nobody asked to read.
///
/// An artist already asked for is not asked again, whether or not the lookup
/// found anything: an artist the services have never heard of would otherwise
/// be retried on every rebuild for the life of the session. A run that fails
/// outright stops the pass where it stands, leaving the artists behind it
/// unasked — a machine with no network at startup tries again the next time
/// the library loads, rather than burning through the whole library
/// discovering it is offline.
class ArtistPortraitBackfillController
    extends Notifier<ArtistPortraitBackfill> {
  /// Whether a pass is in flight, so a rebuild does not start a second one
  /// alongside it.
  bool _walking = false;

  /// The artists this session has already asked about.
  final Set<String> _asked = {};

  /// How many photographs this session has fetched.
  ///
  /// A field rather than a read of [state]: `build` reports it, and a
  /// provider's own state does not exist yet the first time its `build`
  /// runs.
  int _fetched = 0;

  /// How many artists the pass has still to reach.
  int _remaining = 0;

  @override
  ArtistPortraitBackfill build() {
    final enabled = ref.watch(
      preferencesControllerProvider.select(
        (preferences) => preferences.musicLookupEnabled,
      ),
    );
    // Watched, not read: signing in is what makes a credential exist, and the
    // pass has to start then rather than never.
    final session = ref.watch(sessionControllerProvider);
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    final library = ref.watch(musicLibraryProvider).value;

    // Off means off (FR-UX-13): the preference is the owner saying this
    // application does not reach the network, and a background pass is
    // exactly the kind of traffic they turned off.
    if (!enabled || session is! SessionActive || credential == null) {
      return const ArtistPortraitBackfill();
    }
    if (library == null || library.entries.isEmpty) {
      return const ArtistPortraitBackfill();
    }

    final artists = artistsIn(library.entries);
    if (!_walking) {
      // After the build that asked for it: a provider may not write its own
      // state during `build`, and the first thing the pass does is report
      // that it has started.
      final work = artists.where(
        (group) => group.name != null && !_asked.contains(group.name),
      );
      if (work.isNotEmpty) {
        Future<void>.microtask(() => _walk(artists, credential));
      }
    }

    _remaining = artists.where((group) => !_asked.contains(group.name)).length;

    return ArtistPortraitBackfill(
      isRunning: _walking,
      fetched: _fetched,
      remaining: _remaining,
    );
  }

  /// Walks the artists, looking up the ones with no photograph cached.
  ///
  /// Checked against `ref.mounted` at every await rather than against a flag
  /// this class sets from `onDispose`: Riverpod runs a provider's dispose
  /// callbacks on every *rebuild* as well as on disposal, and this pass
  /// deliberately outlives its own builds — the library reloading mid-pass is
  /// an ordinary thing to happen. `ref.mounted` is false only when the
  /// provider is genuinely gone, which is the one case where carrying on
  /// would be writing state nobody owns and spending a credential the session
  /// no longer has.
  Future<void> _walk(List<MusicGroup> artists, String credential) async {
    if (_walking) return;
    _walking = true;
    final gateway = ref.read(enrichmentGatewayProvider);

    try {
      for (final group in artists) {
        if (!ref.mounted) return;

        final key = artistPortraitKeyFor(group);
        if (key == null || !_asked.add(key.artistName!)) continue;

        // Asked of the cache first, because most of a library is already
        // answered after the first session: a read is a database call, where
        // a run is a request to somebody else's server.
        final cached = await gateway.readTrack(
          fileUuid: key.fileUuid,
          artistName: key.artistName,
          credential: credential,
        );
        if (!ref.mounted) return;
        if (cached is TrackEnrichmentReadLoaded &&
            cached.enrichment.artistImage != null) {
          continue;
        }

        state = ArtistPortraitBackfill(
          isRunning: true,
          fetched: _fetched,
          remaining: _remaining,
        );

        final outcome = await gateway.run(
          scope: EnrichmentScope.file(key.fileUuid),
          credential: credential,
        );
        if (!ref.mounted) return;
        if (outcome is EnrichmentRunFailed) return;

        // What makes the row change under the owner: the list watches this
        // key, and nothing else would tell it the cache it read a moment ago
        // has something in it now.
        ref.invalidate(trackEnrichmentControllerProvider(key));

        _fetched += 1;
        if (_remaining > 0) _remaining -= 1;
        state = ArtistPortraitBackfill(
          isRunning: true,
          fetched: _fetched,
          remaining: _remaining,
        );
      }
    } finally {
      _walking = false;
      if (ref.mounted) {
        state = ArtistPortraitBackfill(
          fetched: _fetched,
          remaining: _remaining,
        );
      }
    }
  }
}
