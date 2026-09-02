import 'package:flutter/material.dart';

import '../../../../core/theme/album_palette.dart';

/// The transport a device's own buttons work (UC-21 main flow, FR-PL-06).
///
/// The buttons were painted long before they did anything: every device
/// carried a row of caps with a play triangle and a stop square on them, and
/// pressing one did nothing at all, because the geometry that drew them
/// lived inside each painter's private method and nothing above the canvas
/// knew where they were. This enum and [transportBoundsFor] are that
/// geometry lifted out — one description of where a device's controls are,
/// read by the painter that draws them and by the stage that lays hit
/// targets over them, so a button can never be drawn in a place the owner's
/// press does not reach.
enum DeviceControl {
  /// The previous track in the queue.
  previous,

  /// Running or paused — the one button whose glyph depends on the state.
  playPause,

  /// Stop, which empties the queue as the bar's own stop does.
  stop,

  /// The next track in the queue.
  next,
}

/// The body every device painter draws inside [size].
///
/// One margin, read by all three painters and by the stage that lays hit
/// targets over them: the face was inset by `height * 0.03` in three
/// separate methods, and a transport whose buttons were positioned against a
/// fourth copy of that number would drift away from the caps drawn on it the
/// first time one of them changed.
Rect deviceFaceOf(Size size) {
  final margin = size.height * 0.03;

  return Rect.fromLTWH(
    margin,
    margin,
    size.width - margin * 2,
    size.height - margin * 2,
  );
}

/// Where each control sits on the console drawn into [face], in the same
/// coordinates the painter draws in.
///
/// One row of four, in the order they are read in: back, play or pause,
/// stop, forward. It was briefly a square of two by two on the CD player's
/// face, to free the band across its top for a wider name window — and a
/// square is exactly where the order of four controls stops being obvious,
/// because nothing says whether it is read across or down. There is one
/// machine now and its fascia is wide enough for a row, so a row is what it
/// has: the same order as the playback bar's, left to right, which is the
/// order every transport in the world is in.
///
/// Read by the painter that draws the caps and by the stage that lays hit
/// targets over them, so a button can never be drawn in a place the owner's
/// press does not reach.
Map<DeviceControl, Rect> transportBoundsFor(Rect face) {
  // The row's height, the cap's size, the first cap's centre and the gap to
  // the next — all fractions of the face, so a console drawn at any size
  // keeps the same arrangement.
  const centre = 0.735;
  const size = 0.075;
  const first = 0.385;
  const step = 0.092;

  final diameter = face.height * size;
  final centreY = face.top + face.height * centre;

  return {
    for (final (index, control) in DeviceControl.values.indexed)
      control: Rect.fromCenter(
        center: Offset(
          face.left + face.width * (first + step * index),
          centreY,
        ),
        width: diameter,
        height: diameter,
      ),
  };
}

/// Draws the transport onto [canvas] — the caps, and the glyph on each.
///
/// Shared by all three device painters rather than copied into each: the
/// tape deck and the CD player had two hand-written copies of the same
/// triangles and squares, drawn at slightly different sizes, and the
/// turntable had none. [isPlaying] is what turns the play triangle into a
/// pause bar, which is the only part of a device that has ever had to know
/// what the engine is doing.
///
/// [corner] is the cap's corner radius, as a fraction of its own size: the
/// deck's caps are squarer than the CD player's round ones, and that
/// difference is the devices' own character rather than an accident.
void paintTransport(
  Canvas canvas, {
  required Map<DeviceControl, Rect> bounds,
  required AlbumPalette palette,
  required bool isPlaying,
  required double corner,
}) {
  final cap = Paint()..color = palette.panelDark;
  final capEdge = Paint()
    ..style = PaintingStyle.stroke
    ..color = palette.panelEdge;
  final glyph = Paint()..color = palette.chromeLight;

  for (final entry in bounds.entries) {
    final rect = entry.value;
    final size = rect.width;
    final centre = rect.center;
    capEdge.strokeWidth = size * 0.05;

    final shape = RRect.fromRectAndRadius(rect, Radius.circular(size * corner));
    canvas.drawRRect(shape, cap);
    canvas.drawRRect(shape, capEdge);

    switch (entry.key) {
      case DeviceControl.previous:
        _arrows(canvas, centre, size, glyph, pointsRight: false);
      case DeviceControl.playPause:
        if (isPlaying) {
          // Two bars: the same pause the bar's own button shows, so the
          // device and the bar never disagree about what pressing does.
          for (final dx in [-size * 0.12, size * 0.04]) {
            canvas.drawRect(
              Rect.fromLTWH(
                centre.dx + dx,
                centre.dy - size * 0.18,
                size * 0.08,
                size * 0.36,
              ),
              glyph,
            );
          }
        } else {
          canvas.drawPath(
            Path()
              ..moveTo(centre.dx - size * 0.14, centre.dy - size * 0.18)
              ..lineTo(centre.dx - size * 0.14, centre.dy + size * 0.18)
              ..lineTo(centre.dx + size * 0.18, centre.dy)
              ..close(),
            glyph,
          );
        }
      case DeviceControl.stop:
        canvas.drawRect(
          Rect.fromCenter(
            center: centre,
            width: size * 0.32,
            height: size * 0.32,
          ),
          glyph,
        );
      case DeviceControl.next:
        _arrows(canvas, centre, size, glyph, pointsRight: true);
    }
  }
}

/// The doubled triangle a skip button carries, pointing whichever way the
/// skip goes.
void _arrows(
  Canvas canvas,
  Offset centre,
  double size,
  Paint glyph, {
  required bool pointsRight,
}) {
  final direction = pointsRight ? 1.0 : -1.0;

  for (final offset in [-size * 0.16, size * 0.02]) {
    final from = centre.dx + offset * direction;
    canvas.drawPath(
      Path()
        ..moveTo(from, centre.dy - size * 0.16)
        ..lineTo(from, centre.dy + size * 0.16)
        ..lineTo(from + size * 0.16 * direction, centre.dy)
        ..close(),
      glyph,
    );
  }
}
