import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The bars that move with the music on the player screen (UC-21, FR-PL-07).
///
/// **What this is, plainly: it is not a spectrum of the audio.** Nothing in
/// this application can see the sound. The engine (`MediaPlayer`, over
/// media_kit) reports what is playing, whether it is running and where it has
/// got to — and no samples, no levels, no frequency bands, because mpv exposes
/// none of that through the interface this application has. A visualiser drawn
/// from data nobody has would be a lie told sixty times a second.
///
/// So this is what it honestly is: an animated instrument that runs while the
/// music runs, settles when it stops, and has a character of its own for each
/// track. Every bar carries three waves of its own at frequencies that never
/// line up, tilted the way a spectrum analyser sits — loud at the bottom of
/// the range, quieter at the top — and the whole set is seeded from the
/// track's identity, so two songs do not move the same way and the same song
/// moves the same way twice.
///
/// Making it real is a job for the core rather than a job for this widget: an
/// energy envelope computed once per file at index time, stored beside the
/// track and read back at the position playing, would drive these same bars
/// from the actual music. The shape here is deliberately the shape that would
/// take — a level per band, per moment.
class SoundBars extends StatefulWidget {
  /// Creates the visualiser.
  const SoundBars({
    required this.isPlaying,
    required this.seed,
    this.bars = 56,
    this.height = 140,
    super.key,
  });

  /// Whether audio is running: the bars swell while it is and lie down when
  /// it is not.
  final bool isPlaying;

  /// What gives this track its own movement — the file's uuid, hashed.
  ///
  /// A seed rather than a random source: a visualiser that reshuffled itself
  /// on every rebuild would flicker whenever anything else on the screen
  /// changed, and the same track would look different every time it played.
  final int seed;

  /// How many bars are drawn.
  final int bars;

  /// How tall the whole instrument is, in logical pixels.
  final double height;

  @override
  State<SoundBars> createState() => _SoundBarsState();
}

class _SoundBarsState extends State<SoundBars> with TickerProviderStateMixin {
  /// The clock the waves are read against.
  ///
  /// A minute per cycle rather than a second: the waves below are functions
  /// of elapsed seconds, and a controller that reset every second would put a
  /// seam in every one of them each time it did.
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );

  /// How much of the swell is applied, 0 lying flat and 1 at full height.
  ///
  /// Its own animation so that stopping the music settles the bars instead of
  /// dropping them: what an owner sees when they press pause is the sound
  /// falling away, which is what pausing actually did.
  late final AnimationController _energy = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 620),
  );

  @override
  void didUpdateWidget(SoundBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) _apply();
  }

  /// Where the running is decided, rather than in `initState`: what decides
  /// it is [MediaQuery.disableAnimationsOf], and an inherited widget may not
  /// be read before `initState` has finished — this runs once on mount and
  /// again whenever that answer changes.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _apply();
  }

  /// Runs or rests, and honours a request for less motion (AF-03).
  ///
  /// Reduced motion is not "the same thing, slower": nothing moves at all,
  /// and the bars stand at the levels the first moment of the track would
  /// have given them — the picture the instrument makes, without the motion
  /// somebody asked the system not to show them.
  void _apply() {
    final reduced = MediaQuery.disableAnimationsOf(context);

    if (reduced) {
      _clock.stop();
      _energy.value = widget.isPlaying ? 1 : 0;

      return;
    }

    if (widget.isPlaying) {
      if (!_clock.isAnimating) unawaited(_clock.repeat());
      unawaited(_energy.forward());
    } else {
      unawaited(
        _energy.reverse().whenComplete(() {
          // Nothing to draw and nothing moving: a stopped clock is a frame
          // never scheduled, which is the whole reason to stop it.
          if (mounted && !widget.isPlaying) _clock.stop();
        }),
      );
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _energy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_clock, _energy]),
          builder: (context, child) => CustomPaint(
            painter: SoundBarsPainter(
              seconds: _clock.value * 60,
              energy: _energy.value,
              seed: widget.seed,
              bars: widget.bars,
              hot: scheme.primary,
              cool: scheme.tertiary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the bars for one frame.
class SoundBarsPainter extends CustomPainter {
  /// Creates the painter.
  const SoundBarsPainter({
    required this.seconds,
    required this.energy,
    required this.seed,
    required this.bars,
    required this.hot,
    required this.cool,
  });

  /// Where the clock has got to, in seconds.
  final double seconds;

  /// How much of the swell to apply, 0 to 1.
  final double energy;

  /// The track's own seed.
  final int seed;

  /// How many bars to draw.
  final int bars;

  /// The colour of a bar at the bottom of the range.
  final Color hot;

  /// The colour of a bar at the top of it.
  final Color cool;

  /// What a bar stands at with nothing playing.
  ///
  /// Not zero: an instrument with nothing on it is still an instrument, and a
  /// row of bars flat against the floor reads as a broken widget rather than
  /// as silence.
  static const double _resting = 0.06;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars <= 0 || size.isEmpty) return;

    // Mirrored about the middle, growing up and down together: it is what a
    // level meter looks like laid on its side, and it keeps the block of
    // colour centred on the line the title above it is centred on.
    final middle = size.height / 2;
    final pitch = size.width / bars;
    final width = pitch * 0.62;
    final radius = Radius.circular(width / 2);

    for (var index = 0; index < bars; index++) {
      final level = levelFor(
        index: index,
        bars: bars,
        seconds: seconds,
        seed: seed,
        energy: energy,
      );
      final half = middle * level;
      final centre = pitch * (index + 0.5);
      final bar = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          centre - width / 2,
          middle - half,
          centre + width / 2,
          middle + half,
        ),
        radius,
      );

      canvas.drawRRect(
        bar,
        Paint()
          ..color = Color.lerp(hot, cool, index / (bars - 1))!.withValues(
            // Lit in proportion to how far it has risen, so the loud bars
            // read as the loud ones rather than the tall ones.
            alpha: 0.45 + 0.55 * level,
          ),
      );
    }
  }

  /// How high the bar at [index] stands, 0 to 1.
  ///
  /// Top-level and pure so the shape can be tested without a ticker, a
  /// canvas, or a frame: everything below is a function of the four numbers
  /// it is given, which is what makes the same track move the same way twice.
  static double levelFor({
    required int index,
    required int bars,
    required double seconds,
    required int seed,
    required double energy,
  }) {
    final band = bars <= 1 ? 0.0 : index / (bars - 1);
    // The tilt of a spectrum analyser at rest: bass on the left and loud,
    // treble on the right and quiet. Without it a row of equal bars reads as
    // a decoration rather than as an instrument.
    final tilt = 0.42 + 0.58 * math.pow(1 - band, 0.9);

    // Three waves whose periods never line up, so no two bars share a rhythm
    // and the pattern does not repeat while anybody is watching.
    final fast = math.sin(seconds * (2.4 + band * 7.5) + _phase(index, seed));
    final slow = math.sin(
      seconds * (0.7 + band * 1.9) + _phase(index + 31, seed),
    );
    final beat = math.sin(seconds * 3.1 + _phase(index + 71, seed));
    // Weighted so the product of three waves lands high often rather than
    // multiplying down to a ripple: three factors each averaging a half
    // average an eighth between them, which is a row of stubs.
    final swell =
        (0.64 + 0.36 * fast) * (0.74 + 0.26 * slow) * (0.88 + 0.12 * beat);

    final level = tilt * swell;

    return (_resting + (level - _resting) * energy).clamp(_resting, 1.0);
  }

  /// A phase angle for one bar, from the track's seed.
  ///
  /// Hashed rather than random: the same track has to move the same way every
  /// time it plays, and a widget that rebuilt into a new arrangement would
  /// twitch every time anything else on the screen changed.
  static double _phase(int index, int seed) {
    final mixed = (seed ^ (index * 2654435761)) & 0x7FFFFFFF;

    return (mixed % 6283) / 1000;
  }

  @override
  bool shouldRepaint(SoundBarsPainter old) =>
      old.seconds != seconds ||
      old.energy != energy ||
      old.seed != seed ||
      old.bars != bars ||
      old.hot != hot ||
      old.cool != cool;
}
