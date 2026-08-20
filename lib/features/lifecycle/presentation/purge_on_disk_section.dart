import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/domain/catalog_file.dart';
import '../../shell/presentation/confirmation_dialog.dart';
import '../application/purge_controller.dart';

/// Where a file is removed from disk as well as from the catalog (UC-36).
///
/// FR-LC-06 is specific about how this is presented, and the shape here is
/// that requirement read literally:
///
/// * **Never the default action.** It is folded away, below everything else on
///   the detail view, and has to be opened before it is even visible.
/// * **Never one interaction away from a listing row.** A row opens the detail
///   view; this then has to be expanded, pressed, and confirmed.
/// * **Confirmed by a dialog naming the exact path.** The confirmation carries
///   the file's own path, not its name, and says the deletion cannot be undone.
class PurgeOnDiskSection extends ConsumerWidget {
  /// Creates the section for [file].
  const PurgeOnDiskSection({required this.file, super.key});

  /// The file that would be removed.
  final CatalogFile file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final purge = ref.watch(purgeControllerProvider);

    return ExpansionTile(
      leading: Icon(
        Icons.warning_amber_outlined,
        color: theme.colorScheme.error,
      ),
      title: Text(
        l10n.purgeOnDiskTitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.purgeOnDiskExplanation,
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => unawaited(_confirm(context, ref)),
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text(l10n.purgeOnDiskAction),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        ),

        // AF-02, AF-03, and AF-04, said where the action was taken.
        if (_messageFor(purge, l10n) case final message?) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Step 2: the confirmation names the exact path and says the deletion
  /// cannot be undone (FR-LC-06, BR-07). AF-01 is declining it; AF-05 is
  /// something having the file open, which is said here and let go of by the
  /// controller before the core is called.
  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final isOpen = ref
        .read(deletionControllerProvider.notifier)
        .holdsOn(file.uuid)
        .isNotEmpty;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: l10n.purgeOnDiskTitle,
      message: isOpen
          ? '${l10n.purgeOnDiskMessage(file.path)} ${l10n.deleteFileInUse}'
          : l10n.purgeOnDiskMessage(file.path),
      confirmLabel: l10n.purgeOnDiskAction,
      fileOnDiskNotice: l10n.purgeOnDiskIrreversible,
    );
    if (!confirmed) return;

    await ref.read(purgeControllerProvider.notifier).purgeOnDisk(file.uuid);
  }

  String? _messageFor(PurgeState purge, AppLocalizations l10n) =>
      switch (purge.notice) {
        PurgeNotice.nothingOnDisk => l10n.purgeNothingOnDisk,
        PurgeNotice.diskFailed => l10n.purgeDiskFailed,
        PurgeNotice.notFound => l10n.purgeNotFound,
        PurgeNotice.refused => purge.refusal?.localizedMessage(l10n),
        _ => null,
      };
}
