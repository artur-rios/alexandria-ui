import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/domain/library_type.dart';
import '../../catalog/domain/catalog_search.dart';
import '../../catalog/presentation/catalog_listing.dart';
import '../../catalog/presentation/catalog_search_view.dart';
import '../../catalog/presentation/home_dashboard.dart';
import '../domain/shell_destination.dart';
import 'playback_bar.dart';
import 'shell_navigation_panel.dart';

/// The application shell (UC-38, FR-UX-01, FR-UX-02).
///
/// Three regions and nothing else: the navigation panel down the left, the
/// content area beside it, and the playback bar across the bottom. Everything
/// the owner does happens inside the content area, which is why this widget
/// stays this small — it is a frame, and a frame that grew feature logic would
/// be the thing every later use case has to edit.
class ShellScreen extends ConsumerWidget {
  /// Creates the shell.
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destination = ref.watch(shellControllerProvider);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                ShellNavigationPanel(
                  selected: destination,
                  onSelected: ref.read(shellControllerProvider.notifier).go,
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: ShellContentArea(destination: destination)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          const PlaybackBar(),
        ],
      ),
    );
  }
}

/// The content area (FR-UX-01).
///
/// A file type shows its listing (UC-09). Home is still the dashboard's seam
/// (UC-14) and bookmarks are still the bookmark manager's (UC-28) — neither is
/// a file listing, and building either now would be building it without its
/// specification.
class ShellContentArea extends ConsumerWidget {
  /// Creates the content area for [destination].
  const ShellContentArea({required this.destination, super.key});

  /// Which area is shown.
  final ShellDestination destination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // UC-11: the search is across every type at once, so it belongs to the
    // shell rather than to any one listing — and while a term is present, the
    // results are what the content area shows.
    final searching = isSearchable(ref.watch(searchTermProvider));

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(destination.label(l10n), style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          const CatalogSearchField(),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: switch ((searching, libraryTypeFor(destination))) {
              // AF-02 needs nothing of its own: an empty term is not a search,
              // and the listing is already what an absent search shows.
              (true, _) => const CatalogSearchResults(),
              // Home is the dashboard UC-14 builds; bookmarks are still
              // UC-28's seam.
              (false, null) when destination == ShellDestination.home =>
                const HomeDashboard(),
              (false, null) => Center(
                child: Text(
                  l10n.shellAreaPending,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              (false, _) => const CatalogListing(),
            },
          ),
        ],
      ),
    );
  }
}
