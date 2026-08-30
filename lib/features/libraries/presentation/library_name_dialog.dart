import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';

/// Asks over [context] what to call a library, offering [suggestion].
///
/// Shared by the two places a folder becomes one — the scope dialog that asks
/// while a folder is being registered, and the action that marks a folder
/// already registered — so the question is worded once and a library named
/// from either place is named the same way.
///
/// Resolves to `null` when the owner cancels *and* when they confirm an empty
/// field: a library has to be called something, and "" is a refusal to name
/// it rather than a name.
Future<String?> askForLibraryName(
  BuildContext context, {
  required String suggestion,
}) {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: suggestion);

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.libraryAdd),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.libraryNameLabel),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: Text(l10n.libraryAdd),
        ),
      ],
    ),
  ).then((value) => (value == null || value.isEmpty) ? null : value);
}
