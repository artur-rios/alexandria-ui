import 'package:flutter/material.dart';

/// The soft diagonal band of light clear plastic throws — the way glass or
/// polycarbonate catches an angle of light unevenly rather than as a flat
/// tint (UC-21, FR-PL-07).
///
/// Shared by [CassettePainter]'s own window and `AlbumVisor`'s recess
/// (Finding 10): the visor's own painter was a copy of this device rather
/// than a call to it, which is exactly the kind of duplication a later
/// tweak to one could silently leave the other behind.
///
/// Returns a [Paint] rather than drawing directly, because the two callers
/// fill different shapes with it — a rounded rectangle for the cassette's
/// window, a plain one for the visor's recess — and the shape to draw is
/// theirs to choose, not this function's.
///
/// [alpha] is the gradient's peak opacity and [stops] are where it rises and
/// falls back to nothing — left as parameters, not fixed, because the two
/// callers use this at different sizes and want a different peak: a wider
/// pane can carry a stronger sheen than a small recessed one without either
/// looking like a stain.
Paint diagonalSheenPaint(
  Rect rect,
  Color color, {
  required double alpha,
  required List<double> stops,
}) => Paint()
  ..shader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      color.withValues(alpha: 0),
      color.withValues(alpha: alpha),
      color.withValues(alpha: 0),
    ],
    stops: stops,
  ).createShader(rect);
