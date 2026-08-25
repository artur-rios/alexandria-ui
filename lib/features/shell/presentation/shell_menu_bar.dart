import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';
import '../../catalog/presentation/catalog_search_view.dart';
import '../domain/shell_destination.dart';
import 'library_menu.dart';
import 'settings_menu.dart';

/// The shell's menu bar (FR-UX-01, FR-UX-02).
///
/// The library-wide menus across the top, above the rail and the content area.
/// A frame element in the sense the playback bar is: it does not know which
/// destination is showing beyond what it needs to decide whether the catalog
/// search belongs there, and it holds no feature logic of its own, which is
/// what keeps it from becoming the file every later use case has to edit.
class ShellMenuBar extends ConsumerWidget {
  /// Creates the bar.
  const ShellMenuBar({super.key});

  /// The widest the search field is drawn where the bar has room to spare.
  ///
  /// A field that grew with the window would put a single-word search term in
  /// the middle of a thousand pixels of empty input.
  static const double _searchWidth = 360;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final showsLabels = Breakpoint.from(context) != Breakpoint.compact;

    // UC-11 searches every type at once, which is why the field belongs to the
    // frame rather than to whichever listing is showing. Bookmarks are the one
    // area that holds no files, and so the one area with nothing to answer.
    final searchable =
        ref.watch(shellControllerProvider) != ShellDestination.bookmarks;

    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            MenuBar(
              // A `MenuBar` paints its own surface and elevation, which inside
              // a bar that already has one would be a raised strip drawn on a
              // raised strip. Zero alpha rather than `Colors.transparent`:
              // BR-18 keeps every color literal out of the widget tree, and a
              // fully faded theme color reads exactly the same as one.
              style: MenuStyle(
                backgroundColor: WidgetStatePropertyAll(
                  theme.colorScheme.surfaceContainer.withValues(alpha: 0),
                ),
                elevation: const WidgetStatePropertyAll(0),
                padding: const WidgetStatePropertyAll(EdgeInsets.zero),
              ),
              children: [
                LibraryMenu(showsLabel: showsLabels),
                SettingsMenu(showsLabel: showsLabels),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            if (searchable)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    // At the compact tier the field takes what the collapsed
                    // menus left rather than a fixed width, which is the
                    // width that is actually there.
                    constraints: const BoxConstraints(maxWidth: _searchWidth),
                    child: const CatalogSearchField(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
