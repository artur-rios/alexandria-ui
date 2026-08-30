import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/track_enrichment.dart';
import 'synced_lyrics_view.dart';

/// The artist photograph and lyrics for the track playing now (music
/// enrichment design).
///
/// Renders nothing at all when there is nothing to show, which is most of a
/// real library and is not a failure. An embellishment beside a playing
/// track does not get to occupy space announcing its own absence, and it
/// does not get to report errors either — see
/// `TrackEnrichmentController.build`.
class TrackEnrichmentPanel extends ConsumerWidget {
  /// Creates the panel for [fileUuid], reading [artistName]'s image.
  const TrackEnrichmentPanel({
    required this.fileUuid,
    required this.artistName,
    super.key,
  });

  /// The track being shown.
  final String fileUuid;

  /// Whose photograph to show, or `null` when the track's tags name nobody.
  final String? artistName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrichment = ref
        .watch(
          trackEnrichmentControllerProvider((
            fileUuid: fileUuid,
            artistName: artistName,
          )),
        )
        .value;

    if (enrichment == null || enrichment.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (enrichment.artistImage != null)
            _ArtistPortrait(image: enrichment.artistImage!),
          if (enrichment.lyrics != null) _Lyrics(lyrics: enrichment.lyrics!),
        ],
      ),
    );
  }
}

/// The artist's photograph, with the credit its licence requires.
class _ArtistPortrait extends StatelessWidget {
  const _ArtistPortrait({required this.image});

  final ArtistImage image;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Image.file(
            File(image.path),
            width: 160,
            height: 160,
            fit: BoxFit.cover,
            // The bytes are a cache the core wrote, and a cache can be
            // cleared, moved, or half-written. A missing or unreadable file
            // shows nothing rather than Flutter's broken-image glyph, which
            // would read as a defect in the application rather than as an
            // image that is simply not there any more.
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
        if (image.sourceUrl != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            // Not decoration. Wikimedia Commons licences require
            // attribution, so the credit travels with the picture — an image
            // whose provenance was lost cannot lawfully be shown, which is
            // why the core stores the source alongside the bytes.
            l10n.enrichmentImageCredit(image.sourceUrl!),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// The words, and who supplied them.
class _Lyrics extends StatelessWidget {
  const _Lyrics({required this.lyrics});

  final TrackLyrics lyrics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(l10n.enrichmentLyricsTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        // Timed lines when the provider had them, the plain block when it
        // did not. Plenty of tracks have only the words, and a view that
        // required timing would show them nothing.
        if (lyrics.synced case final synced?)
          ConstrainedBox(
            // Bounded because this sits inside the now-playing screen's own
            // scroll view: an unbounded ListView there has no height to lay
            // itself out in.
            constraints: const BoxConstraints(maxHeight: 320),
            child: SyncedLyricsView(lyrics: synced),
          )
        else
          // Selectable, because the obvious thing to do with a line of
          // lyrics is copy it.
          SelectableText(
            lyrics.lines.join('\n'),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        if (lyrics.source != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.enrichmentLyricsSource(lyrics.source!),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
