import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';
import 'library_menu.dart';
import 'settings_menu.dart';

/// The shell's menu bar (FR-UX-01, FR-UX-02).
///
/// The library-wide menus across the top, above the rail and the content area.
/// A frame element in the sense the playback bar is: it does not know which
/// destination is showing and holds no feature logic, which is what keeps it
/// from becoming the file every later use case has to edit.
class ShellMenuBar extends StatelessWidget {
  /// Creates the bar.
  const ShellMenuBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showsLabels = Breakpoint.from(context) != Breakpoint.compact;

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
          ],
        ),
      ),
    );
  }
}
