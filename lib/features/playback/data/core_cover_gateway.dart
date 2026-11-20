import 'dart:convert';
import 'dart:typed_data';

import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../domain/cover_gateway.dart';

/// [CoverGateway] over `alexandria_file_thumbnail`, whose answer carries the
/// picture as base64 inside its JSON.
class CoreCoverGateway implements CoverGateway {
  /// Creates the gateway over [_core].
  const CoreCoverGateway(this._core);

  final CoreClient _core;

  @override
  Future<Uint8List?> cover({
    required String uuid,
    required String credential,
  }) async {
    try {
      final response = await _core.fileThumbnail(uuid, credential);
      final json = response.json;
      if (!CoreStatusFamily.playback.isOk(response.status) || json == null) {
        return null;
      }

      final body = jsonDecode(json) as Map<String, dynamic>;
      final encoded = body['bytesBase64'] as String?;

      return encoded == null ? null : base64Decode(encoded);
    } on CoreCallException {
      return null;
    } on FormatException {
      return null;
    }
  }
}
