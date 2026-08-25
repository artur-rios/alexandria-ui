import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/album_palette.dart';
import '../application/album_animation_controller.dart';
import '../application/audio_playback_controller.dart';
import '../domain/album_medium.dart';
import 'media/cassette_painter.dart';
import 'media/disc_painter.dart';
import 'media/vinyl_painter.dart';

/// A recessed window in the playback bar, showing the same medium the full
/// player's stage would (UC-21, FR-PL-07, FR-UX-01).
///
/// The bar is on screen for as long as the owner is anywhere in the
/// application, which is most of a session — that is what makes it the
/// surface a passing glance at the turning record is seen from, not the full
/// player, which is only open while the owner is looking at it on purpose.
/// Drives its own [AnimationController] at [spinPeriodFor]'s rate rather than
/// sharing one with `AlbumStage`: the two widgets are never mounted from the
/// same element (the stage lives on `NowPlayingScreen`, a separate route),
/// so there is nothing for a shared controller to save, only a dependency
/// between two otherwise independent widgets to introduce.
class AlbumVisor extends ConsumerStatefulWidget {
  /// Creates the visor.
  const AlbumVisor({this.size = 64, super.key});

  /// How wide and tall the recess is drawn, as a square.
  final double size;

  @override
  ConsumerState<AlbumVisor> createState() => _AlbumVisorState();
}

class _AlbumVisorState extends ConsumerState<AlbumVisor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  /// What [_spin] was last told to show, kept so a rebuild triggered by
  /// something else entirely (the bar's own text, the transport) does not
  /// re-issue `repeat()`/`stop()` for values that have not actually changed.
  AlbumMedium? _medium;
  bool _isPlaying = false;
  bool _hasCurrent = false;

  /// AF-04: whether the system asked for less motion, exactly as `AlbumStage`
  /// reads it — decided in `didChangeDependencies`, not `build`, because a
  /// context is not safe to establish an inherited dependency from before
  /// then.
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    final animation = ref.read(albumAnimationControllerProvider);
    final audio = ref.read(audioPlaybackControllerProvider);
    _medium = animation.medium;
    _isPlaying = audio.isPlaying;
    _hasCurrent = audio.current != null;
    if (_medium case final medium?) _spin.duration = spinPeriodFor(medium);
    _applySpin();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion == _reduceMotion) return;

    _reduceMotion = reduceMotion;
    _applySpin();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  /// Held exactly where it stopped, not reset: `stop()` preserves the
  /// controller's current value and `reset()` does not, and a paused medium
  /// has to stay where playback left it (main flow steps 4 and 5, mirrored
  /// from `AlbumStage._applySpin`).
  ///
  /// `_hasCurrent` is guarded here as well as in `build`'s own "nothing to
  /// show" check: `AudioPlaybackController` never reports `isPlaying` with an
  /// empty queue today, but this widget should not be correct only because of
  /// that — a controller change elsewhere must not be able to leave a ticker
  /// running behind an empty recess.
  void _applySpin() {
    if (_medium == null || _reduceMotion || !_isPlaying || !_hasCurrent) {
      _spin.stop();
      return;
    }
    _spin.repeat();
  }

  @override
  Widget build(BuildContext context) {
    // `ref.listen` rather than reacting inline to the `ref.watch` below: the
    // spin controller is imperative state this widget owns, and only an
    // actual change in medium or playing-ness should touch it — a rebuild
    // for an unrelated reason (the track title, the transport) must not
    // re-issue `repeat()` and restart the ticker's internal clock.
    ref.listen<AlbumAnimationState>(albumAnimationControllerProvider, (
      previous,
      next,
    ) {
      if (previous?.medium == next.medium) return;
      _medium = next.medium;
      if (next.medium case final medium?) _spin.duration = spinPeriodFor(medium);
      _applySpin();
    });
    ref.listen<AudioPlaybackState>(audioPlaybackControllerProvider, (
      previous,
      next,
    ) {
      final hasCurrent = next.current != null;
      if (previous?.isPlaying == next.isPlaying &&
          (previous?.current != null) == hasCurrent) {
        return;
      }
      _isPlaying = next.isPlaying;
      _hasCurrent = hasCurrent;
      _applySpin();
    });

    final medium = ref.watch(
      albumAnimationControllerProvider.select((state) => state.medium),
    );
    final current = ref.watch(
      audioPlaybackControllerProvider.select((state) => state.current),
    );

    // Off, or nothing playing: nothing here for the owner to glance at, and
    // an empty recess would be a decoration with no reason to be looked at.
    if (medium == null || current == null) return const SizedBox.shrink();

    final palette = context.albumPalette;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: _label(l10n, medium),
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _spin,
          builder: (context, _) =>
              _Recess(medium: medium, palette: palette, turns: _spin.value),
        ),
      ),
    );
  }

  /// What a screen reader is told the visor is — the same words `AlbumStage`
  /// uses for the same mediums (UC-21, FR-PL-07), so the bar and the full
  /// player never describe the same record differently.
  String _label(AppLocalizations l10n, AlbumMedium medium) => switch (medium) {
    AlbumMedium.vinyl => l10n.albumMediumVinyl,
    AlbumMedium.tape => l10n.albumMediumTape,
    AlbumMedium.disc => l10n.albumMediumDisc,
  };
}

/// The recess itself, and the medium turning inside it: a dark well, a
/// one-pixel edge, a shadow pooled toward the corners, and a sheet of glass
/// laid diagonally over the whole thing.
///
/// A plain function of its inputs, exactly like `AlbumStage`'s own
/// `_StageLayout` — nothing here owns the ticker, which is what lets it be
/// rebuilt on every frame without carrying animation state of its own.
class _Recess extends StatelessWidget {
  const _Recess({required this.medium, required this.palette, required this.turns});

  final AlbumMedium medium;
  final AlbumPalette palette;
  final double turns;

  /// The recess reads as a cut-out in the bar's panel, not a card sitting on
  /// it — a small radius rather than a fully rounded shape keeps that read at
  /// the size this is drawn.
  static const double _cornerRadius = 6;

  double get _aspect => switch (medium) {
    AlbumMedium.vinyl => VinylPainter.aspect,
    AlbumMedium.disc => DiscPainter.aspect,
    AlbumMedium.tape => CassettePainter.aspect,
  };

  CustomPainter get _mediumPainter => switch (medium) {
    AlbumMedium.vinyl => VinylPainter(palette: palette, turns: turns),
    AlbumMedium.disc => DiscPainter(palette: palette, turns: turns),
    AlbumMedium.tape => CassettePainter(palette: palette, turns: turns),
  };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.panelDark,
        borderRadius: BorderRadius.circular(_cornerRadius),
        border: Border.all(color: palette.panelEdge),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_cornerRadius - 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _InnerShadowPainter(color: palette.contactShadow)),
            // The medium is fit to the recess by its own aspect rather than
            // forced square: `CassettePainter.aspect` is 130/66, and filling
            // a square with it would squash the shell into a circle-adjacent
            // blob instead of the rectangle a cassette actually is.
            Center(
              child: AspectRatio(
                aspectRatio: _aspect,
                child: RepaintBoundary(child: CustomPaint(painter: _mediumPainter)),
              ),
            ),
            IgnorePointer(
              child: CustomPaint(painter: _SheenPainter(color: palette.glassSheen)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A shadow pooled toward the recess's edges, the way light falling into a
/// cut-out well darkens at its own walls rather than at its floor's centre.
class _InnerShadowPainter extends CustomPainter {
  const _InnerShadowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.6)],
          stops: const [0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _InnerShadowPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A sheet of glass laid diagonally over the recess, the same device
/// `CassettePainter._paintWindow` uses for its own window — a soft band of
/// light rather than a flat tint, so it reads as a reflection and not as a
/// stain on the medium underneath it.
class _SheenPainter extends CustomPainter {
  const _SheenPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: 0.4),
            color.withValues(alpha: 0),
          ],
          stops: const [0.05, 0.25, 0.5],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _SheenPainter oldDelegate) =>
      oldDelegate.color != color;
}
