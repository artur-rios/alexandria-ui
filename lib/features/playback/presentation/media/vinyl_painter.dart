import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/album_palette.dart';

/// A record, turning (UC-21, FR-PL-07).
///
/// Painted rather than shipped as an image because the part that turns has to
/// be separable from the part that does not: the specular sweep stays where
/// the light is while the grooves move underneath it, and that one detail is
/// most of what makes this read as a spinning object rather than a rotating
/// picture.
class VinylPainter extends CustomPainter {
  /// Creates the painter.
  const VinylPainter({required this.palette, required this.turns});

  /// The artwork's colours (FR-UX-07).
  final AlbumPalette palette;

  /// How far through a turn the record is, in whole turns.
  final double turns;

  /// The record is round, so it is drawn in a square.
  static const double aspect = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(turns * 2 * math.pi);
    canvas.translate(-centre.dx, -centre.dy);
    _paintTurning(canvas, centre, radius);
    canvas.restore();

    // Outside the rotation on purpose: a highlight that turned with the
    // record would be a mark painted on it.
    _paintSpecular(canvas, centre, radius);
  }

  void _paintTurning(Canvas canvas, Offset centre, double radius) {
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.vinylSheenTop, palette.vinylSheenBottom],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );

    // Rings rather than a spiral: at this size a spiral is a texture and
    // rings are what the eye reads as a record.
    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.011
      ..color = palette.groove;
    for (var ring = 0.50; ring < 0.96; ring += 0.042) {
      canvas.drawCircle(centre, radius * ring, groove);
    }

    canvas.drawCircle(centre, radius * 0.36, Paint()..color = palette.labelPaper);
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius * 0.27),
      -math.pi / 2,
      math.pi / 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.037
        ..color = palette.labelInk,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: centre.translate(0, radius * 0.11),
        width: radius * 0.46,
        height: radius * 0.03,
      ),
      Paint()..color = palette.labelInk,
    );
    canvas.drawCircle(centre, radius * 0.05, Paint()..color = palette.wellDark);
  }

  void _paintSpecular(Canvas canvas, Offset centre, double radius) {
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.34, -0.46),
          radius: 0.62,
          colors: [
            palette.specular,
            palette.specular.withValues(alpha: 0.04),
            palette.specular.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(VinylPainter oldDelegate) =>
      oldDelegate.turns != turns || oldDelegate.palette != palette;
}
