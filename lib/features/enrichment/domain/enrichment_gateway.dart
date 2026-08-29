import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import 'track_enrichment.dart';

part 'enrichment_gateway.freezed.dart';

/// What reading one track's enrichment produced.
@freezed
sealed class TrackEnrichmentRead with _$TrackEnrichmentRead {
  /// The core answered — possibly with nothing, which is a state and not a
  /// failure.
  const factory TrackEnrichmentRead.loaded({
    required TrackEnrichment enrichment,
  }) = TrackEnrichmentReadLoaded;

  /// The core could not answer.
  const factory TrackEnrichmentRead.failed({required Failure failure}) =
      TrackEnrichmentReadFailed;
}

/// What an enrichment run produced.
@freezed
sealed class EnrichmentRunOutcome with _$EnrichmentRunOutcome {
  /// The run finished. It may have found nothing — a service being down or
  /// having no answer is counted in the report, not raised.
  const factory EnrichmentRunOutcome.done({required EnrichmentReport report}) =
      EnrichmentRunDone;

  /// The run could not start, or the core refused it.
  const factory EnrichmentRunOutcome.failed({required Failure failure}) =
      EnrichmentRunFailed;
}

/// What to enrich (music enrichment design).
///
/// A named scope rather than a free-form filter, because these three are
/// what a surface actually offers and each has a very different cost the
/// owner should be choosing between deliberately.
sealed class EnrichmentScope {
  const EnrichmentScope();

  /// One track: its artist's image and its own lyrics. Seconds.
  const factory EnrichmentScope.file(String fileUuid) = EnrichmentScopeFile;

  /// One artist, and the lyrics of every track of theirs. Minutes.
  const factory EnrichmentScope.artist(String name) = EnrichmentScopeArtist;

  /// Everything not yet looked up, at most [limit] of it.
  ///
  /// Hours on a real library, which is why a surface asks for a batch at a
  /// time: each call is short and complete, so progress is visible and
  /// stopping is simply not asking for the next one. `null` is the whole
  /// sweep, which no interface should ask for.
  const factory EnrichmentScope.pending({int? limit}) = EnrichmentScopePending;
}

/// One file's scope.
class EnrichmentScopeFile extends EnrichmentScope {
  /// Creates the scope.
  const EnrichmentScopeFile(this.fileUuid);

  /// The file to enrich.
  final String fileUuid;
}

/// One artist's scope.
class EnrichmentScopeArtist extends EnrichmentScope {
  /// Creates the scope.
  const EnrichmentScopeArtist(this.name);

  /// The artist to enrich.
  final String name;
}

/// The sweep, bounded or whole.
class EnrichmentScopePending extends EnrichmentScope {
  /// Creates the scope.
  const EnrichmentScopePending({this.limit});

  /// How many items this call should do, or `null` for all of them.
  final int? limit;
}

/// The core's music enrichment operations (music enrichment design).
abstract interface class EnrichmentGateway {
  /// What enrichment holds for [fileUuid].
  ///
  /// [artistName] is whose image to read. The caller is already showing the
  /// track and holding its tags, so passing the name costs nothing where
  /// resolving it again would be a second lookup.
  ///
  /// Makes no network call and answers whether or not enrichment is switched
  /// on: reading what was already cached is a plain database read.
  Future<TrackEnrichmentRead> readTrack({
    required String fileUuid,
    String? artistName,
    required String credential,
  });

  /// Runs enrichment over [scope].
  ///
  /// **Reaches the network, and is slow by design**: MusicBrainz is
  /// rate-limited to one request per second, so a sweep runs for hours. Never
  /// awaited anywhere a frame is waiting on it.
  Future<EnrichmentRunOutcome> run({
    required EnrichmentScope scope,
    required String credential,
  });
}
