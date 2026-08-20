import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shell/presentation/async_state_view.dart';
import '../../shell/presentation/confirmation_dialog.dart';
import '../application/reading_lists_controller.dart';
import '../domain/reading_list.dart';

/// The reading-lists screen (UC-31, FR-TR-08 … FR-TR-11).
///
/// Reached from the books and comics areas, as watchlists are from videos: a
/// reading list is not a file type, so it is not a destination of its own
/// (FR-CT-01).
class ReadingListsScreen extends ConsumerWidget {
  /// Creates the screen.
  const ReadingListsScreen({super.key});

  /// Presents the screen over [context] (main flow step 1).
  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => const Dialog.fullscreen(child: ReadingListsScreen()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lists = ref.watch(readingListsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.readingListsTitle),
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
            const _CreateField(),
            const _Notice(),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: AsyncStateView(
                value: lists,
                onRetry: ref
                    .read(readingListsControllerProvider.notifier)
                    .reload,
                isEmpty: (lists) => lists.isEmpty,
                emptyBuilder: (context) =>
                    Center(child: Text(l10n.readingListsNone)),
                builder: (context, lists) => ListView.builder(
                  itemCount: lists.length,
                  itemBuilder: (context, index) =>
                      _ReadingListTile(readingList: lists[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where a reading list is created (main flow steps 1 and 2).
class _CreateField extends ConsumerStatefulWidget {
  const _CreateField();

  @override
  ConsumerState<_CreateField> createState() => _CreateFieldState();
}

class _CreateFieldState extends ConsumerState<_CreateField> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(readingListsFormProvider);
    final form = ref.read(readingListsFormProvider.notifier);

    // Cleared when the create succeeds, which is the one time the field's text
    // is not the owner's to keep.
    if (state.name.isEmpty && _name.text.isNotEmpty && !state.isCreating) {
      _name.clear();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _name,
            enabled: !state.isCreating,
            decoration: InputDecoration(
              labelText: l10n.readingListNameLabel,
              // AF-01: marked, and the core is not called.
              errorText: state.nameError == null
                  ? null
                  : l10n.readingListNameEmpty,
            ),
            onChanged: form.editName,
            onSubmitted: (_) => unawaited(form.create()),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: FilledButton.icon(
            onPressed: state.isCreating ? null : () => unawaited(form.create()),
            icon: const Icon(Icons.add),
            label: Text(l10n.readingListCreate),
          ),
        ),
      ],
    );
  }
}

/// AF-03 and AF-04, and anything else the core refused.
class _Notice extends ConsumerWidget {
  const _Notice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(readingListsFormProvider);
    if (state.notice == ReadingListNotice.none) return const SizedBox.shrink();

    final message = switch (state.notice) {
      ReadingListNotice.alreadyTracked => l10n.readingListAlreadyTracked,
      ReadingListNotice.notFound => l10n.readingListNotFound,
      ReadingListNotice.refused =>
        state.refusal?.localizedMessage(l10n) ?? l10n.readingListNotFound,
      ReadingListNotice.none => '',
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
            onPressed: ref.read(readingListsFormProvider.notifier).acknowledge,
            child: Text(l10n.editorDismiss),
          ),
        ],
      ),
    );
  }
}

/// One reading list, and what it tracks.
class _ReadingListTile extends ConsumerWidget {
  const _ReadingListTile({required this.readingList});

  final ReadingList readingList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: ExpansionTile(
        title: Text(readingList.name),
        subtitle: Text(l10n.readingListItemCount(readingList.items.length)),
        trailing: IconButton(
          tooltip: l10n.readingListDelete,
          icon: const Icon(Icons.delete_outline),
          onPressed: () => unawaited(_delete(context, ref)),
        ),
        children: [
          if (readingList.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(l10n.readingListEmpty),
            )
          else
            for (final item in readingList.items)
              _ItemTile(readingList: readingList, progress: item),
        ],
      ),
    );
  }

  /// Step 6: the confirmation states that the books and comics are preserved
  /// and only the tracking goes (FR-TR-09, BR-07). AF-05 is cancelling it.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await ConfirmationDialog.show(
      context,
      title: l10n.readingListDelete,
      message: l10n.readingListDeleteMessage(readingList.name),
      confirmLabel: l10n.readingListDelete,
    );
    if (!confirmed) return;

    await ref.read(readingListsFormProvider.notifier).delete(readingList.uuid);
  }
}

/// One tracked book or comic inside a reading list.
class _ItemTile extends ConsumerWidget {
  const _ItemTile({required this.readingList, required this.progress});

  final ReadingList readingList;
  final ReadingProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return ListTile(
      dense: true,
      leading: Icon(
        progress.targetKind == ReadingTargetKind.comic
            ? Icons.auto_stories_outlined
            : Icons.menu_book_outlined,
      ),
      // The name is the catalog's; a reading list carries only the uuid the
      // core tracks the item by. UC-32 is what puts a title and the progress
      // on screen beside it.
      title: Text(progress.itemUuid),
      subtitle: Text(_stateLabel(l10n)),
      trailing: IconButton(
        tooltip: l10n.readingListRemoveItem,
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: () => unawaited(
          ref
              .read(readingListsFormProvider.notifier)
              .removeItem(
                readingListUuid: readingList.uuid,
                itemUuid: progress.itemUuid,
              ),
        ),
      ),
    );
  }

  String _stateLabel(AppLocalizations l10n) => switch (progress.state) {
    ReadingState.pending => l10n.readStatePending,
    ReadingState.reading => l10n.readStateReading,
    ReadingState.read => l10n.readStateRead,
  };
}
