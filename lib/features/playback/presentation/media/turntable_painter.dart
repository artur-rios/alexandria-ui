import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/album_palette.dart';

/// A turntable, waiting for a record or playing one (UC-21, FR-PL-07).
///
/// The still/moving split here is the tonearm: everything else — the plinth,
/// the platter well, the mat, the controls — sits exactly where it always
/// does, and only the pivoted arm assembly swings between its rest peg and
/// the record as [closed] runs from 0 to 1. The platter itself does not spin
/// here; that motion belongs to [VinylPainter], which the stage layers on
/// top once the arm is down.
class TurntablePainter extends CustomPainter {
  /// Creates the painter.
  const TurntablePainter({required this.palette, required this.closed});

  /// The artwork's colours (FR-UX-07).
  final AlbumPalette palette;

  /// 0 with the tonearm lifted and parked on its rest; 1 with it lowered
  /// onto the record.
  final double closed;

  /// A turntable's plinth is noticeably wider than it is tall.
  static const double aspect = 1.5;

  /// How far the tonearm swings back from the record to its rest, in
  /// radians. A real tonearm's whole travel is only 25–35°; anything close
  /// to that reads as "lifted", and anything close to 90° reads as broken.
  /// Chosen a little wider than the real figure so the tip clears the
  /// platter's rim entirely rather than lifting to a point still over the
  /// record — a resting arm that hung over the edge of the mat would look
  /// like it forgot to move.
  static const double _restSweep = 0.95;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _paintPlinth(canvas, w, h);
    final platterCentre = Offset(w * 0.40, h * 0.52);
    final platterRadius = h * 0.40;
    _paintPlatter(canvas, platterCentre, platterRadius);
    _paintControls(canvas, w, h);
    _paintTonearm(canvas, w, h, platterCentre, platterRadius);
  }

  void _paintPlinth(Canvas canvas, double w, double h) {
    final margin = h * 0.03;
    final bounds = Rect.fromLTWH(margin, margin, w - margin * 2, h - margin * 2);
    final plinth = RRect.fromRectAndRadius(bounds, Radius.circular(h * 0.03));

    canvas.drawRRect(
      plinth,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.plinthTop, palette.plinthBottom],
        ).createShader(bounds),
    );

    // The lit top edge: a thin, brighter stroke along the upper rim, the way
    // a raking light catches the front lip of a wooden case.
    canvas.drawLine(
      Offset(bounds.left + h * 0.03, bounds.top + h * 0.012),
      Offset(bounds.right - h * 0.03, bounds.top + h * 0.012),
      Paint()
        ..strokeWidth = h * 0.02
        ..strokeCap = StrokeCap.round
        ..color = palette.plinthTop.withValues(alpha: 0.55),
    );

    canvas.drawRRect(
      plinth,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.008
        ..color = palette.plinthEdge,
    );

    final foot = Paint()..color = palette.plinthEdge;
    for (final dx in [bounds.left + w * 0.05, bounds.right - w * 0.05]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(dx, bounds.bottom - h * 0.006),
            width: w * 0.05,
            height: h * 0.03,
          ),
          Radius.circular(h * 0.006),
        ),
        foot,
      );
    }
  }

  void _paintPlatter(Canvas canvas, Offset centre, double radius) {
    // The well the platter sits in, a shade darker than the plinth around it.
    canvas.drawCircle(centre, radius * 1.08, Paint()..color = palette.wellDark);

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [palette.matInner, palette.matOuter],
          stops: const [0.55, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );

    // Eight strobe dots around the mat's rim, evenly spaced, the way a
    // 33/45 strobe pattern reads at rest under a fixed light.
    final strobe = Paint()..color = palette.chromeLight.withValues(alpha: 0.5);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawCircle(
        centre.translate(
          math.cos(angle) * radius * 0.88,
          math.sin(angle) * radius * 0.88,
        ),
        radius * 0.02,
        strobe,
      );
    }

    canvas.drawCircle(centre, radius * 0.05, Paint()..color = palette.chromeDark);
    canvas.drawCircle(centre, radius * 0.024, Paint()..color = palette.chromeLight);
  }

  void _paintControls(Canvas canvas, double w, double h) {
    final indicatorCentre = Offset(w * 0.86, h * 0.16);
    canvas.drawCircle(indicatorCentre, h * 0.018, Paint()..color = palette.indicator);
    canvas.drawCircle(
      indicatorCentre,
      h * 0.018,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.004
        ..color = palette.panelEdge,
    );

    // The 33 and 45 speed buttons, a pair of low, dark caps rather than
    // labelled discs — legible as controls at this size without needing
    // text small enough to blur.
    final cap = Paint()..color = palette.panelDark;
    final capEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.005
      ..color = palette.panelEdge;
    for (final dy in [h * 0.30, h * 0.42]) {
      final centre = Offset(w * 0.86, dy);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: centre, width: w * 0.08, height: h * 0.07),
        Radius.circular(h * 0.012),
      );
      canvas.drawRRect(rect, cap);
      canvas.drawRRect(rect, capEdge);
    }
  }

  void _paintTonearm(
    Canvas canvas,
    double w,
    double h,
    Offset platterCentre,
    double platterRadius,
  ) {
    final pivot = Offset(w * 0.86, h * 0.60);

    // The played position points at a spot short of the platter's centre —
    // near the inner grooves, where a needle actually rides — rather than
    // the centre itself, which is where the spindle sits, not the stylus.
    final toCentre = platterCentre - pivot;
    final playTip = platterCentre - toCentre / toCentre.distance * platterRadius * 0.32;
    final toPlayTip = playTip - pivot;
    final armLength = toPlayTip.distance;
    final playAngle = toPlayTip.direction;
    final restAngle = playAngle + _restSweep;
    final angle = ui.lerpDouble(restAngle, playAngle, closed)!;

    // The full assembly is one rigid body about the pivot: swinging its
    // parts independently is what would make the counterweight appear to
    // slide along the tube instead of riding fixed behind the pivot.
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);

    // The counterweight, behind the pivot.
    canvas.drawCircle(
      Offset(-armLength * 0.12, 0),
      h * 0.028,
      Paint()..color = palette.chromeDark,
    );
    canvas.drawCircle(
      Offset(-armLength * 0.12, 0),
      h * 0.028,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.004
        ..color = palette.chromeLight.withValues(alpha: 0.6),
    );

    // The pivot housing.
    canvas.drawCircle(Offset.zero, h * 0.024, Paint()..color = palette.chromeMid);

    // The chrome tube, tapering slightly toward the headshell.
    canvas.drawLine(
      Offset.zero,
      Offset(armLength, 0),
      Paint()
        ..strokeWidth = h * 0.014
        ..strokeCap = StrokeCap.round
        ..color = palette.chromeLight,
    );
    canvas.drawLine(
      Offset(h * 0.02, -h * 0.003),
      Offset(armLength - h * 0.02, -h * 0.003),
      Paint()
        ..strokeWidth = h * 0.005
        ..strokeCap = StrokeCap.round
        ..color = palette.chromeDark.withValues(alpha: 0.5),
    );

    // The headshell, angled slightly off the tube the way a real headshell
    // sits, plus the cartridge and stylus at its tip.
    final headshell = Offset(armLength, 0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: headshell, width: h * 0.09, height: h * 0.028),
        Radius.circular(h * 0.006),
      ),
      Paint()..color = palette.panelDark,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: headshell.translate(h * 0.055, 0),
        width: h * 0.03,
        height: h * 0.02,
      ),
      Paint()..color = palette.chromeDark,
    );
    canvas.drawCircle(
      headshell.translate(h * 0.075, 0),
      h * 0.006,
      Paint()..color = palette.chromeLight,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(TurntablePainter oldDelegate) =>
      oldDelegate.closed != closed || oldDelegate.palette != palette;
}
