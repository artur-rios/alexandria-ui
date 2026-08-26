import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/album_palette.dart';
import '../domain/album_medium.dart';
import '../domain/sleeve_design.dart';
import 'album_medium_label.dart';
import 'stage_layout.dart';

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
    this.cover,
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

  /// The current album's own picture, decoded and ready to paint, or `null`
  /// to draw the designed jacket (design section 4).
  ///
  /// A plain data parameter, sourced by the caller from
  /// `albumCoverControllerProvider` — the same way [title], [artist] and
  /// [album] already arrive as plain strings rather than this widget
  /// reading a provider for them itself. Swapping this between frames does
  /// not touch either [AnimationController] below: [StageLayout] only
  /// repaints the sleeve with it, which is what keeps a cover arriving
  /// mid-insertion from restarting anything (design section 4).
  final ui.Image? cover;

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
    duration: spinPeriodFor(widget.medium),
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
      _spin.duration = spinPeriodFor(widget.medium);
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
          builder: (context, _) => StageLayout(
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
            cover: widget.cover,
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
  /// with no screen-reader label. The words themselves come from
  /// [albumMediumLabel] (Finding 10), shared with `AlbumVisor` so the two
  /// can never describe the same medium differently.
  String _label(BuildContext context) =>
      albumMediumLabel(widget.medium, AppLocalizations.of(context));
}
