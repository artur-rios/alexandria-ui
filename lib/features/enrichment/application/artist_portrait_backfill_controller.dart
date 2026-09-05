import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../auth/application/session_state.dart';
import '../../playback/domain/music_browse.dart';
import '../domain/enrichment_gateway.dart';
import '../domain/track_enrichment.dart';

/// The photograph stored for one artist, by name (FR-PL-15).
///
/// Read, never fetched: an artists list is a screenful of rows, and a row
/// that could reach the network would be dozens of requests a second against
/// services that allow one. What fills the gaps is [ArtistPortraitBackfill],
/// which asks once per artist and invalidates this so the row picks it up.
///
/// By name rather than by a representative track, which is the defect this
/// replaced: the core stored a picture under whatever one file was tagged
/// with, and the list — grouped by the record's own artist (FR-PL-14) — asked
/// for a name that was never written. Both sides ask by the name on screen
/// now.
class ArtistImageController extends AsyncNotifier<ArtistImage?> {
  /// Creates the controller for [artistName].
  ArtistImageController(this.artistName);

  /// Whose photograph to read.
  final String artistName;

  @override
  Future<ArtistImage?> build() async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07).
    if (credential == null) return null;

    return ref
        .read(enrichmentGatewayProvider)
        .readArtistImage(artistName: artistName, credential: credential);
  }
}

/// How far the pass through the library's artists has got (FR-PL-15).
class ArtistPortraitBackfill {
  /// Creates a state.
  const ArtistPortraitBackfill({
    this.isRunning = false,
    this.fetched = 0,
    this.considered = 0,
    this.total = 0,
    this.stopped = false,
  });

  /// Whether a lookup is in flight right now.
  final bool isRunning;

  /// How many artists this session has fetched a photograph for.
  final int fetched;

  /// How many artists the pass has been through, found or not.
  final int considered;

  /// How many it set out to reach.
  final int total;

  /// Whether it gave up: the services could not be reached often enough in a
  /// row to be worth continuing against.
  final bool stopped;

  /// How far through, or `null` when there is nothing to be a fraction of.
  double? get progress => total == 0 ? null : considered / total;
}

/// Fetches the photograph of every artist that has none, once, at startup
/// (FR-PL-15, UC-46 step 3).
///
/// The artists list shows the picture the core has stored and never fetches
/// one itself — a screenful of rows scrolling past would be dozens of
/// requests a second against services that allow one. That rule is right for
/// *browsing* and it left the list looking half-finished. This is the other
/// half: one pass, from the top of the library, one artist at a time, off the
/// interface's critical path entirely.
///
/// One lookup per *artist name* — the name the list itself shows. That is the
/// correction this pass needed: it used to ask for one *track* of theirs to be
/// enriched, which stored the picture under whatever that file was tagged
/// with, and a list grouped by the record's artist then asked for a name
/// nobody had written. Pictures were fetched, paid for, and never shown.
///
/// An artist already asked for is not asked again, and neither is one the
/// core has already settled: the core answers a settled row from its own
/// storage without a request, so a second session costs nothing for an artist
/// whose photograph was found — or genuinely was not.
///
/// A pass keeps going past a lookup that fails, because one artist missing
/// from MusicBrainz says nothing about the next; it gives up only when
/// several in a row cannot be reached at all, which is what being offline
/// looks like from here.
class ArtistPortraitBackfillController
    extends Notifier<ArtistPortraitBackfill> {
  /// How many consecutive unreachable lookups end the pass.
  ///
  /// Three rather than one: a single artist can fail for reasons of their
  /// own — a name the service refuses, a picture that will not download —
  /// and stopping the whole library over it is how a pass that ran fine
  /// yesterday quietly does nothing today. Three in a row is not one
  /// artist's problem, it is the network's.
  static const int _givesUpAfter = 3;

  /// Whether a pass is in flight, so a rebuild does not start a second one.
  bool _walking = false;

  /// The artists this session has already asked about.
  final Set<String> _asked = {};

  int _fetched = 0;
  int _considered = 0;
  int _total = 0;
  bool _stopped = false;

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

    // The untagged group has no name and is not an artist: it is the files
    // that name none.
    final names = [for (final group in artistsIn(library.entries)) ?group.name];
    final outstanding = names.where((name) => !_asked.contains(name)).toList();

    if (!_walking && !_stopped && outstanding.isNotEmpty) {
      // After the build that asked for it: a provider may not write its own
      // state during `build`, and the first thing the pass does is report
      // that it has started.
      Future<void>.microtask(() => _walk(outstanding, credential));
    }

    return ArtistPortraitBackfill(
      isRunning: _walking,
      fetched: _fetched,
      considered: _considered,
      total: _total,
      stopped: _stopped,
    );
  }

  /// Starts the pass again after it gave up (FR-PL-15).
  ///
  /// Giving up is right — three unreachable lookups in a row is the network,
  /// not one artist, and continuing would be hundreds of requests into a
  /// void. Giving up *for the session* was not: a laptop that woke before its
  /// Wi-Fi did meant no photographs until the application was restarted, with
  /// nothing on screen saying so. This is the way back, and the strip offers
  /// it beside the notice.
  ///
  /// Clearing the flag is the whole of it. `build` starts a pass whenever
  /// there are artists outstanding and none is running, and invalidating this
  /// provider is what makes it run again — the artists whose lookups never
  /// landed are outstanding again, because [_walk] no longer keeps them in
  /// [_asked].
  void resume() {
    if (!_stopped) return;

    _stopped = false;
    ref.invalidateSelf();
  }

  /// Walks the artists, looking up the ones the core has nothing for.
  ///
  /// Checked against `ref.mounted` at every await rather than against a flag
  /// this class sets from `onDispose`: Riverpod runs a provider's dispose
  /// callbacks on every *rebuild* as well as on disposal, and this pass
  /// deliberately outlives its own builds — the library reloading mid-pass is
  /// an ordinary thing to happen.
  Future<void> _walk(List<String> names, String credential) async {
    if (_walking) return;
    _walking = true;
    _total = _considered + names.length;
    _publish();

    final gateway = ref.read(enrichmentGatewayProvider);
    var unreachable = 0;

    try {
      for (final name in names) {
        if (!ref.mounted) return;
        if (!_asked.add(name)) continue;

        // Asked of the core's own storage first, because most of a library is
        // already answered after the first session: a read is a database
        // call, where a lookup is a request to somebody else's server.
        final stored = await gateway.readArtistImage(
          artistName: name,
          credential: credential,
        );
        if (!ref.mounted) return;

        if (stored != null) {
          _considered += 1;
          _publish();
          continue;
        }

        final outcome = await gateway.fetchArtistImage(
          artistName: name,
          credential: credential,
        );
        if (!ref.mounted) return;

        switch (outcome) {
          case ArtistImageLookup.found:
            _fetched += 1;
            unreachable = 0;
            // What makes the row change under the owner: the list watches
            // this name, and nothing else would tell it the storage it read
            // a moment ago has something in it now.
            ref.invalidate(artistImageControllerProvider(name));

          case ArtistImageLookup.nothing:
            // Settled: the core will answer this from storage next time, so
            // nothing here has to remember it.
            unreachable = 0;

          case ArtistImageLookup.unavailable:
            // Nothing was settled — the core stored no row, because the
            // services could not be reached — so this artist has not been
            // asked about in any sense that matters. Forgetting them is what
            // makes the pass resumable: [_asked] is marked *before* the
            // lookup so a rebuild mid-flight cannot ask twice, and leaving
            // the mark behind on a request that never landed excluded that
            // artist from every later pass this session.
            _asked.remove(name);
            unreachable += 1;
            if (unreachable >= _givesUpAfter) {
              _stopped = true;
              return;
            }
        }

        _considered += 1;
        _publish();
      }
    } finally {
      _walking = false;
      if (ref.mounted) _publish();
    }
  }

  /// Publishes where the pass has got to.
  void _publish() {
    if (!ref.mounted) return;

    state = ArtistPortraitBackfill(
      isRunning: _walking,
      fetched: _fetched,
      considered: _considered,
      total: _total,
      stopped: _stopped,
    );
  }
}
