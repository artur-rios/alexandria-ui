import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';

/// The modal every destructive action goes through (FR-UX-10, BR-07).
///
/// One dialog for the whole application rather than one per use case, so that
/// "names what will be removed, and whether the on-disk file is affected" is a
/// property the shell guarantees instead of a paragraph each later use case
/// has to re-read.
///
/// Cancelling resolves to `false` and changes nothing (UC-38 AF-05) — including
/// dismissing it with the escape key or a tap outside, which resolve the same
/// way rather than to `null`, so a caller cannot accidentally treat "dismissed"
/// as "confirmed".
class ConfirmationDialog extends StatelessWidget {
  /// Creates the dialog.
  const ConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.fileOnDiskNotice,
    super.key,
  });

  /// What is about to happen, as a heading.
  final String title;

  /// What will be removed, named. Never "this item".
  final String message;

  /// The confirming action's label — the verb, not "OK".
  final String confirmLabel;

  /// What happens to the file on disk, when the action reaches it.
  ///
  /// `null` when the action is catalog-only, which is itself the answer
  /// FR-UX-10 asks for: a dialog with no notice is a dialog about a record.
  final String? fileOnDiskNotice;

  /// Presents the dialog over [context] and resolves to what the owner chose.
  ///
  /// `false` for every way of declining, so the call site reads as a plain
  /// boolean and cannot mistake a dismissal for a confirmation.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String? fileOnDiskNotice,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => ConfirmationDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          fileOnDiskNotice: fileOnDiskNotice,
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final notice = fileOnDiskNotice;

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (notice != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              notice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        // Autofocus goes to cancelling, not to confirming: the keyboard must
        // reach the dialog's actions (FR-UX-11), and a destructive action that
        // fires on a stray return key is the data loss the confirmation exists
        // to prevent.
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
