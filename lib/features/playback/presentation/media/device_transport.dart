import 'package:flutter/material.dart';

import '../../../../core/theme/album_palette.dart';
import '../../domain/album_medium.dart';

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

/// Where each control sits on a device drawn into [face], in the same
/// coordinates the painter draws in.
///
/// The band is the same idea on every device — a row of caps clear of the
/// display, the well and the medium — because the four controls mean the
/// same four things whichever record is playing, and an owner who found
/// them on the deck should not have to hunt for them on the CD player.
///
/// Where they *sit* is not the same, and cannot be. The deck and the CD
/// player both keep their upper right free, so the row goes there. The
/// turntable's platter is centred at 0.40 of the width with a radius of
/// 0.40 of the height, which reaches 0.667 of the width at its widest — a
/// row in that band would be laid half under the record. Its buttons go
/// along the front edge of the plinth instead, below the platter's own
/// curve and above the feet, which is where a modern deck puts its cue
/// controls anyway. They are smaller there, because that strip is what the
/// plinth has left.
///
/// The turntable is the one that had no transport at all: a real one has
/// none, which is why these had to be invented rather than merely wired up.
///
/// The CD player is the one that is no longer a row. Its buttons sat in the
/// top right, which is where the nameplate had to go once a track title
/// needed a window wide enough to hold one — the band across the top is the
/// only part of that face nothing is ever drawn over. So the four caps moved
/// down the right-hand side into a square of two by two, in the strip
/// between the well's edge and the face's, reading left to right and top to
/// bottom in the order they always had.
Map<DeviceControl, Rect> transportBoundsFor(AlbumMedium medium, Rect face) =>
    switch (medium) {
      AlbumMedium.disc => _discGrid(face),
      AlbumMedium.tape => _row(face, centre: 0.20, size: 0.10, first: 0.60),
      AlbumMedium.vinyl => _row(
        face,
        centre: 0.93,
        size: 0.085,
        first: 0.769,
        step: 0.065,
      ),
    };

/// A row of four caps across [face], at [centre] of its height.
///
/// [size], [first] and [step] are all fractions of the face — its height for
/// the cap, its width for where the caps sit — so a device drawn at any size
/// keeps the same arrangement.
Map<DeviceControl, Rect> _row(
  Rect face, {
  required double centre,
  required double size,
  required double first,
  double step = 0.10,
}) {
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

/// The CD player's four caps, in two rows of two down the face's right side.
///
/// The column positions are what keep them off the disc: the well is centred
/// on the face with a radius of 0.296 of the height, which on this face's
/// 1.7 aspect reaches 0.674 of the width — and the lid drawn over it is
/// exactly as wide. Both columns begin past that, and the outer one stops
/// short of the face's own edge.
Map<DeviceControl, Rect> _discGrid(Rect face) {
  const size = 0.13;
  const columns = [0.765, 0.90];
  const rows = [0.50, 0.72];
  final diameter = face.height * size;

  return {
    for (final (index, control) in DeviceControl.values.indexed)
      control: Rect.fromCenter(
        center: Offset(
          face.left + face.width * columns[index % 2],
          face.top + face.height * rows[index ~/ 2],
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
