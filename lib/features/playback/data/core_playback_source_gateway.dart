import 'dart:convert';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../domain/playback_source.dart';

/// [PlaybackSourceGateway] over `alexandria_file_playback_source` (FR-PL-01).
class CorePlaybackSourceGateway implements PlaybackSourceGateway {
  /// Wraps [_core].
  const CorePlaybackSourceGateway(this._core);

  final CoreClient _core;

  @override
  Future<PlaybackSourceOutcome> resolve({
    required String uuid,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.filePlaybackSource(uuid, credential);
    } on CoreCallException {
      return _unresolvable();
    }

    // AF-01's missing file, a rejected session, and a record the core does not
    // have are three statuses on the same call. The playback family is its own
    // set of codes, which is why it is named here (IR-08).
    if (!CoreStatusFamily.playback.isOk(response.status)) {
      return PlaybackSourceOutcome.failed(
        failure: mapCoreStatus(CoreStatusFamily.playback, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unresolvable();

    try {
      final body = jsonDecode(json) as Map<String, dynamic>;

      return PlaybackSourceOutcome.resolved(
        source: PlaybackSource(
          uuid: body['uuid'] as String,
          path: body['path'] as String,
          mimeType: body['mimeType'] as String?,
          sizeBytes: body['sizeBytes'] as int?,
        ),
      );
    } on Object {
      return _unresolvable();
    }
  }

  PlaybackSourceOutcome _unresolvable() => const PlaybackSourceOutcome.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.playback,
      code: PLAYBACK_ERR_OTHER,
    ),
  );
}
