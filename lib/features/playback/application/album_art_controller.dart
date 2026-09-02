import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../catalog/domain/catalog_gateway.dart';

/// The picture on one record's sleeve, for a row or a tile (UC-46, FR-CT-03).
///
/// The listing showed a generic record glyph against every album ever
/// indexed, which says an album is an album and nothing about *which* one.
/// The sleeve is what an owner recognises, and the core already has it: the
/// same thumbnail the player's own cover comes from, embedded in the file's
/// tag and cached on disk after the first read.
///
/// Keyed by a representative file rather than by the album, because that is
/// what the core can answer about: a picture belongs to a file's tag, and an
/// album is a grouping this application made. Any track of the record would
/// do; the first is the one the row already has in hand.
///
/// Auto-disposed, and the image with it: a library of a thousand records
/// scrolled past would otherwise hold a thousand decoded pictures for the
/// life of the process.
class AlbumArtController extends AsyncNotifier<ui.Image?> {
  /// Creates the controller for [fileUuid].
  AlbumArtController(this.fileUuid);

  /// The track whose embedded picture stands for the record.
  final String fileUuid;

  @override
  Future<ui.Image?> build() async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07).
    if (credential == null) return null;

    final outcome = await ref
        .read(catalogGatewayProvider)
        .fileThumbnail(uuid: fileUuid, credential: credential);

    if (outcome is! FileThumbnailRead) return null;

    final image = await _decode(outcome.bytes);
    if (image == null) return null;

    // The one thing a decoded image needs that a plain value does not: the
    // texture is native memory, and a row scrolled off screen has to give it
    // back.
    ref.onDispose(image.dispose);

    return image;
  }

  /// The bytes as an image, or `null` when they are not one.
  ///
  /// A file whose tag holds something that is not a picture is the same
  /// answer as a file with no picture: there is nothing to draw, and an
  /// owner has nothing to do about either.
  Future<ui.Image?> _decode(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      return frame.image;
    } on Object {
      return null;
    }
  }
}
