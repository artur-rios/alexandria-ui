import 'package:flutter/material.dart';

import '../../../../core/theme/album_palette.dart';
import 'device_layer.dart';

/// A tape deck, waiting for a cassette or playing one (UC-21, FR-PL-07).
///
/// The still/moving split is the glass door: the face, the VU meter, the
/// transport buttons and the well beneath the door all sit fixed, and only
/// the door itself travels as [closed] runs from 0 (racked up, the well open
/// and waiting) to 1 (slid down over the well). [CassettePainter] is what the
/// stage layers into that well; this painter only owns what the cassette sits
/// inside.
///
/// Painted in two passes, chosen by [layer]: the door has to be seen sliding
/// down *over* the cassette, so it cannot share a pass with the well it
/// closes over — the stage paints the well behind the cassette and the door
/// in front of it. See [DeviceLayer].
class TapeDeckPainter extends CustomPainter {
  /// Creates the painter.
  const TapeDeckPainter({
    required this.palette,
    required this.closed,
    required this.layer,
  });

  /// The artwork's colours (FR-UX-07).
  final AlbumPalette palette;

  /// 0 with the door racked open above the well; 1 with it slid down,
  /// closed over the cassette.
  final double closed;

  /// Which pass this paint call draws.
  final DeviceLayer layer;

  /// A deck face is a wide, short panel.
  static const double aspect = 1.7;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final faceMargin = h * 0.03;
    final face = Rect.fromLTWH(
      faceMargin,
      faceMargin,
      w - faceMargin * 2,
      h - faceMargin * 2,
    );
    final well = Rect.fromLTWH(
      face.left + face.width * 0.06,
      face.top + face.height * 0.50,
      face.width * 0.55,
      face.height * 0.42,
    );

    switch (layer) {
      case DeviceLayer.chassis:
        _paintFace(canvas, face);
        _paintVuMeter(canvas, face);
        _paintButtons(canvas, face);
        _paintWell(canvas, well);
      case DeviceLayer.foreground:
        _paintDoor(canvas, face, well);
    }
  }

  void _paintFace(Canvas canvas, Rect face) {
    final panel = RRect.fromRectAndRadius(
      face,
      Radius.circular(face.height * 0.04),
    );

    // A four-stop sweep rather than the raw two-colour gradient: repeating
    // through the tonal range once gives the brushed aluminium a visible
    // horizontal grain instead of one smooth fade top to bottom.
    canvas.drawRRect(
      panel,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.deckFaceTop,
            palette.deckFaceBottom,
            palette.deckFaceTop,
            palette.deckFaceBottom,
          ],
          stops: const [0, 0.32, 0.62, 1],
        ).createShader(face),
    );

    canvas.drawLine(
      Offset(face.left + face.height * 0.04, face.top + face.height * 0.012),
      Offset(face.right - face.height * 0.04, face.top + face.height * 0.012),
      Paint()
        ..strokeWidth = face.height * 0.016
        ..strokeCap = StrokeCap.round
        ..color = palette.chromeLight.withValues(alpha: 0.35),
    );

    canvas.drawRRect(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = face.height * 0.008
        ..color = palette.panelEdge,
    );
  }

  void _paintVuMeter(Canvas canvas, Rect face) {
    final recessRect = Rect.fromLTWH(
      face.left + face.width * 0.06,
      face.top + face.height * 0.08,
      face.width * 0.55,
      face.height * 0.32,
    );
    final recess = RRect.fromRectAndRadius(
      recessRect,
      Radius.circular(face.height * 0.02),
    );
    canvas.drawRRect(recess, Paint()..color = palette.panelDark);
    canvas.drawRRect(
      recess,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = face.height * 0.006
        ..color = palette.panelEdge,
    );

    final scale = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = face.height * 0.006
      ..strokeCap = StrokeCap.round
      ..color = palette.chromeMid.withValues(alpha: 0.7);
    for (final (dx, ratio) in [
      (0.5, 0.5),
      (0.3, 0.5),
      (0.7, 0.5),
      (0.12, 0.4),
      (0.88, 0.4),
    ]) {
      final base = Offset(
        recessRect.left + recessRect.width * dx,
        recessRect.bottom,
      );
      canvas.drawLine(
        base,
        base.translate(0, -recessRect.height * ratio * 0.4),
        scale,
      );
    }

    // Two needles at different rest angles, so the pair reads as two
    // independent instruments rather than one shape mirrored.
    for (final angle in [-0.5, -0.28]) {
      final pivot = Offset(
        recessRect.left + recessRect.width * 0.5,
        recessRect.bottom - recessRect.height * 0.06,
      );
      canvas.save();
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(angle);
      canvas.drawLine(
        Offset.zero,
        Offset(recessRect.width * 0.34, 0),
        Paint()
          ..strokeWidth = face.height * 0.008
          ..strokeCap = StrokeCap.round
          ..color = palette.indicator,
      );
      canvas.restore();
    }
  }

  void _paintButtons(Canvas canvas, Rect face) {
    final glyph = Paint()..color = palette.chromeLight;
    final cap = Paint()..color = palette.panelDark;
    final capEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = face.height * 0.005
      ..color = palette.panelEdge;

    final buttonsY = face.top + face.height * 0.20;
    final size = face.height * 0.10;

    void button(double dx, void Function(Offset centre) drawGlyph) {
      final centre = Offset(face.left + face.width * dx, buttonsY);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: centre, width: size, height: size),
        Radius.circular(size * 0.18),
      );
      canvas.drawRRect(rect, cap);
      canvas.drawRRect(rect, capEdge);
      drawGlyph(centre);
    }

    button(0.70, (c) {
      final path = Path()
        ..moveTo(c.dx - size * 0.14, c.dy - size * 0.18)
        ..lineTo(c.dx - size * 0.14, c.dy + size * 0.18)
        ..lineTo(c.dx + size * 0.18, c.dy)
        ..close();
      canvas.drawPath(path, glyph);
    });
    button(0.80, (c) {
      canvas.drawRect(
        Rect.fromCenter(center: c, width: size * 0.32, height: size * 0.32),
        glyph,
      );
    });
    button(0.90, (c) {
      for (final dx in [-size * 0.16, size * 0.02]) {
        final path = Path()
          ..moveTo(c.dx + dx, c.dy - size * 0.16)
          ..lineTo(c.dx + dx, c.dy + size * 0.16)
          ..lineTo(c.dx + dx + size * 0.16, c.dy)
          ..close();
        canvas.drawPath(path, glyph);
      }
    });
    button(0.60, (c) {
      for (final dx in [size * 0.14, -size * 0.02]) {
        final path = Path()
          ..moveTo(c.dx + dx, c.dy - size * 0.16)
          ..lineTo(c.dx + dx, c.dy + size * 0.16)
          ..lineTo(c.dx + dx - size * 0.16, c.dy)
          ..close();
        canvas.drawPath(path, glyph);
      }
    });
  }

  void _paintWell(Canvas canvas, Rect well) {
    // The well is where the eye lands, and a flat fill read as a shape
    // painted on the face rather than a cavity cut into it. The fix is the
    // same recess vocabulary the VU meter and display use elsewhere: a
    // gradient that darkens toward the back of the cavity, a lit rim
    // catching light along the top the way a real inset edge would, and an
    // outer stroke deep enough to read as a wall rather than a hairline.
    final shape = RRect.fromRectAndRadius(
      well,
      Radius.circular(well.height * 0.05),
    );

    // A lighter tone at the mouth of the cavity fading to wellDark at the
    // back — panelDark and wellDark alone were too close to each other in
    // value to read as a gradient at this size, the same problem the deck
    // face solved by repeating its two tones through four stops rather than
    // fading once.
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(palette.panelDark, palette.chromeMid, 0.22) ??
                palette.panelDark,
            palette.wellDark,
          ],
          stops: const [0, 0.6],
        ).createShader(well),
    );

    // A vignette along the side and bottom walls, darker than the cavity's
    // own gradient — the shadow the walls of a real recess throw across
    // their own floor, which is what turns a gradient into depth rather
    // than just a second flat tone.
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.4),
          radius: 1.1,
          colors: [
            palette.wellDark.withValues(alpha: 0),
            palette.panelEdge.withValues(alpha: 0.85),
          ],
          stops: const [0.55, 1],
        ).createShader(well),
    );

    // The lit lip: a bright, deliberately thick stroke along the top inside
    // edge, with a dark line just beneath it standing in for the shadow the
    // lip itself casts a hair's-width into the cavity — the pairing that
    // reads as an inset edge rather than a line drawn on a flat surface.
    canvas.drawLine(
      Offset(well.left + well.height * 0.1, well.top + well.height * 0.03),
      Offset(well.right - well.height * 0.1, well.top + well.height * 0.03),
      Paint()
        ..strokeWidth = well.height * 0.035
        ..strokeCap = StrokeCap.round
        ..color = palette.chromeLight.withValues(alpha: 0.55),
    );
    canvas.drawLine(
      Offset(well.left + well.height * 0.1, well.top + well.height * 0.09),
      Offset(well.right - well.height * 0.1, well.top + well.height * 0.09),
      Paint()
        ..strokeWidth = well.height * 0.02
        ..strokeCap = StrokeCap.round
        ..color = palette.wellDark.withValues(alpha: 0.7),
    );

    canvas.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = well.height * 0.035
        ..color = palette.panelEdge,
    );
  }

  void _paintDoor(Canvas canvas, Rect face, Rect well) {
    // The door slides down from fully behind the top bezel at closed = 0 —
    // clipped away entirely, the way a real sliding door disappears into
    // its housing — to sit exactly over the well at closed = 1. Racking it
    // up only as far as the VU meter's lower edge (the first version of
    // this) left it overlapping the meter instead of hiding; going all the
    // way above the face is what actually reads as "open".
    final doorRect = Rect.fromLTWH(
      well.left - well.width * 0.04,
      well.top - well.height * 0.06,
      well.width * 1.08,
      well.height * 1.12,
    );
    final openTop = face.top - doorRect.height;
    final doorTop = openTop + (doorRect.top - openTop) * closed;
    final travelling = Rect.fromLTWH(
      doorRect.left,
      doorTop,
      doorRect.width,
      doorRect.height,
    );
    final door = RRect.fromRectAndRadius(
      travelling,
      Radius.circular(well.height * 0.04),
    );

    canvas.save();
    canvas.clipRect(face);

    canvas.drawRRect(door, Paint()..color = palette.glassTint);

    // The diagonal sheen clear plastic throws, same technique the cassette
    // shell's window uses, so the deck's door and the cassette it will hold
    // read as the same material family.
    canvas.drawRRect(
      door,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.glassSheen.withValues(alpha: 0),
            palette.glassSheen.withValues(alpha: 0.5),
            palette.glassSheen.withValues(alpha: 0),
          ],
          stops: const [0.05, 0.24, 0.5],
        ).createShader(travelling),
    );

    canvas.drawRRect(
      door,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = well.height * 0.015
        ..color = palette.chromeMid.withValues(alpha: 0.6),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(TapeDeckPainter oldDelegate) =>
      oldDelegate.closed != closed ||
      oldDelegate.palette != palette ||
      oldDelegate.layer != layer;
}
