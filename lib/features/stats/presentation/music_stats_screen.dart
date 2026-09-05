import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shell/presentation/async_state_view.dart';
import '../domain/music_stats.dart';

/// What the owner has played most (play history design).
///
/// A dialog over whatever reached it, the shape every library-wide screen
/// uses: what was played belongs to no single file type, so it is not a
/// destination of its own (FR-CT-01).
class MusicStatsScreen extends ConsumerWidget {
  /// Creates the screen.
  const MusicStatsScreen({super.key});

  /// Presents the screen over [context].
  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => const Dialog.fullscreen(child: MusicStatsScreen()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stats = ref.watch(musicStatsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.musicStatsTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.preferencesClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: l10n.musicStatsRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: ref.read(musicStatsControllerProvider.notifier).reload,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AsyncStateView(
          value: stats,
          onRetry: ref.read(musicStatsControllerProvider.notifier).reload,
          // Null is the no-session case the controller answers with, and
          // reads the same as nothing played: there is no chart either way.
          isEmpty: (stats) => stats == null || stats.isEmpty,
          emptyBuilder: (context) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _proseWidth),
              child: Text(
                l10n.musicStatsNone,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          builder: (context, stats) => _Rankings(stats: stats!),
        ),
      ),
    );
  }

  /// How wide a paragraph is allowed to get before it stops being readable.
  static const double _proseWidth = 480;
}

/// The summary, then the four rankings.
class _Rankings extends StatelessWidget {
  const _Rankings({required this.stats});

  final MusicStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dates = MaterialLocalizations.of(context);
    final first = stats.firstPlayedAt;
    final last = stats.lastPlayedAt;

    return ListView(
      children: [
        Text(
          l10n.musicStatsSummary(stats.totalPlays, stats.distinctTracks),
          style: theme.textTheme.titleMedium,
        ),
        // Both ends, or neither: the core answers them together, and a period
        // with one end is not a period.
        //
        // `toLocal` on each: the core stamps a play in UTC, and a date drawn
        // from UTC fields is the wrong day for anyone whose evening is the
        // next day in Greenwich. The period an owner reads is in their own
        // calendar.
        if (first != null && last != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              l10n.musicStatsPeriod(
                dates.formatMediumDate(first.toLocal()),
                dates.formatMediumDate(last.toLocal()),
              ),
              style: theme.textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: AppSpacing.lg),

        _Ranking(
          heading: l10n.musicStatsTopTracks,
          icon: Icons.music_note_outlined,
          rows: [
            for (final track in stats.topTracks)
              _Row(
                // Never empty: the core substitutes the filename for a track
                // that nothing tagged.
                title: track.title,
                // Both, when both are known, because "Intro" by itself names
                // a hundred different tracks.
                subtitle: [
                  ?track.artist,
                  ?track.album,
                ].join(' — '),
                trailing: l10n.musicStatsPlays(track.plays),
              ),
          ],
        ),
        _Ranking(
          heading: l10n.musicStatsTopArtists,
          icon: Icons.person_outline,
          rows: [
            for (final artist in stats.topArtists)
              _Row(
                title: artist.artist,
                subtitle: l10n.musicStatsArtistTracks(artist.tracks),
                trailing: l10n.musicStatsPlays(artist.plays),
              ),
          ],
        ),
        _Ranking(
          heading: l10n.musicStatsTopAlbums,
          icon: Icons.album_outlined,
          rows: [
            for (final album in stats.topAlbums)
              _Row(
                title: album.album,
                // Empty for a compilation whose tracks name different
                // artists: there is no single answer, and the row says
                // nothing rather than picking one of them.
                subtitle: album.artist ?? '',
                trailing: l10n.musicStatsPlays(album.plays),
              ),
          ],
        ),
        _Ranking(
          heading: l10n.musicStatsTopGenres,
          icon: Icons.label_outline,
          rows: [
            for (final genre in stats.topGenres)
              _Row(
                title: genre.genre,
                subtitle: '',
                trailing: l10n.musicStatsPlays(genre.plays),
              ),
          ],
        ),

        // Said once, at the bottom, where an owner who noticed the artist
        // list is shorter than the totals goes looking for why.
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Text(
            l10n.musicStatsUntaggedNote,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// One ranking, with its heading.
///
/// Drawn even when it is empty — as an untagged library's artist ranking is
/// — because a heading with nothing under it says the ranking exists and has
/// nothing in it, where dropping it entirely says the application forgot
/// about artists.
class _Ranking extends StatelessWidget {
  const _Ranking({
    required this.heading,
    required this.icon,
    required this.rows,
  });

  final String heading;
  final IconData icon;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(heading, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          for (final (index, row) in rows.indexed)
            ListTile(
              dense: true,
              leading: _Position(position: index + 1, icon: icon),
              title: Text(row.title),
              subtitle: row.subtitle.isEmpty ? null : Text(row.subtitle),
              trailing: Text(row.trailing, style: theme.textTheme.labelLarge),
            ),
        ],
      ),
    );
  }
}

/// Where a row sits in its ranking.
///
/// The number rather than the icon alone: the list is ordered, and a reader
/// who has scrolled past the heading has nothing else to tell the third from
/// the fourth.
class _Position extends StatelessWidget {
  const _Position({required this.position, required this.icon});

  final int position;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: _width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _iconSize, color: theme.colorScheme.outline),
          const SizedBox(width: AppSpacing.xs),
          Text('$position', style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }

  static const double _width = 48;
  static const double _iconSize = 18;
}

/// One line of a ranking, as text — the rankings differ in what they name,
/// not in how a row is drawn.
class _Row {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;
}
