import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../library_sources/presentation/library_sources_screen.dart';
import '../../shell/presentation/async_state_view.dart';
import '../domain/catalog_file.dart';
import '../domain/library_type.dart';
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
          Align(
            alignment: Alignment.centerRight,
            child: SegmentedButton<ViewLayout>(
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
              catalogEmpty ? l10n.catalogEmptyFirstRun : l10n.catalogEmptyTitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (catalogEmpty) ...[
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
