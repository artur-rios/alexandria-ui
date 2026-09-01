import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/album_palette.dart';
import '../../domain/album_medium.dart';
import 'device_layer.dart';
import 'device_nameplate.dart';
import 'device_transport.dart';
import 'led_panel.dart';

/// A CD player, waiting for a disc or playing one (UC-21, FR-PL-07).
///
/// The still/moving split is the lid: the face, the display, the transport
/// buttons and the disc well all sit fixed, and only the lid travels, hinged
/// at the well's back edge and flattening down over it as [closed] runs from
/// 0 (standing open) to 1 (shut flat). [DiscPainter] is what the stage lays
/// into the well; this painter only owns what the disc sits inside.
///
/// Painted in two passes, chosen by [layer]: the lid has to be seen closing
/// *over* the disc, so it cannot share a pass with the well underneath it —
/// the stage paints the well behind the disc and the lid in front of it. See
/// [DeviceLayer].
class CdPlayerPainter extends CustomPainter {
  /// Creates the painter.
  const CdPlayerPainter({
    required this.palette,
    required this.closed,
    required this.layer,
    this.isPlaying = false,
    this.trackTitle = '',
    this.display = '',
  });

  /// The artwork's colours (FR-UX-07).
  final AlbumPalette palette;

  /// 0 with the lid standing open on its hinge; 1 with it shut flat over
  /// the disc.
  final double closed;

  /// Which pass this paint call draws.
  final DeviceLayer layer;

  /// Whether audio is running, which is what the play cap shows as a pause.
  final bool isPlaying;

  /// What is playing, printed on the device's own nameplate. Empty draws no
  /// plate at all — a device with nothing in it says nothing.
  final String trackTitle;

  /// What the readout says — the track and where it has got to, formatted by
  /// the caller (`AlbumStage`).
  ///
  /// A string rather than a track number and a duration: the display is a
  /// piece of glass with digits behind it, and how a position is written is
  /// already decided in one place for the whole application
  /// (`formatPlaybackPosition`). A painter that formatted its own would be a
  /// second answer to that question, free to drift from the one beside it in
  /// the bar. Empty draws nothing, which is a player with no disc in it.
  final String display;

  /// A CD player face is wide, like the tape deck it sits beside.
  static const double aspect = 1.7;

  @override
  void paint(Canvas canvas, Size size) {
    final face = deviceFaceOf(size);

    // The well is the dominant feature and sits centred in the body, below
    // the display/button band, with room on every side so the lid — sized
    // to the well alone — can never reach either of them. The first version
    // of this put the well off-centre and undersized the top band, which
    // let the well, the display and the lid all fight for the same pixels
    // at both ends of `closed`.
    final wellCentre = Offset(face.center.dx, face.top + face.height * 0.66);
    final wellRadius = face.height * 0.26;

    switch (layer) {
      case DeviceLayer.chassis:
        _paintFace(canvas, face);
        _paintDisplay(canvas, face);
        _paintGrille(canvas, face);
        _paintButtons(canvas, face);
        _paintNameplate(canvas, size);
        _paintWell(canvas, wellCentre, wellRadius);
      case DeviceLayer.foreground:
        _paintLid(canvas, face, wellCentre, wellRadius);
    }
  }

  void _paintFace(Canvas canvas, Rect face) {
    final panel = RRect.fromRectAndRadius(
      face,
      Radius.circular(face.height * 0.04),
    );

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

  /// The readout, in the left half of the display band.
  ///
  /// Narrower than it was, and lit rather than printed: the band it sits in
  /// is shared with the nameplate now (see [nameplateFor]), and the two
  /// windows together are what make this face read as an instrument panel.
  /// The digits are sized off the window's *width* as well as its height,
  /// because what has to fit is a known nine characters — a font chosen off
  /// the height alone would spill them the moment the band narrowed.
  void _paintDisplay(Canvas canvas, Rect face) {
    final bounds = Rect.fromLTWH(
      face.left + face.width * 0.05,
      face.top + face.height * 0.07,
      face.width * 0.35,
      face.height * 0.22,
    );

    paintLedPanel(
      canvas,
      bounds: bounds,
      palette: palette,
      text: display,
      fontSize: math.min(bounds.height * 0.34, bounds.width * 0.12),
    );
  }

  /// The speaker, down the face's left side.
  ///
  /// Not a CD player's feature — a radio's. The face had a wide empty strip
  /// beside the well once the transport moved to the right of it, and an
  /// empty strip of brushed aluminium reads as a device missing a part. A
  /// grille is what a machine with a display band across its top and a
  /// square of buttons beside it is: the drilled dots are the cue, so they
  /// are drawn as dots rather than suggested with a texture.
  void _paintGrille(Canvas canvas, Rect face) {
    final bounds = Rect.fromLTWH(
      face.left + face.width * 0.05,
      face.top + face.height * 0.40,
      face.width * 0.22,
      face.height * 0.48,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, Radius.circular(face.height * 0.03)),
      Paint()..color = palette.panelDark.withValues(alpha: 0.55),
    );

    // Rows and columns counted from the pitch rather than fixed, so the
    // grille keeps the same hole *size* on a small device instead of the
    // same number of ever-smaller holes.
    final pitch = face.height * 0.062;
    final hole = Paint()..color = palette.wellDark;
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = pitch * 0.06
      ..color = palette.chromeDark.withValues(alpha: 0.5);

    for (
      var y = bounds.top + pitch * 0.7;
      y < bounds.bottom - pitch * 0.3;
      y += pitch
    ) {
      for (
        var x = bounds.left + pitch * 0.7;
        x < bounds.right - pitch * 0.3;
        x += pitch
      ) {
        canvas.drawCircle(Offset(x, y), pitch * 0.26, hole);
        canvas.drawCircle(Offset(x, y), pitch * 0.26, rim);
      }
    }
  }

  /// The transport, drawn from the shared geometry the stage lays its hit
  /// targets over ([transportBoundsFor]) so a press lands on the cap the
  /// owner aimed at.
  ///
  /// The eject glyph that used to sit here is gone: it was the one button on
  /// the face that named an action this application has no equivalent of —
  /// there is no disc to eject — where the other three were already the
  /// transport the player has always had. Skipping took its place.
  void _paintButtons(Canvas canvas, Rect face) {
    paintTransport(
      canvas,
      bounds: transportBoundsFor(AlbumMedium.disc, face),
      palette: palette,
      isPlaying: isPlaying,
      // Round caps, as a CD player's buttons are.
      corner: 0.5,
    );
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
    canvas.drawCircle(
      centre,
      radius * 0.14,
      Paint()..color = palette.chromeMid,
    );
    canvas.drawCircle(
      centre,
      radius * 0.06,
      Paint()..color = palette.chromeLight,
    );
  }

  void _paintLid(
    Canvas canvas,
    Rect face,
    Offset wellCentre,
    double wellRadius,
  ) {
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

  /// What is playing, on the face (see [nameplateFor]).
  void _paintNameplate(Canvas canvas, Size size) {
    paintNameplate(
      canvas,
      bounds: nameplateFor(AlbumMedium.disc, deviceFaceOf(size)),
      palette: palette,
      title: trackTitle,
    );
  }

  @override
  bool shouldRepaint(CdPlayerPainter oldDelegate) =>
      oldDelegate.closed != closed ||
      oldDelegate.palette != palette ||
      oldDelegate.layer != layer ||
      oldDelegate.isPlaying != isPlaying ||
      oldDelegate.trackTitle != trackTitle ||
      oldDelegate.display != display;
}
