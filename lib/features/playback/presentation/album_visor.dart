import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/album_palette.dart';
import '../application/album_animation_controller.dart';
import '../application/audio_playback_controller.dart';
import '../domain/album_cover.dart';
import '../domain/album_medium.dart';
import 'album_medium_label.dart';
import 'media/cassette_painter.dart';
import 'media/diagonal_sheen.dart';
import 'media/disc_painter.dart';
import 'media/vinyl_painter.dart';
import 'now_playing_screen.dart';

/// A recessed window in the playback bar, showing the album's own cover —
/// or, for a record that carries none, the same medium the full player's
/// stage turns (UC-21, FR-PL-07, FR-UX-01).
///
/// The cover comes first, and that is a change from what this showed at
/// first. A spinning disc is the same drawing for every album ever played:
/// it says a record is on, and nothing whatever about *which* record. The
/// sleeve is what an owner recognises at a glance across a room, which is
/// precisely what a bar that is on screen all session is for. The medium is
/// what remains when a file carries no picture — common enough that it is a
/// fallback rather than an error, exactly as it is for the case on the
/// stage (design section 4).
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
  const AlbumVisor({this.size = defaultSize, super.key});

  /// [size]'s own default (Finding 10) — `PlaybackBar.height` derives its
  /// own room for the visor from this rather than a second, hardcoded copy
  /// of the same number, which is what let the two drift apart in the first
  /// place.
  static const double defaultSize = 64;

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

  /// Whether the album's own picture is what is in the recess.
  ///
  /// Tracked alongside the rest because it decides whether the ticker runs
  /// at all: a cover does not turn, and a controller left repeating behind a
  /// still photograph would burn a frame's work every frame for a rotation
  /// nobody can see — the same waste `_reduceMotion` exists to avoid.
  bool _showsCover = false;

  /// AF-03: whether the system asked for less motion, exactly as `AlbumStage`
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
    _showsCover = ref.read(albumCoverControllerProvider) is AlbumCoverFetched;
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
    if (_medium == null ||
        _reduceMotion ||
        _showsCover ||
        !_isPlaying ||
        !_hasCurrent) {
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
      if (next.medium case final medium?) {
        _spin.duration = spinPeriodFor(medium);
      }
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

    ref.listen<AlbumCover>(albumCoverControllerProvider, (previous, next) {
      final showsCover = next is AlbumCoverFetched;
      if (showsCover == _showsCover) return;
      _showsCover = showsCover;
      _applySpin();
    });

    final medium = ref.watch(
      albumAnimationControllerProvider.select((state) => state.medium),
    );
    // The album's own picture, when `AlbumCoverController` has fetched one.
    // The very same image the full player's case is drawn with, from the
    // very same provider: the bar and the stage cannot show two different
    // covers for one record, and nothing here fetches anything of its own.
    final cover = switch (ref.watch(albumCoverControllerProvider)) {
      AlbumCoverFetched(:final image) => image,
      AlbumCoverDesigned() => null,
    };
    final current = ref.watch(
      audioPlaybackControllerProvider.select((state) => state.current),
    );

    // Off, or nothing playing: nothing here for the owner to glance at, and
    // an empty recess would be a decoration with no reason to be looked at.
    if (medium == null || current == null) return const SizedBox.shrink();

    final palette = context.albumPalette;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      // What is actually in the recess, which is not always the medium any
      // more: a screen reader told "long-playing record" while a sleeve is
      // on screen is being told about a drawing that is not there.
      label: cover == null ? _label(l10n, medium) : l10n.albumCoverLabel,
      button: true,
      // The sleeve is the obvious thing to press to see the record playing,
      // and an owner who has just recognised their album across the room
      // reaches for the picture rather than for the chevron beside it
      // (UC-21 main flow step 2). The bar's own button stays: this is a
      // second way in, not a replacement, and a control that only exists as
      // an unlabelled picture is one a keyboard cannot reach.
      child: GestureDetector(
        onTap: () => unawaited(NowPlayingScreen.show(context)),
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _spin,
            builder: (context, _) => _Recess(
              medium: medium,
              palette: palette,
              turns: _spin.value,
              cover: cover,
            ),
          ),
        ),
      ),
    );
  }

  /// What a screen reader is told the visor is — [albumMediumLabel]
  /// (Finding 10), the same words `AlbumStage` uses for the same mediums
  /// (UC-21, FR-PL-07), so the bar and the full player never describe the
  /// same record differently.
  String _label(AppLocalizations l10n, AlbumMedium medium) =>
      albumMediumLabel(medium, l10n);
}

/// The recess itself, and the medium turning inside it: a dark well, a
/// one-pixel edge, a shadow pooled toward the corners, and a sheet of glass
/// laid diagonally over the whole thing.
///
/// A plain function of its inputs, exactly like `AlbumStage`'s own
/// `_StageLayout` — nothing here owns the ticker, which is what lets it be
/// rebuilt on every frame without carrying animation state of its own.
class _Recess extends StatelessWidget {
  const _Recess({
    required this.medium,
    required this.palette,
    required this.turns,
    this.cover,
  });

  final AlbumMedium medium;
  final AlbumPalette palette;
  final double turns;

  /// The album's own picture, or `null` to turn the medium instead.
  final ui.Image? cover;

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
            CustomPaint(
              painter: _InnerShadowPainter(color: palette.contactShadow),
            ),
            if (cover case final cover?)
              // Cropped to fill the recess rather than letterboxed inside
              // it: sleeves are square and the recess is square, so the
              // crop is almost never visible — and a picture with bars down
              // its sides would read as a mistake in a window this small.
              RawImage(image: cover, fit: BoxFit.cover)
            else
              // The medium is fit to the recess by its own aspect rather
              // than forced square: `CassettePainter.aspect` is 130/66, and
              // filling a square with it would squash the shell into a
              // circle-adjacent blob instead of the rectangle a cassette
              // actually is.
              Center(
                child: AspectRatio(
                  aspectRatio: _aspect,
                  child: RepaintBoundary(
                    child: CustomPaint(painter: _mediumPainter),
                  ),
                ),
              ),
            IgnorePointer(
              child: CustomPaint(
                painter: _SheenPainter(color: palette.glassSheen),
              ),
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

/// A sheet of glass laid diagonally over the recess — a soft band of light
/// rather than a flat tint, so it reads as a reflection and not as a stain
/// on the medium underneath it. Built from [diagonalSheenPaint] (Finding
/// 10), the same device `CassettePainter._paintWindow` uses for its own
/// window, rather than a second copy of it.
class _SheenPainter extends CustomPainter {
  const _SheenPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      diagonalSheenPaint(
        rect,
        color,
        alpha: 0.4,
        stops: const [0.05, 0.25, 0.5],
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _SheenPainter oldDelegate) =>
      oldDelegate.color != color;
}
