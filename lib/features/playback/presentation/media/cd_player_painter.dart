import 'package:flutter/material.dart';

import '../../../../core/theme/album_palette.dart';
import '../../domain/album_medium.dart';
import 'device_layer.dart';
import 'device_transport.dart';

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
        _paintButtons(canvas, face);
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

    if (display.isEmpty) return;

    final track = TextPainter(
      text: TextSpan(
        text: display,
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

  @override
  bool shouldRepaint(CdPlayerPainter oldDelegate) =>
      oldDelegate.closed != closed ||
      oldDelegate.palette != palette ||
      oldDelegate.layer != layer ||
      oldDelegate.isPlaying != isPlaying ||
      oldDelegate.display != display;
}
