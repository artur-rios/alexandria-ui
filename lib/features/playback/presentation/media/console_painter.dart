import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/album_medium.dart';
import '../../../../core/theme/album_palette.dart';
import 'cassette_painter.dart';
import 'device_layer.dart';
import 'device_transport.dart';
import 'led_panel.dart';

/// The one machine every record is played on (UC-21, FR-PL-07, FR-PL-12).
///
/// Three devices used to share this stage — a turntable, a tape deck and a CD
/// player, each drawn by a painter of its own and each replacing the others
/// when the medium changed. That is not what the shelf it is modelled on
/// looks like. The all-in-one it replaces them with is a single console: a
/// turntable under a smoked lid on top, a cassette bay down the left of the
/// fascia, a disc drawer along the bottom, the displays and the transport in
/// the middle, and a speaker on the right — every slot present at once, and
/// whichever one the record playing belongs in is the one with something
/// turning in it.
///
/// What moves is chosen by [medium], and only what that medium would move:
/// the lid lifts for a record and stays down otherwise, the drawer runs out
/// for a disc and stays shut otherwise, and the cassette bay's window is
/// glass a tape is seen through rather than a door that swings. [closed] is
/// the same 0-to-1 the stage has always driven — the device receiving what it
/// has just been handed.
///
/// Painted in two passes, chosen by [layer], for the reason every device
/// painter here has been: the lid, the tonearm, the bay's glass and the
/// drawer's front lip all have to be seen *over* the medium, and the platter,
/// the bay's recess and the drawer's bed all have to be seen under it. See
/// [DeviceLayer].
class ConsolePainter extends CustomPainter {
  /// Creates the painter.
  const ConsolePainter({
    required this.palette,
    required this.medium,
    required this.closed,
    required this.layer,
    this.isPlaying = false,
    this.trackTitle = '',
    this.display = '',
  });

  /// The artwork's colours (FR-UX-07).
  final AlbumPalette palette;

  /// Which of the three slots is in use, and so which mechanism moves.
  final AlbumMedium medium;

  /// 0 with the machine open and waiting; 1 with it holding the medium.
  final double closed;

  /// Which pass this paint call draws.
  final DeviceLayer layer;

  /// Whether audio is running, which is what the play cap shows as a pause.
  final bool isPlaying;

  /// What is playing, lit in the name window. Empty leaves the window dark —
  /// a machine with nothing in it says nothing.
  final String trackTitle;

  /// What the readout says — the track and where it has got to, formatted by
  /// the caller (`AlbumStage`), for the reason a painter never formats a
  /// position itself: it is decided once, in `formatPlaybackPosition`, for
  /// the bar and the device alike.
  final String display;

  /// A console is nearly as tall as it is wide: a deck on top of a fascia,
  /// where each of the three devices it replaces was a single wide face.
  static const double aspect = 1.08;

  /// The drawer's depth when it is shut and when it is fully out, as
  /// fractions of the face's height.
  ///
  /// Grown rather than translated, which is what a drawer coming toward the
  /// viewer looks like drawn face-on: shut, it is the slot along the front;
  /// open, it is a bed deep enough for a disc to lie in.
  static const double trayShut = 0.055;

  /// See [trayShut].
  static const double trayOpen = 0.200;

  /// The deck the platter turns on: the top of the machine.
  static Rect deckOf(Rect face) => Rect.fromLTRB(
    face.left + face.width * 0.02,
    face.top + face.height * 0.02,
    face.right - face.width * 0.02,
    face.top + face.height * 0.50,
  );

  /// The platter's centre and radius.
  static (Offset, double) platterOf(Rect face) => (
    Offset(face.left + face.width * 0.38, face.top + face.height * 0.255),
    face.height * 0.205,
  );

  /// The cassette bay, down the left of the fascia.
  static Rect bayOf(Rect face) => Rect.fromLTRB(
    face.left + face.width * 0.03,
    face.top + face.height * 0.615,
    face.left + face.width * 0.30,
    face.top + face.height * 0.865,
  );

  /// The disc drawer, [closed] of the way out.
  static Rect trayOf(Rect face, double closed) {
    final top = face.top + face.height * 0.79;

    return Rect.fromLTRB(
      face.left + face.width * 0.31,
      top,
      face.left + face.width * 0.73,
      top + face.height * (trayShut + (trayOpen - trayShut) * closed),
    );
  }

  /// The readout window — the track number and the position.
  static Rect readoutOf(Rect face) => Rect.fromLTRB(
    face.left + face.width * 0.325,
    face.top + face.height * 0.545,
    face.left + face.width * 0.475,
    face.top + face.height * 0.665,
  );

  /// The name window — what is playing.
  static Rect nameWindowOf(Rect face) => Rect.fromLTRB(
    face.left + face.width * 0.495,
    face.top + face.height * 0.545,
    face.left + face.width * 0.805,
    face.top + face.height * 0.665,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final face = deviceFaceOf(size);

    switch (layer) {
      case DeviceLayer.chassis:
        _paintBody(canvas, face);
        _paintDeck(canvas, face);
        _paintFascia(canvas, face);
        _paintBay(canvas, face);
        _paintWindows(canvas, face);
        _paintKnobs(canvas, face);
        _paintSpeaker(canvas, face);
        _paintTransport(canvas, face);
        _paintTray(canvas, face);
      case DeviceLayer.foreground:
        _paintLid(canvas, face);
        _paintTonearm(canvas, face);
        _paintBayGlass(canvas, face);
        _paintTrayLip(canvas, face);
    }
  }

  /// The wooden case, grain and all.
  void _paintBody(Canvas canvas, Rect face) {
    final body = RRect.fromRectAndRadius(
      face,
      Radius.circular(face.height * 0.025),
    );

    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.plinthTop, palette.plinthBottom],
        ).createShader(face),
    );

    canvas.save();
    canvas.clipRRect(body);
    _paintGrain(canvas, face);
    canvas.restore();

    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = face.height * 0.006
        ..color = palette.plinthEdge,
    );
  }

  /// The veneer's vertical grain, drawn at deterministic uneven spacing so it
  /// reads as wood rather than as a hatch — and so the goldens reproduce.
  void _paintGrain(Canvas canvas, Rect bounds) {
    final line = Paint()..strokeWidth = bounds.height * 0.008;
    const count = 26;
    for (var i = 0; i < count; i++) {
      final x = bounds.left + bounds.width * (i / count);
      final dark = math.sin(i * 2.4) > 0;
      final alpha = 0.08 + 0.12 * (0.5 + 0.5 * math.sin(i * 1.7 + 0.4));
      line.color = (dark ? palette.plinthEdge : palette.plinthTop).withValues(
        alpha: alpha,
      );
      canvas.drawLine(Offset(x, bounds.top), Offset(x, bounds.bottom), line);
    }
  }

  /// The deck: a recessed bed with the platter and its spindle in it.
  void _paintDeck(Canvas canvas, Rect face) {
    final deck = deckOf(face);
    canvas.drawRRect(
      RRect.fromRectAndRadius(deck, Radius.circular(face.height * 0.02)),
      Paint()..color = palette.wellDark.withValues(alpha: 0.55),
    );

    final (centre, radius) = platterOf(face);
    canvas.drawCircle(centre, radius * 1.07, Paint()..color = palette.wellDark);
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [palette.matInner, palette.matOuter],
          stops: const [0.55, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );

    // Eight strobe dots around the mat's rim, the way a 33/45 strobe pattern
    // reads at rest under a fixed light.
    final strobe = Paint()..color = palette.chromeLight.withValues(alpha: 0.5);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawCircle(
        centre.translate(
          math.cos(angle) * radius * 0.88,
          math.sin(angle) * radius * 0.88,
        ),
        radius * 0.025,
        strobe,
      );
    }

    canvas.drawCircle(
      centre,
      radius * 0.06,
      Paint()..color = palette.chromeDark,
    );
    canvas.drawCircle(
      centre,
      radius * 0.028,
      Paint()..color = palette.chromeLight,
    );

    _paintDeckControls(canvas, face);
  }

  /// The power lamp and the two speed caps, on the deck to the right of the
  /// platter — where a turntable puts them, and where this machine would
  /// otherwise have a stretch of empty veneer under its lid.
  void _paintDeckControls(Canvas canvas, Rect face) {
    final lamp = Offset(
      face.left + face.width * 0.885,
      face.top + face.height * 0.11,
    );
    canvas.drawCircle(
      lamp,
      face.height * 0.016,
      Paint()..color = palette.indicator,
    );
    canvas.drawCircle(
      lamp,
      face.height * 0.016,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = face.height * 0.004
        ..color = palette.panelEdge,
    );

    final cap = Paint()..color = palette.chromeMid;
    final capEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = face.height * 0.004
      ..color = palette.panelEdge;
    for (final dy in [0.22, 0.34]) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(
            face.left + face.width * 0.885,
            face.top + face.height * dy,
          ),
          width: face.width * 0.075,
          height: face.height * 0.06,
        ),
        Radius.circular(face.height * 0.010),
      );
      canvas.drawRRect(rect, cap);
      canvas.drawRRect(rect, capEdge);
    }
  }

  /// The brushed fascia the controls are set into.
  void _paintFascia(Canvas canvas, Rect face) {
    final fascia = Rect.fromLTRB(
      face.left + face.width * 0.02,
      face.top + face.height * 0.52,
      face.right - face.width * 0.02,
      face.bottom - face.height * 0.02,
    );
    final plate = RRect.fromRectAndRadius(
      fascia,
      Radius.circular(face.height * 0.018),
    );

    canvas.drawRRect(
      plate,
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
          stops: const [0, 0.35, 0.7, 1],
        ).createShader(fascia),
    );

    // The lit lip along the top edge, where a raking light catches it.
    canvas.drawLine(
      Offset(
        fascia.left + face.height * 0.03,
        fascia.top + face.height * 0.010,
      ),
      Offset(
        fascia.right - face.height * 0.03,
        fascia.top + face.height * 0.010,
      ),
      Paint()
        ..strokeWidth = face.height * 0.012
        ..strokeCap = StrokeCap.round
        ..color = palette.chromeLight.withValues(alpha: 0.35),
    );

    canvas.drawRRect(
      plate,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = face.height * 0.005
        ..color = palette.panelEdge,
    );
  }

  /// The cassette bay's recess — the dark well a tape sits in.
  void _paintBay(Canvas canvas, Rect face) {
    final bay = bayOf(face);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bay, Radius.circular(face.height * 0.014)),
      Paint()..color = palette.wellDark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bay, Radius.circular(face.height * 0.014)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = face.height * 0.005
        ..color = palette.panelEdge,
    );
  }

  /// The glass the cassette is seen through, drawn over it.
  void _paintBayGlass(Canvas canvas, Rect face) {
    final bay = bayOf(face);
    final glass = RRect.fromRectAndRadius(
      bay.deflate(face.height * 0.012),
      Radius.circular(face.height * 0.010),
    );

    // Barely tinted: what is behind it is the cassette, and glass dark
    // enough to read as a door is dark enough to lose it.
    canvas.drawRRect(
      glass,
      Paint()..color = palette.glassTint.withValues(alpha: 0.14),
    );
    canvas.drawRRect(
      glass,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.glassSheen.withValues(alpha: 0),
            palette.glassSheen.withValues(alpha: 0.22),
            palette.glassSheen.withValues(alpha: 0),
          ],
          stops: const [0.1, 0.3, 0.55],
        ).createShader(bay),
    );
    canvas.drawRRect(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = face.height * 0.004
        ..color = palette.chromeMid.withValues(alpha: 0.5),
    );
  }

  /// The two lit windows: the readout, and the name of what is playing.
  void _paintWindows(Canvas canvas, Rect face) {
    final readout = readoutOf(face);
    paintLedPanel(
      canvas,
      bounds: readout,
      palette: palette,
      text: display,
      fontSize: math.min(readout.height * 0.32, readout.width * 0.115),
    );

    final name = nameWindowOf(face);
    paintLedPanel(
      canvas,
      bounds: name,
      palette: palette,
      text: trackTitle,
      // Smaller than the window would take a short title at, because most
      // titles are not short: set at the window's full height, an ordinary
      // one is shrunk to the floor and cut anyway, and a name window that
      // cuts names is the thing this whole fascia was rebuilt around.
      fontSize: name.height * 0.28,
    );
  }

  /// Tuning and volume, right of the windows.
  void _paintKnobs(Canvas canvas, Rect face) {
    final radius = face.height * 0.048;
    for (final dx in [0.855, 0.945]) {
      final centre = Offset(
        face.left + face.width * dx,
        face.top + face.height * 0.605,
      );

      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.chromeLight, palette.chromeDark],
          ).createShader(Rect.fromCircle(center: centre, radius: radius)),
      );
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.12
          ..color = palette.panelEdge,
      );
      // The pointer line, at the angle a knob left near its middle sits.
      canvas.drawLine(
        centre,
        centre.translate(0, -radius * 0.75),
        Paint()
          ..strokeWidth = radius * 0.16
          ..strokeCap = StrokeCap.round
          ..color = palette.panelDark,
      );
    }
  }

  /// The speaker, on the right of the fascia.
  void _paintSpeaker(Canvas canvas, Rect face) {
    final bounds = Rect.fromLTRB(
      face.left + face.width * 0.815,
      face.top + face.height * 0.70,
      face.left + face.width * 0.985,
      face.top + face.height * 0.94,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, Radius.circular(face.height * 0.014)),
      Paint()..color = palette.panelDark.withValues(alpha: 0.55),
    );

    final pitch = face.height * 0.028;
    final hole = Paint()..color = palette.wellDark;
    for (
      var y = bounds.top + pitch * 0.8;
      y < bounds.bottom - pitch * 0.3;
      y += pitch
    ) {
      for (
        var x = bounds.left + pitch * 0.8;
        x < bounds.right - pitch * 0.3;
        x += pitch
      ) {
        canvas.drawCircle(Offset(x, y), pitch * 0.26, hole);
      }
    }
  }

  /// The four caps, in one row and in the order they have always been read
  /// in: back, play, stop, forward.
  void _paintTransport(Canvas canvas, Rect face) {
    paintTransport(
      canvas,
      bounds: transportBoundsFor(face),
      palette: palette,
      isPlaying: isPlaying,
      corner: 0.3,
    );
  }

  /// The drawer's bed — what the disc lies in, so it is painted under it.
  void _paintTray(Canvas canvas, Rect face) {
    final tray = trayOf(face, medium == AlbumMedium.disc ? closed : 0);
    final drawer = RRect.fromRectAndRadius(
      tray,
      Radius.circular(face.height * 0.012),
    );

    canvas.drawRRect(drawer, Paint()..color = palette.wellDark);
    canvas.drawRRect(
      drawer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = face.height * 0.004
        ..color = palette.panelEdge,
    );
  }

  /// The drawer's front lip, over the disc's lower edge, so the disc reads as
  /// lying *in* the drawer rather than on top of the machine.
  void _paintTrayLip(Canvas canvas, Rect face) {
    if (medium != AlbumMedium.disc) return;

    final tray = trayOf(face, closed);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          tray.left + face.width * 0.012,
          tray.bottom - face.height * 0.016,
          tray.right - face.width * 0.012,
          tray.bottom - face.height * 0.003,
        ),
        Radius.circular(face.height * 0.006),
      ),
      Paint()..color = palette.chromeDark,
    );
  }

  /// The smoked lid over the deck, hinged at the back.
  ///
  /// Down for every medium but the record: a machine playing a tape has no
  /// reason to have its lid standing open, and a record being put on is the
  /// one time the owner sees it move. Modelled as a vertical scale about the
  /// hinge line rather than a slide, because a lid opens by rotating about a
  /// fixed edge.
  void _paintLid(Canvas canvas, Rect face) {
    final deck = deckOf(face);
    final open = medium == AlbumMedium.vinyl ? closed : 1.0;

    canvas.save();
    canvas.translate(deck.center.dx, deck.top);
    canvas.scale(1, 0.05 + 0.95 * open);
    canvas.translate(-deck.center.dx, -deck.top);

    final lid = RRect.fromRectAndRadius(
      deck,
      Radius.circular(face.height * 0.02),
    );
    // Smoked, not blacked out: what is under it is the record, and a lid
    // dark enough to be read as a lid is dark enough to lose it.
    canvas.drawRRect(
      lid,
      Paint()..color = palette.glassTint.withValues(alpha: 0.42),
    );
    canvas.drawRRect(
      lid,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.glassSheen.withValues(alpha: 0),
            palette.glassSheen.withValues(alpha: 0.30),
            palette.glassSheen.withValues(alpha: 0),
          ],
          stops: const [0.05, 0.24, 0.5],
        ).createShader(deck),
    );
    canvas.drawRRect(
      lid,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = face.height * 0.005
        ..color = palette.chromeMid.withValues(alpha: 0.6),
    );

    canvas.restore();
  }

  /// The tonearm, swinging in over the record as the lid comes down.
  void _paintTonearm(Canvas canvas, Rect face) {
    final h = face.height;
    final (platterCentre, platterRadius) = platterOf(face);
    final pivot = Offset(
      face.left + face.width * 0.72,
      face.top + face.height * 0.11,
    );

    // The played position points at the lead-in groove near the rim, not at
    // the label in the middle, which is not a groove at all.
    final toCentre = platterCentre - pivot;
    final playTip =
        platterCentre - toCentre / toCentre.distance * platterRadius * 0.90;
    final toPlayTip = playTip - pivot;
    final armLength = toPlayTip.distance;
    final playAngle = toPlayTip.direction;
    // Only a record is played by the arm: for a tape or a disc it stays on
    // its rest, where a real one would be.
    final seated = medium == AlbumMedium.vinyl ? closed : 0.0;
    final angle = ui.lerpDouble(playAngle - _restSweep, playAngle, seated)!;

    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);

    canvas.drawCircle(
      Offset(-armLength * 0.14, 0),
      h * 0.026,
      Paint()..color = palette.chromeDark,
    );
    canvas.drawCircle(
      Offset.zero,
      h * 0.022,
      Paint()..color = palette.chromeMid,
    );
    canvas.drawLine(
      Offset.zero,
      Offset(armLength, 0),
      Paint()
        ..strokeWidth = h * 0.016
        ..strokeCap = StrokeCap.round
        ..color = palette.chromeLight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(armLength, 0),
          width: h * 0.06,
          height: h * 0.02,
        ),
        Radius.circular(h * 0.004),
      ),
      Paint()..color = palette.panelDark,
    );

    canvas.restore();
  }

  /// How far the arm swings back to its rest, in radians. A real tonearm's
  /// whole travel is only 25–35°; anything near 90° reads as broken.
  static const double _restSweep = 0.85;

  @override
  bool shouldRepaint(ConsolePainter old) =>
      old.closed != closed ||
      old.palette != palette ||
      old.layer != layer ||
      old.medium != medium ||
      old.isPlaying != isPlaying ||
      old.trackTitle != trackTitle ||
      old.display != display;
}

/// Where, and how large, [medium] sits on a console drawn into [face].
///
/// One function rather than a seat per device: the three slots are all on the
/// same machine now, so where a medium goes is a fact about the console and
/// belongs beside the geometry that draws it.
///
/// Where the disc *comes to rest*, not where the drawer currently is: the
/// drawer opens under it during the last beat of the insertion, which is the
/// machine taking what it has been handed rather than the disc riding a
/// moving shelf.
({Offset centre, double width, double height}) consoleSeatFor(
  AlbumMedium medium,
  Rect face,
) {
  switch (medium) {
    case AlbumMedium.vinyl:
      final (centre, radius) = ConsolePainter.platterOf(face);
      // A record overhangs the platter it turns on, as a twelve-inch record
      // overhangs every platter ever made.
      return (centre: centre, width: radius * 2.08, height: radius * 2.08);

    case AlbumMedium.tape:
      final bay = ConsolePainter.bayOf(face);
      final height = face.height * 0.142;
      return (
        centre: bay.center,
        width: height * CassettePainter.aspect,
        height: height,
      );

    case AlbumMedium.disc:
      final tray = ConsolePainter.trayOf(face, 1);
      final size = face.height * 0.155;
      return (
        centre: Offset(tray.center.dx, tray.center.dy - face.height * 0.004),
        width: size,
        height: size,
      );
  }
}
