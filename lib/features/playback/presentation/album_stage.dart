import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/album_palette.dart';
import '../domain/album_medium.dart';
import '../domain/sleeve_design.dart';
import 'media/case_painter.dart';
import 'media/cassette_painter.dart';
import 'media/cd_player_painter.dart';
import 'media/device_layer.dart';
import 'media/disc_painter.dart';
import 'media/tape_deck_painter.dart';
import 'media/turntable_painter.dart';
import 'media/vinyl_painter.dart';

/// The two timelines over the painters from Tasks 3 and 4 (UC-21 main flow,
/// FR-PL-07, BR-21): a one-shot insertion, then a continuous spin.
///
/// [insert] true plays the insertion once on mount — the case appearing, the
/// medium emerging from it, travelling to the device and the device closing
/// over it — and then hands off to the spin. [insert] false skips straight to
/// the seated, spinning state, because a track change within an album already
/// on the platter does not take the record off and put it back on.
///
/// Replaces [AlbumAnimation]'s single `RotationTransition` over a flat
/// painting: that widget had no device to seat the medium in and no
/// insertion to seat it with, because Tasks 3 and 4 had not built either yet.
class AlbumStage extends StatefulWidget {
  /// Creates the stage.
  const AlbumStage({
    required this.medium,
    required this.isPlaying,
    required this.insert,
    required this.title,
    required this.artist,
    required this.album,
    this.size = 420,
    this.onInserted,
    super.key,
  });

  /// Which medium and matching device are drawn.
  final AlbumMedium medium;

  /// Whether audio is running. The spin holds exactly where it was when this
  /// turns false, and continues from there when it turns true again (main
  /// flow steps 4 and 5).
  final bool isPlaying;

  /// Whether the medium still owes its insertion. `false` starts already
  /// seated and spinning.
  final bool insert;

  /// The album title, typeset on the case while it is shown.
  final String title;

  /// The artist, typeset beneath the title.
  final String artist;

  /// The album name the case's jacket colour is derived from
  /// (`sleeveIndexFor`), or `null` for an untitled album.
  final String? album;

  /// How wide and tall the stage is drawn, as a square.
  final double size;

  /// Called once, when the insertion finishes — how the screen knows not to
  /// play another insertion for the next track of the same record.
  final VoidCallback? onInserted;

  /// How long the insertion takes, start to finish (Reference values).
  static const Duration insertionDuration = Duration(milliseconds: 4400);

  @override
  State<AlbumStage> createState() => _AlbumStageState();
}

/// The insertion's beat boundaries (Reference values), each expressed as an
/// [Interval] on the insertion controller: 0 before the beat starts, 1 once
/// it ends, and eased between.
class _Beats {
  const _Beats._();

  static const Interval caseIn = Interval(0, 0.16, curve: Curves.easeOut);
  static const Interval mediumOut = Interval(
    0.21,
    0.42,
    curve: Curves.easeInOut,
  );
  static const Interval hold = Interval(0.42, 0.54);
  static const Interval travel = Interval(0.54, 0.82, curve: Curves.easeInOut);
  static const Interval deviceCloses = Interval(
    0.82,
    0.94,
    curve: Curves.easeInOut,
  );
}

class _AlbumStageState extends State<AlbumStage> with TickerProviderStateMixin {
  late final AnimationController _insertion = AnimationController(
    vsync: this,
    duration: AlbumStage.insertionDuration,
  )..addStatusListener(_onInsertionStatus);

  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: _spinPeriod(widget.medium),
  );

  late final Animation<double> _caseIn = CurvedAnimation(
    parent: _insertion,
    curve: _Beats.caseIn,
  );
  late final Animation<double> _mediumOut = CurvedAnimation(
    parent: _insertion,
    curve: _Beats.mediumOut,
  );
  late final Animation<double> _hold = CurvedAnimation(
    parent: _insertion,
    curve: _Beats.hold,
  );
  late final Animation<double> _travel = CurvedAnimation(
    parent: _insertion,
    curve: _Beats.travel,
  );
  late final Animation<double> _deviceCloses = CurvedAnimation(
    parent: _insertion,
    curve: _Beats.deviceCloses,
  );

  /// AF-04: whether the system asked for less motion.
  ///
  /// Read here rather than in `build`, exactly as `AlbumAnimation` (which
  /// this replaces) already did: it decides whether either ticker runs at
  /// all, and a controller left running under a still medium would burn a
  /// frame's work every frame for something nobody can see.
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _applyInsertion();
    _applySpin();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion == _reduceMotion) return;

    _reduceMotion = reduceMotion;
    _applyInsertion();
    _applySpin();
  }

  @override
  void didUpdateWidget(AlbumStage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // `repeat()` captures its period into a running simulation, so a bare
    // duration assignment would leave a still-playing spin at the old rate
    // until something next paused and resumed it. Re-applying restarts the
    // repeat at the new period — `repeat()` continues from the current
    // value rather than resetting it, so this does not jump the medium.
    var spinNeedsReapplying = oldWidget.isPlaying != widget.isPlaying;
    if (oldWidget.medium != widget.medium) {
      _spin.duration = _spinPeriod(widget.medium);
      spinNeedsReapplying = true;
    }
    if (spinNeedsReapplying) _applySpin();

    // An insertion that becomes owed after mount — Task 6's case, a
    // different record loaded into a stage that stayed on screen — plays
    // the same way the first one did.
    if (widget.insert && !oldWidget.insert && !_reduceMotion) {
      _insertion.value = 0;
      unawaited(_insertion.forward());
    }
  }

  @override
  void dispose() {
    _insertion.dispose();
    _spin.dispose();
    super.dispose();
  }

  /// Main flow steps 2 and 3: plays once on mount, unless reduced motion or
  /// no insertion is owed — in which case the medium starts already seated,
  /// with nothing left for a screen reader to be told is moving.
  void _applyInsertion() {
    if (_reduceMotion || !widget.insert) {
      _insertion.value = 1;
      return;
    }
    if (_insertion.status == AnimationStatus.dismissed) {
      unawaited(_insertion.forward());
    }
  }

  /// Reports a finished insertion — but only one that actually played.
  ///
  /// Setting [_insertion]'s value to 1 directly (no insertion owed, or
  /// motion reduced) also drives the controller to `completed`, which fires
  /// this same status listener. Without the [AlbumStage.insert] and
  /// [_reduceMotion] guard, a stage that never animated at all would still
  /// report an insertion as finished — synchronously, from inside
  /// `initState` or `didChangeDependencies` — which is exactly where Task 6
  /// wires a `setState` into this callback that would then throw.
  void _onInsertionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (!widget.insert || _reduceMotion) return;

    widget.onInserted?.call();
  }

  /// Steps 4 and 5: repeats for as long as [AlbumStage.isPlaying] and motion
  /// is allowed.
  ///
  /// `repeat` rather than `forward`, and `stop` rather than `reset`: the
  /// medium holds its position through a pause, which is what "frozen where
  /// it is" means — resetting or reversing the controller would move it.
  void _applySpin() {
    if (widget.isPlaying && !_reduceMotion) {
      _spin.repeat();
    } else {
      _spin.stop();
    }
  }

  /// How long one full turn takes, by medium (Reference values). Read off
  /// the medium rather than a single constant: a record, a disc and a
  /// cassette's reels turn at genuinely different rates.
  Duration _spinPeriod(AlbumMedium medium) => switch (medium) {
    AlbumMedium.vinyl => const Duration(milliseconds: 1500),
    AlbumMedium.disc => const Duration(milliseconds: 900),
    AlbumMedium.tape => const Duration(milliseconds: 1800),
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.albumPalette;
    final direction = Directionality.of(context);
    final sleeve = palette
        .sleeveHues[sleeveIndexFor(widget.album, palette.sleeveHues.length)];

    return Semantics(
      label: _label(context),
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_insertion, _spin]),
          builder: (context, _) => _StageLayout(
            medium: widget.medium,
            palette: palette,
            sleeve: sleeve,
            title: widget.title,
            artist: widget.artist,
            direction: direction,
            size: widget.size,
            closed: _deviceCloses.value,
            turns: _spin.value,
            caseOpacity: (_caseIn.value - _hold.value).clamp(0, 1),
            caseSettle: _caseIn.value,
            caseDeparture: _hold.value,
            mediumEmergence: _mediumOut.value,
            travel: _travel.value,
          ),
        ),
      ),
    );
  }

  /// What a screen reader is told the stage is — the medium turning, as
  /// `AlbumAnimation` already said it (UC-21, FR-PL-07).
  ///
  /// A plain `AppLocalizations.of` lookup, same as every other widget in
  /// this application: a host that mounts this without wiring up
  /// `localizationsDelegates` is missing something every screen needs, not
  /// something this widget should quietly work around by shipping a stage
  /// with no screen-reader label.
  String _label(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return switch (widget.medium) {
      AlbumMedium.vinyl => l10n.albumMediumVinyl,
      AlbumMedium.tape => l10n.albumMediumTape,
      AlbumMedium.disc => l10n.albumMediumDisc,
    };
  }
}

/// The four painted layers, placed for one frame of the insertion or the
/// spin: the device's chassis, the medium, the device's foreground, and the
/// case — in that order, so a device's tonearm, door or lid lands in front
/// of the medium it closes over rather than buried beneath it (Finding 2).
/// A plain function of its inputs — nothing here owns an
/// [AnimationController] — so it can be rebuilt on every tick without
/// carrying animation state of its own.
class _StageLayout extends StatelessWidget {
  const _StageLayout({
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
  });

  final AlbumMedium medium;
  final AlbumPalette palette;
  final Color sleeve;
  final String title;
  final String artist;
  final TextDirection direction;
  final double size;
  final double closed;
  final double turns;
  final double caseOpacity;
  final double caseSettle;
  final double caseDeparture;
  final double mediumEmergence;
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
    // The case settles into place as it arrives, then drifts up and away as
    // it fades — the same beats that drive its opacity, read as a slide
    // rather than a plain cross-fade.
    final caseSlide =
        size * 0.12 * (1 - caseSettle) - size * 0.08 * caseDeparture;
    final caseCentre = Offset(size / 2, size * 0.66 + caseSlide);

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
  _Seat _seatFor(AlbumMedium medium, Rect device) => switch (medium) {
    AlbumMedium.vinyl => _Seat(
      centre: Offset(
        device.left + device.width * 0.40,
        device.top + device.height * 0.52,
      ),
      width: device.height * 0.80,
      height: device.height * 0.80,
    ),
    AlbumMedium.disc => _Seat(
      centre: Offset(
        device.left + device.width * 0.50,
        device.top + device.height * 0.66,
      ),
      width: device.height * 0.52,
      height: device.height * 0.52,
    ),
    AlbumMedium.tape => _Seat(
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
class _Seat {
  const _Seat({
    required this.centre,
    required this.width,
    required this.height,
  });

  final Offset centre;
  final double width;
  final double height;
}
