import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../lifecycle/presentation/deleted_items_screen.dart';
import '../../lifecycle/presentation/missing_files_screen.dart';
import '../../library_sources/presentation/library_sources_screen.dart';
import '../../organization/presentation/collections_screen.dart';
import '../../enrichment/presentation/enrichment_sweep_screen.dart';
import '../../playlists/presentation/playlists_screen.dart';
import '../../tracking/presentation/reading_lists_screen.dart';
import '../../tracking/presentation/watchlists_screen.dart';
import 'menu_entry.dart';

/// The library-wide areas, reached from the menu bar (UC-37 main flow step 1,
/// FR-UX-01).
///
/// Seven screens that belong to no single file type — sources, collections,
/// watchlists, reading lists, playlists, deleted items, and the missing-files
/// review — and so are not destinations of their own (FR-CT-01). They were
/// reached from the bottom of the navigation rail, below a divider that was
/// the only thing saying they were not destinations; a menu bar says it by
/// construction.
///
/// Three headings inside, because a menu holding seven unrelated screens
/// cannot be read at a glance without them. The order beneath each runs from
/// filling the library to reviewing what has left it.
class LibraryMenu extends StatelessWidget {
  /// Creates the menu.
  const LibraryMenu({required this.showsLabel, super.key});

  /// Whether the trigger carries its label beside its icon.
  ///
  /// False at the compact tier, where the bar has room for the icon and the
  /// search field but not for both menu labels as well (FR-UX-02).
  final bool showsLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final button = SubmenuButton(
      leadingIcon: const Icon(Icons.widgets_outlined),
      menuChildren: [
        MenuGroupHeading(l10n.libraryToolsGroupLibrary),
        MenuEntry(
          icon: Icons.folder_outlined,
          label: l10n.librarySourcesOpen,
          onSelected: () => LibrarySourcesScreen.show(context),
        ),
        MenuEntry(
          icon: Icons.collections_bookmark_outlined,
          label: l10n.collectionsOpen,
          onSelected: () => CollectionsScreen.show(context),
        ),
        MenuGroupHeading(l10n.libraryToolsGroupTracking),
        MenuEntry(
          icon: Icons.playlist_play,
          label: l10n.watchlistsOpen,
          onSelected: () => WatchlistsScreen.show(context),
        ),
        MenuEntry(
          icon: Icons.library_books_outlined,
          label: l10n.readingListsOpen,
          onSelected: () => ReadingListsScreen.show(context),
        ),
        MenuEntry(
          icon: Icons.queue_music_outlined,
          label: l10n.playlistsOpen,
          onSelected: () => PlaylistsScreen.show(context),
        ),
        MenuEntry(
          icon: Icons.travel_explore_outlined,
          label: l10n.enrichmentSweepOpen,
          onSelected: () => EnrichmentSweepScreen.show(context),
        ),
        MenuGroupHeading(l10n.libraryToolsGroupReview),
        MenuEntry(
          icon: Icons.delete_outline,
          label: l10n.deletedItemsOpen,
          onSelected: () => DeletedItemsScreen.show(context),
        ),
        MenuEntry(
          icon: Icons.help_outline,
          label: l10n.missingFilesOpen,
          onSelected: () => MissingFilesScreen.show(context),
        ),
      ],
      child: showsLabel ? Text(l10n.libraryToolsLabel) : const SizedBox.shrink(),
    );

    if (showsLabel) return button;

    // The tooltip has to wrap the whole trigger, not sit on its shrunk
    // child: SubmenuButton lays `leadingIcon` and `child` side by side, so a
    // tooltip anchored to a zero-height child alone would cover a sliver
    // beside the icon that a pointer can never actually land on, and the
    // name it carries could never be revealed (FR-UX-02).
    return Tooltip(message: l10n.libraryToolsLabel, child: button);
  }
}
