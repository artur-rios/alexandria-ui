import 'package:flutter/material.dart';

import '../../../../core/theme/album_palette.dart';
import '../../domain/album_medium.dart';

/// Where a device says what is playing (UC-21, FR-PL-07).
///
/// The full player used to name the track only in the page's own text,
/// beneath the stage — so the device, which is the thing the owner is
/// looking at, was the one part of the screen that did not know what was on
/// it. This is the strip that fixes that: a printed plate on the face,
/// placed per device in the one part of it that is not already the display,
/// the well or the medium.
///
/// Empty on a stage with nothing playing, which is a device with nothing to
/// say rather than a device with a blank label painted on it.
Rect nameplateFor(AlbumMedium medium, Rect face) {
  final (left, top, width, height) = switch (medium) {
    // Under the display recess, above the disc well: the band the display
    // and the transport leave free.
    AlbumMedium.disc => (0.06, 0.32, 0.46, 0.09),
    // The deck's right half, below the buttons and beside the well, which
    // occupies the left of the face up to 0.61.
    AlbumMedium.tape => (0.66, 0.56, 0.30, 0.10),
    // The plinth's right side, below the tonearm's pivot and above the
    // transport. Not along the front, where there is more room: the platter
    // is centred at 0.40 of the width with a radius of 0.40 of the height,
    // and the record laid over it would cover the end of a plate there —
    // the medium is painted above the chassis, so anything the platter
    // reaches is something the owner cannot read.
    AlbumMedium.vinyl => (0.70, 0.66, 0.28, 0.085),
  };

  return Rect.fromLTWH(
    face.left + face.width * left,
    face.top + face.height * top,
    face.width * width,
    face.height * height,
  );
}

/// Draws [title] onto the plate at [bounds].
///
/// Truncated with an ellipsis rather than scaled down: a plate that shrank
/// its lettering to fit would set every track in a different size, and a
/// long title would arrive unreadable instead of arriving cut.
void paintNameplate(
  Canvas canvas, {
  required Rect bounds,
  required AlbumPalette palette,
  required String title,
}) {
  if (title.trim().isEmpty) return;

  final plate = RRect.fromRectAndRadius(
    bounds,
    Radius.circular(bounds.height * 0.22),
  );
  canvas.drawRRect(plate, Paint()..color = palette.panelDark);
  canvas.drawRRect(
    plate,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bounds.height * 0.06
      ..color = palette.panelEdge,
  );

  final text = TextPainter(
    text: TextSpan(
      text: title.trim(),
      style: TextStyle(
        color: palette.displayInk,
        fontSize: bounds.height * 0.52,
        letterSpacing: 0.2,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: bounds.width - bounds.height * 0.5);

  text.paint(
    canvas,
    Offset(
      bounds.left + bounds.height * 0.25,
      bounds.center.dy - text.height / 2,
    ),
  );
}
