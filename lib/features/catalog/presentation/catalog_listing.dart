import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../library_sources/presentation/library_sources_screen.dart';
import '../../shell/presentation/async_state_view.dart';
import '../domain/catalog_file.dart';

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

    return AsyncStateView<List<CatalogFile>>(
      value: listing,
      onRetry: () => ref.read(listingControllerProvider.notifier).reload(),
      isEmpty: (files) => files.isEmpty,
      emptyBuilder: (context) => const _EmptyListing(),
      builder: (context, files) => _FileList(files: files),
    );
  }
}

/// The rows themselves.
///
/// A builder, not a column: FR-CT-10 asks that scrolling cost not grow with
/// the size of the library, and a listing that built every row would spend the
/// whole library's worth of work to show one screen of it.
class _FileList extends StatelessWidget {
  const _FileList({required this.files});

  final List<CatalogFile> files;

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: files.length,
    itemBuilder: (context, index) => _FileRow(file: files[index]),
  );
}

/// One file.
class _FileRow extends StatelessWidget {
  const _FileRow({required this.file});

  final CatalogFile file;

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
      subtitle: Text(
        file.path,
        style: theme.textTheme.bodySmall,
        overflow: TextOverflow.ellipsis,
      ),
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
