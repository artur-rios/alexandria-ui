import 'package:flutter/material.dart';

import '../../../../core/theme/album_palette.dart';
import '../../domain/album_medium.dart';
import 'led_panel.dart';

/// Where a device says what is playing (UC-21, FR-PL-07, FR-PL-12).
///
/// The full player used to name the track only in the page's own text,
/// beneath the stage — so the device, which is the thing the owner is
/// looking at, was the one part of the screen that did not know what was on
/// it. This is the window that fixes that: a lit display on the face, placed
/// per device in the one part of it that is not already the readout, the
/// well or the medium.
///
/// Wider and taller than it first was, on every device. A track title is the
/// longest thing any of these machines has to show and it had the smallest
/// window on the face to show it in, so most titles arrived cut after three
/// words — `Many Men (Wish De…` on a plate barely taller than its own
/// lettering. Every device has room the medium never reaches; this takes it.
///
/// Empty on a stage with nothing playing, which is a device with nothing to
/// say rather than a device with a blank window lit on it.
Rect nameplateFor(AlbumMedium medium, Rect face) {
  final (left, top, width, height) = switch (medium) {
    // The right half of the display band, beside the readout.
    //
    // The band across the top is the only place on this face that is wide
    // enough for a title, and the player earns it twice over: the two
    // windows read as one instrument panel, which is what makes the machine
    // a radio rather than a lid with labels around it. Nothing is ever
    // drawn over it — the lid closes from 0.355 of the face downward, and
    // the transport moved off this band to the face's right side to make
    // the room.
    AlbumMedium.disc => (0.43, 0.07, 0.52, 0.22),
    // The deck's right half, below the buttons and beside the well, which
    // occupies the left of the face up to 0.61 and starts at 0.50 down.
    AlbumMedium.tape => (0.63, 0.46, 0.34, 0.16),
    // The plinth's right side, below the speed caps and above the
    // transport. Not along the front, where there is more room: the platter
    // is centred at 0.40 of the width with a radius of 0.40 of the height,
    // and the record laid over it would cover the end of a window there —
    // the medium is painted above the chassis, so anything the platter
    // reaches is something the owner cannot read.
    AlbumMedium.vinyl => (0.69, 0.58, 0.28, 0.15),
  };

  return Rect.fromLTWH(
    face.left + face.width * left,
    face.top + face.height * top,
    face.width * width,
    face.height * height,
  );
}

/// Draws [title] into the window at [bounds].
///
/// The lettering is sized to the window rather than to the title, and capped
/// so a tall window on a large device does not set a track title in display
/// type — a nameplate is a label on a machine, not a headline.
void paintNameplate(
  Canvas canvas, {
  required Rect bounds,
  required AlbumPalette palette,
  required String title,
}) {
  if (title.trim().isEmpty) return;

  paintLedPanel(
    canvas,
    bounds: bounds,
    palette: palette,
    text: title,
    fontSize: bounds.height * 0.34,
  );
}
