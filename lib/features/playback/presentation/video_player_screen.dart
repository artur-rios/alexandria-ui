import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/playback_colors.dart';
import '../../catalog/domain/catalog_file.dart';
import '../application/video_playback_controller.dart';
import '../domain/media_player.dart';
import '../../shell/presentation/playback_bar.dart';
import 'video_surface.dart';

/// The video player (UC-19, FR-PL-01 … FR-PL-04).
///
/// A full-screen dialog: watching something is what the owner is doing, not
/// something they do beside a listing, and full-screen toggling (FR-PL-02) is
/// then a matter of hiding the controls rather than of moving the surface.
class VideoPlayerScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const VideoPlayerScreen({super.key});

  /// Opens [file] (main flow step 1).
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    CatalogFile file,
  ) {
    unawaited(ref.read(videoPlaybackControllerProvider.notifier).open(file));

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog.fullscreen(child: VideoPlayerScreen()),
    );
  }

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videoPlaybackControllerProvider);
    final controller = ref.read(videoPlaybackControllerProvider.notifier);

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.space): _TogglePlayingIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight): _SeekIntent(
          forward: true,
        ),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _SeekIntent(
          forward: false,
        ),
        SingleActivator(LogicalKeyboardKey.keyF): _ToggleFullScreenIntent(),
      },
      child: Actions(
        // FR-UX-11: the player is usable from the keyboard, which for a video
        // means the three things a hand reaches for without looking.
        actions: {
          _TogglePlayingIntent: CallbackAction<_TogglePlayingIntent>(
            onInvoke: (_) => unawaited(controller.togglePlaying()),
          ),
          _SeekIntent: CallbackAction<_SeekIntent>(
            onInvoke: (intent) => unawaited(
              controller.seekBy(intent.forward ? _seekStep : -_seekStep),
            ),
          ),
          _ToggleFullScreenIntent: CallbackAction<_ToggleFullScreenIntent>(
            onInvoke: (_) => controller.toggleFullScreen(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: context.playbackColors.surround,
            appBar: state.isFullScreen
                ? null
                : AppBar(
                    title: Text(state.file?.name ?? ''),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: AppLocalizations.of(context).videoClose,
                      onPressed: () async {
                        await controller.close();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ),
            body: switch (state.stage) {
              VideoStage.offeringResume => const _ResumePrompt(),
              VideoStage.opening => const Center(
                child: CircularProgressIndicator(),
              ),
              VideoStage.failed => const _PlaybackFailed(),
              VideoStage.closed => const SizedBox.shrink(),
              VideoStage.playing => const _Player(),
            },
          ),
        ),
      ),
    );
  }
}

/// How far a seek moves (FR-PL-02).
const Duration _seekStep = Duration(seconds: 10);

class _TogglePlayingIntent extends Intent {
  const _TogglePlayingIntent();
}

class _SeekIntent extends Intent {
  const _SeekIntent({required this.forward});

  final bool forward;
}

class _ToggleFullScreenIntent extends Intent {
  const _ToggleFullScreenIntent();
}

/// The surface and its controls (main flow steps 4 to 6).
class _Player extends ConsumerWidget {
  const _Player();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(videoPlaybackControllerProvider);

    return Column(
      children: [
        Expanded(child: VideoSurface(isFullScreen: state.isFullScreen)),
        if (!state.isFullScreen) const _Controls(),
      ],
    );
  }
}

/// Pause, seek, tracks, and full screen (FR-PL-02 … FR-PL-04).
class _Controls extends ConsumerWidget {
  const _Controls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(videoPlaybackControllerProvider);
    final controller = ref.read(videoPlaybackControllerProvider.notifier);
    final duration = state.status.duration;

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(_formatted(state.status.position)),
                Expanded(
                  child: Slider(
                    value: _sliderValue(state.status.position, duration),
                    onChanged: duration == null
                        ? null
                        : (value) =>
                              unawaited(controller.seekTo(duration * value)),
                  ),
                ),
                Text(duration == null ? '--:--' : _formatted(duration)),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                IconButton(
                  tooltip: l10n.videoSeekBackward,
                  icon: const Icon(Icons.replay_10),
                  onPressed: () => unawaited(controller.seekBy(-_seekStep)),
                ),
                IconButton(
                  tooltip: state.isPlaying ? l10n.videoPause : l10n.videoPlay,
                  icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () => unawaited(controller.togglePlaying()),
                ),
                IconButton(
                  tooltip: l10n.videoSeekForward,
                  icon: const Icon(Icons.forward_10),
                  onPressed: () => unawaited(controller.seekBy(_seekStep)),
                ),
                const _TrackMenu(kind: _TrackKind.subtitle),
                const _TrackMenu(kind: _TrackKind.audio),
                IconButton(
                  tooltip: l10n.videoFullScreen,
                  icon: Icon(
                    state.isFullScreen
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen,
                  ),
                  onPressed: controller.toggleFullScreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static double _sliderValue(Duration position, Duration? duration) {
    if (duration == null || duration == Duration.zero) return 0;

    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Shared with the player bar: a position written by one player is offered
  /// by the other, and reading differently would be two answers to the same
  /// question.
  static String _formatted(Duration duration) =>
      formatPlaybackPosition(duration);
}

/// Which list of tracks a menu offers.
enum _TrackKind { subtitle, audio }

/// The menu value that means "no subtitles" (FR-PL-03).
///
/// Not a track id, and not null: a popup menu item whose value is null is
/// never reported as a selection, so turning subtitles off would quietly do
/// nothing.
const String subtitlesOffValue = 'subtitles-off';

/// The subtitle and audio track menus (FR-PL-03, FR-PL-04).
///
/// AF-03 is why this is always present: a file with no alternative track says
/// so, rather than the control quietly not being there — which the owner would
/// read as the application not supporting tracks at all.
class _TrackMenu extends ConsumerWidget {
  const _TrackMenu({required this.kind});

  final _TrackKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(videoPlaybackControllerProvider);
    final controller = ref.read(videoPlaybackControllerProvider.notifier);

    final tracks = switch (kind) {
      _TrackKind.subtitle => state.status.subtitleTracks,
      _TrackKind.audio => state.status.audioTracks,
    };

    final tooltip = switch (kind) {
      _TrackKind.subtitle => l10n.videoSubtitles,
      _TrackKind.audio => l10n.videoAudioTracks,
    };

    return PopupMenuButton<String>(
      tooltip: tooltip,
      icon: Icon(
        kind == _TrackKind.subtitle
            ? Icons.subtitles_outlined
            : Icons.multitrack_audio,
      ),
      onSelected: (id) => unawaited(switch (kind) {
        // A sentinel rather than a null value: a menu item whose value is null
        // is never reported as a selection, so turning subtitles off would
        // quietly do nothing.
        _TrackKind.subtitle => controller.selectSubtitle(
          id == subtitlesOffValue ? null : id,
        ),
        _TrackKind.audio => controller.selectAudio(id),
      }),
      itemBuilder: (context) => [
        if (tracks.isEmpty)
          PopupMenuItem<String>(
            enabled: false,
            child: Text(
              kind == _TrackKind.subtitle
                  ? l10n.videoNoSubtitles
                  : l10n.videoNoAudioTracks,
            ),
          )
        else ...[
          // Turning subtitles off is a choice among the tracks, not a separate
          // control: FR-PL-03 names it as one of them.
          if (kind == _TrackKind.subtitle)
            PopupMenuItem<String>(
              value: subtitlesOffValue,
              child: Text(l10n.videoSubtitlesOff),
            ),
          for (final track in tracks)
            PopupMenuItem<String>(
              value: track.id,
              child: Text(_label(track, l10n)),
            ),
        ],
      ],
    );
  }

  static String _label(MediaTrack track, AppLocalizations l10n) =>
      track.title ?? track.language ?? l10n.videoTrackUnnamed(track.id);
}

/// What AF-04 asks before anything is opened.
class _ResumePrompt extends ConsumerWidget {
  const _ResumePrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(videoPlaybackControllerProvider);
    final controller = ref.read(videoPlaybackControllerProvider.notifier);
    final at = state.resumeFrom ?? Duration.zero;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.videoResumePrompt(_Controls._formatted(at)),
              style: theme.textTheme.titleMedium?.copyWith(
                color: context.playbackColors.onSurround,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.md,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => unawaited(controller.startOver()),
                  child: Text(l10n.videoStartOver),
                ),
                FilledButton(
                  autofocus: true,
                  onPressed: () => unawaited(controller.resume()),
                  child: Text(l10n.videoResume),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// What AF-01 and AF-02 show (FR-PL-10).
class _PlaybackFailed extends ConsumerWidget {
  const _PlaybackFailed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(videoPlaybackControllerProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.isMissing ? Icons.search_off : Icons.videocam_off_outlined,
              color: theme.colorScheme.error,
              size: AppSpacing.xl,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              // AF-01 and AF-02 are different problems with different answers,
              // so they read differently.
              state.isMissing ? l10n.videoFileMissing : l10n.videoCannotDecode,
              style: theme.textTheme.titleMedium?.copyWith(
                color: context.playbackColors.onSurround,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.failure case final failure?) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                failure.localizedMessage(l10n),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.playbackColors.onSurround,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            // AF-01 offers the re-scan; AF-02 has nothing to offer, because a
            // format the engine cannot read is not fixed by indexing again.
            if (state.isMissing) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () => ref
                    .read(indexRunsControllerProvider.notifier)
                    .startRefresh(),
                icon: const Icon(Icons.autorenew),
                label: Text(l10n.detailsRescan),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
