import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';

/// An action beside the navigation panel's destinations — library tools and
/// preferences, in `ShellNavigationPanel.trailing`.
///
/// `NavigationRailDestination` renders one of three arrangements depending on
/// [Breakpoint.from]: an icon with a tooltip at the minimum window, an icon
/// above a label once there is room for one, and an icon beside a label at
/// the widest tier. Before this, the two actions below the destinations were
/// bare `IconButton`s that stayed icon-only at every width, which is what
/// made them read as a lesser class of control sitting in a column of nine
/// labelled entries — not because they are destinations in disguise (they are
/// deliberately not: FR-CT-01 keeps library-wide tools out of the
/// destination list), but because nothing about how they looked said "this is
/// the same kind of thing as the rest of the rail". `RailAction` mirrors the
/// destinations' own three tiers, unselectable, so the two controls read as
/// actions beside the rail rather than an afterthought bolted onto it.
class RailAction extends StatelessWidget {
  /// Creates the action.
  const RailAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.showsDisclosure = false,
    super.key,
  });

  /// The action's icon, drawn the same size and weight as a destination's.
  final IconData icon;

  /// The action's name. A tooltip at the narrowest tier, visible text at the
  /// other two — never dropped, which is what keeps this consistent with
  /// FR-UX-02's promise for the destinations beside it.
  final String label;

  /// Called when the action is chosen.
  final VoidCallback onPressed;

  /// Whether a trailing chevron marks this as opening a menu rather than
  /// acting immediately. Only the library tools action sets this.
  final bool showsDisclosure;

  @override
  Widget build(BuildContext context) {
    final breakpoint = Breakpoint.from(context);

    // The minimum window: the destinations beside this are icon-only with a
    // tooltip standing in for the label, so this matches rather than being
    // the one entry in the rail that still carries visible text.
    if (!breakpoint.showsNavigationLabels) {
      return Tooltip(
        message: label,
        child: IconButton(icon: Icon(icon), onPressed: onPressed),
      );
    }

    final child = breakpoint.usesExtendedNavigation
        ? _ExtendedContent(
            icon: icon,
            label: label,
            showsDisclosure: showsDisclosure,
          )
        : _LabelledContent(
            icon: icon,
            label: label,
            showsDisclosure: showsDisclosure,
          );

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: breakpoint.usesExtendedNavigation
            ? const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              )
            : const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: child,
      ),
    );
  }
}

/// The medium tier's arrangement: icon above label, matching
/// `NavigationRailLabelType.all`.
class _LabelledContent extends StatelessWidget {
  const _LabelledContent({
    required this.icon,
    required this.label,
    required this.showsDisclosure,
  });

  final IconData icon;
  final String label;
  final bool showsDisclosure;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          if (showsDisclosure) const Icon(Icons.expand_more, size: 16),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(label, style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}

/// The widest tier's arrangement: icon beside label, matching an extended
/// rail's own destinations.
class _ExtendedContent extends StatelessWidget {
  const _ExtendedContent({
    required this.icon,
    required this.label,
    required this.showsDisclosure,
  });

  final IconData icon;
  final String label;
  final bool showsDisclosure;

  @override
  Widget build(BuildContext context) => Row(
    // `mainAxisSize.min` rather than `Expanded` around the label: the rail
    // sits inside a scroll view with an intrinsic height (UC-38), and that
    // ancestry can hand this row an unbounded width — something an
    // `Expanded` child cannot resolve against.
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon),
      const SizedBox(width: AppSpacing.md),
      Text(label),
      if (showsDisclosure) ...[
        const SizedBox(width: AppSpacing.sm),
        const Icon(Icons.chevron_right),
      ],
    ],
  );
}
