import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';

/// The persistent playback bar (FR-UX-01).
///
/// Persistent means present, not present-only-while-playing: it holds the
/// bottom of the shell from the first frame so the content area above it never
/// changes height when a track starts. Until UC-19 and UC-20 give it a player
/// to drive, it states that nothing is playing.
class PlaybackBar extends StatelessWidget {
  /// Creates the bar.
  const PlaybackBar({super.key});

  /// The bar's height, in logical pixels.
  ///
  /// Fixed rather than intrinsic: the content area is laid out above it, and a
  /// bar that changed height as its contents arrived would reflow the listing
  /// behind it.
  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: l10n.playbackBarLabel,
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        child: SizedBox(
          height: height,
          child: Row(
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
          ),
        ),
      ),
    );
  }
}
