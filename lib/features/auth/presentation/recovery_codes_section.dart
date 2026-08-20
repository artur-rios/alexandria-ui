import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shell/presentation/confirmation_dialog.dart';

/// Where the recovery codes are replaced (UC-42 main flow steps 1 to 3).
///
/// In preferences, beside changing the password: both are things an owner does
/// to an account they still have access to. The count comes from the core and
/// is never computed here (`FR-AU-14`, `FR-AU-19`).
class RecoveryCodesSection extends ConsumerWidget {
  /// Creates the section.
  const RecoveryCodesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final account = ref.watch(accountControllerProvider).value;
    final remaining = account?.recoveryCodesRemaining;
    final refusal = ref.watch(regenerateRecoveryCodesControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => unawaited(_regenerate(context, ref)),
            icon: const Icon(Icons.key_outlined),
            label: Text(l10n.recoveryCodesRegenerate),
          ),
        ),

        // Step 1: how many are left, when the core said. AF-03 is this being
        // absent — the action stays, because hiding it behind a number the
        // core would not give helps nobody.
        if (remaining != null)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: Text(
              remaining == 0
                  // Zero is worth its own sentence: the account cannot
                  // currently be recovered at all.
                  ? l10n.recoveryCodesNoneLeft
                  : l10n.recoveryCodesRemaining(remaining),
              style: theme.textTheme.bodySmall?.copyWith(
                color: remaining == 0
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

        // AF-02: the core refused, and every existing code still works.
        if (refusal != null)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: Text(
              refusal.failure.localizedMessage(l10n),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  /// Step 3: the confirmation states that every existing code stops working
  /// (`FR-AU-17`, BR-07). AF-01 is declining it.
  Future<void> _regenerate(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await ConfirmationDialog.show(
      context,
      title: l10n.recoveryCodesRegenerate,
      message: l10n.recoveryCodesRegenerateMessage,
      confirmLabel: l10n.recoveryCodesRegenerate,
    );
    if (!confirmed) return;

    await ref
        .read(regenerateRecoveryCodesControllerProvider.notifier)
        .regenerate();

    // Step 4 shows the new set in place of the catalog, so the preferences
    // dialog over it has to go — otherwise the codes are behind it.
    if (navigator.canPop()) navigator.pop();
  }
}
