import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/album_palette.dart';

/// A cassette, turning (UC-21, FR-PL-07).
///
/// The still/moving split here is not the vinyl's "highlight stays, body
/// turns" — a cassette's shell never turns at all. Only the two reel hubs
/// spin, each about its own centre, while the shell, its label, its window
/// and the tape strung between the reels stay exactly where they are. The
/// animation this replaces rotated the whole shell, which is the single most
/// obviously wrong thing a cassette's artwork can do: a shell that turned
/// would tear the tape off both hubs in one revolution.
class CassettePainter extends CustomPainter {
  /// Creates the painter.
  const CassettePainter({required this.palette, required this.turns});

  /// The artwork's colours (FR-UX-07).
  final AlbumPalette palette;

  /// How far through a turn the reels are, in whole turns.
  final double turns;

  /// A cassette shell's real-world proportions (100mm x ~51mm face),
  /// rounded to a ratio the stage can multiply against any width.
  static const double aspect = 130 / 66;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _paintShell(canvas, w, h);
    _paintLabel(canvas, w, h);
    _paintWindow(canvas, w, h);
    _paintTapePath(canvas, w, h);
    _paintPressurePad(canvas, w, h);
    _paintScrews(canvas, w, h);

    _paintReel(canvas, Offset(w * 0.305, h * 0.44), h, packRadius: h * 0.205);
    _paintReel(canvas, Offset(w * 0.695, h * 0.44), h, packRadius: h * 0.145);
  }

  void _paintShell(Canvas canvas, double w, double h) {
    final shell = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(h * 0.08),
    );
    canvas.drawRRect(
      shell,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.shellTop, palette.shellBottom],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  void _paintScrews(Canvas canvas, double w, double h) {
    final rim = Paint()..color = palette.chromeDark;
    final dimple = Paint()..color = palette.chromeMid;
    final radius = h * 0.035;

    for (final centre in [
      Offset(w * 0.07, h * 0.11),
      Offset(w * 0.93, h * 0.11),
      Offset(w * 0.07, h * 0.89),
      Offset(w * 0.93, h * 0.89),
    ]) {
      canvas.drawCircle(centre, radius, rim);
      canvas.drawCircle(centre, radius * 0.55, dimple);
    }
  }

  void _paintLabel(Canvas canvas, double w, double h) {
    final label = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.04, w * 0.84, h * 0.15),
      Radius.circular(h * 0.02),
    );
    canvas.drawRRect(label, Paint()..color = palette.tapeLabel);

    final ink = Paint()..color = palette.tapeLabelInk;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.13, h * 0.075, w * 0.4, h * 0.03),
      ink,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.13, h * 0.125, w * 0.24, h * 0.02),
      ink,
    );
  }

  void _paintWindow(Canvas canvas, double w, double h) {
    final window = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.22, w * 0.76, h * 0.46),
      Radius.circular(h * 0.03),
    );
    canvas.drawRRect(window, Paint()..color = palette.glassTint);

    // A diagonal sheen, the way moulded clear plastic catches light unevenly
    // rather than as a flat tint.
    canvas.save();
    canvas.clipRRect(window);
    canvas.drawParallelogram(
      Rect.fromLTWH(w * 0.12, h * 0.22, w * 0.3, h * 0.46),
      palette.glassSheen,
    );
    canvas.restore();
  }

  void _paintTapePath(Canvas canvas, double w, double h) {
    final path = Path()
      ..moveTo(w * 0.305, h * 0.60)
      ..quadraticBezierTo(w * 0.5, h * 0.665, w * 0.695, h * 0.60);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.018
        ..strokeCap = StrokeCap.round
        ..color = palette.tapePack,
    );
  }

  void _paintPressurePad(Canvas canvas, double w, double h) {
    final pad = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.665),
        width: w * 0.045,
        height: h * 0.05,
      ),
      Radius.circular(h * 0.008),
    );
    canvas.drawRRect(pad, Paint()..color = palette.panelDark);
  }

  void _paintReel(
    Canvas canvas,
    Offset centre,
    double h, {
    required double packRadius,
  }) {
    // The wound tape pack, seen edge-on. It does not need to rotate to read
    // correctly — a plain disc looks the same at any angle — but it is
    // grouped with the hub because the two are one physical part.
    canvas.drawCircle(centre, packRadius, Paint()..color = palette.tapePack);

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(turns * 2 * math.pi);
    canvas.translate(-centre.dx, -centre.dy);

    final hubRadius = h * 0.078;
    canvas.drawCircle(centre, hubRadius, Paint()..color = palette.reelHub);

    final tooth = Paint()..color = palette.reelTeeth;
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final toothCentre = centre.translate(
        math.cos(angle) * hubRadius * 0.6,
        math.sin(angle) * hubRadius * 0.6,
      );
      canvas.save();
      canvas.translate(toothCentre.dx, toothCentre.dy);
      canvas.rotate(angle);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: hubRadius * 0.5,
          height: hubRadius * 0.22,
        ),
        tooth,
      );
      canvas.restore();
    }

    canvas.drawCircle(centre, hubRadius * 0.22, Paint()..color = palette.wellDark);

    // A single index mark, off the six-fold tooth pattern. Six teeth are
    // symmetric under a half turn, so without this a hub at 0.5 turns would
    // render pixel-identical to a hub at rest — a passing golden that proved
    // nothing about rotation.
    canvas.drawCircle(
      centre.translate(0, -hubRadius * 0.85),
      hubRadius * 0.1,
      Paint()..color = palette.wellDark,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(CassettePainter oldDelegate) =>
      oldDelegate.turns != turns || oldDelegate.palette != palette;
}

extension _ParallelogramPainting on Canvas {
  /// A slanted band of colour across [bounds], fading out at both ends — the
  /// window's plastic sheen. A private extension rather than a method on
  /// [CassettePainter] because it is pure canvas geometry, not cassette
  /// domain logic.
  void drawParallelogram(Rect bounds, Color colour) {
    final path = Path()
      ..moveTo(bounds.left + bounds.width * 0.1, bounds.top)
      ..lineTo(bounds.left + bounds.width * 0.4, bounds.top)
      ..lineTo(bounds.left - bounds.width * 0.3, bounds.bottom)
      ..lineTo(bounds.left - bounds.width * 0.6, bounds.bottom)
      ..close();

    drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colour.withValues(alpha: 0), colour, colour.withValues(alpha: 0)],
        ).createShader(bounds),
    );
  }
}
