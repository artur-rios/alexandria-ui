import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/domain/file_type.dart';
import '../../catalog/domain/listing_view.dart';
import '../../catalog/domain/view_layout.dart';
import '../../catalog/presentation/catalog_search_view.dart';
import '../../catalog/presentation/file_tiles.dart';
import '../../shell/presentation/async_state_view.dart';
import '../application/library_view_controller.dart';
import '../domain/library.dart';
import 'libraries_view.dart';
import 'library_run_status.dart';
import 'rename_library.dart';

/// One library in the main area, browsed as the folders it is (library
/// navigation design §4).
///
/// The header says which library and offers what can be done to it, the
/// breadcrumbs say where in it, and the toolbar shapes the files of the open
/// folder. Folders always come first, A–Z; the files are drawn with the same
/// rows and tiles every listing uses, so each opens, plays and shows its
/// details as it does anywhere else.
class LibraryView extends ConsumerWidget {
  /// Creates the view of the library [uuid] identifies.
  const LibraryView({required this.uuid, super.key});

  /// The library shown.
  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read from the list the left menu shows, so a rename, a pin or a
    // favorite reaches the header the moment the list reloads. A library the
    // list does not hold yet has nothing to show; one it no longer holds
    // sends the shell home (`ShellController`).
    final library = ref
        .watch(librariesControllerProvider)
        .value
        ?.where((library) => library.uuid == uuid)
        .firstOrNull;
    if (library == null) return const SizedBox.shrink();

    final path = ref.watch(
      libraryViewControllerProvider.select((open) => open[uuid] ?? ''),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LibraryHeader(library: library),
        const SizedBox(height: AppSpacing.sm),
        LibraryBreadcrumbs(library: library, path: path),
        const SizedBox(height: AppSpacing.sm),
        // UC-10 AF-01 is about whether a layout fits *where it is drawn*,
        // which is this column rather than the window.
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Toolbar(width: constraints.maxWidth),
                Expanded(
                  child: _Contents(
                    library: library,
                    path: path,
                    width: constraints.maxWidth,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The library's name, its Pin and Favorite toggles, its menu, and its run.
class LibraryHeader extends ConsumerWidget {
  /// Creates the header of [library].
  const LibraryHeader({required this.library, super.key});

  /// The library shown.
  final Library library;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final libraries = ref.read(librariesControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                library.name,
                style: theme.textTheme.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Toggles that show their state, so the header says whether the
            // library is pinned and a favorite as well as changing it.
            IconButton(
              isSelected: library.pinned,
              icon: const Icon(Icons.push_pin_outlined),
              selectedIcon: const Icon(Icons.push_pin),
              tooltip: library.pinned ? l10n.libraryUnpin : l10n.libraryPin,
              onPressed: () => _change(
                context,
                libraries.setPinned(library.uuid, !library.pinned),
              ),
            ),
            IconButton(
              isSelected: library.favorite,
              icon: const Icon(Icons.star_outline),
              selectedIcon: const Icon(Icons.star),
              tooltip: library.favorite
                  ? l10n.libraryFavoriteRemove
                  : l10n.libraryFavoriteAdd,
              onPressed: () => _change(
                context,
                libraries.setFavorite(library.uuid, !library.favorite),
              ),
            ),
            _LibraryActions(library: library),
          ],
        ),
        LibraryRunStatus(library: library),
      ],
    );
  }

  /// Waits for [change], and says so when the core refused it.
  ///
  /// The toggle shows what the core holds, so a refusal leaves it as it was;
  /// the snackbar is what tells the owner the press was not ignored.
  Future<void> _change(BuildContext context, Future<Failure?> change) async {
    final failure = await change;
    if (failure == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).libraryChangeNotSaved),
      ),
    );
  }
}

/// Rename, Scan again, Move and Remove, behind one button.
///
/// A button the keyboard reaches and opens with Enter or Space, so nothing
/// the left menu's context menu offers needs a pointer here (FR-UX-11).
class _LibraryActions extends ConsumerStatefulWidget {
  const _LibraryActions({required this.library});

  final Library library;

  @override
  ConsumerState<_LibraryActions> createState() => _LibraryActionsState();
}

class _LibraryActionsState extends ConsumerState<_LibraryActions> {
  // Handed to the menu as well as the button, so the arrow keys move from
  // the button into the menu and Escape returns to it.
  final _button = FocusNode(debugLabel: 'library actions');

  @override
  void dispose() {
    _button.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final library = widget.library;

    return MenuAnchor(
      childFocusNode: _button,
      builder: (context, menu, child) => IconButton(
        focusNode: _button,
        icon: const Icon(Icons.more_vert),
        tooltip: l10n.libraryActions,
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
      ),
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.drive_file_rename_outline),
          onPressed: () => renameLibrary(context, ref, library),
          child: Text(l10n.libraryRenameEntry),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.youtube_searched_for),
          onPressed: () => scanLibrary(context, ref, library),
          child: Text(l10n.libraryScan),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.drive_file_move_outlined),
          onPressed: () => moveLibrary(context, ref, library),
          child: Text(l10n.libraryMove),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.delete_outline),
          onPressed: () => removeLibrary(context, ref, library),
          child: Text(l10n.libraryRemove),
        ),
      ],
    );
  }
}

/// Where in the library the owner is: its root, then each folder down to the
/// open one. Every crumb but the last opens its level.
///
/// The root is the library's icon, named by its tooltip: the header beside it
/// already says the library's name, and saying it twice reads as two things.
class LibraryBreadcrumbs extends ConsumerWidget {
  /// Creates the crumbs of [path] within [library].
  const LibraryBreadcrumbs({
    required this.library,
    required this.path,
    super.key,
  });

  /// The library shown.
  final Library library;

  /// The open folder, relative to the root; empty at the top.
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final segments = path.isEmpty ? const <String>[] : path.split('/');
    void open(String path) => ref
        .read(libraryViewControllerProvider.notifier)
        .openFolder(library.uuid, path);

    // Wrapped rather than scrolled: a deep folder takes a second line at the
    // narrowest window instead of hiding the crumbs that lead to it.
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.folder_special_outlined),
          tooltip: library.name,
          onPressed: segments.isEmpty ? null : () => open(''),
        ),
        for (var index = 0; index < segments.length; index++) ...[
          Icon(
            Icons.chevron_right,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          if (index == segments.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Text(segments[index], style: theme.textTheme.titleSmall),
            )
          else
            TextButton(
              onPressed: () => open(segments.sublist(0, index + 1).join('/')),
              child: Text(segments[index]),
            ),
        ],
      ],
    );
  }
}

/// The type filter, the order and the layout, with what each has to say.
class _Toolbar extends ConsumerWidget {
  const _Toolbar({required this.width});

  /// The width the files are drawn in, which is what a layout has to fit.
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final preferences = ref.watch(libraryViewPreferencesProvider);
    final controller = ref.read(libraryViewPreferencesProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MenuAnchor(
                builder: (context, menu, child) => TextButton.icon(
                  onPressed: () => menu.isOpen ? menu.close() : menu.open(),
                  icon: Icon(
                    preferences.isFiltered
                        ? Icons.filter_alt
                        : Icons.filter_alt_outlined,
                  ),
                  label: Text(
                    preferences.type?.label(l10n) ?? l10n.libraryTypeAll,
                  ),
                ),
                menuChildren: [
                  for (final type in <FileType?>[null, ...FileType.values])
                    _RadioEntry(
                      selected: preferences.type == type,
                      onPressed: () => controller.filterTo(type),
                      label: type?.label(l10n) ?? l10n.libraryTypeAll,
                    ),
                ],
              ),
              MenuAnchor(
                builder: (context, menu, child) => TextButton.icon(
                  onPressed: () => menu.isOpen ? menu.close() : menu.open(),
                  icon: const Icon(Icons.sort),
                  label: Text(l10n.sortLabel),
                ),
                menuChildren: [
                  for (final field in SortField.values)
                    _RadioEntry(
                      selected: preferences.sortField == field,
                      onPressed: () => controller.sortBy(field),
                      label: field.label(l10n),
                    ),
                  const Divider(),
                  for (final direction in SortDirection.values)
                    _RadioEntry(
                      selected: preferences.direction == direction,
                      onPressed: () => controller.orderIn(direction),
                      label: direction.label(l10n),
                    ),
                ],
              ),
              const Spacer(),
              // Named as a group, because the three segments carry only
              // icons: each has a tooltip a pointer can reach, but a screen
              // reader arriving at the control itself was told nothing about
              // what the three choices are for.
              Semantics(
                container: true,
                label: l10n.layoutLabel,
                child: SegmentedButton<ViewLayout>(
                  segments: [
                    for (final layout in ViewLayout.values)
                      ButtonSegment(
                        value: layout,
                        icon: Icon(layout.icon),
                        tooltip: layout.label(l10n),
                      ),
                  ],
                  selected: {preferences.layout},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      controller.chooseLayout(selection.first),
                ),
              ),
            ],
          ),

          // UC-10 AF-01: the chosen layout does not fit, so the closest one
          // that does is drawn and the substitution is said out loud rather
          // than columns being quietly clipped.
          if (preferences.layout.isSubstitutedAt(width))
            _Notice(
              l10n.layoutSubstituted,
              color: theme.colorScheme.onSurfaceVariant,
            ),

          // UC-10 AF-02: it applied, it was not saved, and the owner is told.
          if (preferences.lastChangeUnsaved)
            _Notice(l10n.libraryViewUnsaved, color: theme.colorScheme.error),
        ],
      ),
    );
  }
}

/// One choice of a menu whose choices exclude each other.
class _RadioEntry extends StatelessWidget {
  const _RadioEntry({
    required this.selected,
    required this.onPressed,
    required this.label,
  });

  final bool selected;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => MenuItemButton(
    leadingIcon: Icon(
      selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
    ),
    onPressed: onPressed,
    child: Text(label),
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Text(
      text,
      textAlign: TextAlign.right,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
    ),
  );
}

/// The open folder: its folders, then its files.
class _Contents extends ConsumerWidget {
  const _Contents({
    required this.library,
    required this.path,
    required this.width,
  });

  final Library library;
  final String path;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final layout = ref
        .watch(libraryViewPreferencesProvider.select((view) => view.layout))
        .resolvedFor(width);

    return AsyncStateView<LibraryFolderView>(
      value: ref.watch(libraryFolderProvider(library.uuid)),
      onRetry: () => ref.invalidate(
        libraryTreeControllerProvider((uuid: library.uuid, path: path)),
      ),
      isEmpty: (folder) => folder.isEmpty,
      // At the top of a library, empty means something different from empty
      // three folders down: a library is browsed out of what the catalog
      // holds beneath its root, so a root with nothing in it is almost always
      // a folder that has never been indexed. Saying "nothing in this folder"
      // there describes the disk, which the owner can see is not true.
      emptyBuilder: (context) => _Message(
        path.isEmpty ? l10n.libraryEmptyRoot : l10n.libraryEmptyFolder,
      ),
      builder: (context, folder) => CustomScrollView(
        slivers: [
          if (layout == ViewLayout.grid)
            SliverGrid.builder(
              gridDelegate: fileGridDelegate,
              itemCount: folder.folders.length,
              itemBuilder: (context, index) =>
                  _FolderTile(library: library, folder: folder.folders[index]),
            )
          else
            SliverList.builder(
              itemCount: folder.folders.length,
              itemBuilder: (context, index) =>
                  _FolderRow(library: library, folder: folder.folders[index]),
            ),
          // A gap between the two grids, so the files start a row of their
          // own rather than running on from the last folder.
          if (layout == ViewLayout.grid && folder.folders.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
          FileSlivers(files: folder.files, layout: layout),
          if (ref.watch(libraryViewPreferencesProvider).type case final type?
              when folder.filteredToNothing)
            SliverToBoxAdapter(child: _NoneOfType(type: type)),
        ],
      ),
    );
  }
}

/// A folder as a row, which opens it.
class _FolderRow extends ConsumerWidget {
  const _FolderRow({required this.library, required this.folder});

  final Library library;
  final LibraryFolder folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    leading: const Icon(Icons.folder_outlined),
    title: Text(folder.name),
    onTap: () => ref
        .read(libraryViewControllerProvider.notifier)
        .openFolder(library.uuid, folder.path),
  );
}

/// A folder as a tile, which opens it.
class _FolderTile extends ConsumerWidget {
  const _FolderTile({required this.library, required this.folder});

  final Library library;
  final LibraryFolder folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => ref
            .read(libraryViewControllerProvider.notifier)
            .openFolder(library.uuid, folder.path),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.folder_outlined),
              const SizedBox(height: AppSpacing.sm),
              Text(
                folder.name,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A folder with files, none of the chosen type, and the way back to all of
/// them.
class _NoneOfType extends ConsumerWidget {
  const _NoneOfType({required this.type});

  /// The type chosen, which the folder holds none of.
  final FileType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(
            type.noneInThisFolder(l10n),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => ref
                .read(libraryViewPreferencesProvider.notifier)
                .filterTo(null),
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: Text(l10n.libraryTypeFilterClear),
          ),
        ],
      ),
    );
  }
}

/// A sentence in the middle of the files' area.
class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}

/// What a folder with none of a type says.
extension _NoneOfTypeMessage on FileType {
  String noneInThisFolder(AppLocalizations l10n) => switch (this) {
    FileType.video => l10n.libraryNoneVideos,
    FileType.audio => l10n.libraryNoneMusic,
    FileType.document => l10n.libraryNoneBooks,
    FileType.comic => l10n.libraryNoneComicBooks,
    FileType.text => l10n.libraryNoneNotes,
    FileType.html => l10n.libraryNonePages,
    FileType.image => l10n.libraryNoneImages,
  };
}

/// How each layout presents itself in the switcher.
extension _ViewLayoutPresentation on ViewLayout {
  IconData get icon => switch (this) {
    ViewLayout.list => Icons.view_list_outlined,
    ViewLayout.detailedList => Icons.view_agenda_outlined,
    ViewLayout.grid => Icons.grid_view_outlined,
  };

  String label(AppLocalizations l10n) => switch (this) {
    ViewLayout.list => l10n.layoutList,
    ViewLayout.detailedList => l10n.layoutDetailedList,
    ViewLayout.grid => l10n.layoutGrid,
  };
}

extension _SortFieldLabel on SortField {
  String label(AppLocalizations l10n) => switch (this) {
    SortField.name => l10n.sortByName,
    SortField.indexed => l10n.sortByIndexed,
    SortField.album => l10n.sortByAlbum,
  };
}

extension _SortDirectionLabel on SortDirection {
  String label(AppLocalizations l10n) => switch (this) {
    SortDirection.ascending => l10n.sortAscending,
    SortDirection.descending => l10n.sortDescending,
  };
}
