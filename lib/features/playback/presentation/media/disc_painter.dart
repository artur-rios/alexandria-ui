import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/album_palette.dart';

/// A compact disc, turning (UC-21, FR-PL-07).
///
/// Same still/moving split as [VinylPainter]: the specular highlight stays
/// fixed to the light while the diffraction rainbow — the thing that most
/// says "CD" at a glance — turns with the disc, because that shifting
/// iridescence is a property of the etched data surface, not of the light
/// falling on it.
class DiscPainter extends CustomPainter {
  /// Creates the painter.
  const DiscPainter({required this.palette, required this.turns});

  /// The artwork's colours (FR-UX-07).
  final AlbumPalette palette;

  /// How far through a turn the disc is, in whole turns.
  final double turns;

  /// The disc is round, so it is drawn in a square.
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

    // Outside the rotation, same reason as the record: the light stays put
    // while the disc spins under it.
    _paintSpecular(canvas, centre, radius);
  }

  void _paintTurning(Canvas canvas, Offset centre, double radius) {
    final discRect = Rect.fromCircle(center: centre, radius: radius);

    // The disc is aluminium first: a CD is fundamentally silver, and the
    // rainbow is a sheen that plays across that metal, not the disc's own
    // colour. A sweep through the chrome tones gives it the brushed,
    // lathe-turned look real pressed metal has, before any colour is added.
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = SweepGradient(
          colors: [
            palette.chromeLight,
            palette.chromeMid,
            palette.chromeDark,
            palette.chromeMid,
            palette.chromeLight,
            palette.chromeMid,
            palette.chromeDark,
            palette.chromeMid,
            palette.chromeLight,
          ],
        ).createShader(discRect),
    );

    // The diffraction rainbow, riding the metal at low alpha rather than
    // replacing it — a sheen that shifts with the angle, not the disc's own
    // paint. Full-strength stops here are what made the disc read as a
    // pastel rainbow ball instead of shiny metal catching colour.
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = SweepGradient(
          colors: [
            palette.discSheenA.withValues(alpha: 0.32),
            palette.discSheenB.withValues(alpha: 0.32),
            palette.discSheenC.withValues(alpha: 0.32),
            palette.discSheenD.withValues(alpha: 0.32),
            palette.discSheenE.withValues(alpha: 0.32),
            palette.discSheenA.withValues(alpha: 0.32),
          ],
        ).createShader(discRect),
    );

    // Four fine concentric highlights: the faint rings a pressed disc's
    // surface shows under raking light, distinct from the vinyl's grooves
    // because these are highlights, not troughs — stroked in a light tone
    // rather than the base colour.
    final ringHighlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.006
      ..color = palette.chromeLight.withValues(alpha: 0.35);
    for (final ring in [0.62, 0.74, 0.86, 0.94]) {
      canvas.drawCircle(centre, radius * ring, ringHighlight);
    }

    // The clear stacking ring: unprinted polycarbonate between the data
    // area and the label, faintly lighter than the data area it borders.
    canvas.drawCircle(
      centre,
      radius * 0.42,
      Paint()..color = palette.discRing.withValues(alpha: 0.55),
    );

    // The data area proper — the mirrored zone the laser reads. Still
    // silver, but a shade duller than the outer field, the way an inner
    // ring pressed for data differs subtly from the reflective rim around
    // it rather than dropping to flat grey.
    canvas.drawCircle(
      centre,
      radius * 0.37,
      Paint()
        ..shader = RadialGradient(
          colors: [palette.chromeMid, palette.chromeDark],
        ).createShader(Rect.fromCircle(center: centre, radius: radius * 0.37)),
    );

    // The hub and its spindle hole.
    canvas.drawCircle(centre, radius * 0.16, Paint()..color = palette.discRing);
    canvas.drawCircle(centre, radius * 0.05, Paint()..color = palette.wellDark);

    // The bright arc: a short highlight riding the rim, present purely so a
    // still frame at any angle shows unambiguously that this disc has a
    // facing side that has moved.
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius * 0.97),
      -math.pi / 3,
      math.pi / 5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.03
        ..color = palette.chromeLight.withValues(alpha: 0.8),
    );
  }

  void _paintSpecular(Canvas canvas, Offset centre, double radius) {
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.5),
          radius: 0.6,
          colors: [
            palette.specular,
            palette.specular.withValues(alpha: 0.05),
            palette.specular.withValues(alpha: 0),
          ],
          stops: const [0, 0.4, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(DiscPainter oldDelegate) =>
      oldDelegate.turns != turns || oldDelegate.palette != palette;
}
