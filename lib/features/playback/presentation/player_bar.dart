import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/presentation/file_details_view.dart';
import '../../catalog/presentation/music_display_name.dart';
import '../application/audio_playback_state.dart';

/// The music playing, docked at the bottom of the shell (libraries-only
/// design §6).
///
/// It takes no height when nothing is loaded, like the activity strip below
/// it, so the shell is unchanged for anyone not listening. While a track is
/// loaded it stays whatever the owner browses to: that is the point of a bar
/// rather than a player screen.
class PlayerBar extends ConsumerWidget {
  /// Creates the bar.
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioPlaybackControllerProvider);
    if (!state.isLoaded) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(audioPlaybackControllerProvider.notifier);
    final current = state.current;

    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1, thickness: 1),
          if (state.failure != null)
            _Notice(
              message: l10n.playerNothingPlayable,
              action: TextButton(
                onPressed: () => ref
                    .read(indexRunsControllerProvider.notifier)
                    .startRefresh(),
                child: Text(l10n.playerRescan),
              ),
            )
          else if (state.skippedName case final String skipped)
            _Notice(message: l10n.playerSkipped(skipped)),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _Cover(state: state),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: current == null
                      ? const SizedBox.shrink()
                      : InkWell(
                          onTap: () =>
                              FileDetailsView.show(context, ref, current.uuid),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                musicTitle(current),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall,
                              ),
                              if (musicByline(current) case final String by)
                                Text(
                                  by,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                ),
                IconButton(
                  tooltip: l10n.playerPrevious,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: current == null ? null : controller.previous,
                ),
                IconButton(
                  tooltip: state.playing ? l10n.playerPause : l10n.playerPlay,
                  icon: Icon(state.playing ? Icons.pause : Icons.play_arrow),
                  onPressed: current == null ? null : controller.togglePlaying,
                ),
                IconButton(
                  tooltip: l10n.playerNext,
                  icon: const Icon(Icons.skip_next),
                  onPressed: state.index + 1 < state.queue.length
                      ? controller.next
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(flex: 3, child: _Seek(state: state)),
                IconButton(
                  tooltip: l10n.playerClose,
                  icon: const Icon(Icons.close),
                  onPressed: controller.stop,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.state});

  final AudioPlaybackState state;

  @override
  Widget build(BuildContext context) {
    const size = 48.0;
    final cover = state.cover;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox.square(
        dimension: size,
        child: cover == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.music_note_outlined),
              )
            : Image.memory(cover, fit: BoxFit.cover, gaplessPlayback: true),
      ),
    );
  }
}

class _Seek extends ConsumerWidget {
  const _Seek({required this.state});

  final AudioPlaybackState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final duration = state.duration;
    final position = duration == null || state.position <= duration
        ? state.position
        : duration;

    String clock(Duration value) => formatDuration(value.inMilliseconds / 1000);

    return Row(
      children: [
        Text(clock(position), style: theme.textTheme.bodySmall),
        Expanded(
          child: Slider(
            value: duration == null ? 0 : position.inMilliseconds.toDouble(),
            max: duration == null || duration == Duration.zero
                ? 1
                : duration.inMilliseconds.toDouble(),
            onChanged: duration == null || state.current == null
                ? null
                : (value) => ref
                      .read(audioPlaybackControllerProvider.notifier)
                      .seekTo(Duration(milliseconds: value.round())),
          ),
        ),
        Text(
          duration == null ? '–:––' : clock(duration),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
          ?action,
        ],
      ),
    );
  }
}
