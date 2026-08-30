import 'dart:convert';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../domain/enrichment_gateway.dart';
import '../domain/synced_lyrics.dart';
import '../domain/track_enrichment.dart';

/// [EnrichmentGateway] over the core's enrichment calls (music enrichment
/// design).
class CoreEnrichmentGateway implements EnrichmentGateway {
  /// Wraps [_core].
  const CoreEnrichmentGateway(this._core);

  final CoreClient _core;

  @override
  Future<TrackEnrichmentRead> readTrack({
    required String fileUuid,
    String? artistName,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.enrichmentReadTrack(
        fileUuid,
        // The empty string is "no image wanted", which is what the core's
        // own NULL means — there is no third state to carry across.
        artistName?.trim() ?? '',
        credential,
      );
    } on CoreCallException {
      return _unreadableRead();
    }

    if (!CoreStatusFamily.enrichment.isOk(response.status)) {
      return TrackEnrichmentRead.failed(
        failure: mapCoreStatus(CoreStatusFamily.enrichment, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadableRead();

    try {
      final body = jsonDecode(json) as Map<String, dynamic>;

      return TrackEnrichmentRead.loaded(
        enrichment: TrackEnrichment(
          artistImage: _imageFrom(body['artistImage']),
          lyrics: _lyricsFrom(body['lyrics']),
        ),
      );
    } on Object {
      // Broad by intent, as on every payload path in the sibling gateways: a
      // malformed document surfaces as FormatException and a wrongly-typed
      // field as TypeError.
      return _unreadableRead();
    }
  }

  @override
  Future<EnrichmentRunOutcome> run({
    required EnrichmentScope scope,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.enrichmentRun(_scopeBody(scope), credential);
    } on CoreCallException {
      return _unreadableRun();
    }

    if (!CoreStatusFamily.enrichment.isOk(response.status)) {
      return EnrichmentRunOutcome.failed(
        failure: mapCoreStatus(CoreStatusFamily.enrichment, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadableRun();

    try {
      final body = jsonDecode(json) as Map<String, dynamic>;
      int count(String key) => (body[key] as num?)?.toInt() ?? 0;

      return EnrichmentRunOutcome.done(
        report: EnrichmentReport(
          considered: count('considered'),
          found: count('found'),
          notFound: count('notFound'),
          rejected: count('rejected'),
          failed: count('failed'),
          skipped: count('skipped'),
          remaining: count('remaining'),
        ),
      );
    } on Object {
      return _unreadableRun();
    }
  }

  /// The JSON body the core reads a scope from.
  ///
  /// The sweep sends an empty string rather than `{}` — the core treats both
  /// alike, and an empty body is what "everything not yet looked up"
  /// actually is.
  String _scopeBody(EnrichmentScope scope) => switch (scope) {
    EnrichmentScopeFile(:final fileUuid) => jsonEncode({'fileUuid': fileUuid}),
    EnrichmentScopeArtist(:final name) => jsonEncode({'artist': name}),
    // The whole sweep sends an empty body, which is what the core reads an
    // absent one as; a bounded one has to say how far.
    EnrichmentScopePending(:final limit) =>
      limit == null ? '' : jsonEncode({'limit': limit}),
  };

  /// The stored image, or `null` when there is none to show.
  ///
  /// A row with no path is a lookup that concluded something — nothing
  /// found, or a match rejected — and there is nothing to draw for it. The
  /// core already filters those, and this is the second half of the same
  /// rule rather than a duplicate of it: the parse cannot build an
  /// [ArtistImage] without a path, so the check has to live here too.
  ArtistImage? _imageFrom(Object? value) {
    if (value is! Map<String, dynamic>) return null;

    final path = value['imagePath'] as String?;
    final artistName = value['artistName'] as String?;
    if (path == null || path.isEmpty || artistName == null) return null;

    return ArtistImage(
      artistName: artistName,
      path: path,
      sourceUrl: value['sourceUrl'] as String?,
    );
  }

  /// The stored lyrics, or `null` when there are none to show.
  TrackLyrics? _lyricsFrom(Object? value) {
    if (value is! Map<String, dynamic>) return null;

    final plain = value['plain'] as String?;
    final synced = _syncedFrom(value['synced'] as String?);
    if ((plain == null || plain.trim().isEmpty) && synced == null) return null;

    return TrackLyrics(
      // Split on either line ending: the text is whatever a contributor
      // typed, and a file that travelled through Windows carries CRLF.
      lines: (plain ?? '')
          .split(RegExp(r'\r\n|\r|\n'))
          .map((line) => line.trimRight())
          .toList(),
      synced: synced,
      source: value['source'] as String?,
    );
  }

  /// The timed lines an LRC document carries, or `null` when it has none.
  ///
  /// A document that parses to nothing is treated as absent rather than as
  /// empty timing: the panel would otherwise show a lyrics view with no
  /// lines in it, which reads as a defect rather than as a track whose
  /// timing nobody has contributed.
  SyncedLyrics? _syncedFrom(String? document) {
    if (document == null || document.trim().isEmpty) return null;

    final lines = parseLrc(document);

    return lines.isEmpty ? null : SyncedLyrics(lines);
  }

  TrackEnrichmentRead _unreadableRead() => const TrackEnrichmentRead.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.enrichment,
      code: ENRICHMENT_ERR_OTHER,
    ),
  );

  EnrichmentRunOutcome _unreadableRun() => const EnrichmentRunOutcome.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.enrichment,
      code: ENRICHMENT_ERR_OTHER,
    ),
  );
}
