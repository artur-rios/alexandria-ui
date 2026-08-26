import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/album_palette.dart';
import '../domain/album_medium.dart';
import 'media/case_painter.dart';
import 'media/cassette_painter.dart';
import 'media/cd_player_painter.dart';
import 'media/device_layer.dart';
import 'media/disc_painter.dart';
import 'media/tape_deck_painter.dart';
import 'media/turntable_painter.dart';
import 'media/vinyl_painter.dart';

/// The four painted layers, placed for one frame of the insertion or the
/// spin: the device's chassis, the medium, the device's foreground, and the
/// case — in that order, so a device's tonearm, door or lid lands in front
/// of the medium it closes over rather than buried beneath it (Finding 2).
/// A plain function of its inputs — nothing here owns an
/// [AnimationController] — so it can be rebuilt on every tick without
/// carrying animation state of its own.
///
/// Lifted out of `album_stage.dart` into its own file (Finding 10): that
/// file was doing three jobs at once — the animation timelines
/// (`AlbumStage`), this pure layout, and [Seat]'s small geometry record —
/// and only the first of those owns any animation state at all.
class StageLayout extends StatelessWidget {
  /// Creates the layout.
  const StageLayout({
    required this.medium,
    required this.palette,
    required this.sleeve,
    required this.title,
    required this.artist,
    required this.direction,
    required this.size,
    required this.closed,
    required this.turns,
    required this.caseOpacity,
    required this.caseSettle,
    required this.caseDeparture,
    required this.mediumEmergence,
    required this.travel,
    super.key,
  });

  /// Which medium and matching device are drawn.
  final AlbumMedium medium;

  /// The artwork's colours (FR-UX-07).
  final AlbumPalette palette;

  /// The case jacket's face colour.
  final Color sleeve;

  /// The album title, typeset on the case while it is shown.
  final String title;

  /// The artist, typeset beneath the title.
  final String artist;

  /// The text direction the case's title and artist are laid out in.
  final TextDirection direction;

  /// How wide and tall the layout is drawn, as a square.
  final double size;

  /// 0 with the device open and waiting; 1 with it shut on the medium.
  final double closed;

  /// How far through a turn the medium is, in whole turns.
  final double turns;

  /// The case's opacity, 0 to 1.
  final double caseOpacity;

  /// How far through arriving the case is, 0 to 1.
  final double caseSettle;

  /// How far through leaving the case is, 0 to 1.
  final double caseDeparture;

  /// How far out of the case the medium has emerged, 0 to 1.
  final double mediumEmergence;

  /// How far the medium has travelled from the case to its seat, 0 to 1.
  final double travel;

  /// The medium's scale while still nested in the case (Reference values):
  /// smaller for the cassette, whose case is wider than the record or disc
  /// sleeves either side of it.
  static double _insideCaseScale(AlbumMedium medium) =>
      medium == AlbumMedium.tape ? 0.48 : 0.60;

  @override
  Widget build(BuildContext context) {
    final deviceAspect = switch (medium) {
      AlbumMedium.vinyl => TurntablePainter.aspect,
      AlbumMedium.tape => TapeDeckPainter.aspect,
      AlbumMedium.disc => CdPlayerPainter.aspect,
    };
    final deviceHeight = size / deviceAspect;
    final deviceRect = Rect.fromLTWH(
      0,
      (size - deviceHeight) / 2,
      size,
      deviceHeight,
    );
    final seat = _seatFor(medium, deviceRect);

    final caseAspect = CasePainter.aspectFor(medium);
    final caseWidth = size * 0.5;
    final caseHeight = caseWidth / caseAspect;
    // Finding 8, beat 1: the case floats in from the left, its sleeve facing
    // the owner — not centred and faded up in place, which read as a sleeve
    // pasted flat over the device rather than something arriving from
    // anywhere. `caseSettle` (the `caseIn` interval) now drives *where* the
    // case is, not only how visible it is: it starts off-canvas, past the
    // stage's own left edge, and slides in to where it parks.
    //
    // The parked X is left of centre rather than centred on the device: a
    // centred jacket at this width sits squarely over a device's well and
    // display, which is exactly the "sleeve pasted on top" Finding 8 named —
    // every device's own controls (`_paintControls`/`_paintButtons`, drawn
    // from roughly 0.66 to 0.90 of the width in each device painter) sit well
    // clear of a case parked here.
    final caseParkX = size * 0.30;
    final caseArriveX = ui.lerpDouble(-caseWidth * 0.7, caseParkX, caseSettle)!;
    // The case settles into place as it arrives, then drifts up and away as
    // it fades — the same beats that drive its opacity, read as a slide
    // rather than a plain cross-fade.
    final caseSlideY =
        size * 0.12 * (1 - caseSettle) - size * 0.08 * caseDeparture;
    final caseCentre = Offset(caseArriveX, size * 0.66 + caseSlideY);

    final mediumScale = ui.lerpDouble(
      _insideCaseScale(medium),
      1,
      mediumEmergence,
    )!;
    final mediumCentre = Offset.lerp(caseCentre, seat.centre, travel)!;
    final mediumWidth = seat.width * mediumScale;
    final mediumHeight = seat.height * mediumScale;

    // Zero rather than `turns` until travel is under way: the medium is
    // still sitting beside the case for the whole of the emergence and hold
    // beats, and a record that visibly spins before anything has carried it
    // toward the platter reads as turning in mid-air.
    final appliedTurns = travel > 0 ? turns : 0.0;

    Widget devicePainted(DeviceLayer layer) => Positioned.fromRect(
      rect: deviceRect,
      child: RepaintBoundary(
        child: CustomPaint(painter: _devicePainter(layer)),
      ),
    );

    return Stack(
      children: [
        // The chassis — everything a device shows before the medium is on
        // it — sits behind the medium (Finding 2): the well the record or
        // disc rests in, or the slot the cassette slides into, has to be
        // under it, not painted over it.
        devicePainted(DeviceLayer.chassis),
        Positioned(
          left: mediumCentre.dx - mediumWidth / 2,
          top: mediumCentre.dy - mediumHeight / 2,
          width: mediumWidth,
          height: mediumHeight,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: switch (medium) {
                AlbumMedium.vinyl => VinylPainter(
                  palette: palette,
                  turns: appliedTurns,
                ),
                AlbumMedium.disc => DiscPainter(
                  palette: palette,
                  turns: appliedTurns,
                ),
                AlbumMedium.tape => CassettePainter(
                  palette: palette,
                  turns: appliedTurns,
                ),
              },
            ),
          ),
        ),
        // The foreground — the tonearm, the deck's door, the player's lid —
        // is the part of the device whose entire job is to be seen touching
        // or covering the medium, so it has to be painted after it.
        devicePainted(DeviceLayer.foreground),
        if (caseOpacity > 0)
          Positioned(
            left: caseCentre.dx - caseWidth / 2,
            top: caseCentre.dy - caseHeight / 2,
            width: caseWidth,
            height: caseHeight,
            child: Opacity(
              opacity: caseOpacity,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: CasePainter(
                    palette: palette,
                    medium: medium,
                    sleeve: sleeve,
                    title: title,
                    artist: artist,
                    direction: direction,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// The device painter for [layer], by medium.
  CustomPainter _devicePainter(DeviceLayer layer) => switch (medium) {
    AlbumMedium.vinyl => TurntablePainter(
      palette: palette,
      closed: closed,
      layer: layer,
    ),
    AlbumMedium.tape => TapeDeckPainter(
      palette: palette,
      closed: closed,
      layer: layer,
    ),
    AlbumMedium.disc => CdPlayerPainter(
      palette: palette,
      closed: closed,
      layer: layer,
    ),
  };

  /// Where, and how large, the medium sits once fully seated on [device] —
  /// derived from the same geometry each device painter positions its own
  /// platter, well or hub at, so the medium lands where the device is
  /// actually drawn to hold it.
  Seat _seatFor(AlbumMedium medium, Rect device) => switch (medium) {
    AlbumMedium.vinyl => Seat(
      centre: Offset(
        device.left + device.width * 0.40,
        device.top + device.height * 0.52,
      ),
      width: device.height * 0.80,
      height: device.height * 0.80,
    ),
    AlbumMedium.disc => Seat(
      centre: Offset(
        device.left + device.width * 0.50,
        device.top + device.height * 0.66,
      ),
      width: device.height * 0.52,
      height: device.height * 0.52,
    ),
    AlbumMedium.tape => Seat(
      centre: Offset(
        device.left + device.width * 0.335,
        device.top + device.height * 0.71,
      ),
      width: device.height * 0.42 * CassettePainter.aspect,
      height: device.height * 0.42,
    ),
  };
}

/// A layer's centre point and footprint, in the stage's own coordinates.
class Seat {
  /// Creates a seat.
  const Seat({required this.centre, required this.width, required this.height});

  /// The seat's centre point.
  final Offset centre;

  /// The seat's width.
  final double width;

  /// The seat's height.
  final double height;
}
