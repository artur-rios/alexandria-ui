import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/enrichment_run_controller.dart';
import '../application/track_enrichment_controller.dart';
import '../domain/track_enrichment.dart';
import 'synced_lyrics_view.dart';

/// Opens the words of the track playing now (music enrichment design).
///
/// A control of its own rather than a second way to reach something already
/// on screen: nothing renders until a lookup has cached something, so a track
/// nobody has looked up yet shows no sign that lyrics are a thing this
/// application has. This button is that sign, and pressing it is what fetches
/// them — the owner asks once and reads, rather than asking for a lookup,
/// waiting, and then scrolling to find out whether it landed.
///
/// A toggle, not a door onto a sheet. The words used to open in a modal over
/// the player, which is the wrong shape for what they are: timed lines are
/// read *while* the record turns, and a modal put the turning record behind
/// them. The screen makes room beside the device instead
/// (`NowPlayingScreen`), and this button says whether it currently has.
class LyricsButton extends StatelessWidget {
  /// Creates the button.
  const LyricsButton({
    required this.isOpen,
    required this.onPressed,
    super.key,
  });

  /// Whether the words are on screen right now.
  final bool isOpen;

  /// Called to show them, or to put them away.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return IconButton(
      // Named for what pressing it does next, not for what it opened: a
      // control that still said "Lyrics" while the lyrics were open would
      // leave the owner guessing which way it goes.
      tooltip: isOpen ? l10n.lyricsClose : l10n.lyricsOpen,
      isSelected: isOpen,
      icon: Icon(isOpen ? Icons.lyrics : Icons.lyrics_outlined),
      color: isOpen ? theme.colorScheme.primary : null,
      onPressed: onPressed,
    );
  }
}

/// The words themselves, beside the player they belong to.
///
/// Sized by whoever places it and filling what it is given: the player hands
/// it a column down one side of the window, and [SyncedLyricsView] follows
/// the same engine position the device's own readout shows.
///
/// It holds the words and nothing else. It briefly also carried the artist's
/// photograph and the credit its licence requires, which made this column a
/// short article about the artist with the song underneath — a photograph
/// belongs where an owner is looking *for* artists, which is the artists
/// list, and that is where it is now (`MusicGroupList`).
class LyricsPanel extends ConsumerStatefulWidget {
  /// Creates the panel.
  const LyricsPanel({
    required this.fileUuid,
    required this.artistName,
    super.key,
  });

  /// The track whose words are shown.
  final String fileUuid;

  /// Whose photograph the lookup this panel may start also fetches; carried
  /// so one press fills both the words here and the portrait in the artists
  /// list.
  final String? artistName;

  @override
  ConsumerState<LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends ConsumerState<LyricsPanel> {
  /// Whether this panel has already asked for a lookup.
  ///
  /// Once per opening, never once per build: the read below rebuilds this
  /// widget every time the engine reports a position, and a lookup started
  /// from `build` would be started again on each of them.
  bool _asked = false;

  TrackEnrichmentKey get _key =>
      (fileUuid: widget.fileUuid, artistName: widget.artistName);

  /// Looks the track up, if nothing is cached for it and the owner has left
  /// the lookup switched on.
  ///
  /// This is the whole point of the button: a track nobody has looked up
  /// shows its words on the first press, not on the second. Off is honoured
  /// without a call — the preference is the owner saying this application
  /// does not reach the network, and asking anyway to be refused by the core
  /// would make the switch a formality.
  void _lookUpIfNeeded(TrackEnrichment? enrichment) {
    if (_asked || enrichment == null || enrichment.lyrics != null) return;
    if (!ref.read(preferencesControllerProvider).musicLookupEnabled) return;

    _asked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref
            .read(enrichmentRunControllerProvider.notifier)
            .runForTrack(
              fileUuid: widget.fileUuid,
              artistName: widget.artistName,
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final enrichment = ref.watch(trackEnrichmentControllerProvider(_key));
    final run = ref.watch(enrichmentRunControllerProvider);
    final enabled = ref.watch(
      preferencesControllerProvider.select(
        (preferences) => preferences.musicLookupEnabled,
      ),
    );

    _lookUpIfNeeded(enrichment.value);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        // No heading over it. The column appears because the owner pressed
        // the lyrics button a moment ago, and it holds the words to the song
        // that is audibly playing — a line of type saying "Lyrics" over the
        // top of that told them nothing they had not just done themselves,
        // and cost a line of the song.
        child: _Body(
          lyrics: enrichment.value?.lyrics,
          // The lookup in flight and the first read of the cache are the
          // same thing to read: both are "the words are on their way".
          isWaiting: run.isRunning || enrichment.isLoading,
          isEnabled: enabled,
          stage: run.stage,
        ),
      ),
    );
  }
}

/// What the panel has to show: the words, or why there are none.
class _Body extends StatelessWidget {
  const _Body({
    required this.lyrics,
    required this.isWaiting,
    required this.isEnabled,
    required this.stage,
  });

  final TrackLyrics? lyrics;
  final bool isWaiting;
  final bool isEnabled;

  /// What the lookup this panel started concluded, when it started one.
  final EnrichmentRunStage stage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final words = lyrics;
    if (words != null) {
      final synced = words.synced;

      return Column(
        children: [
          // The whole column, top to bottom. It used to be capped at half
          // the window because it was a sheet that grew upward from the
          // bottom edge; a column beside the device is given its height by
          // the screen, and every line it can hold is a line the owner does
          // not have to scroll to.
          Expanded(
            // Timed lines when the provider had them, the plain block when
            // it did not, because plenty of tracks have only the words.
            child: synced != null
                ? SyncedLyricsView(lyrics: synced)
                : SingleChildScrollView(
                    // Selectable, because the obvious thing to do with a
                    // line of lyrics is copy it.
                    child: SelectableText(
                      words.lines.join('\n'),
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
          if (words.source case final source?) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.enrichmentLyricsSource(source),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      );
    }

    // Centred in the column, both below: a message about why there are no
    // words is all this side of the window holds, and pinned to the top of
    // a full-height column it would read as a caption for a device that is
    // not there.
    if (isWaiting) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.enrichmentLookingUp),
          ],
        ),
      );
    }

    return Center(
      child: Text(
        // Why there are no words, in the owner's terms. Four different
        // facts, and what they can do about each one differs: turn the
        // lookup on, tag the file, try again later, or nothing at all.
        // Told only "no lyrics found", a track that was never searched for
        // and a service that could not be reached both read as the feature
        // being broken.
        switch (stage) {
          _ when !isEnabled => l10n.lyricsSwitchedOff,
          EnrichmentRunStage.unavailable => l10n.enrichmentUnavailable,
          EnrichmentRunStage.failed => l10n.enrichmentLookupFailed,
          EnrichmentRunStage.untagged => l10n.enrichmentUntagged,
          _ => l10n.lyricsNone,
        },
        style: theme.textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
