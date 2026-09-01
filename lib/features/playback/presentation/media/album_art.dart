import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// The album's own picture, printed onto the medium (UC-21, FR-PL-07).
///
/// A record carries its art on its label, a disc has it printed across the
/// face, a cassette wears it on the sticker — which is why the cover belongs
/// on the medium and not only on the case it arrived in. The case is a beat
/// of the insertion and then gone; the medium is what stays on screen for
/// the rest of the album, and until now it was the same drawing whatever was
/// playing.
///
/// `BoxFit.cover` throughout, and cropped rather than letterboxed: sleeves
/// are square, the label is round, and a picture with bars across it reads
/// as a mistake where a crop reads as a label.
void paintAlbumArtInCircle(
  Canvas canvas, {
  required ui.Image cover,
  required Offset centre,
  required double radius,
}) {
  final bounds = Rect.fromCircle(center: centre, radius: radius);

  canvas
    ..save()
    ..clipPath(Path()..addOval(bounds));
  paintImage(canvas: canvas, rect: bounds, image: cover, fit: BoxFit.cover);
  canvas.restore();
}

/// The same, printed into a rectangle — the cassette's sticker.
void paintAlbumArtInRect(
  Canvas canvas, {
  required ui.Image cover,
  required Rect bounds,
  required double corner,
}) {
  canvas
    ..save()
    ..clipRRect(RRect.fromRectAndRadius(bounds, Radius.circular(corner)));
  paintImage(canvas: canvas, rect: bounds, image: cover, fit: BoxFit.cover);
  canvas.restore();
}
