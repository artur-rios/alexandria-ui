import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// One entry in a menu-bar menu.
class MenuEntry extends StatelessWidget {
  /// Creates an entry.
  const MenuEntry({
    required this.icon,
    required this.label,
    required this.onSelected,
    super.key,
  });

  /// The glyph beside the label.
  final IconData icon;

  /// What the entry is called.
  final String label;

  /// What choosing it does.
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => MenuItemButton(
    leadingIcon: Icon(icon),
    onPressed: onSelected,
    child: Text(label),
  );
}

/// A heading over a group of entries.
///
/// Not a `MenuItemButton`: a heading names a group, it does not open one, and
/// giving it the same hoverable, focusable treatment as the entries below it
/// would invite a tap that does nothing.
class MenuGroupHeading extends StatelessWidget {
  /// Creates a heading.
  const MenuGroupHeading(this.text, {super.key});

  /// The group's name.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
