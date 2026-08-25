import 'package:flutter/material.dart';

import '../../../../core/theme/album_palette.dart';

/// A CD player, waiting for a disc or playing one (UC-21, FR-PL-07).
///
/// The still/moving split is the lid: the face, the display, the transport
/// buttons and the disc well all sit fixed, and only the lid travels, hinged
/// at the well's back edge and flattening down over it as [closed] runs from
/// 0 (standing open) to 1 (shut flat). [DiscPainter] is what the stage lays
/// into the well; this painter only owns what the disc sits inside.
class CdPlayerPainter extends CustomPainter {
  /// Creates the painter.
  const CdPlayerPainter({required this.palette, required this.closed});

  /// The artwork's colours (FR-UX-07).
  final AlbumPalette palette;

  /// 0 with the lid standing open on its hinge; 1 with it shut flat over
  /// the disc.
  final double closed;

  /// A CD player face is wide, like the tape deck it sits beside.
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
    _paintDisplay(canvas, face);
    _paintButtons(canvas, face);

    // The well is the dominant feature and sits centred in the body, below
    // the display/button band, with room on every side so the lid — sized
    // to the well alone — can never reach either of them. The first version
    // of this put the well off-centre and undersized the top band, which
    // let the well, the display and the lid all fight for the same pixels
    // at both ends of `closed`.
    final wellCentre = Offset(face.center.dx, face.top + face.height * 0.66);
    final wellRadius = face.height * 0.26;
    _paintWell(canvas, wellCentre, wellRadius);
    _paintLid(canvas, face, wellCentre, wellRadius);
  }

  void _paintFace(Canvas canvas, Rect face) {
    final panel = RRect.fromRectAndRadius(face, Radius.circular(face.height * 0.04));

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

  void _paintDisplay(Canvas canvas, Rect face) {
    final recessRect = Rect.fromLTWH(
      face.left + face.width * 0.06,
      face.top + face.height * 0.08,
      face.width * 0.46,
      face.height * 0.20,
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

    final track = TextPainter(
      text: TextSpan(
        text: '01  03:47',
        style: TextStyle(
          color: palette.displayInk,
          fontSize: recessRect.height * 0.4,
          fontFeatures: const [FontFeature.tabularFigures()],
          fontFamily: 'monospace',
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: recessRect.width - recessRect.width * 0.16);
    track.paint(
      canvas,
      Offset(
        recessRect.left + recessRect.width * 0.08,
        recessRect.center.dy - track.height / 2,
      ),
    );
  }

  void _paintButtons(Canvas canvas, Rect face) {
    final glyph = Paint()..color = palette.chromeLight;
    final cap = Paint()..color = palette.panelDark;
    final capEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = face.height * 0.005
      ..color = palette.panelEdge;

    final buttonsY = face.top + face.height * 0.18;
    final size = face.height * 0.11;
    // Kept clear of the display recess, which occupies the left half of
    // this same band — a button drawn over the readout was the bug an
    // earlier pass had here.

    void button(double dx, void Function(Offset centre) drawGlyph) {
      final centre = Offset(face.left + face.width * dx, buttonsY);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: centre, width: size, height: size),
        Radius.circular(size),
      );
      canvas.drawRRect(rect, cap);
      canvas.drawRRect(rect, capEdge);
      drawGlyph(centre);
    }

    button(0.66, (c) {
      final path = Path()
        ..moveTo(c.dx - size * 0.14, c.dy - size * 0.18)
        ..lineTo(c.dx - size * 0.14, c.dy + size * 0.18)
        ..lineTo(c.dx + size * 0.18, c.dy)
        ..close();
      canvas.drawPath(path, glyph);
    });
    button(0.78, (c) {
      canvas.drawRect(
        Rect.fromCenter(center: c, width: size * 0.32, height: size * 0.32),
        glyph,
      );
    });
    button(0.90, (c) {
      // The eject glyph: an upward arrow over a bar.
      final path = Path()
        ..moveTo(c.dx, c.dy - size * 0.20)
        ..lineTo(c.dx - size * 0.16, c.dy + size * 0.02)
        ..lineTo(c.dx + size * 0.16, c.dy + size * 0.02)
        ..close();
      canvas.drawPath(path, glyph);
      canvas.drawRect(
        Rect.fromCenter(
          center: c.translate(0, size * 0.18),
          width: size * 0.34,
          height: size * 0.06,
        ),
        glyph,
      );
    });
  }

  void _paintWell(Canvas canvas, Offset centre, double radius) {
    canvas.drawCircle(centre, radius * 1.14, Paint()..color = palette.wellDark);
    canvas.drawCircle(
      centre,
      radius * 1.14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.05
        ..color = palette.panelEdge,
    );
    canvas.drawCircle(centre, radius * 0.14, Paint()..color = palette.chromeMid);
    canvas.drawCircle(centre, radius * 0.06, Paint()..color = palette.chromeLight);
  }

  void _paintLid(Canvas canvas, Rect face, Offset wellCentre, double wellRadius) {
    // The lid is hinged at the well's back (top) edge and flattens down to
    // lie over the whole well as it closes. Modelled as a vertical scale
    // about the hinge line rather than a slide, because a lid opens by
    // rotating about a fixed edge, not by travelling — the same idea as the
    // tape door sliding, applied to a hinge instead of a rail.
    final hinge = wellCentre.dy - wellRadius * 1.14;
    final lidRect = Rect.fromLTWH(
      wellCentre.dx - wellRadius * 1.14,
      hinge,
      wellRadius * 2.28,
      wellRadius * 2.28,
    );

    canvas.save();
    canvas.clipRect(face);
    canvas.translate(lidRect.center.dx, hinge);
    // A minimum scale keeps the lid a visible sliver rather than vanishing
    // entirely when open, matching a real hinged lid propped near-vertical.
    canvas.scale(1, 0.06 + 0.94 * closed);
    canvas.translate(-lidRect.center.dx, -hinge);

    final lid = RRect.fromRectAndRadius(
      lidRect,
      Radius.circular(wellRadius * 0.16),
    );
    canvas.drawRRect(lid, Paint()..color = palette.glassTint);
    canvas.drawRRect(
      lid,
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
        ).createShader(lidRect),
    );
    canvas.drawRRect(
      lid,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = wellRadius * 0.04
        ..color = palette.chromeMid.withValues(alpha: 0.6),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(CdPlayerPainter oldDelegate) =>
      oldDelegate.closed != closed || oldDelegate.palette != palette;
}
