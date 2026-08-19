import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/breakpoints.dart';
import '../domain/shell_destination.dart';

/// The navigation panel (FR-UX-01, FR-UX-02).
///
/// It collapses rather than hides: at the minimum supported window it is a
/// rail of icons with tooltips, and at the wider tiers the same entries carry
/// their labels. No entry is ever dropped, which is the distinction
/// FR-UX-02 draws between adapting and clipping.
class ShellNavigationPanel extends StatelessWidget {
  /// Creates the panel.
  const ShellNavigationPanel({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// The destination currently shown.
  final ShellDestination selected;

  /// Called when the owner picks a destination.
  final ValueChanged<ShellDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final breakpoint = Breakpoint.from(context);

    // The breakpoints are widths, and a window can be wide and short: at the
    // medium tier the ten labelled entries need more height than a 640-pixel
    // window has. Scrolling is how the panel keeps every entry reachable there
    // — FR-UX-02 forbids clipping one, not making it scroll to. The
    // constrained intrinsic height is what lets the rail still fill a tall
    // window, which a bare scroll view would collapse.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: NavigationRail(
              selectedIndex: ShellDestination.values.indexOf(selected),
              onDestinationSelected: (index) =>
                  onSelected(ShellDestination.values[index]),
              // Labels at every tier but the narrowest, where the icons carry
              // tooltips instead. `all` rather than `selected`, because a rail
              // that labels only the current entry makes the other nine
              // unreadable at a glance for no space saved.
              labelType: breakpoint.showsNavigationLabels
                  ? NavigationRailLabelType.all
                  : NavigationRailLabelType.none,
              groupAlignment: -1,
              destinations: [
                for (final destination in ShellDestination.values)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label(l10n)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// How each destination presents itself.
///
/// An extension in the presentation layer rather than fields on the enum: an
/// icon and a localized label are what this destination *looks like*, and the
/// domain has no business holding either.
extension ShellDestinationPresentation on ShellDestination {
  /// The icon in the navigation panel.
  IconData get icon => switch (this) {
    ShellDestination.home => Icons.home_outlined,
    ShellDestination.music => Icons.library_music_outlined,
    ShellDestination.movies => Icons.movie_outlined,
    ShellDestination.series => Icons.live_tv_outlined,
    ShellDestination.books => Icons.menu_book_outlined,
    ShellDestination.comicBooks => Icons.auto_stories_outlined,
    ShellDestination.notes => Icons.description_outlined,
    ShellDestination.pages => Icons.public_outlined,
    ShellDestination.images => Icons.image_outlined,
    ShellDestination.bookmarks => Icons.bookmark_outline,
  };

  /// The icon shown for the selected destination.
  IconData get selectedIcon => switch (this) {
    ShellDestination.home => Icons.home,
    ShellDestination.music => Icons.library_music,
    ShellDestination.movies => Icons.movie,
    ShellDestination.series => Icons.live_tv,
    ShellDestination.books => Icons.menu_book,
    ShellDestination.comicBooks => Icons.auto_stories,
    ShellDestination.notes => Icons.description,
    ShellDestination.pages => Icons.public,
    ShellDestination.images => Icons.image,
    ShellDestination.bookmarks => Icons.bookmark,
  };

  /// The localized label, in the panel and as the content area's heading.
  String label(AppLocalizations l10n) => switch (this) {
    ShellDestination.home => l10n.destinationHome,
    ShellDestination.music => l10n.destinationMusic,
    ShellDestination.movies => l10n.destinationMovies,
    ShellDestination.series => l10n.destinationSeries,
    ShellDestination.books => l10n.destinationBooks,
    ShellDestination.comicBooks => l10n.destinationComicBooks,
    ShellDestination.notes => l10n.destinationNotes,
    ShellDestination.pages => l10n.destinationPages,
    ShellDestination.images => l10n.destinationImages,
    ShellDestination.bookmarks => l10n.destinationBookmarks,
  };
}
