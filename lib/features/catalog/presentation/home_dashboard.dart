import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../library_sources/presentation/library_sources_screen.dart';
import '../../playback/presentation/music_display_name.dart' show tagOr;
import '../../shell/presentation/async_state_view.dart';
import '../domain/file_details.dart';
import '../domain/music_metadata.dart';
import '../application/dashboard_controller.dart';
import '../application/in_progress.dart';
import '../domain/library_type.dart';
import 'catalog_search_view.dart';
import 'file_details_view.dart';

/// The home dashboard (UC-14, FR-CT-11).
///
/// Four sections, each loading and failing on its own. AF-03 is the reason
/// they are separate widgets rather than one query: a section whose query
/// failed shows its own failure and its own retry, and the rest of the
/// dashboard still renders.
///
/// The library-wide screens it used to link to at the bottom — collections,
/// deleted items, the missing-files review — are in the navigation panel's
/// tools menu now, reachable from every area rather than from this one below
/// four sections of content.
class HomeDashboard extends ConsumerWidget {
  /// Creates the dashboard.
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(typeCountsControllerProvider);

    // AF-01: nothing is cataloged, so the whole dashboard is the first-run
    // guidance — four empty sections would be four ways of saying the same
    // thing. Every type has to have actually been counted before this reads
    // as empty: `TypeCountsController` leaves a type out of the map rather
    // than counting it as zero when its listing fails, so a map shorter than
    // every type means "some of this could not be read", not "there is
    // nothing here" — vacuously true on an empty map is exactly the lie a
    // core outage would otherwise tell the owner.
    final catalogEmpty = counts.maybeWhen(
      data: (byType) =>
          byType.length == LibraryType.values.length &&
          byType.values.every((count) => count == 0),
      orElse: () => false,
    );
    if (catalogEmpty) return const _FirstRun();

    return ListView(
      children: const [
        _RecentSection(),
        SizedBox(height: AppSpacing.lg),
        _InProgressSection(),
        SizedBox(height: AppSpacing.lg),
        _CountsSection(),
        SizedBox(height: AppSpacing.lg),
        _LastRunSection(),
      ],
    );
  }
}

/// The recently added files (main flow step 2).
class _RecentSection extends ConsumerWidget {
  const _RecentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return _Section(
      title: l10n.dashboardRecent,
      child: SizedBox(
        height: 220,
        child: AsyncStateView<List<FileDetails>>(
          value: ref.watch(recentFilesProvider),
          onRetry: () => ref.read(recentFilesProvider.notifier).reload(),
          isEmpty: (rows) => rows.isEmpty,
          emptyBuilder: (context) => _Quiet(l10n.dashboardRecentNone),
          builder: (context, rows) => ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final details = rows[index];
              final file = details.file;
              // FR-CT-13: an audio file is named by its metadata here too,
              // read straight off the row this section already holds —
              // `catalogSearchProvider`'s own listing read carried it, so
              // naming it here asks nothing further of the core. Every other
              // type is still called by its own name.
              final title = file.type == LibraryType.audio
                  ? tagOr(
                      MusicMetadata.fromDetails(details.metadata).title,
                      l10n.musicUnknownTitle,
                    )
                  : file.name;

              return ListTile(
                dense: true,
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(title),
                subtitle: Text(file.type.label(l10n)),
                // Main flow step 4: opening an item here behaves exactly as
                // opening it from its listing, because it is the same view.
                onTap: () => FileDetailsView.show(context, ref, file.uuid),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// What the owner is part-way through (main flow step 2, FR-CT-11).
///
/// Watchlists and reading lists both answer it, merged into one section,
/// because the owner is in the middle of *things* rather than in the middle of
/// two features. AF-02 is the empty case: it is stated rather than rendered as
/// an empty box.
class _InProgressSection extends ConsumerWidget {
  const _InProgressSection();

  /// How many entries the dashboard shows.
  ///
  /// A glance rather than a listing, like the recent section above it: the
  /// lists themselves are one click away.
  static const int limit = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return _Section(
      title: l10n.dashboardInProgress,
      child: AsyncStateView<List<InProgressItem>>(
        value: ref.watch(inProgressProvider),
        onRetry: () => ref.read(inProgressProvider.notifier).reload(),
        isEmpty: (items) => items.isEmpty,
        emptyBuilder: (context) => _Quiet(l10n.dashboardInProgressNone),
        builder: (context, items) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in items.take(limit))
              ListTile(
                dense: true,
                leading: Icon(
                  item.unit == ProgressUnit.episodes
                      ? Icons.movie_outlined
                      : Icons.menu_book_outlined,
                ),
                title: Text(item.title),
                subtitle: Text(_where(item, l10n)),
                // Main flow step 4: opening an item here behaves exactly as
                // opening it from its listing, because it is the same view.
                onTap: () => FileDetailsView.show(context, ref, item.uuid),
              ),
          ],
        ),
      ),
    );
  }

  /// Which list the item is in, and how far through it the owner is.
  ///
  /// The position is folded into the same line rather than given a column of
  /// its own: a movie and a book have none, and a column that is empty for
  /// half the rows reads as missing data.
  String _where(InProgressItem item, AppLocalizations l10n) {
    final position = item.position;
    if (position == null) return l10n.dashboardInProgressIn(item.listName);

    final total = item.total;
    final progress = switch ((item.unit, total)) {
      (ProgressUnit.episodes, null) => l10n.watchEpisode(position),
      (ProgressUnit.episodes, final total?) => l10n.watchEpisodeOf(
        position,
        total,
      ),
      (ProgressUnit.issues, null) => l10n.readIssue(position),
      (ProgressUnit.issues, final total?) => l10n.readIssueOf(position, total),
    };

    return l10n.dashboardInProgressInAt(item.listName, progress);
  }
}

/// How much of each type the library holds (main flow step 2).
class _CountsSection extends ConsumerWidget {
  const _CountsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return _Section(
      title: l10n.dashboardCounts,
      child: AsyncStateView<Map<LibraryType, int>>(
        value: ref.watch(typeCountsControllerProvider),
        onRetry: () => ref.read(typeCountsControllerProvider.notifier).reload(),
        builder: (context, counts) => Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            for (final type in LibraryType.values)
              if (counts[type] case final count?)
                Chip(
                  label: Text('${type.label(l10n)}  $count'),
                  labelStyle: theme.textTheme.bodySmall,
                ),
          ],
        ),
      ),
    );
  }
}

/// What the most recent run did (main flow step 3).
class _LastRunSection extends ConsumerWidget {
  const _LastRunSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final runs = ref.watch(indexRunsControllerProvider);
    final summary = mostRecentRun(runs);

    return _Section(
      title: l10n.dashboardLastRun,
      // AF-04: a run in flight says so, and this rebuilds when it settles
      // because the run state is what it reads.
      child: _Quiet(summary.describe(l10n)),
    );
  }
}

/// The first-run guidance (AF-01).
class _FirstRun extends StatelessWidget {
  const _FirstRun();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: AppSpacing.xxl,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.catalogEmptyFirstRun,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => LibrarySourcesScreen.show(context),
              icon: const Icon(Icons.folder_outlined),
              label: Text(l10n.catalogEmptyAddFolder),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: AppSpacing.sm),
      child,
    ],
  );
}

/// A line of secondary text — a section that has nothing to show, said rather
/// than left blank (AF-02).
class _Quiet extends StatelessWidget {
  const _Quiet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
