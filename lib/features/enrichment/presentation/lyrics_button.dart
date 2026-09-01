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
/// A control of its own rather than a second way to reach
/// `TrackEnrichmentPanel`: the panel renders nothing until something has
/// been cached, so a track nobody has looked up yet shows no sign that
/// lyrics are a thing this application has. This button is that sign, and
/// pressing it is what fetches them — the owner asks once and reads, rather
/// than asking for a lookup, waiting, and then scrolling to find out whether
/// it landed.
class LyricsButton extends ConsumerWidget {
  /// Creates the button for [fileUuid].
  const LyricsButton({
    required this.fileUuid,
    required this.artistName,
    super.key,
  });

  /// The track whose words to show.
  final String fileUuid;

  /// The album artist, carried through to the lookup that may follow.
  final String? artistName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return IconButton(
      tooltip: l10n.lyricsOpen,
      icon: const Icon(Icons.lyrics_outlined),
      onPressed: () => unawaited(
        LyricsPanel.show(
          context,
          fileUuid: fileUuid,
          artistName: artistName,
        ),
      ),
    );
  }
}

/// The words themselves, over the player they belong to.
///
/// A sheet rather than a route: the track keeps playing behind it, and timed
/// lyrics are only worth reading while it does — [SyncedLyricsView] follows
/// the same engine position the transport shows.
class LyricsPanel extends ConsumerStatefulWidget {
  /// Creates the panel.
  const LyricsPanel({
    required this.fileUuid,
    required this.artistName,
    super.key,
  });

  /// The track whose words are shown.
  final String fileUuid;

  /// Whose photograph the re-read afterwards asks for; carried so the lookup
  /// this panel may start is the same one the panel below the player would
  /// have started.
  final String? artistName;

  /// Presents the panel over [context].
  static Future<void> show(
    BuildContext context, {
    required String fileUuid,
    String? artistName,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        LyricsPanel(fileUuid: fileUuid, artistName: artistName),
  );

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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.lyricsTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            _Body(
              lyrics: enrichment.value?.lyrics,
              // The lookup in flight and the first read of the cache are the
              // same thing to read: both are "the words are on their way".
              isWaiting: run.isRunning || enrichment.isLoading,
              isEnabled: enabled,
              stage: run.stage,
            ),
          ],
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

  /// How much of the window the words may claim.
  ///
  /// A fraction rather than a fixed height: the sheet is as tall as its
  /// contents, and a song is tens of lines — bounded, or the timed view
  /// (which builds every line, deliberately) would push the sheet past the
  /// top of the window.
  static const double _heightFraction = 0.5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final words = lyrics;
    if (words != null) {
      final synced = words.synced;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * _heightFraction,
            ),
            // Timed lines when the provider had them, the plain block when
            // it did not — the same rule `TrackEnrichmentPanel` applies,
            // because plenty of tracks have only the words.
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

    if (isWaiting) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.enrichmentLookingUp),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
