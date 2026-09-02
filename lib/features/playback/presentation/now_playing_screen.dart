import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../enrichment/presentation/enrich_track_button.dart';
import '../../enrichment/presentation/lyrics_button.dart';
import '../../playlists/presentation/add_to_playlist_button.dart';
import '../../shell/presentation/playback_bar.dart';
import '../domain/album_cover.dart';
import '../domain/media_player.dart';
import 'music_display_name.dart';
import 'sound_bars.dart';

/// The full audio player (UC-21, FR-PL-07).
///
/// The record, the machine and the whole insertion are gone from here. What
/// stood on this screen was an album animation — a case, a medium, and a
/// drawn or photographed device to put it into — and however well it was
/// drawn it was a picture of something that is not what the owner is
/// listening to. What they are listening to is a track: it has a name, it has
/// a sleeve, and it is making a sound right now.
///
/// So that is the screen. The album's own picture, as large as the window
/// allows. What is playing, named underneath it. And the bars ([SoundBars]),
/// which move while the music does and settle when it stops. Nothing here is
/// a drawing of hardware.
class NowPlayingScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const NowPlayingScreen({super.key});

  /// How wide the words are, when they are open.
  ///
  /// A column of a fixed comfortable measure, capped at a share of the window
  /// so a narrow one does not end up with two thin strips instead of a player
  /// and a page of lyrics.
  static const double _lyricsWidth = 420;

  /// The most of the window the words may take.
  static const double _lyricsShare = 0.42;

  /// The largest the sleeve is ever drawn, and the smallest.
  ///
  /// Bounded at the top because a cover blown up to fill a wide window is a
  /// low-resolution picture stretched past what it holds; bounded at the
  /// bottom because below this it stops being the thing the screen is about.
  static const double _coverMaximum = 420;

  /// See [_coverMaximum].
  static const double _coverMinimum = 140;

  /// Whether a [NowPlayingScreen] is currently mounted anywhere in the tree.
  ///
  /// What [show] checks before pushing another one: the shell's own auto-open
  /// and the playback bar's button are two independent paths to the same
  /// route, and either could otherwise stack a second copy on top of a first
  /// that is already open. Tied to the state's own `initState`/`dispose`
  /// rather than to the push that opened it, so it stays correct however the
  /// screen leaves the tree.
  static bool _mounted = false;

  /// Pushes the full-window player over [context], unless one is already
  /// open.
  static Future<void> show(BuildContext context) {
    if (_mounted) return Future<void>.value();

    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
    );
  }

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  /// Whether the words to the track are open beside the player.
  bool _showsLyrics = false;

  @override
  void initState() {
    super.initState();
    NowPlayingScreen._mounted = true;
  }

  @override
  void dispose() {
    NowPlayingScreen._mounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(audioPlaybackControllerProvider);
    final current = state.current;

    // The sleeve's own picture, when `AlbumCoverController` has one — `null`
    // for the designed placeholder, whether that is because the file carries
    // no picture, the call failed, or the cover has simply not arrived yet.
    final cover = switch (ref.watch(albumCoverControllerProvider)) {
      AlbumCoverFetched(:final image) => image,
      AlbumCoverDesigned() => null,
    };

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (current != null) ...[
            // Task 5 entry point 2: the words of the track playing, fetched
            // on the press when nothing has been cached for it yet.
            LyricsButton(
              isOpen: _showsLyrics,
              onPressed: () => setState(() => _showsLyrics = !_showsLyrics),
            ),
            EnrichTrackButton(
              fileUuid: current.uuid,
              artistName: musicEntryForFile(ref, current).albumArtist,
            ),
            AddToPlaylistButton(fileUuids: [current.uuid]),
          ],
          IconButton(
            tooltip: l10n.audioClosePlayer,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, viewport) {
          final showsLyrics = _showsLyrics && current != null;
          final lyricsWidth = showsLyrics
              ? math.min(
                  NowPlayingScreen._lyricsWidth,
                  viewport.maxWidth * NowPlayingScreen._lyricsShare,
                )
              : 0.0;

          final player = _Player(
            width: viewport.maxWidth - lyricsWidth,
            height: viewport.maxHeight,
            cover: cover,
          );

          if (!showsLyrics) return player;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: player),
              SizedBox(
                width: lyricsWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: LyricsPanel(
                        fileUuid: current.uuid,
                        artistName: musicEntryForFile(ref, current).albumArtist,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The player itself: the sleeve, what is playing, the bars, and the
/// transport.
class _Player extends ConsumerWidget {
  const _Player({
    required this.width,
    required this.height,
    required this.cover,
  });

  /// The room the player was left, once the words have taken theirs.
  final double width;

  /// How tall the window is.
  final double height;

  /// The album's own picture, or `null` for the placeholder.
  final ui.Image? cover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(audioPlaybackControllerProvider);
    final controller = ref.read(audioPlaybackControllerProvider.notifier);
    final current = state.current;

    // The sleeve takes what is left after the words, the bars and the
    // transport have theirs — bounded both ways, so a tall narrow window does
    // not print a postage stamp and a wide one does not blow a 300-pixel
    // picture up to fill it.
    final side = math
        .min(width - AppSpacing.lg * 2, height * 0.42)
        .clamp(NowPlayingScreen._coverMinimum, NowPlayingScreen._coverMaximum)
        .toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: height - AppSpacing.lg * 2,
          minWidth: width - AppSpacing.lg * 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Sleeve(cover: cover, side: side),
            const SizedBox(height: AppSpacing.lg),

            Text(
              // Never the file name (FR-CT-13): the metadata title, the same
              // one the bar and the browsing area agree a track is called.
              current == null
                  ? l10n.playbackNothingPlaying
                  : musicTitleForFile(ref, current, l10n),
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (current != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                // The record's artist rather than the track's performer: it
                // is whose record this is, which is what the browsing area
                // files it under.
                musicAlbumArtistForFile(ref, current, l10n),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                musicAlbumForFile(ref, current, l10n),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Semantics(
                label: l10n.audioSoundBarsLabel,
                child: SoundBars(
                  isPlaying: state.isPlaying,
                  // Each track its own movement, the same way every time it
                  // plays.
                  seed: current?.uuid.hashCode ?? 0,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: _Progress(status: state.status),
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: l10n.audioPrevious,
                  iconSize: 40,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: state.queue.hasPrevious
                      ? () => unawaited(controller.previous())
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  tooltip: state.isPlaying ? l10n.audioPause : l10n.audioPlay,
                  iconSize: 72,
                  icon: Icon(
                    state.isPlaying ? Icons.pause_circle : Icons.play_circle,
                  ),
                  onPressed: current == null
                      ? null
                      : () => unawaited(controller.togglePlaying()),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  tooltip: l10n.audioStop,
                  iconSize: 40,
                  icon: const Icon(Icons.stop),
                  onPressed: current == null
                      ? null
                      : () => unawaited(controller.stop()),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  tooltip: l10n.audioNext,
                  iconSize: 40,
                  icon: const Icon(Icons.skip_next),
                  onPressed: state.queue.hasNext
                      ? () => unawaited(controller.next())
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The album's own picture, or the placeholder that stands in for one.
class _Sleeve extends StatelessWidget {
  const _Sleeve({required this.cover, required this.side});

  final ui.Image? cover;
  final double side;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final corner = BorderRadius.circular(AppSpacing.md);

    return Semantics(
      label: l10n.albumCoverLabel,
      image: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: corner,
          boxShadow: [
            // The one flourish on the screen, and it earns its place: a
            // sleeve lying flat on the surface reads as a swatch, where a
            // sleeve with a shadow under it reads as an object being held up
            // to be looked at.
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.28),
              blurRadius: side * 0.10,
              offset: Offset(0, side * 0.035),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: corner,
          child: SizedBox.square(
            dimension: side,
            child: cover == null
                ? ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.album_outlined,
                      size: side * 0.4,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : RawImage(image: cover, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

/// Where the track has got to (FR-PL-09).
class _Progress extends StatelessWidget {
  const _Progress({required this.status});

  final PlaybackStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = status.duration;
    final fraction = duration == null || duration == Duration.zero
        ? null
        : (status.position.inMilliseconds / duration.inMilliseconds).clamp(
            0.0,
            1.0,
          );

    final label = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          // Shown, not dragged: seeking is the engine's to offer and nothing
          // in this application asks it to yet, so a bar that looked draggable
          // would be a control that does nothing.
          child: LinearProgressIndicator(value: fraction, minHeight: 4),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatPlaybackPosition(status.position), style: label),
            if (duration != null)
              Text(formatPlaybackPosition(duration), style: label),
          ],
        ),
      ],
    );
  }
}
