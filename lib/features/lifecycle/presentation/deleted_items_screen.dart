import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shell/presentation/async_state_view.dart';
import '../application/deleted_items_controller.dart';
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
    final state = ref.watch(restoreControllerProvider);
    if (state.notice == RestoreNotice.none) return const SizedBox.shrink();

    final message = switch (state.notice) {
      RestoreNotice.notFound => l10n.restoreNotFound,
      RestoreNotice.refused =>
        state.refusal?.localizedMessage(l10n) ?? l10n.restoreNotFound,
      RestoreNotice.none => '',
    };

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
            onPressed: ref.read(restoreControllerProvider.notifier).acknowledge,
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
    final retention = record.retentionAt(ref.watch(clockProvider)());

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
      trailing: retention.hasElapsed
          ? null
          : TextButton.icon(
              onPressed: () => unawaited(
                ref.read(restoreControllerProvider.notifier).restore(record),
              ),
              icon: const Icon(Icons.restore),
              label: Text(l10n.restoreRecord),
            ),
    );
  }
}
