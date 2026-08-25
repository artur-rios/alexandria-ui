import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/domain/catalog_file.dart';
import '../../catalog/domain/library_type.dart';
import '../../catalog/presentation/file_details_view.dart';
import '../../playback/presentation/music_display_name.dart' show tagOr;
import '../../shell/presentation/async_state_view.dart';
import '../application/missing_files_controller.dart';

/// The missing-files review (UC-37, FR-LC-08).
///
/// It reviews and it re-scans; it never removes anything. A record whose file
/// is absent is still a record, and BR-16 is explicit that missing is not a
/// reason to delete — so AF-02 routes the owner through the ordinary deletion
/// on the file's own detail view rather than offering a shortcut here.
class MissingFilesScreen extends ConsumerWidget {
  /// Creates the screen.
  const MissingFilesScreen({super.key});

  /// Presents the screen over [context] (main flow step 1).
  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => const Dialog.fullscreen(child: MissingFilesScreen()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final missing = ref.watch(missingFilesControllerProvider);
    final sources = ref.watch(librarySourcesControllerProvider).sources;
    final roots = [for (final source in sources) source.path];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.missingFilesTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.preferencesClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.missingFilesExplanation,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const _RescanButton(),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: AsyncStateView(
                value: missing,
                onRetry: ref
                    .read(missingFilesControllerProvider.notifier)
                    .reload,
                isEmpty: (files) => files.isEmpty,
                // AF-01: nothing is missing, which is a state and not a
                // failure — and the good outcome besides.
                emptyBuilder: (context) =>
                    Center(child: Text(l10n.missingFilesNone)),
                builder: (context, files) => ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) => _MissingTile(
                    file: files[index],
                    // AF-03: a record from a folder the owner has since
                    // unregistered is marked as such — it is missing for a
                    // reason the review can name.
                    fromUnregisteredFolder: !isUnderRegisteredFolder(
                      files[index].path,
                      roots,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 4: a re-scan over everything cataloged (UC-07).
class _RescanButton extends ConsumerWidget {
  const _RescanButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final runs = ref.watch(indexRunsControllerProvider);

    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        onPressed: runs.refreshStarting ? null : () => unawaited(_rescan(ref)),
        icon: const Icon(Icons.refresh),
        label: Text(l10n.missingFilesRescan),
      ),
    );
  }

  /// Step 5: what the re-scan found again leaves the review, which is the
  /// review being read from the core again once the run has been asked for.
  Future<void> _rescan(WidgetRef ref) async {
    await ref.read(indexRunsControllerProvider.notifier).startRefresh();
    await ref.read(missingFilesControllerProvider.notifier).reload();
  }
}

/// One missing file, with the path it was last known at (step 3).
class _MissingTile extends ConsumerWidget {
  const _MissingTile({
    required this.file,
    required this.fromUnregisteredFolder,
  });

  final CatalogFile file;
  final bool fromUnregisteredFolder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // FR-CT-13: an audio file is named by its metadata here too, the same
    // per-file path `catalog_search_view.dart` reads a search result's title
    // from — never by the file on disk, and never by forcing the whole
    // library's scan just to name one row of this review.
    final isAudio = file.type == LibraryType.audio;
    final metadata = isAudio ? ref.watch(audioMetadataProvider(file)).value : null;
    final title = isAudio
        ? tagOr(metadata?.title, l10n.musicUnknownTitle)
        : file.name;

    return ListTile(
      leading: Icon(
        Icons.help_outline,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(file.path),
          if (fromUnregisteredFolder)
            Text(
              l10n.missingFilesUnregisteredFolder,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
      isThreeLine: fromUnregisteredFolder,
      // AF-02: what to do about a record is decided on the record's own detail
      // view, where deletion lives. Nothing is removed from here.
      trailing: TextButton(
        onPressed: () =>
            unawaited(FileDetailsView.show(context, ref, file.uuid)),
        child: Text(l10n.missingFilesOpenDetails),
      ),
    );
  }
}
