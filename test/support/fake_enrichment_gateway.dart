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
  Future<EnrichmentRunOutcome> run({
    required EnrichmentScope scope,
    required String credential,
  }) async {
    runs.add(scope);
    return runOutcome;
  }
}
