import 'package:alexandria_ui/features/enrichment/domain/enrichment_gateway.dart';
import 'package:alexandria_ui/features/enrichment/domain/track_enrichment.dart';

/// An [EnrichmentGateway] that never reaches the core (Testing Specification
/// §2.3).
///
/// Answers "nothing stored" by default, which is what most of a real library
/// holds and what every test that is not about enrichment should see.
class FakeEnrichmentGateway implements EnrichmentGateway {
  /// Creates a gateway answering [enrichment] for every track.
  FakeEnrichmentGateway({this.enrichment = TrackEnrichment.none});

  /// What a read answers.
  TrackEnrichment enrichment;

  /// What a read answers instead, when a test wants a failure.
  TrackEnrichmentRead? readOutcome;

  /// What a run answers.
  EnrichmentRunOutcome runOutcome = const EnrichmentRunOutcome.done(
    report: EnrichmentReport(),
  );

  /// Every read asked for, in order.
  final List<({String fileUuid, String? artistName})> reads = [];

  /// Every run asked for, in order.
  final List<EnrichmentScope> runs = [];

  /// What a read by artist name answers, by name.
  ///
  /// Absent is the ordinary case: most of a library has never been looked up.
  final Map<String, ArtistImage> artistImages = {};

  /// What a fetch by artist name concludes, by name — and what it concludes
  /// for a name nothing was seeded for.
  final Map<String, ArtistImageLookup> artistLookups = {};

  /// See [artistLookups].
  ArtistImageLookup artistLookupOutcome = ArtistImageLookup.nothing;

  /// Every name read, in order.
  final List<String> artistImageReads = [];

  /// Every name looked up, in order.
  final List<String> artistImageFetches = [];

  @override
  Future<TrackEnrichmentRead> readTrack({
    required String fileUuid,
    String? artistName,
    required String credential,
  }) async {
    reads.add((fileUuid: fileUuid, artistName: artistName));

    return readOutcome ?? TrackEnrichmentRead.loaded(enrichment: enrichment);
  }

  @override
  Future<ArtistImage?> readArtistImage({
    required String artistName,
    required String credential,
  }) async {
    artistImageReads.add(artistName);

    return artistImages[artistName];
  }

  @override
  Future<ArtistImageLookup> fetchArtistImage({
    required String artistName,
    required String credential,
  }) async {
    artistImageFetches.add(artistName);
    final outcome = artistLookups[artistName] ?? artistLookupOutcome;
    if (outcome == ArtistImageLookup.found) {
      artistImages[artistName] = ArtistImage(
        artistName: artistName,
        path: '/cache/artist-images/$artistName.jpg',
      );
    }

    return outcome;
  }

  @override
  Future<EnrichmentRunOutcome> run({
    required EnrichmentScope scope,
    required String credential,
  }) async {
    runs.add(scope);
    return runOutcome;
  }
}
