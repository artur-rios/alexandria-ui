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

  /// The photograph stored for [artistName], if one has been looked up.
  ///
  /// A read, and safe to make once per row of an artists list: it makes no
  /// network call and answers whether or not enrichment is switched on.
  /// `null` for an artist nobody has looked up *and* for one looked up
  /// without success — a list has nothing different to draw for the two.
  ///
  /// By name rather than by track, which is the whole point of it: a list
  /// grouped by the record's artist (FR-PL-14) asks for a name no single
  /// file may be tagged with, and a picture stored under one file's tags is
  /// one that list would never find.
  Future<ArtistImage?> readArtistImage({
    required String artistName,
    required String credential,
  });

  /// Looks [artistName]'s photograph up and keeps it (FR-PL-15).
  ///
  /// **Reaches the network**, once, for one artist — and not at all for an
  /// artist already looked up, found or not, which is what keeps a library of
  /// five hundred artists from being five hundred requests every session.
  /// Answers what the lookup concluded so a caller can stop asking.
  Future<ArtistImageLookup> fetchArtistImage({
    required String artistName,
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

/// What looking one artist's photograph up concluded (FR-PL-15).
///
/// Three answers rather than two: a picture, a lookup that settled with
/// nothing to show, and a lookup that could not be made at all. The middle
/// one is why an artists list does not ask again — the services have
/// answered, and the answer was no.
enum ArtistImageLookup {
  /// A photograph is now stored for them.
  found,

  /// The services were asked and had nothing, or nothing good enough.
  nothing,

  /// The lookup could not be made: switched off, unreachable, or refused.
  unavailable,
}
