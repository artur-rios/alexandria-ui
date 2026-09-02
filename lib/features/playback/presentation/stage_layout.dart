import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/album_palette.dart';
import '../domain/album_medium.dart';
import 'media/case_painter.dart';
import 'media/cassette_painter.dart';
import 'media/console_painter.dart';
import 'media/device_layer.dart';
import 'media/device_transport.dart';
import 'media/disc_painter.dart';
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
    this.cover,
    this.isPlaying = false,
    this.display = '',
    this.trackTitle = '',
    this.onControl,
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

  /// The current album's own picture, decoded and ready to paint, or `null`
  /// to draw the designed jacket (design section 4). Handed straight to
  /// [CasePainter], which owns the drawing choice this makes.
  final ui.Image? cover;

  /// Whether audio is running, which is what the device's play button shows
  /// as a pause.
  final bool isPlaying;

  /// What the CD player's readout says — the track and where it has got to,
  /// already formatted. Empty on the devices that have no readout.
  final String display;

  /// What is playing, for the device's own nameplate.
  final String trackTitle;

  /// What a press on one of the device's own buttons does, or `null` for a
  /// stage nobody can operate.
  ///
  /// The buttons are painted either way: they are part of what a tape deck
  /// looks like. What this adds is that pressing one reaches the transport —
  /// the same [AudioPlaybackController] the row beneath the stage reaches,
  /// never a second copy of the queue's rules.
  final void Function(DeviceControl control)? onControl;

  /// The medium's scale while still nested in the case (Reference values):
  /// smaller for the cassette, whose case is wider than the record or disc
  /// sleeves either side of it.
  static double _insideCaseScale(AlbumMedium medium) =>
      medium == AlbumMedium.tape ? 0.48 : 0.60;

  @override
  Widget build(BuildContext context) {
    // One machine for all three media, so one aspect: the stage no longer
    // changes shape when a record from 1996 follows one from 1971.
    final deviceHeight = size / ConsolePainter.aspect;
    final deviceRect = Rect.fromLTWH(
      0,
      (size - deviceHeight) / 2,
      size,
      deviceHeight,
    );
    // The face the painter insets for itself, so a seat lands where the
    // console is actually drawn to hold it.
    final seat = consoleSeatFor(
      medium,
      deviceFaceOf(deviceRect.size).shift(deviceRect.topLeft),
    );

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
              // The cover rides on the medium as well as on the case: the
              // case is a beat of the insertion and then gone, where the
              // medium is what stays on screen for the rest of the album.
              painter: switch (medium) {
                AlbumMedium.vinyl => VinylPainter(
                  palette: palette,
                  turns: appliedTurns,
                  cover: cover,
                ),
                AlbumMedium.disc => DiscPainter(
                  palette: palette,
                  turns: appliedTurns,
                  cover: cover,
                ),
                AlbumMedium.tape => CassettePainter(
                  palette: palette,
                  turns: appliedTurns,
                  cover: cover,
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
                    cover: cover,
                  ),
                ),
              ),
            ),
          ),

        // Over everything, including the case: the case is a passing beat of
        // the insertion and the transport is not, and a jacket sliding
        // through would otherwise swallow presses on its way past. Last in
        // the stack, which is what actually makes that true — it was fourth
        // of five for as long as the three devices kept their controls in a
        // band the case never reached, and the console does not: its fascia
        // runs the width of the machine, so the jacket parks squarely over
        // two of the four caps on its way through.
        if (onControl case final onControl?)
          _TransportOverlay(
            device: deviceRect,
            isPlaying: isPlaying,
            onControl: onControl,
          ),
      ],
    );
  }

  /// The console painter for [layer].
  CustomPainter _devicePainter(DeviceLayer layer) => ConsolePainter(
    palette: palette,
    medium: medium,
    closed: closed,
    layer: layer,
    isPlaying: isPlaying,
    trackTitle: trackTitle,
    display: display,
  );
}

/// The hit targets over a device's painted buttons (UC-21, FR-PL-06).
///
/// Transparent on purpose: the buttons are already drawn, by the device
/// painter, from the very geometry this reads ([transportBoundsFor]). What
/// this adds is that they can be pressed — and that a screen reader finds
/// four named buttons where sighted owners see four caps, rather than a
/// picture of a tape deck with nothing operable in it.
class _TransportOverlay extends StatelessWidget {
  const _TransportOverlay({
    required this.device,
    required this.isPlaying,
    required this.onControl,
  });

  /// Where the console is drawn, in the stage's own coordinates.
  final Rect device;

  /// Whether audio is running, which is what the play button is called.
  final bool isPlaying;

  /// What a press does.
  final void Function(DeviceControl control) onControl;

  /// What each control is called, in the owner's language — the same words
  /// the bar's own transport uses, so the two never name the same action
  /// differently.
  String _label(DeviceControl control, AppLocalizations l10n) =>
      switch (control) {
        DeviceControl.previous => l10n.audioPrevious,
        DeviceControl.playPause => isPlaying ? l10n.audioPause : l10n.audioPlay,
        DeviceControl.stop => l10n.audioStop,
        DeviceControl.next => l10n.audioNext,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The device painter draws into its own rect, so the bounds come back in
    // the device's coordinates and are shifted into the stage's.
    final bounds = transportBoundsFor(
      deviceFaceOf(device.size),
    ).map((control, rect) => MapEntry(control, rect.shift(device.topLeft)));

    return Semantics(
      container: true,
      label: l10n.audioTransportSemantics,
      child: Stack(
        children: [
          for (final entry in bounds.entries)
            Positioned.fromRect(
              // Widened a little beyond the painted cap: the caps are small
              // at a stage's smallest size, and a hit target the exact size
              // of the glyph under it is one an owner has to aim at.
              rect: entry.value.inflate(entry.value.width * 0.2),
              child: Semantics(
                button: true,
                label: _label(entry.key, l10n),
                // A bare gesture detector, with no ink of its own.
                //
                // An `InkResponse` here drew a grey circle over the cap
                // under the pointer, which on a painted device reads as a
                // smudge on the picture rather than as a control lighting
                // up: the highlight is Material's, the cap is not, and the
                // two do not belong to each other. The device says what it
                // is doing by what it *is* — the play cap becomes a pause
                // cap, the medium stops turning — which is feedback the
                // drawing owns rather than feedback laid over it.
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onControl(entry.key),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
        ],
      ),
    );
  }
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
