import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/album_palette.dart';
import 'diagonal_sheen.dart';

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
    // A small margin so the shell reads as an object sitting inside the
    // painter's bounds rather than a flat rectangle filling the frame edge
    // to edge.
    final margin = h * 0.035;
    final bounds = Rect.fromLTWH(
      margin,
      margin,
      w - margin * 2,
      h - margin * 2,
    );
    final shell = RRect.fromRectAndRadius(bounds, Radius.circular(h * 0.09));

    canvas.drawRRect(
      shell,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // shellBottom alone was too close to shellTop to read as a
          // gradient at all; mixing in panelEdge deepens the shadow half so
          // the shell reads as moulded plastic with real thickness.
          colors: [
            palette.shellTop,
            Color.lerp(palette.shellBottom, palette.panelEdge, 0.55) ??
                palette.shellBottom,
          ],
        ).createShader(bounds),
    );

    // A thin edge line completes the moulded look — the shadow a bevel
    // casts along the shell's own rim.
    canvas.drawRRect(
      shell,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.01
        ..color = palette.panelEdge.withValues(alpha: 0.6),
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
    canvas.drawRect(Rect.fromLTWH(w * 0.13, h * 0.075, w * 0.4, h * 0.03), ink);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.13, h * 0.125, w * 0.24, h * 0.02),
      ink,
    );
  }

  void _paintWindow(Canvas canvas, double w, double h) {
    final windowRect = Rect.fromLTWH(w * 0.12, h * 0.22, w * 0.76, h * 0.46);
    final window = RRect.fromRectAndRadius(
      windowRect,
      Radius.circular(h * 0.03),
    );
    canvas.drawRRect(window, Paint()..color = palette.glassTint);

    // A soft diagonal sheen, the way moulded clear plastic catches light
    // unevenly rather than as a flat tint (Finding 10: shared with
    // `AlbumVisor`'s own recess via `diagonalSheenPaint`, rather than each
    // keeping its own copy). Driven entirely by gradient stops rather than a
    // separately clipped shape, so there is no hard geometric edge to read
    // as a stray mark on the window.
    canvas.drawRRect(
      window,
      diagonalSheenPaint(
        windowRect,
        palette.glassSheen,
        alpha: 0.55,
        stops: const [0.05, 0.22, 0.45],
      ),
    );
  }

  /// The height the tape path (and the pressure pad it crosses) sit at.
  double _tapePathY(double h) => h * 0.62;

  void _paintTapePath(Canvas canvas, double w, double h) {
    // A straight ribbon between the packs, not a sagging line — a real
    // cassette's tape is held taut between the two hubs by the guide posts
    // either side of the head opening.
    final y = _tapePathY(h);
    canvas.drawLine(
      Offset(w * 0.305, y),
      Offset(w * 0.695, y),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.025
        ..strokeCap = StrokeCap.butt
        ..color = palette.tapePack,
    );
  }

  void _paintPressurePad(Canvas canvas, double w, double h) {
    final pad = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, _tapePathY(h)),
        width: w * 0.045,
        height: h * 0.07,
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
    // The wound tape pack, seen edge-on. A radial gradient rather than a
    // flat fill: wound tape is a spiral of thousands of layers, and the
    // outer layers catch the light while the pack darkens toward the hub —
    // a flat brown circle read as a coloured disc, not spooled tape. It
    // does not need to rotate to read correctly, but is grouped with the
    // hub because the two are one physical part.
    canvas.drawCircle(
      centre,
      packRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.tapePack,
            Color.lerp(palette.tapePack, palette.chromeLight, 0.28) ??
                palette.tapePack,
          ],
          stops: const [0.55, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: packRadius)),
    );

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

    canvas.drawCircle(
      centre,
      hubRadius * 0.22,
      Paint()..color = palette.wellDark,
    );

    // A single index mark, off the six-fold tooth pattern. Six teeth are
    // symmetric under a half turn, so without this a hub at 0.5 turns would
    // render pixel-identical to a hub at rest — a passing golden that proved
    // nothing about rotation. Sized well above a single pixel so the
    // asymmetry survives the antialiasing differences between machines and
    // Flutter versions the golden comparator already tolerates, rather than
    // being a fragile one-pixel feature itself.
    canvas.drawCircle(
      centre.translate(0, -hubRadius * 0.85),
      hubRadius * 0.22,
      Paint()..color = palette.wellDark,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(CassettePainter oldDelegate) =>
      oldDelegate.turns != turns || oldDelegate.palette != palette;
}
