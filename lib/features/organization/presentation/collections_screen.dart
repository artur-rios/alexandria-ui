import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shell/presentation/async_state_view.dart';
import '../../shell/presentation/confirmation_dialog.dart';
import '../application/collections_controller.dart';
import '../domain/collection.dart';

/// The collections screen (UC-26, FR-OG-01 … FR-OG-03, FR-OG-06).
///
/// A screen of its own rather than a destination: a collection holds files or
/// bookmarks, so it belongs to no single area of the library (FR-CT-01).
class CollectionsScreen extends ConsumerWidget {
  /// Creates the screen.
  const CollectionsScreen({super.key});

  /// Presents the screen over [context] (main flow step 1).
  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => const Dialog.fullscreen(child: CollectionsScreen()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final collections = ref.watch(collectionsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.collectionsTitle),
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
            const _NameField(),
            const _Notice(),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: AsyncStateView(
                value: collections,
                onRetry: ref
                    .read(collectionsControllerProvider.notifier)
                    .reload,
                isEmpty: (collections) => collections.isEmpty,
                emptyBuilder: (context) =>
                    Center(child: Text(l10n.collectionsNone)),
                builder: (context, collections) => ListView.builder(
                  itemCount: collections.length,
                  itemBuilder: (context, index) =>
                      _CollectionTile(collection: collections[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where a collection is named — created, or renamed (steps 2 to 5).
///
/// One field for both, because they are the same question asked twice: the
/// only difference is whether a collection is open for renaming, and that is
/// what the state carries.
class _NameField extends ConsumerStatefulWidget {
  const _NameField();

  @override
  ConsumerState<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends ConsumerState<_NameField> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(collectionsFormProvider);
    final form = ref.read(collectionsFormProvider.notifier);
    final renaming = state.renaming != null;

    // Seeded when a rename opens, and cleared when a write succeeds — the two
    // times the field's text is not the owner's to keep.
    if (state.name != _name.text && !state.isWriting) {
      _name.text = state.name;
      _name.selection = TextSelection.collapsed(offset: _name.text.length);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _name,
                enabled: !state.isWriting,
                decoration: InputDecoration(
                  labelText: renaming
                      ? l10n.collectionRenameLabel
                      : l10n.collectionNameLabel,
                  // AF-01: marked, and the core is not called.
                  errorText: state.nameError == null
                      ? null
                      : l10n.collectionNameEmpty,
                ),
                onChanged: form.editName,
                onSubmitted: (_) => unawaited(
                  renaming ? form.renameSubmitted() : form.create(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: FilledButton.icon(
                onPressed: state.isWriting
                    ? null
                    : () => unawaited(
                        renaming ? form.renameSubmitted() : form.create(),
                      ),
                icon: Icon(renaming ? Icons.check : Icons.add),
                label: Text(
                  renaming ? l10n.collectionRenameSave : l10n.collectionCreate,
                ),
              ),
            ),
            if (renaming) ...[
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: TextButton(
                  onPressed: form.cancelRenaming,
                  child: Text(l10n.cancel),
                ),
              ),
            ],
          ],
        ),

        // Step 2: what a new collection will hold, fixed at creation. Not
        // offered while renaming — the kind is not a thing a rename changes.
        if (!renaming) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<CollectionKind>(
              segments: [
                ButtonSegment(
                  value: CollectionKind.file,
                  label: Text(l10n.collectionKindFile),
                  icon: const Icon(Icons.insert_drive_file_outlined),
                ),
                ButtonSegment(
                  value: CollectionKind.bookmark,
                  label: Text(l10n.collectionKindBookmark),
                  icon: const Icon(Icons.bookmark_outline),
                ),
              ],
              selected: {state.kind},
              onSelectionChanged: (chosen) => form.chooseKind(chosen.first),
            ),
          ),
        ],
      ],
    );
  }
}

/// AF-02 and AF-04, and anything else the core refused.
class _Notice extends ConsumerWidget {
  const _Notice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(collectionsFormProvider);
    if (state.notice == CollectionNotice.none) return const SizedBox.shrink();

    final message = switch (state.notice) {
      CollectionNotice.notFound => l10n.collectionNotFound,
      CollectionNotice.refused =>
        state.refusal?.localizedMessage(l10n) ?? l10n.collectionNotFound,
      CollectionNotice.none => '',
    };

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: ref.read(collectionsFormProvider.notifier).acknowledge,
            child: Text(l10n.editorDismiss),
          ),
        ],
      ),
    );
  }
}

/// One collection, with what it holds and how much.
class _CollectionTile extends ConsumerWidget {
  const _CollectionTile({required this.collection});

  final Collection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: ListTile(
        leading: Icon(
          collection.kind == CollectionKind.bookmark
              ? Icons.bookmark_outline
              : Icons.folder_outlined,
        ),
        title: Text(collection.name),
        subtitle: Text(l10n.collectionItemCount(collection.itemCount)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.collectionRename,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => ref
                  .read(collectionsFormProvider.notifier)
                  .startRenaming(collection),
            ),
            IconButton(
              tooltip: l10n.collectionDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => unawaited(_delete(context, ref)),
            ),
          ],
        ),
      ),
    );
  }

  /// Step 6: the confirmation states that the contained items are preserved
  /// and only the grouping goes (FR-OG-03, BR-07). AF-03 is cancelling it.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await ConfirmationDialog.show(
      context,
      title: l10n.collectionDelete,
      message: l10n.collectionDeleteMessage(collection.name),
      confirmLabel: l10n.collectionDelete,
    );
    if (!confirmed) return;

    await ref.read(collectionsFormProvider.notifier).delete(collection.uuid);
  }
}
