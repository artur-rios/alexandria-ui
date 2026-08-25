import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import 'album_stage.dart';
import 'music_display_name.dart';

/// The full audio player (UC-21, FR-PL-07).
///
/// A route rather than a dialog: `AlbumPlayerScreen`, the widget this
/// replaces, drew the animation into a 360-pixel dialog because a dialog was
/// what UC-21 first asked for, but the insertion and the spin need real room
/// to read as a case, a medium, and a device rather than a cramped diagram.
/// Filling the window is what gives them it. Closing the route is how AF-03's
/// "navigates to another screen" happens — popping it leaves the queue and
/// the bar exactly where they were, because neither one lives in this widget.
class NowPlayingScreen extends ConsumerWidget {
  /// Creates the screen.
  const NowPlayingScreen({super.key});

  /// Pushes the full-window player over [context] (main flow step 2).
  static Future<void> show(BuildContext context) => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (context) => const NowPlayingScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(audioPlaybackControllerProvider);
    final controller = ref.read(audioPlaybackControllerProvider.notifier);
    final animation = ref.watch(albumAnimationControllerProvider);
    final current = state.current;

    // A single track is not a record (AF-02): `AlbumAnimationController`
    // only decides the medium and whether it owes an insertion, not whether
    // this queue is the kind of thing that gets a medium at all, so that
    // question is still asked here — the same split the dialog this replaces
    // already drew between its own "is there room" check and the queue's
    // own `showsAlbumAnimation`.
    final showsAnimation =
        animation.medium != null &&
        current != null &&
        state.queue.showsAlbumAnimation;

    // Never the file name (FR-CT-13), and never the queue's own label for a
    // single track — the generic title stands in for both an untagged queue
    // and a queue with no name of its own.
    final queueLabel = queueLabelOf(state.queue, l10n);

    return Scaffold(
      // No title here: the queue's own name is already the second line of
      // the body below, right under the track title it belongs beside, and
      // an `AppBar` title would only repeat it — this bar exists for the
      // close control alone.
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: l10n.audioClosePlayer,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showsAnimation)
              // The largest square the window allows, short of crowding the
              // title and controls below it: `Expanded` claims whatever
              // height they leave, and the square is clamped to whichever of
              // that height or the available width is smaller.
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) => AlbumStage(
                      medium: animation.medium!,
                      // Step 3: it turns while audio plays; steps 4 and 5
                      // stop and continue it with the playback it belongs
                      // to.
                      isPlaying: state.isPlaying,
                      // Task 6's owed flag, played once and acknowledged
                      // below so the next track of the same record does not
                      // replay it.
                      insert: animation.insertionOwed,
                      title: musicTitleForFile(ref, current, l10n),
                      artist: musicArtistForFile(ref, current, l10n),
                      album: state.queue.label,
                      size: math.min(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      ),
                      onInserted: ref
                          .read(albumAnimationControllerProvider.notifier)
                          .insertionShown,
                    ),
                  ),
                ),
              ),
            if (showsAnimation) const SizedBox(height: AppSpacing.lg),

            Text(
              // Never the file name (FR-CT-13): the metadata title, the same
              // one the bar and the browsing area already agree a track is
              // called — this screen does not get to disagree just because
              // it names the track in its own body text.
              current == null
                  ? l10n.playbackNothingPlaying
                  : musicTitleForFile(ref, current, l10n),
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (current != null && queueLabel != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                queueLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: l10n.audioPrevious,
                  iconSize: 48,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: state.queue.hasPrevious
                      ? () => unawaited(controller.previous())
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton(
                  tooltip: state.isPlaying ? l10n.audioPause : l10n.audioPlay,
                  iconSize: 72,
                  icon: Icon(
                    state.isPlaying ? Icons.pause_circle : Icons.play_circle,
                  ),
                  onPressed: () => unawaited(controller.togglePlaying()),
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton(
                  tooltip: l10n.audioNext,
                  iconSize: 48,
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
