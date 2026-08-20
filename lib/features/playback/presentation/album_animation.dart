import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/album_medium.dart';

/// The medium on its matching player, turning while audio runs (UC-21,
/// FR-PL-07, BR-21).
///
/// Painted rather than drawn from an asset: the shapes are simple, they have
/// to take their colours from the active theme (BR-18), and a bitmap would
/// have to ship at every density the desktop targets support.
class AlbumAnimation extends StatefulWidget {
  /// Creates the animation.
  const AlbumAnimation({
    required this.medium,
    required this.isPlaying,
    this.size = 220,
    super.key,
  });

  /// Which medium is shown.
  final AlbumMedium medium;

  /// Whether audio is running. The motion stops when it is not (main flow
  /// steps 4 and 5) and the medium stays exactly where it was.
  final bool isPlaying;

  /// How wide the animation is drawn.
  final double size;

  /// How long one full turn takes.
  ///
  /// Slower than any of the real formats. A record turning at speed reads as
  /// spinning rather than playing, and this is beside a track title the owner
  /// is trying to read.
  static const Duration turn = Duration(seconds: 6);

  @override
  State<AlbumAnimation> createState() => _AlbumAnimationState();
}

class _AlbumAnimationState extends State<AlbumAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AlbumAnimation.turn,
  );

  /// AF-04: whether the system asked for less motion.
  ///
  /// Read here rather than in `build` because it decides whether the ticker
  /// runs at all: a controller left repeating under a still medium would burn
  /// a frame's work every frame for something nobody can see.
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _applyPlaying();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion == _reduceMotion) return;

    _reduceMotion = reduceMotion;
    _applyPlaying();
  }

  @override
  void didUpdateWidget(AlbumAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) _applyPlaying();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Step 4 stops the motion where it is; step 5 continues from there.
  ///
  /// `repeat` rather than `forward`, and `stop` rather than `reset`: the
  /// medium holds its position through a pause, which is what "stays in place"
  /// means.
  void _applyPlaying() {
    if (widget.isPlaying && !_reduceMotion) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final medium = _MediumPainting(
      medium: widget.medium,
      surface: scheme.surfaceContainerHighest,
      ink: scheme.onSurface,
      accent: scheme.primary,
      size: widget.size,
    );

    return Semantics(
      label: _label(context),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        // AF-04: the medium is still shown, on its player, and playback is
        // unaffected — it simply does not turn.
        child: _reduceMotion
            ? medium
            : RotationTransition(turns: _controller, child: medium),
      ),
    );
  }

  /// What a screen reader is told the animation is.
  ///
  /// It is decoration with meaning: which medium is turning is the whole of
  /// what it says, and it is said in the owner's language like everything else.
  String _label(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return switch (widget.medium) {
      AlbumMedium.vinyl => l10n.albumMediumVinyl,
      AlbumMedium.tape => l10n.albumMediumTape,
      AlbumMedium.disc => l10n.albumMediumDisc,
    };
  }
}

/// The medium itself, painted.
class _MediumPainting extends StatelessWidget {
  const _MediumPainting({
    required this.medium,
    required this.surface,
    required this.ink,
    required this.accent,
    required this.size,
  });

  final AlbumMedium medium;
  final Color surface;
  final Color ink;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: switch (medium) {
      AlbumMedium.vinyl => _VinylPainter(ink: ink, accent: accent),
      AlbumMedium.disc => _DiscPainter(
        surface: surface,
        ink: ink,
        accent: accent,
      ),
      AlbumMedium.tape => _TapePainter(
        surface: surface,
        ink: ink,
        accent: accent,
      ),
    },
  );
}

/// A record: grooves, a label, and a spindle hole.
class _VinylPainter extends CustomPainter {
  const _VinylPainter({required this.ink, required this.accent});

  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    canvas.drawCircle(centre, radius, Paint()..color = ink);

    // The grooves. Drawn as rings rather than a spiral, because at this size a
    // spiral is a texture and rings are what the eye reads as a record.
    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = accent.withValues(alpha: 0.25);
    for (var ring = 0.45; ring < 0.95; ring += 0.08) {
      canvas.drawCircle(centre, radius * ring, groove);
    }

    canvas.drawCircle(centre, radius * 0.32, Paint()..color = accent);
    canvas.drawCircle(centre, radius * 0.05, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(_VinylPainter oldDelegate) =>
      oldDelegate.ink != ink || oldDelegate.accent != accent;
}

/// A compact disc: a bright face and a wide centre hole.
class _DiscPainter extends CustomPainter {
  const _DiscPainter({
    required this.surface,
    required this.ink,
    required this.accent,
  });

  final Color surface;
  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    canvas.drawCircle(centre, radius, Paint()..color = surface);
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ink.withValues(alpha: 0.4),
    );

    // The read side's sheen, as one bright quarter — which is what makes a
    // still disc read as turning once it moves.
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius * 0.78),
      -0.6,
      1.2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.35
        ..color = accent.withValues(alpha: 0.35),
    );

    canvas.drawCircle(centre, radius * 0.18, Paint()..color = ink);
    canvas.drawCircle(centre, radius * 0.08, Paint()..color = surface);
  }

  @override
  bool shouldRepaint(_DiscPainter oldDelegate) =>
      oldDelegate.surface != surface ||
      oldDelegate.ink != ink ||
      oldDelegate.accent != accent;
}

/// A cassette: a shell with two spools.
///
/// The whole shell turns, which no tape deck does. The alternative is turning
/// the two spools inside a still shell, and at this size that reads as nothing
/// moving at all — the animation has to be legible from across a desk.
class _TapePainter extends CustomPainter {
  const _TapePainter({
    required this.surface,
    required this.ink,
    required this.accent,
  });

  final Color surface;
  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final width = size.shortestSide * 0.86;
    final height = width * 0.62;
    final shell = Rect.fromCenter(center: centre, width: width, height: height);

    canvas.drawRRect(
      RRect.fromRectAndRadius(shell, const Radius.circular(AppRadius.sm)),
      Paint()..color = surface,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(shell, const Radius.circular(AppRadius.sm)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ink.withValues(alpha: 0.5),
    );

    final spool = width * 0.15;
    for (final dx in [-width * 0.22, width * 0.22]) {
      final hub = centre.translate(dx, 0);
      canvas.drawCircle(hub, spool, Paint()..color = accent);
      canvas.drawCircle(hub, spool * 0.35, Paint()..color = ink);
    }

    // The window between the spools, where the tape is visible.
    canvas.drawRect(
      Rect.fromCenter(center: centre, width: width * 0.2, height: height * 0.3),
      Paint()..color = ink.withValues(alpha: 0.3),
    );
  }

  @override
  bool shouldRepaint(_TapePainter oldDelegate) =>
      oldDelegate.surface != surface ||
      oldDelegate.ink != ink ||
      oldDelegate.accent != accent;
}
