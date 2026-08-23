import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../lifecycle/presentation/deleted_items_screen.dart';
import '../../lifecycle/presentation/missing_files_screen.dart';
import '../../library_sources/presentation/library_sources_screen.dart';
import '../../organization/presentation/collections_screen.dart';
import '../../tracking/presentation/reading_lists_screen.dart';
import '../../tracking/presentation/watchlists_screen.dart';
import 'rail_action.dart';

/// The library-wide areas, reached from the navigation panel (UC-37 main flow
/// step 1, FR-UX-01).
///
/// Six screens that belong to no single file type — sources, collections,
/// watchlists, reading lists, deleted items, and the missing-files review — and
/// so are not destinations of their own (FR-CT-01). Before this they were each
/// reachable from exactly one place: three from the bottom of the dashboard,
/// two from the listing of the type they happen to track, and one from inside
/// preferences. That made them findable only by an owner who already knew
/// where to look.
///
/// A menu rather than six more entries in the rail: at the minimum supported
/// window the panel is already nine destinations tall in 640 pixels
/// (`NFR-07`), and six more would turn a panel that adapts into one the owner
/// scrolls. A labelled trigger and six labelled entries, the same at every
/// breakpoint — and three headings inside the menu, because a single icon
/// hiding six unrelated screens was itself unreadable: nothing about it told
/// the owner what was behind it before they opened it.
class LibraryToolsButton extends StatelessWidget {
  /// Creates the button.
  const LibraryToolsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return MenuAnchor(
      builder: (context, controller, child) => RailAction(
        icon: Icons.widgets_outlined,
        label: l10n.libraryToolsLabel,
        showsDisclosure: true,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: [
        // Three headings turn one unlabelled icon hiding six unrelated
        // screens into a menu whose contents can be told apart at a glance —
        // the complaint this menu drew once it stopped being new. The order
        // beneath each heading is unchanged: it runs from filling the
        // library to reviewing what has left it, and the headings only name
        // the stretches that order already falls into.
        _GroupHeading(l10n.libraryToolsGroupLibrary),
        _ToolItem(
          icon: Icons.folder_outlined,
          label: l10n.librarySourcesOpen,
          onSelected: () => LibrarySourcesScreen.show(context),
        ),
        _ToolItem(
          icon: Icons.collections_bookmark_outlined,
          label: l10n.collectionsOpen,
          onSelected: () => CollectionsScreen.show(context),
        ),
        _GroupHeading(l10n.libraryToolsGroupTracking),
        _ToolItem(
          icon: Icons.playlist_play,
          label: l10n.watchlistsOpen,
          onSelected: () => WatchlistsScreen.show(context),
        ),
        _ToolItem(
          icon: Icons.library_books_outlined,
          label: l10n.readingListsOpen,
          onSelected: () => ReadingListsScreen.show(context),
        ),
        _GroupHeading(l10n.libraryToolsGroupReview),
        _ToolItem(
          icon: Icons.delete_outline,
          label: l10n.deletedItemsOpen,
          onSelected: () => DeletedItemsScreen.show(context),
        ),
        _ToolItem(
          icon: Icons.help_outline,
          label: l10n.missingFilesOpen,
          onSelected: () => MissingFilesScreen.show(context),
        ),
      ],
    );
  }
}

/// One entry in the tools menu.
class _ToolItem extends StatelessWidget {
  const _ToolItem({
    required this.icon,
    required this.label,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => MenuItemButton(
    leadingIcon: Icon(icon),
    onPressed: onSelected,
    child: Text(label),
  );
}

/// A heading over one of the tools menu's three groups.
///
/// Not a `MenuItemButton`: a heading names a group, it does not open one, and
/// giving it the same hoverable, focusable treatment as the entries below it
/// would invite a tap that does nothing.
class _GroupHeading extends StatelessWidget {
  const _GroupHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.sm,
      AppSpacing.md,
      AppSpacing.xs,
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
