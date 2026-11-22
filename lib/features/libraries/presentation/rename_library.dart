import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/library.dart';

/// Asks what to call [library], and renames it when confirmed.
///
/// Available from every place that lists a library, and at any time — a run
/// in progress included. The dialog stays open with the core's message when
/// the core refuses, so the name typed is not lost.
Future<void> renameLibrary(
  BuildContext context,
  WidgetRef ref,
  Library library,
) => showDialog<void>(
  context: context,
  builder: (context) => LibraryNameDialog(
    initialName: library.name,
    onConfirm: (name) => ref
        .read(librariesControllerProvider.notifier)
        .rename(library.uuid, name),
  ),
);

/// The dialog asking for a library's name.
class LibraryNameDialog extends StatefulWidget {
  /// Creates the dialog, prefilled with [initialName].
  const LibraryNameDialog({
    required this.initialName,
    required this.onConfirm,
    super.key,
  });

  /// The name the field starts with, all selected.
  final String initialName;

  /// Saves the trimmed name; answers the refusal, or `null` when it is done.
  final Future<Failure?> Function(String name) onConfirm;

  @override
  State<LibraryNameDialog> createState() => _LibraryNameDialogState();
}

class _LibraryNameDialogState extends State<LibraryNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.initialName.length,
        );

  Failure? _failure;
  bool _saving = false;

  bool get _canConfirm => !_saving && _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_canConfirm) return;

    setState(() {
      _saving = true;
      _failure = null;
    });

    final failure = await widget.onConfirm(_controller.text.trim());
    if (!mounted) return;

    if (failure == null) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _saving = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.libraryRename),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_saving,
              decoration: InputDecoration(labelText: l10n.libraryNameLabel),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => unawaited(_confirm()),
            ),
            if (_failure case final failure?) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                failure.localizedMessage(l10n),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _canConfirm ? () => unawaited(_confirm()) : null,
          child: Text(l10n.renameSubmit),
        ),
      ],
    );
  }
}
