import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../core/failures/failure.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';

/// Asks over [context] what to call a library, offering [suggestion].
///
/// Used when a library is added, from the Library menu's "Add library…", the
/// Manage libraries dialog or an empty screen's offer. [LibraryNameDialog]
/// itself is also the one a library is renamed with, so the question is
/// worded once and a library is named the same way whether it is new or not.
///
/// Resolves to `null` when the owner cancels. Confirm is disabled while the
/// field is blank, the same rule as when a library is renamed: a library has
/// to be called something.
Future<String?> askForLibraryName(
  BuildContext context, {
  required String suggestion,
}) {
  final l10n = AppLocalizations.of(context);

  return showDialog<String>(
    context: context,
    builder: (context) => LibraryNameDialog(
      title: l10n.libraryAdd,
      confirmLabel: l10n.libraryAdd,
      initialName: suggestion,
      onConfirm: (_) async => null,
    ),
  );
}

/// The dialog asking for a library's name.
class LibraryNameDialog extends StatefulWidget {
  /// Creates the dialog, prefilled with [initialName].
  const LibraryNameDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialName,
    required this.onConfirm,
    super.key,
  });

  /// What the dialog is for, as its title.
  final String title;

  /// What the confirming button says.
  final String confirmLabel;

  /// The name the field starts with, all selected.
  final String initialName;

  /// Saves the trimmed name; answers the refusal, or `null` when it is done.
  ///
  /// Called only for a non-blank name. The dialog closes on `null`, handing
  /// the name back to whoever opened it.
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

    final name = _controller.text.trim();
    final failure = await widget.onConfirm(name);
    if (!mounted) return;

    if (failure == null) {
      Navigator.of(context).pop(name);
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
      title: Text(widget.title),
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
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
