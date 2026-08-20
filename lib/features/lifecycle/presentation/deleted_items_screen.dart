import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shell/presentation/async_state_view.dart';
import '../../shell/presentation/confirmation_dialog.dart';
import '../application/deleted_items_controller.dart';
import '../application/purge_controller.dart';
import '../domain/deleted_record.dart';

/// The deleted-items view (UC-34, FR-LC-03, FR-LC-04).
///
/// A screen of its own rather than a destination: what is deleted spans every
/// type and the bookmarks alike, so it is not an area of the library
/// (FR-CT-01).
class DeletedItemsScreen extends ConsumerWidget {
  /// Creates the screen.
  const DeletedItemsScreen({super.key});

  /// Presents the screen over [context] (main flow step 1).
  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => const Dialog.fullscreen(child: DeletedItemsScreen()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final records = ref.watch(deletedItemsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deletedItemsTitle),
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
            const _Notice(),
            Expanded(
              child: AsyncStateView(
                value: records,
                onRetry: ref
                    .read(deletedItemsControllerProvider.notifier)
                    .reload,
                isEmpty: (records) => records.isEmpty,
                // AF-01: nothing is deleted, which is a state and not a
                // failure.
                emptyBuilder: (context) =>
                    Center(child: Text(l10n.deletedItemsNone)),
                builder: (context, records) => ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) =>
                      _RecordTile(record: records[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AF-03, and anything else the core refused.
class _Notice extends ConsumerWidget {
  const _Notice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final restore = ref.watch(restoreControllerProvider);
    final purge = ref.watch(purgeControllerProvider);

    final message = switch ((restore.notice, purge.notice)) {
      (RestoreNotice.notFound, _) => l10n.restoreNotFound,
      (RestoreNotice.refused, _) =>
        restore.refusal?.localizedMessage(l10n) ?? l10n.restoreNotFound,
      (_, PurgeNotice.notDeleted) => l10n.purgeNotDeleted,
      // FR-LC-07: when it becomes possible, not a status code.
      (_, PurgeNotice.tooSoon) => l10n.purgeTooSoon(purge.daysRemaining ?? 0),
      (_, PurgeNotice.notFound) => l10n.purgeNotFound,
      (_, PurgeNotice.nothingOnDisk) => l10n.purgeNothingOnDisk,
      (_, PurgeNotice.diskFailed) => l10n.purgeDiskFailed,
      (_, PurgeNotice.refused) =>
        purge.refusal?.localizedMessage(l10n) ?? l10n.purgeNotFound,
      _ => null,
    };
    if (message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
            onPressed: () {
              ref.read(restoreControllerProvider.notifier).acknowledge();
              ref.read(purgeControllerProvider.notifier).acknowledge();
            },
            child: Text(l10n.editorDismiss),
          ),
        ],
      ),
    );
  }
}

/// One deleted record, with what is left of its retention window (step 3).
class _RecordTile extends ConsumerWidget {
  const _RecordTile({required this.record});

  final DeletedRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final retention = record.retentionAt(
      ref.watch(clockProvider)(),
      days: ref.watch(retentionWindowProvider).value,
    );

    return ListTile(
      leading: Icon(
        record.kind == DeletedRecordKind.bookmark
            ? Icons.bookmark_outline
            : Icons.insert_drive_file_outlined,
      ),
      title: Text(record.name),
      subtitle: Text(
        switch (retention) {
          // AF-02: the window has run out, so restoring is not offered and
          // purging is what is left (UC-35).
          final elapsed when elapsed.hasElapsed => l10n.retentionElapsed,
          final known when known.isKnown => l10n.retentionRemaining(
            known.daysRemaining,
          ),
          _ => l10n.retentionUnknown,
        },
        style: retention.hasElapsed
            ? theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              )
            : null,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AF-02: past the window there is nothing left to restore, so only
          // the purge is offered.
          if (!retention.hasElapsed)
            TextButton.icon(
              onPressed: () => unawaited(
                ref.read(restoreControllerProvider.notifier).restore(record),
              ),
              icon: const Icon(Icons.restore),
              label: Text(l10n.restoreRecord),
            ),
          // UC-35 main flow step 1.
          TextButton.icon(
            onPressed: () => unawaited(_purge(context, ref)),
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text(l10n.purgeRecord),
          ),
        ],
      ),
    );
  }

  /// UC-35 main flow step 2: the confirmation states that the record goes
  /// permanently and that the file on disk does not (FR-LC-05, BR-07). AF-01
  /// is declining it.
  Future<void> _purge(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await ConfirmationDialog.show(
      context,
      title: l10n.purgeRecord,
      message: l10n.purgeRecordMessage(record.name),
      confirmLabel: l10n.purgeRecord,
      // A bookmark has no file on disk, so a dialog that promised one was
      // spared would be describing something that is not there.
      fileOnDiskNotice: record.kind == DeletedRecordKind.file
          ? l10n.purgeRecordOnDisk
          : null,
    );
    if (!confirmed) return;

    await ref.read(purgeControllerProvider.notifier).purge(record);
  }
}
