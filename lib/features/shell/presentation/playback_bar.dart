import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../playback/application/audio_playback_controller.dart';

/// The persistent playback bar (FR-UX-01, FR-PL-05).
///
/// Persistent means present, not present-only-while-playing: it holds the
/// bottom of the shell from the first frame so the content area above it never
/// changes height when a track starts. It is a view of
/// [AudioPlaybackController] and holds nothing itself, which is what lets
/// playback continue while the owner navigates anywhere else (main flow
/// step 5).
class PlaybackBar extends ConsumerWidget {
  /// Creates the bar.
  const PlaybackBar({super.key});

  /// The bar's height, in logical pixels.
  ///
  /// Fixed rather than intrinsic: the content area is laid out above it, and a
  /// bar that changed height as its contents arrived would reflow the listing
  /// behind it.
  static const double height = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(audioPlaybackControllerProvider);

    return Semantics(
      container: true,
      label: l10n.playbackBarLabel,
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AF-01 and AF-02: a skipped track is named above the bar rather
            // than replacing what is playing, because the queue has already
            // moved on and the owner is listening to the next one.
            if (state.lastSkipped case final skipped?)
              _SkipNotice(name: skipped.name),

            // AF-03: nothing in the selection could be played.
            if (state.stage == AudioStage.allFailed) const _NothingPlayable(),

            const SizedBox(height: height, child: _Bar()),
          ],
        ),
      ),
    );
  }
}

/// The bar itself: what is playing, and the transport.
class _Bar extends ConsumerWidget {
  const _Bar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(audioPlaybackControllerProvider);
    final controller = ref.read(audioPlaybackControllerProvider.notifier);
    final current = state.current;

    // AF-04: a single track with a resume position asks before it starts.
    if (state.stage == AudioStage.offeringResume) {
      return const _ResumePrompt();
    }

    if (current == null) {
      return Row(
        children: [
          const SizedBox(width: AppSpacing.md),
          Icon(
            Icons.music_note_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              l10n.playbackNothingPlaying,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      );
    }

    return Row(
      children: [
        const SizedBox(width: AppSpacing.md),
        const Icon(Icons.music_note),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                current.name,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
              if (state.queue.label.isNotEmpty)
                Text(
                  state.queue.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        // FR-PL-06: skipping within the queue. Disabled rather than hidden at
        // its ends, so the controls do not move as a queue plays through.
        IconButton(
          tooltip: l10n.audioPrevious,
          icon: const Icon(Icons.skip_previous),
          onPressed: state.queue.hasPrevious
              ? () => unawaited(controller.previous())
              : null,
        ),
        IconButton(
          tooltip: state.isPlaying ? l10n.audioPause : l10n.audioPlay,
          icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () => unawaited(controller.togglePlaying()),
        ),
        IconButton(
          tooltip: l10n.audioNext,
          icon: const Icon(Icons.skip_next),
          onPressed: state.queue.hasNext
              ? () => unawaited(controller.next())
              : null,
        ),
        IconButton(
          tooltip: l10n.audioStop,
          icon: const Icon(Icons.stop),
          onPressed: () => unawaited(controller.stop()),
        ),
        const SizedBox(width: AppSpacing.md),
      ],
    );
  }
}

/// What AF-04 asks, in the bar rather than over the screen: the owner is
/// somewhere else in the application, and a modal would interrupt it.
class _ResumePrompt extends ConsumerWidget {
  const _ResumePrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(audioPlaybackControllerProvider);
    final controller = ref.read(audioPlaybackControllerProvider.notifier);
    final at = state.resumeFrom ?? Duration.zero;

    return Row(
      children: [
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            l10n.audioResumePrompt(formatPlaybackPosition(at)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: () => unawaited(controller.startOver()),
          child: Text(l10n.videoStartOver),
        ),
        const SizedBox(width: AppSpacing.sm),
        FilledButton(
          onPressed: () => unawaited(controller.resume()),
          child: Text(l10n.videoResume),
        ),
        const SizedBox(width: AppSpacing.md),
      ],
    );
  }
}

/// AF-01 and AF-02: which file was skipped, and why.
class _SkipNotice extends ConsumerWidget {
  const _SkipNotice({required this.name});

  /// The file that was skipped, named. Which file it was is the whole of what
  /// the owner needs; why it failed is the same answer for every skip the
  /// queue makes, and a reason per line would bury the name.
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.audioSkipped(name),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: ref
                .read(audioPlaybackControllerProvider.notifier)
                .acknowledgeSkip,
            child: Text(l10n.editorDismiss),
          ),
        ],
      ),
    );
  }
}

/// AF-03: nothing in the selection could be played.
class _NothingPlayable extends StatelessWidget {
  const _NothingPlayable();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        l10n.audioNothingPlayable,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}

/// A duration as the players show it.
///
/// Shared between the bar and the video player, because a position written by
/// one is offered by the other and reading differently would be two answers to
/// the same question.
String formatPlaybackPosition(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = duration.inHours;

  return hours == 0 ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
}
