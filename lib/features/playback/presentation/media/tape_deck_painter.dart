import 'package:flutter/material.dart';

import '../../../../core/theme/album_palette.dart';

/// A tape deck, waiting for a cassette or playing one (UC-21, FR-PL-07).
///
/// The still/moving split is the glass door: the face, the VU meter, the
/// transport buttons and the well beneath the door all sit fixed, and only
/// the door itself travels as [closed] runs from 0 (racked up, the well open
/// and waiting) to 1 (slid down over the well). [CassettePainter] is what the
/// stage layers into that well; this painter only owns what the cassette sits
/// inside.
class TapeDeckPainter extends CustomPainter {
  /// Creates the painter.
  const TapeDeckPainter({required this.palette, required this.closed});

  /// The artwork's colours (FR-UX-07).
  final AlbumPalette palette;

  /// 0 with the door racked open above the well; 1 with it slid down,
  /// closed over the cassette.
  final double closed;

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

    _paintFace(canvas, face);
    _paintVuMeter(canvas, face);
    _paintButtons(canvas, face);

    final well = Rect.fromLTWH(
      face.left + face.width * 0.06,
      face.top + face.height * 0.50,
      face.width * 0.55,
      face.height * 0.42,
    );
    _paintWell(canvas, well);
    _paintDoor(canvas, face, well);
  }

  void _paintFace(Canvas canvas, Rect face) {
    final panel = RRect.fromRectAndRadius(face, Radius.circular(face.height * 0.04));

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
    canvas.drawRRect(
      RRect.fromRectAndRadius(well, Radius.circular(well.height * 0.05)),
      Paint()..color = palette.wellDark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(well, Radius.circular(well.height * 0.05)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = well.height * 0.02
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
      oldDelegate.closed != closed || oldDelegate.palette != palette;
}
