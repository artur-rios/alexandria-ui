import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';
import '../domain/album_medium.dart';
import 'album_animation.dart';
import 'music_display_name.dart';

/// The full audio player (UC-21, FR-PL-07).
///
/// A dialog over the shell rather than a destination: playback belongs to the
/// bar, and this is the bar opened up. Closing it is how AF-03's "navigates to
/// another screen" happens — the queue and the bar are untouched by it.
class AlbumPlayerScreen extends ConsumerWidget {
  /// Creates the screen.
  const AlbumPlayerScreen({super.key});

  /// Presents the full player over [context] (main flow step 2).
  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => const AlbumPlayerScreen(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(audioPlaybackControllerProvider);
    final controller = ref.read(audioPlaybackControllerProvider.notifier);
    final current = state.current;

    // AF-01: the window is too small for the animation. The compact player is
    // what is shown instead, and playback is unaffected.
    final hasRoom = Breakpoint.from(context) != Breakpoint.compact;

    // AF-02: a single track is not a record, so it gets the compact player too.
    final showsAnimation = hasRoom && state.queue.showsAlbumAnimation;

    // Never the file name (FR-CT-13), and never the queue's own label for a
    // single track — the generic title stands in for both an untagged queue
    // and a queue with no name of its own.
    final queueLabel = queueLabelOf(state.queue, l10n);

    return AlertDialog(
      title: Text(queueLabel ?? l10n.audioPlayer),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showsAnimation) ...[
              AlbumAnimation(
                medium: mediumForYear(state.queue.year),
                // Step 3: it turns while audio plays; steps 4 and 5 stop and
                // continue it with the playback it belongs to.
                isPlaying: state.isPlaying,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            Text(
              // Never the file name (FR-CT-13): the metadata title, the same
              // one the bar and the browsing area already agree a track is
              // called — this dialog does not get to disagree just because
              // it names the track in its own body text.
              current == null
                  ? l10n.playbackNothingPlaying
                  : musicTitleForFile(ref, current, l10n),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: l10n.audioPrevious,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: state.queue.hasPrevious
                      ? () => unawaited(controller.previous())
                      : null,
                ),
                IconButton(
                  tooltip: state.isPlaying ? l10n.audioPause : l10n.audioPlay,
                  iconSize: 40,
                  icon: Icon(
                    state.isPlaying ? Icons.pause_circle : Icons.play_circle,
                  ),
                  onPressed: () => unawaited(controller.togglePlaying()),
                ),
                IconButton(
                  tooltip: l10n.audioNext,
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
      actions: [
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.preferencesClose),
        ),
      ],
    );
  }
}
