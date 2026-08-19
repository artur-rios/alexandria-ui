import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../library_sources/presentation/library_sources_screen.dart';
import '../../shell/presentation/async_state_view.dart';
import '../domain/catalog_file.dart';
import '../domain/library_type.dart';
import '../domain/listing_view.dart';
import '../domain/view_layout.dart';

/// The files of the selected type (UC-09, FR-CT-02, FR-CT-10).
///
/// The loading, failure, and retry behaviour is the shell's `AsyncStateView`
/// rather than this screen's own — which is what UC-38 built it for, and why
/// AF-02 needs nothing here beyond throwing the failure.
class CatalogListing extends ConsumerWidget {
  /// Creates the listing.
  const CatalogListing({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = ref.watch(listingControllerProvider);
    final type = libraryTypeFor(ref.watch(shellControllerProvider));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (type != null) _LayoutBar(type: type),
        Expanded(
          child: AsyncStateView<List<CatalogFile>>(
            value: listing,
            onRetry: () =>
                ref.read(listingControllerProvider.notifier).reload(),
            isEmpty: (files) => files.isEmpty,
            emptyBuilder: (context) => const _EmptyListing(),
            builder: (context, files) => type == null
                ? _FileList(files: files)
                : _LaidOutFiles(files: files, type: type),
          ),
        ),
      ],
    );
  }
}

/// The layout switcher, and what it has to say about the window (UC-10).
class _LayoutBar extends ConsumerWidget {
  const _LayoutBar({required this.type});

  final LibraryType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final layouts = ref.watch(layoutControllerProvider);
    final chosen = layouts.chosenFor(type);
    final width = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _FilterControls(),
              const Spacer(),
              SegmentedButton<ViewLayout>(
                segments: [
                  for (final layout in ViewLayout.values)
                    ButtonSegment(
                      value: layout,
                      icon: Icon(layout.icon),
                      tooltip: layout.label(l10n),
                    ),
                ],
                selected: {chosen},
                showSelectedIcon: false,
                onSelectionChanged: (selection) => ref
                    .read(layoutControllerProvider.notifier)
                    .choose(type, selection.first),
              ),
            ],
          ),

          // AF-04: the core refused a filter, the previous one is back, and
          // the owner is told why rather than watching the controls move on
          // their own.
          if (ref.watch(listingViewControllerProvider).rejection != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                l10n.filtersRejected,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),

          // AF-01: the chosen layout does not fit, so the closest one that
          // does is drawn and the substitution is said out loud rather than
          // columns being quietly clipped.
          if (chosen.isSubstitutedAt(width))
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                l10n.layoutSubstituted,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

          // AF-02: it applied, it was not saved, and the owner is told.
          if (layouts.lastChangeUnsaved)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                l10n.layoutUnsaved,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The files, drawn the way the owner asked for (FR-CT-03).
class _LaidOutFiles extends ConsumerWidget {
  const _LaidOutFiles({required this.files, required this.type});

  final List<CatalogFile> files;
  final LibraryType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = ref.watch(layoutControllerProvider).chosenFor(type);
    final width = MediaQuery.sizeOf(context).width;

    return switch (chosen.resolvedFor(width)) {
      ViewLayout.list => _FileList(files: files),
      ViewLayout.detailedList => _FileList(files: files, detailed: true),
      ViewLayout.grid => _FileGrid(files: files),
    };
  }
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

/// The tiles (FR-CT-03, FR-CT-10).
class _FileGrid extends StatelessWidget {
  const _FileGrid({required this.files});

  final List<CatalogFile> files;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // A builder here too: a grid that built every tile would defeat FR-CT-10
    // exactly as a column would.
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 4 / 3,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  file.isMissing
                      ? Icons.report_gmailerrorred_outlined
                      : Icons.insert_drive_file_outlined,
                  color: file.isMissing ? theme.colorScheme.error : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  file.name,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The rows themselves.
///
/// A builder, not a column: FR-CT-10 asks that scrolling cost not grow with
/// the size of the library, and a listing that built every row would spend the
/// whole library's worth of work to show one screen of it.
class _FileList extends StatelessWidget {
  const _FileList({required this.files, this.detailed = false});

  final List<CatalogFile> files;

  /// Whether each row carries its details alongside the name.
  final bool detailed;

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: files.length,
    itemBuilder: (context, index) =>
        _FileRow(file: files[index], detailed: detailed),
  );
}

/// One file.
class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, this.detailed = false});

  final CatalogFile file;

  /// Whether the row shows the file's path beneath its name.
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        // Deliberately not one of the navigation panel's icons: a row and a
        // destination that draw the same glyph are two different things
        // claiming to be one.
        file.isMissing
            ? Icons.report_gmailerrorred_outlined
            : Icons.insert_drive_file_outlined,
        color: file.isMissing ? theme.colorScheme.error : null,
      ),
      title: Text(file.name),
      // The plain list is the name and nothing else; the detailed one adds
      // where the file actually is, which is the detail that distinguishes two
      // files with the same name.
      subtitle: detailed
          ? Text(
              file.path,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      // A file the last refresh could not find is still an active record; it
      // is marked rather than hidden, and reviewing them is UC-37.
      trailing: file.isMissing
          ? Text(
              l10n.catalogFileMissing,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            )
          : null,
    );
  }
}

/// The empty state (AF-01).
///
/// Two of them, told apart by whether anything is cataloged at all: a type
/// with nothing in it is ordinary, and an empty library is a first run that
/// needs a folder.
class _EmptyListing extends ConsumerWidget {
  const _EmptyListing();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final type = libraryTypeFor(ref.watch(shellControllerProvider));
    final filtered =
        type != null &&
        ref.watch(listingViewControllerProvider).forType(type).isFiltered;

    final counts = ref.watch(typeCountsControllerProvider);
    final catalogEmpty = counts.maybeWhen(
      data: (byType) => byType.values.every((count) => count == 0),
      // Unknown counts are not an empty catalog: offering the first-run
      // guidance because a query failed would be guessing.
      orElse: () => false,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: AppSpacing.xxl,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              switch ((catalogEmpty, filtered)) {
                // AF-01: filters are narrowing the listing to nothing, which
                // is a different thing from an empty library and has a
                // different answer — clear them.
                (_, true) => l10n.filtersEmpty,
                (true, _) => l10n.catalogEmptyFirstRun,
                (false, _) => l10n.catalogEmptyTitle,
              },
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (filtered) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () {
                  final type = libraryTypeFor(
                    ref.read(shellControllerProvider),
                  );
                  if (type != null) {
                    ref
                        .read(listingViewControllerProvider.notifier)
                        .clearFilters(type);
                  }
                },
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: Text(l10n.filtersClear),
              ),
            ],
            if (catalogEmpty && !filtered) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => LibrarySourcesScreen.show(context),
                icon: const Icon(Icons.folder_outlined),
                label: Text(l10n.catalogEmptyAddFolder),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The filter and sort choices (UC-12, FR-CT-07, FR-CT-08).
///
/// A menu rather than a row of controls: the listing is what the owner came to
/// read, and the choices that shape it belong one click away rather than
/// across the top of it.
class _FilterControls extends ConsumerWidget {
  const _FilterControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final type = libraryTypeFor(ref.watch(shellControllerProvider));
    if (type == null) return const SizedBox.shrink();

    final view = ref.watch(listingViewControllerProvider).forType(type);
    final controller = ref.read(listingViewControllerProvider.notifier);

    return MenuAnchor(
      builder: (context, anchor, child) => TextButton.icon(
        onPressed: () => anchor.isOpen ? anchor.close() : anchor.open(),
        icon: Icon(
          view.isFiltered ? Icons.filter_alt : Icons.filter_alt_outlined,
        ),
        label: Text(l10n.filtersLabel),
      ),
      menuChildren: [
        _MenuHeading(l10n.filterLifecycle),
        for (final lifecycle in LifecycleFilter.values)
          MenuItemButton(
            leadingIcon: Icon(
              view.lifecycle == lifecycle
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            onPressed: () =>
                controller.apply(type, view.copyWith(lifecycle: lifecycle)),
            child: Text(lifecycle.label(l10n)),
          ),

        const Divider(),
        _MenuHeading(l10n.sortLabel),
        for (final field in SortField.values)
          MenuItemButton(
            leadingIcon: Icon(
              view.sortField == field
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            onPressed: () =>
                controller.apply(type, view.copyWith(sortField: field)),
            child: Text(field.label(l10n)),
          ),
        for (final direction in SortDirection.values)
          MenuItemButton(
            leadingIcon: Icon(
              view.direction == direction
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            onPressed: () =>
                controller.apply(type, view.copyWith(direction: direction)),
            child: Text(direction.label(l10n)),
          ),

        if (view.isFiltered) ...[
          const Divider(),
          MenuItemButton(
            leadingIcon: const Icon(Icons.filter_alt_off_outlined),
            onPressed: () => controller.clearFilters(type),
            child: Text(l10n.filtersClear),
          ),
        ],
      ],
    );
  }
}

class _MenuHeading extends StatelessWidget {
  const _MenuHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.sm,
      AppSpacing.md,
      AppSpacing.xs,
    ),
    child: Text(text, style: Theme.of(context).textTheme.labelSmall),
  );
}

/// How each filter and sort choice presents itself.
extension _LifecycleLabel on LifecycleFilter {
  String label(AppLocalizations l10n) => switch (this) {
    LifecycleFilter.active => l10n.filterLifecycleActive,
    LifecycleFilter.deleted => l10n.filterLifecycleDeleted,
    LifecycleFilter.all => l10n.filterLifecycleAll,
  };
}

extension _SortFieldLabel on SortField {
  String label(AppLocalizations l10n) => switch (this) {
    SortField.name => l10n.sortByName,
    SortField.indexed => l10n.sortByIndexed,
  };
}

extension _SortDirectionLabel on SortDirection {
  String label(AppLocalizations l10n) => switch (this) {
    SortDirection.ascending => l10n.sortAscending,
    SortDirection.descending => l10n.sortDescending,
  };
}
