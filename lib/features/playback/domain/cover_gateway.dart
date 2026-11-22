import 'dart:typed_data';

/// A track's front cover, as the core extracts it (UC-40).
abstract interface class CoverGateway {
  /// The cover of the file [uuid], or null when it has none or the core
  /// could not answer: a missing picture is drawn as an icon, never as a
  /// failure.
  Future<Uint8List?> cover({required String uuid});
}
