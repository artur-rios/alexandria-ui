import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';
import '../../libraries/domain/library.dart';
import '../../libraries/presentation/libraries_view.dart';
import '../../libraries/presentation/rename_library.dart';
import '../domain/menu_order.dart';
import '../domain/shell_destination.dart';

/// The left menu (FR-UX-01, FR-UX-02, spec §3).
///
/// Home, the bookmarks, then the libraries: the pinned ones A–Z, a divider,
/// and the others A–Z. The divider is drawn only when both groups have a
/// library in them, because a line with nothing on one side of it divides
/// nothing.
///
/// It collapses rather than hides: at the minimum supported window it is a
/// column of icons with tooltips, and at the wider tiers the same entries
/// carry their labels. No entry is ever dropped, which is the distinction
/// FR-UX-02 draws between adapting and clipping — however many libraries the
/// owner has, the panel scrolls rather than losing one.
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
    final tier = _Tier.of(Breakpoint.from(context));
    // The last list loaded stays while a reload runs, so a pin does not
    // blank the menu on its way through. Nothing loaded yet, or a list that
    // could not be read, lists no libraries — rather than offering to add
    // one to an owner who may already have twenty.
    final libraries = ref.watch(librariesControllerProvider).value;

    Widget fixed(
      ShellDestination destination, {
      required IconData icon,
      required IconData selectedIcon,
      required String label,
    }) => _PanelEntry(
      tier: tier,
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon),
      label: label,
      selected: selected == destination,
      onTap: () => onSelected(destination),
    );

    final ordered = menuOrder(libraries ?? const []);
    final pinned = [...ordered.where((library) => library.pinned)];
    final others = [...ordered.where((library) => !library.pinned)];

    Widget libraryEntry(Library library) => _LibraryEntry(
      key: ValueKey(library.uuid),
      library: library,
      tier: tier,
      selected: selected == LibraryDestination(library.uuid),
      onTap: () => onSelected(LibraryDestination(library.uuid)),
    );

    // A scroll view because a window can be wide and short, and an owner can
    // have more libraries than any window is tall: scrolling is how the panel
    // keeps every entry reachable — FR-UX-02 forbids clipping one, not making
    // it scroll to. The minimum height is what still lets the panel fill a
    // tall window, which a bare scroll view would collapse to its entries.
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: tier.width,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  fixed(
                    const HomeDestination(),
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: l10n.destinationHome,
                  ),
                  fixed(
                    const BookmarksDestination(),
                    icon: Icons.bookmark_outline,
                    selectedIcon: Icons.bookmark,
                    label: l10n.destinationBookmarks,
                  ),
                  if (libraries != null && libraries.isEmpty)
                    // The libraries are the whole of the menu below the two
                    // fixed entries, so an empty catalog offers the one thing
                    // that fills it.
                    _PanelEntry(
                      tier: tier,
                      icon: const Icon(Icons.create_new_folder_outlined),
                      selectedIcon: const Icon(
                        Icons.create_new_folder_outlined,
                      ),
                      label: l10n.libraryAdd,
                      selected: false,
                      onTap: () => openLibrariesAndAdd(ref),
                    ),
                  for (final library in pinned) libraryEntry(library),
                  if (pinned.isNotEmpty && others.isNotEmpty)
                    const Divider(
                      height: AppSpacing.md,
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                    ),
                  for (final library in others) libraryEntry(library),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The three ways the panel lays itself out, one per breakpoint.
///
/// Icons with tooltips at the narrowest, labels beneath them at the medium
/// one, and labels beside them once there is room. Every entry is labelled
/// at once rather than only the selected one, because a menu that names one
/// entry makes the others unreadable at a glance for no space saved.
enum _Tier {
  icons(80),
  labelled(96),
  extended(256);

  const _Tier(this.width);

  /// The panel's width at this tier.
  final double width;

  static _Tier of(Breakpoint breakpoint) {
    if (breakpoint.usesExtendedNavigation) return _Tier.extended;
    if (breakpoint.showsNavigationLabels) return _Tier.labelled;
    return _Tier.icons;
  }
}

/// One library in the left menu, with its context menu (spec §3).
///
/// Right-click and long-press open the same menu: pin or unpin, add to or
/// remove from the favorites, and rename. A change the core refuses is not
/// shown — the list is only ever what the core says — and a snackbar says it
/// could not be saved.
class _LibraryEntry extends ConsumerWidget {
  const _LibraryEntry({
    required this.library,
    required this.tier,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Library library;
  final _Tier tier;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(librariesControllerProvider.notifier);

    Future<void> save(Future<Failure?> Function() change) async {
      // Taken before the call, so the answer can be said even if this entry
      // has been rebuilt somewhere else in the list by the time it arrives.
      final messenger = ScaffoldMessenger.of(context);
      final failure = await change();
      if (failure == null) return;

      messenger.showSnackBar(
        SnackBar(content: Text(l10n.libraryChangeNotSaved)),
      );
    }

    Widget folder(IconData icon) {
      if (!library.pinned) return Icon(icon);

      return Badge(
        backgroundColor: theme.colorScheme.tertiaryContainer,
        label: Icon(
          Icons.push_pin,
          size: 10,
          color: theme.colorScheme.onTertiaryContainer,
          semanticLabel: l10n.libraryPinned,
        ),
        child: Icon(icon),
      );
    }

    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: Icon(
            library.pinned ? Icons.push_pin : Icons.push_pin_outlined,
          ),
          onPressed: () => unawaited(
            save(() => controller.setPinned(library.uuid, !library.pinned)),
          ),
          child: Text(library.pinned ? l10n.libraryUnpin : l10n.libraryPin),
        ),
        MenuItemButton(
          // The star is what says a library is a favorite, here and on home.
          leadingIcon: Icon(library.favorite ? Icons.star : Icons.star_border),
          onPressed: () => unawaited(
            save(() => controller.setFavorite(library.uuid, !library.favorite)),
          ),
          child: Text(
            library.favorite
                ? l10n.libraryFavoriteRemove
                : l10n.libraryFavoriteAdd,
          ),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_outlined),
          onPressed: () => unawaited(renameLibrary(context, ref, library)),
          child: Text(l10n.libraryRenameEntry),
        ),
      ],
      builder: (context, menu, _) => _PanelEntry(
        tier: tier,
        icon: folder(Icons.folder_outlined),
        selectedIcon: folder(Icons.folder),
        label: library.name,
        selected: selected,
        onTap: onTap,
        onSecondaryTapUp: (details) =>
            menu.open(position: details.localPosition),
        onLongPress: menu.open,
      ),
    );
  }
}

/// One entry of the panel, laid out for its [tier].
class _PanelEntry extends StatelessWidget {
  const _PanelEntry({
    required this.tier,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onSecondaryTapUp,
    this.onLongPress,
  });

  final _Tier tier;
  final Widget icon;
  final Widget selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final GestureTapUpCallback? onSecondaryTapUp;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final shown = selected ? selectedIcon : icon;
    final labelStyle =
        (tier == _Tier.extended
                ? theme.textTheme.labelLarge
                : theme.textTheme.labelMedium)
            ?.copyWith(
              color: selected ? colors.onSurface : colors.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : null,
            );

    // The indicator behind the icon, as Material's own rail draws it; at the
    // widest tier it runs the whole row, as a drawer's does.
    Widget indicator({required Widget child, double? width}) => Container(
      width: width,
      height: 32,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: selected ? colors.secondaryContainer : null,
      ),
      child: child,
    );

    final content = switch (tier) {
      _Tier.icons => indicator(width: 56, child: shown),
      _Tier.labelled => Column(
        children: [
          indicator(width: 56, child: shown),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: labelStyle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      _Tier.extended => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          color: selected ? colors.secondaryContainer : null,
        ),
        child: Row(
          children: [
            shown,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: labelStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    };

    final entry = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          customBorder: tier == _Tier.extended
              ? const StadiumBorder()
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
          onTap: onTap,
          onSecondaryTapUp: onSecondaryTapUp,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: content,
          ),
        ),
      ),
    );

    // The label is the tooltip only where it is not drawn — which is also
    // what names the entry to a screen reader there. A tooltip repeating the
    // text beside it is noise.
    if (tier != _Tier.icons) return entry;
    return Tooltip(message: label, child: entry);
  }
}
