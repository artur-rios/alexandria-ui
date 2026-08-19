import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../library_sources/presentation/library_sources_screen.dart';
import '../../shell/presentation/async_state_view.dart';
import '../domain/catalog_file.dart';
import '../application/dashboard_controller.dart';
import '../domain/library_type.dart';
import 'catalog_search_view.dart';
import 'file_details_view.dart';

/// The home dashboard (UC-14, FR-CT-11).
///
/// Four sections, each loading and failing on its own. AF-03 is the reason
/// they are separate widgets rather than one query: a section whose query
/// failed shows its own failure and its own retry, and the rest of the
/// dashboard still renders.
class HomeDashboard extends ConsumerWidget {
  /// Creates the dashboard.
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(typeCountsControllerProvider);

    // AF-01: nothing is cataloged, so the whole dashboard is the first-run
    // guidance — four empty sections would be four ways of saying the same
    // thing.
    final catalogEmpty = counts.maybeWhen(
      data: (byType) => byType.values.every((count) => count == 0),
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
        child: AsyncStateView<List<CatalogFile>>(
          value: ref.watch(recentFilesProvider),
          onRetry: () => ref.read(recentFilesProvider.notifier).reload(),
          isEmpty: (files) => files.isEmpty,
          emptyBuilder: (context) => _Quiet(l10n.dashboardRecentNone),
          builder: (context, files) => ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];

              return ListTile(
                dense: true,
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(file.name),
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

/// What the owner is part-way through (main flow step 2).
///
/// Watchlists and reading lists are M-09's, so nothing is ever in progress
/// yet — which is precisely the state AF-02 describes, and it is stated
/// rather than rendered as an empty box.
class _InProgressSection extends StatelessWidget {
  const _InProgressSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return _Section(
      title: l10n.dashboardInProgress,
      child: _Quiet(l10n.dashboardInProgressNone),
    );
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
