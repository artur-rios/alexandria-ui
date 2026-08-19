import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shell/presentation/confirmation_dialog.dart';
import '../application/library_sources_state.dart';
import '../domain/folder_registration.dart';

/// The library-sources screen (UC-05, FR-LB-01 … FR-LB-04, FR-LB-11).
///
/// Presented as a full-screen dialog reached from preferences. The registered
/// folders are application settings (System Requirements §4.11), and the
/// navigation panel is specified as the file types (FR-CT-01) — so this is not
/// a destination of its own.
class LibrarySourcesScreen extends ConsumerWidget {
  /// Creates the screen.
  const LibrarySourcesScreen({super.key});

  /// Presents the screen over [context].
  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) =>
        const Dialog.fullscreen(child: LibrarySourcesScreen()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(librarySourcesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.librarySourcesTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.refusal != null) ...[
              _RefusalNotice(state: state),
              const SizedBox(height: AppSpacing.md),
            ],

            Expanded(
              child: state.isEmpty
                  ? const _FirstRunGuidance()
                  : _SourceList(state: state),
            ),

            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                // The screen's primary action, focused so it is reachable from
                // the keyboard (FR-UX-11).
                autofocus: true,
                onPressed: state.registering
                    ? null
                    : () => _addFolder(context, ref),
                icon: state.registering
                    ? const SizedBox.square(
                        dimension: AppSpacing.md,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.create_new_folder_outlined),
                label: Text(l10n.librarySourcesAdd),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the picker, answering AF-04's question through the shell's
  /// confirmation modal when it is asked.
  Future<void> _addFolder(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    await ref
        .read(librarySourcesControllerProvider.notifier)
        .registerFolder(
          onOverlapConfirmed: (path, existing) async {
            if (!context.mounted) return false;

            return ConfirmationDialog.show(
              context,
              title: l10n.librarySourcesOverlapTitle,
              // Both folders by name: the one being added and the one it
              // overlaps, so the owner can see which pair is at issue.
              message: l10n.librarySourcesOverlapBody(path, existing.label),
              confirmLabel: l10n.librarySourcesOverlapConfirm,
            );
          },
        );
  }
}

/// The first-run guidance, shown whenever nothing is registered (FR-LB-11).
class _FirstRunGuidance extends StatelessWidget {
  const _FirstRunGuidance();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: AppSpacing.xxl,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.librarySourcesEmptyTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.librarySourcesEmptyBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// The registered folders (main flow step 5).
class _SourceList extends StatelessWidget {
  const _SourceList({required this.state});

  final LibrarySourcesState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView.builder(
      itemCount: state.sources.length,
      itemBuilder: (context, index) {
        final source = state.sources[index];
        // AF-03 highlights the entry the refused folder duplicated, so the
        // owner can see the one they already have rather than hunting for it.
        final highlighted = state.conflictingSource?.path == source.path;

        return Card(
          color: highlighted ? theme.colorScheme.secondaryContainer : null,
          child: ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(source.label),
            subtitle: Text(
              source.path,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
            // UC-06 replaces this with the action that starts a run. The row
            // exists now so registering a folder visibly produces one.
            trailing: Text(
              l10n.librarySourcesIndexLater,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Why the last attempt was refused (AF-02, AF-03).
class _RefusalNotice extends ConsumerWidget {
  const _RefusalNotice({required this.state});

  final LibrarySourcesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final path = state.refusedPath ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              // FR-LB-02 requires the three refusals be told apart, so each
              // reads as the condition that failed rather than as one "no".
              switch (state.refusal!) {
                FolderRegistrationVerdict.missing => l10n.librarySourcesMissing(
                  path,
                ),
                FolderRegistrationVerdict.unreadable =>
                  l10n.librarySourcesUnreadable(path),
                FolderRegistrationVerdict.alreadyRegistered =>
                  l10n.librarySourcesAlreadyRegistered,
                // Neither reaches here: one is not a refusal and the other is
                // not a verdict the notice is shown for.
                FolderRegistrationVerdict.overlaps ||
                FolderRegistrationVerdict.acceptable => '',
              },
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            // Its own label rather than the screen's close: dismissing a
            // notice and closing the screen are different actions, and a
            // reader reaching for one must not find the other.
            icon: const Icon(Icons.close),
            tooltip: l10n.dismiss,
            onPressed: () => ref
                .read(librarySourcesControllerProvider.notifier)
                .acknowledgeRefusal(),
          ),
        ],
      ),
    );
  }
}
