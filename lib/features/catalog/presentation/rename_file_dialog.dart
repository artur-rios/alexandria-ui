import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/file_rename_controller.dart';
import '../domain/catalog_file.dart';
import '../domain/file_name.dart';
import 'file_details_view.dart';

/// The rename dialog (UC-17, FR-ME-04).
class RenameFileDialog extends ConsumerStatefulWidget {
  /// Creates the dialog.
  const RenameFileDialog({super.key});

  /// Presents the dialog for [file] (main flow step 1).
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    CatalogFile file,
  ) {
    ref.read(fileRenameControllerProvider.notifier).open(file.uuid, file.name);

    return showDialog<void>(
      context: context,
      builder: (context) => const RenameFileDialog(),
    );
  }

  @override
  ConsumerState<RenameFileDialog> createState() => _RenameFileDialogState();
}

class _RenameFileDialogState extends ConsumerState<RenameFileDialog> {
  /// Created once from the name the dialog opened on: it holds the owner's
  /// text, so rebuilding it from state would move the cursor as they typed.
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(fileRenameControllerProvider).name,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(fileRenameControllerProvider);
    final controller = ref.read(fileRenameControllerProvider.notifier);

    // Step 5 and AF-03: the dialog is finished, so it closes itself.
    ref.listen(fileRenameControllerProvider, (_, next) {
      switch (next.stage) {
        case RenameStage.renamed:
          Navigator.of(context).pop();
        case RenameStage.gone:
          Navigator.of(context).pop();
          unawaited(showFileNotFound(context, ref));
        case RenameStage.editing || RenameStage.saving:
          break;
      }
    });

    return AlertDialog(
      title: Text(l10n.renameTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              // The dialog's only field, so it takes focus: the whole of this
              // is reachable from the keyboard (FR-UX-11).
              autofocus: true,
              enabled: !state.isSaving,
              decoration: InputDecoration(
                labelText: l10n.renameFieldLabel,
                // AF-01: the field is marked with what is wrong with it, and
                // nothing was sent.
                errorText: state.error == null
                    ? null
                    : _errorText(state.error!, l10n),
              ),
              onChanged: controller.edit,
              onSubmitted: (_) => unawaited(controller.submit()),
            ),

            // AF-02: what the core refused, and the promise that goes with a
            // disk failure — neither the catalog nor the file changed.
            if (state.failure case final failure?) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                failure.localizedMessage(l10n),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.renameNothingChanged,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: state.isSaving ? null : () => controller.submit(),
          child: state.isSaving
              ? const SizedBox(
                  width: AppSpacing.md,
                  height: AppSpacing.md,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.renameSubmit),
        ),
      ],
    );
  }

  String _errorText(FileNameError error, AppLocalizations l10n) =>
      switch (error) {
        FileNameError.empty => l10n.renameErrorEmpty,
        FileNameError.forbiddenCharacter => l10n.renameErrorForbidden,
        FileNameError.reservedName => l10n.renameErrorReserved,
        FileNameError.trailingDot => l10n.renameErrorTrailingDot,
        FileNameError.tooLong => l10n.renameErrorTooLong(maxFileNameLength),
      };
}
