import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/album_palette.dart';
import 'album_art.dart';
import 'device_artwork.dart';
import 'display_text.dart';

/// A photographed machine, with the parts of it that move (UC-21, FR-PL-07).
///
/// Three things happen over the picture and nothing else does. The medium in
/// it turns, by rotating the pixels inside the circle it occupies. The screen
/// says what is actually playing, by covering the two lines the photograph was
/// taken with and lighting the real ones in their place. And the album's own
/// art goes on the record's label, which is both what a record carries there
/// and the only thing that makes a photographed record look like it is
/// turning at all.
///
/// Everything else — the wood, the brushed steel, the speaker cloth, the
/// tonearm lying across the record, the level meter — is the photograph, left
/// alone.
class DevicePhotograph extends CustomPainter {
  /// Creates the painter.
  const DevicePhotograph({
    required this.image,
    required this.artwork,
    required this.palette,
    required this.turns,
    required this.isPlaying,
    required this.status,
    required this.trackTitle,
    this.cover,
  });

  /// The decoded picture.
  final ui.Image image;

  /// Where everything on it is.
  final DeviceArtwork artwork;

  /// The colours the screen is lit in (BR-18, FR-UX-07).
  final AlbumPalette palette;

  /// How far through a turn the medium is, in whole turns.
  final double turns;

  /// Whether audio is running, which is what the screen's first word says.
  final bool isPlaying;

  /// The right of the top line: which track, and where it has got to.
  final String status;

  /// The second line: what is playing.
  final String trackTitle;

  /// The album's own picture, for the label that carries one.
  final ui.Image? cover;

  @override
  void paint(Canvas canvas, Size size) {
    final device = Offset.zero & size;

    paintImage(
      canvas: canvas,
      rect: device,
      image: image,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.low,
    );

    for (final spin in artwork.spins) {
      _paintSpin(canvas, device, spin);
    }

    _paintScreen(canvas, device);
  }

  /// Turns one circle of the photograph in place.
  ///
  /// The transform is the whole of it: into the ellipse's own space, out of
  /// the flattening the camera applied, around, back into it, and home. A
  /// rotation applied to a flattened circle without that middle step would
  /// tumble the ellipse rather than spin what is inside it.
  void _paintSpin(Canvas canvas, Rect device, DeviceSpin spin) {
    final bounds = DeviceArtwork.ellipseOf(spin, device);
    final centre = bounds.center;
    final angle = turns * 2 * math.pi;

    canvas
      ..save()
      ..clipPath(Path()..addOval(bounds));

    if (spin.carriesCover) {
      // The album's art, turning on the label — and nothing else on this
      // spinner turns at all (see [DeviceSpin.carriesCover]). Rotated first
      // and flattened after, which is a circle of art seen at the angle the
      // record was photographed from.
      if (cover case final art?) {
        canvas
          ..translate(centre.dx, centre.dy)
          ..scale(1, spin.flattening)
          ..rotate(angle)
          ..translate(-centre.dx, -centre.dy);
        paintAlbumArtInCircle(
          canvas,
          cover: art,
          centre: centre,
          // Inside the label's own edge, so the ring of paper the photograph
          // already has stays visible around the art.
          radius: bounds.width / 2 * 0.94,
        );
      }
    } else {
      // The photograph's own pixels, turned in place: out of the flattening
      // the camera applied, around, and back into it. A rotation applied to
      // a flattened circle without that middle step would tumble the ellipse
      // rather than spin what is inside it.
      canvas
        ..translate(centre.dx, centre.dy)
        ..scale(1, 1 / spin.flattening)
        ..rotate(angle)
        ..scale(1, spin.flattening)
        ..translate(-centre.dx, -centre.dy);
      paintImage(
        canvas: canvas,
        rect: device,
        image: image,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.low,
      );
    }

    canvas.restore();

    // The spindle, back where it was: a record turns around it, and a pin is
    // the one thing on a turntable a rotation smears into a streak.
    if (spin.hub case final hub?) {
      canvas
        ..save()
        ..clipRect(DeviceArtwork.resolve(hub, device));
      paintImage(
        canvas: canvas,
        rect: device,
        image: image,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.low,
      );
      canvas.restore();
    }
  }

  /// Lights the screen with what is playing.
  ///
  /// Two lines and no more. The photograph's own meter, its `L`/`R` legend
  /// and the bezel around them are left exactly as they were — this covers
  /// the two rows of type the machine was photographed showing and lights the
  /// real ones in the same amber, which is what makes the screen belong to
  /// this application's queue rather than to a picture of somebody else's.
  void _paintScreen(Canvas canvas, Rect device) {
    final status = DeviceArtwork.resolve(artwork.statusRow, device);
    final title = DeviceArtwork.resolve(artwork.titleRow, device);

    final ground = Paint()..color = palette.displayGround;
    canvas
      ..drawRect(status.inflate(status.height * 0.10), ground)
      ..drawRect(title.inflate(title.height * 0.10), ground);

    // A machine says what it is doing before it says what it is doing it to,
    // and the two halves of that line are given half the row each: the
    // cassette deck's screen is the narrowest of the three, and a word that
    // grew into the track number would read as one string of nonsense.
    paintFittedText(
      canvas,
      bounds: Rect.fromLTRB(
        status.left,
        status.top,
        status.left + status.width * 0.46,
        status.bottom,
      ),
      text: isPlaying ? 'PLAYING' : 'PAUSED',
      colour: palette.displayInk,
    );
    paintFittedText(
      canvas,
      bounds: Rect.fromLTRB(
        status.left + status.width * 0.50,
        status.top,
        status.right,
        status.bottom,
      ),
      text: this.status,
      colour: palette.displayInk,
      alignEnd: true,
    );
    paintFittedText(
      canvas,
      bounds: title,
      text: trackTitle,
      colour: palette.displayInk,
    );
  }

  @override
  bool shouldRepaint(DevicePhotograph old) =>
      old.turns != turns ||
      old.isPlaying != isPlaying ||
      old.status != status ||
      old.trackTitle != trackTitle ||
      !identical(old.image, image) ||
      !identical(old.cover, cover) ||
      old.artwork != artwork ||
      old.palette != palette;
}
