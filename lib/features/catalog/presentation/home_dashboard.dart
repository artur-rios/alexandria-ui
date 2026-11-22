import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../libraries/domain/catalog_stats.dart';
import '../../libraries/domain/library.dart';
import '../../libraries/presentation/libraries_view.dart';
import '../../libraries/presentation/library_run_status.dart';
import '../../shell/domain/shell_destination.dart';
import '../../shell/presentation/async_state_view.dart';
import '../domain/file_type.dart';
import 'catalog_search_view.dart';

/// The home screen (libraries design §6).
///
/// Two sections, each loading and failing on its own: the favorite libraries,
/// and the totals. A section whose query failed shows its own failure and its
/// own retry while the other still renders, and a total that could not be
/// counted is never shown as a zero.
///
/// The library-wide screens it used to link to — collections, deleted items,
/// the missing-files review — are in the navigation panel's tools menu.
class HomeDashboard extends ConsumerWidget {
  /// Creates the dashboard.
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // First run: no libraries at all. Only a list that loaded and is empty
    // says so — while it loads, or when it failed, nothing is known about
    // what is registered, and guidance to add one would be a lie.
    final libraries = ref.watch(librariesControllerProvider);
    if (libraries case AsyncData(:final value) when value.isEmpty) {
      return const _FirstRun();
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: const [
        _FavoritesSection(),
        SizedBox(height: AppSpacing.lg),
        _StatisticsSection(),
      ],
    );
  }
}

/// The libraries marked as favorites, A–Z, as cards.
class _FavoritesSection extends ConsumerWidget {
  const _FavoritesSection();

  /// The width of a card; the cards wrap into as many columns as fit.
  static const double cardWidth = 280;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return _Section(
      title: l10n.homeFavorites,
      child: AsyncStateView<List<Library>>(
        value: ref.watch(librariesControllerProvider),
        onRetry: () => ref.read(librariesControllerProvider.notifier).reload(),
        builder: (context, libraries) {
          final favorites = [
            for (final library in libraries)
              if (library.favorite) library,
          ]..sort(_byName);

          if (favorites.isEmpty) return _Quiet(l10n.homeFavoritesNone);

          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final library in favorites)
                SizedBox(
                  width: cardWidth,
                  child: _LibraryCard(library: library),
                ),
            ],
          );
        },
      ),
    );
  }

  /// The menu's own comparison — case-insensitive, then by uuid — so the two
  /// agree on the order.
  static int _byName(Library a, Library b) {
    final order = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return order != 0 ? order : a.uuid.compareTo(b.uuid);
  }
}

class _LibraryCard extends ConsumerWidget {
  const _LibraryCard({required this.library});

  final Library library;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => ref
                .read(shellControllerProvider.notifier)
                .go(LibraryDestination(library.uuid)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    library.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    library.rootPath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          LibraryRunStatus(library: library),
        ],
      ),
    );
  }
}

/// The totals: how many libraries, and how many files of each type.
class _StatisticsSection extends ConsumerWidget {
  const _StatisticsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return _Section(
      title: l10n.homeStatistics,
      child: AsyncStateView<CatalogStats>(
        value: ref.watch(catalogStatsProvider),
        onRetry: () => ref.read(catalogStatsProvider.notifier).reload(),
        builder: (context, stats) => ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeLibraryCount(stats.libraries),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final type in FileType.values)
                Padding(
                  key: ValueKey('home-stat-${type.wireName}'),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(child: Text(type.label(l10n))),
                      Text('${stats.filesByType[type] ?? 0}'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The first-run guidance (AF-01).
class _FirstRun extends ConsumerWidget {
  const _FirstRun();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              onPressed: () => openLibrariesAndAdd(context, ref),
              icon: const Icon(Icons.folder_outlined),
              label: Text(l10n.libraryAdd),
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
