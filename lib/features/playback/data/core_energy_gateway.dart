import 'dart:convert';
import 'dart:typed_data';

import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../domain/track_energy.dart';

/// A call that never reached the core.
const Failure _unreachable = Failure.unexpected(
  family: CoreStatusFamily.playback,
  code: 0,
);

/// An answer that came back in a shape this application cannot read.
///
/// The same failure whether the JSON was malformed, the base64 was not
/// base64, or a field was missing: all three are the core and this
/// application disagreeing about the envelope's shape, and none of them is
/// something an owner can act on differently.
const Failure _unreadable = Failure.unexpected(
  family: CoreStatusFamily.playback,
  code: 0,
);

/// [EnergyGateway] over `alexandria_track_energy` (UC-21, FR-MP-07).
///
/// The levels arrive as base64 because JSON has no way to carry bytes, and
/// they are bytes for a reason: a four-minute track is thirty-eight thousand
/// levels, which as a JSON array of small integers would be four times the
/// size and slower to parse at both ends.
class CoreEnergyGateway implements EnergyGateway {
  /// Wraps [_core].
  const CoreEnergyGateway(this._core);

  final CoreClient _core;

  @override
  Future<TrackEnergyRead> readEnergy({
    required String fileUuid,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.trackEnergy(fileUuid, credential);
    } on CoreCallException {
      // The isolate is gone, or the library will not load: the same
      // "unexpected" every other gateway maps a dead call to.
      return const TrackEnergyUnavailable(failure: _unreachable);
    }

    if (!CoreStatusFamily.playback.isOk(response.status)) {
      return TrackEnergyUnavailable(
        failure: mapCoreStatus(CoreStatusFamily.playback, response.status),
      );
    }

    final json = response.json;
    if (json == null) {
      return const TrackEnergyUnavailable(failure: _unreadable);
    }

    try {
      final body = jsonDecode(json) as Map<String, dynamic>;
      final bands = (body['bands'] as num).toInt();
      final frameMs = (body['frameMs'] as num).toInt();
      final levels = base64Decode(body['levelsBase64'] as String);

      return TrackEnergyLoaded(
        energy: TrackEnergy(
          bands: bands,
          frameMs: frameMs,
          levels: Uint8List.fromList(levels),
        ),
      );
    } on FormatException {
      return const TrackEnergyUnavailable(failure: _unreadable);
    } on TypeError {
      return const TrackEnergyUnavailable(failure: _unreadable);
    }
  }
}
