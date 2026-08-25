import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';
import '../../catalog/domain/library_type.dart';
import '../domain/shell_destination.dart';
import 'preferences_dialog.dart';
import 'rail_action.dart';

/// The navigation panel (FR-UX-01, FR-UX-02).
///
/// It collapses rather than hides: at the minimum supported window it is a
/// rail of icons with tooltips, and at the wider tiers the same entries carry
/// their labels. No entry is ever dropped, which is the distinction
/// FR-UX-02 draws between adapting and clipping.
class ShellNavigationPanel extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final breakpoint = Breakpoint.from(context);
    // FR-CT-01 wants a count beside each type. A type whose query failed has
    // no entry here and so shows no number, rather than a zero that would read
    // as "nothing here".
    final counts = ref
        .watch(typeCountsControllerProvider)
        .maybeWhen(data: (byType) => byType, orElse: () => null);

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
              // Three tiers, three arrangements: icons with tooltips at the
              // narrowest, labels beneath them at the medium one, and labels
              // beside them once there is room. `all` rather than `selected`,
              // because a rail that labels only the current entry makes the
              // other eight unreadable at a glance for no space saved.
              //
              // An extended rail carries its labels itself, and Material
              // requires the label type be `none` when it does.
              extended: breakpoint.usesExtendedNavigation,
              labelType:
                  breakpoint.showsNavigationLabels &&
                      !breakpoint.usesExtendedNavigation
                  ? NavigationRailLabelType.all
                  : NavigationRailLabelType.none,
              groupAlignment: -1,
              // The library tools and preferences sit below the destinations
              // rather than among them: neither is an area of the library
              // (FR-CT-01), and UC-39 reaches preferences from here and from
              // the authentication screens alike. The tools menu is what makes
              // the library-wide screens — sources, collections, watchlists,
              // reading lists, deleted items, and the missing-files review
              // (UC-37 step 1) — reachable from wherever the owner is.
              //
              // Placed in the flow after the destinations rather than pinned
              // to the bottom with an Expanded: the rail already sits inside a
              // scroll view with an intrinsic height, and an unbounded child
              // in that arrangement is a layout error at the short windows
              // UC-38 added the scrolling for.
              trailing: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                // `IntrinsicWidth` rather than a bare `Column`: the rail sits
                // inside a scroll view with an intrinsic height (UC-38), so
                // this subtree's incoming width is unbounded — which is fine
                // for the column itself but leaves a `Divider` with no width
                // to stretch to, since it has none of its own. Measuring the
                // actions' intrinsic width first gives the divider something
                // concrete to fill.
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // A divider rather than just the extra spacing above:
                      // these two are actions, not destinations, and the
                      // line is what tells the eye that before it stops
                      // mattering.
                      const Divider(),
                      RailAction(
                        icon: Icons.settings_outlined,
                        label: l10n.preferencesLabel,
                        onPressed: () => PreferencesDialog.show(context),
                      ),
                    ],
                  ),
                ),
              ),
              destinations: [
                for (final destination in ShellDestination.values)
                  NavigationRailDestination(
                    icon: _CountedIcon(
                      icon: destination.icon,
                      count: counts?[libraryTypeFor(destination)],
                    ),
                    selectedIcon: _CountedIcon(
                      icon: destination.selectedIcon,
                      count: counts?[libraryTypeFor(destination)],
                    ),
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

/// A destination's icon, with its item count when there is one (FR-CT-01).
///
/// A badge rather than a number in the label, because the panel collapses to
/// icons at the minimum window (FR-UX-02) and the count has to survive that.
class _CountedIcon extends StatelessWidget {
  const _CountedIcon({required this.icon, this.count});

  final IconData icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final value = count;
    if (value == null || value == 0) return Icon(icon);

    final theme = Theme.of(context);

    // Not the badge's default colouring, which is the error one: a count is
    // how much is there, and drawing it in the same red as a failure makes a
    // stocked library look like a list of problems.
    return Badge.count(
      count: value,
      backgroundColor: theme.colorScheme.secondaryContainer,
      textColor: theme.colorScheme.onSecondaryContainer,
      child: Icon(icon),
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
    ShellDestination.videos => Icons.movie_outlined,
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
    ShellDestination.videos => Icons.movie,
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
    ShellDestination.videos => l10n.destinationVideos,
    ShellDestination.books => l10n.destinationBooks,
    ShellDestination.comicBooks => l10n.destinationComicBooks,
    ShellDestination.notes => l10n.destinationNotes,
    ShellDestination.pages => l10n.destinationPages,
    ShellDestination.images => l10n.destinationImages,
    ShellDestination.bookmarks => l10n.destinationBookmarks,
  };
}
