import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/domain/catalog_search.dart';
import '../../catalog/presentation/catalog_search_view.dart';
import '../../catalog/presentation/home_dashboard.dart';
import '../../libraries/presentation/library_view.dart';
import '../../playback/presentation/player_bar.dart';
import '../../organization/presentation/bookmarks_view.dart';
import '../domain/shell_destination.dart';
import 'background_activity_strip.dart';
import 'shell_menu_bar.dart';
import 'shell_navigation_panel.dart';

/// The application shell (UC-38, FR-UX-01, FR-UX-02).
///
/// Three regions and nothing else: the menu bar across the top, the
/// navigation panel down the left, and the content area beside it, with the
/// indexing strip below them while a scan runs. Everything the owner does
/// happens inside the content area, which is why this widget stays this
/// small — it is a frame, and a frame that grew feature logic would be the
/// thing every later use case has to edit.
class ShellScreen extends ConsumerWidget {
  /// Creates the shell.
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destination = ref.watch(shellControllerProvider);

    return Scaffold(
      body: Column(
        children: [
          // FR-UX-01: the library-wide menus, above everything the destination
          // owns.
          const ShellMenuBar(),
          const Divider(height: 1, thickness: 1),
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
          // The music playing, under whatever the owner is browsing
          // (libraries-only design §6). No height when nothing is loaded.
          const PlayerBar(),
          // FR-LB-15: whatever the core is indexing, below everything else.
          // It takes no height when nothing is running, so the shell is
          // unchanged for anyone not indexing.
          const BackgroundActivityStrip(),
        ],
      ),
    );
  }
}

/// The content area (FR-UX-01).
///
/// Home is the dashboard (UC-14), bookmarks are the bookmark manager (UC-28),
/// and a library is its folders (library navigation design §4).
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

    // Read from the list the left menu shows rather than kept on the
    // destination, so a rename reaches the heading the moment the list
    // reloads. A library the list does not hold yet has no name to show; one
    // it no longer holds sends the shell home (`ShellController`).
    final library = switch (destination) {
      LibraryDestination(:final uuid) =>
        ref
            .watch(librariesControllerProvider)
            .value
            ?.where((library) => library.uuid == uuid)
            .firstOrNull,
      _ => null,
    };

    final heading = switch (destination) {
      HomeDestination() => l10n.destinationHome,
      BookmarksDestination() => l10n.destinationBookmarks,
      LibraryDestination() => library?.name ?? '',
    };

    // A library draws its own heading, with its toggles and menu beside the
    // name; the shell's would say the name twice. A search over it still
    // needs the shell's, to say where the owner is.
    final headed = searching || destination is! LibraryDestination;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headed) ...[
            Text(heading, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
          ],
          Expanded(
            child: switch (destination) {
              // AF-02 needs nothing of its own: an empty term is not a search,
              // and the listing is already what an absent search shows.
              // FR-CT-06 matches file names and file metadata, and bookmarks
              // are not files: the field is withheld there (see
              // `ShellMenuBar`), so a term left over from another area must
              // not replace the bookmarks with matching files either.
              _ when searching && destination is! BookmarksDestination =>
                const CatalogSearchResults(),
              HomeDestination() => const HomeDashboard(),
              BookmarksDestination() => const BookmarksView(),
              LibraryDestination(:final uuid) => LibraryView(uuid: uuid),
            },
          ),
        ],
      ),
    );
  }
}
