import 'package:flutter/material.dart';

import '../../../../core/theme/album_palette.dart';
import 'device_lettering.dart';

/// A lit window on a device's face (UC-21, FR-PL-07, FR-PL-12).
///
/// The devices had two kinds of window on them and painted them two ways: the
/// CD player's readout was digits laid straight onto a dark recess, and the
/// nameplate was a plate with a title printed on it. Neither looked lit.
/// Reading them side by side, the machine looked like it had a screen and a
/// sticker rather than two displays — which is what an owner asking for "both
/// visors like LED ones" was looking at.
///
/// So both go through here, and here draws glass rather than paint: a recess
/// that darkens toward the top, a scan of faint horizontal lines across it,
/// and lettering laid down twice — once blurred, for the bloom a lit segment
/// throws onto the glass in front of it, then again sharp on top. The bloom is
/// the whole trick; without it green text on a dark rectangle stays text on a
/// rectangle, however dark the rectangle is.
///
/// [fontSize] is what the caller would *like* — the size a short string is
/// set at. A long one is set smaller rather than cut short; see the floor
/// below.
void paintLedPanel(
  Canvas canvas, {
  required Rect bounds,
  required AlbumPalette palette,
  required String text,
  required double fontSize,
}) {
  final glass = RRect.fromRectAndRadius(
    bounds,
    Radius.circular(bounds.height * 0.14),
  );

  canvas.drawRRect(
    glass,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        // Darkest where the bezel shades it, lifting toward the bottom: a
        // recess is lit from above like everything else on the face, so the
        // shadow it casts on itself falls at the top.
        colors: [palette.wellDark, palette.panelDark],
      ).createShader(bounds),
  );

  // The scan.
  //
  // A real segment display is a grid of lit elements behind a filter, and
  // what says so at a glance is that the glass has structure in it. Spaced
  // off the panel's own height so the lines stay lines at any device size,
  // and floored at two logical pixels so a small device draws a few of them
  // rather than a solid wash.
  final spacing = (bounds.height * 0.11).clamp(2.0, bounds.height);
  final scan = Paint()
    ..strokeWidth = spacing * 0.28
    ..color = palette.wellDark.withValues(alpha: 0.55);
  canvas.save();
  canvas.clipRRect(glass);
  for (var y = bounds.top + spacing / 2; y < bounds.bottom; y += spacing) {
    canvas.drawLine(Offset(bounds.left, y), Offset(bounds.right, y), scan);
  }
  canvas.restore();

  canvas.drawRRect(
    glass,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bounds.height * 0.05
      ..color = palette.panelEdge,
  );

  if (text.trim().isEmpty) return;

  final inset = bounds.height * 0.22;
  final room = bounds.width - inset * 2;

  /// The same lettering, at whatever size, in whichever paint the pass wants.
  TextPainter lettering(Paint ink, double size, {double? maxWidth}) =>
      TextPainter(
        text: TextSpan(
          text: text.trim(),
          style: TextStyle(
            foreground: ink,
            fontSize: size,
            // The bundled face, for the reason [deviceFontFamily] records: a
            // window that let the host choose would cut a title at a
            // different word on each platform.
            fontFamily: deviceFontFamily,
            // Digits that do not shuffle as the seconds tick: the readout
            // rewrites itself every second, and proportional figures would
            // make the whole line twitch each time a 1 became a 2. Which is
            // also why there is no monospaced option here — tabular figures
            // are the part of a monospaced face a counter actually needs.
            fontFeatures: const [FontFeature.tabularFigures()],
            letterSpacing: size * 0.08,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth ?? double.infinity);

  // Shrunk to fit before it is cut, down to a floor.
  //
  // The window is sized for a device, and a track title is as long as it
  // happens to be: set rigidly at the size the window would like, most of
  // them arrive chopped — `Many Men (Wish D…` was the complaint that got
  // this window enlarged in the first place, and merely enlarging it moves
  // the chop rather than removing it. So a long title is set smaller, and
  // only a title too long even for the floor is cut. The floor is what keeps
  // the lettering readable at a glance from across a desk, which is the one
  // thing a nameplate has to be.
  //
  // Measured, then stepped down rather than divided once: the ratio of the
  // natural width to the room is the right first guess, but a line laid out
  // at exactly the width it is allowed still counts as overflowing, and the
  // last character would be dropped for a fraction of a pixel.
  const floor = 0.62;
  const step = 0.96;
  var size = fontSize;
  final natural = lettering(Paint(), size).width;
  if (natural > room) size = fontSize * (room / natural);
  while (size > fontSize * floor && lettering(Paint(), size).width > room) {
    size *= step;
  }
  size = size.clamp(fontSize * floor, fontSize);

  final bloom = lettering(
    Paint()
      ..color = palette.displayInk.withValues(alpha: 0.6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.22),
    size,
    maxWidth: room,
  );
  final lit = lettering(
    Paint()..color = palette.displayInk,
    size,
    maxWidth: room,
  );

  final at = Offset(bounds.left + inset, bounds.center.dy - lit.height / 2);
  bloom.paint(canvas, at);
  lit.paint(canvas, at);
}
