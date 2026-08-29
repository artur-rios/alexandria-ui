import 'package:freezed_annotation/freezed_annotation.dart';

part 'track_enrichment.freezed.dart';

/// A photograph of an artist, fetched and cached by the core (music
/// enrichment design).
@freezed
abstract class ArtistImage with _$ArtistImage {
  /// Creates an image.
  const factory ArtistImage({
    required String artistName,

    /// Where the bytes are on disk, absolute.
    ///
    /// The core stores this relative to its own image cache and resolves it
    /// on read, because that directory is the core's configuration and this
    /// application has no way to learn it. Read straight off disk, which is
    /// how every other media byte reaches this application (Operations §3).
    required String path,

    /// The page the image came from, for attribution. Wikimedia Commons
    /// licences require it, and an image whose provenance was lost cannot
    /// lawfully be shown.
    String? sourceUrl,
  }) = _ArtistImage;
}

/// The words to a track, fetched and cached by the core.
@freezed
abstract class TrackLyrics with _$TrackLyrics {
  /// Creates lyrics.
  const factory TrackLyrics({
    /// The unsynchronized text, as lines.
    ///
    /// Split here rather than in the presentation layer so nothing rendering
    /// them has to agree about what a line is.
    required List<String> lines,

    /// The LRC-format text with timestamps, when the provider had it. Not
    /// yet rendered — kept because dropping it at the boundary would mean
    /// re-fetching every track to get it back.
    String? synced,

    /// Which service answered, for attribution.
    String? source,
  }) = _TrackLyrics;
}

/// What enrichment holds for one track.
///
/// Both halves are optional and independent: most of a real library will
/// have one, some, or neither, and neither absence is a failure.
@freezed
abstract class TrackEnrichment with _$TrackEnrichment {
  /// Creates a view.
  const factory TrackEnrichment({ArtistImage? artistImage, TrackLyrics? lyrics}) =
      _TrackEnrichment;

  const TrackEnrichment._();

  /// Nothing has been found for this track.
  static const TrackEnrichment none = TrackEnrichment();

  /// Whether there is anything at all to show.
  bool get isEmpty => artistImage == null && lyrics == null;
}

/// What one enrichment run did (music enrichment design).
///
/// Counted rather than itemized: a run over a whole library touches
/// thousands of rows, and what a surface needs is that it finished and
/// roughly what happened.
@freezed
abstract class EnrichmentReport with _$EnrichmentReport {
  /// Creates a report.
  const factory EnrichmentReport({
    @Default(0) int considered,
    @Default(0) int found,
    @Default(0) int notFound,
    @Default(0) int rejected,
    @Default(0) int failed,
    @Default(0) int skipped,
  }) = _EnrichmentReport;
}
