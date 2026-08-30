import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/domain/file_type.dart';

/// What [type] is called, for an owner rather than for the core (FR-CT-02).
///
/// Here rather than on [FileType] itself: the enum is the core's
/// vocabulary and the domain layer does not localize (BR-02, IR-11).
String fileTypeLabel(FileType type, AppLocalizations l10n) =>
    switch (type) {
      FileType.audio => l10n.fileTypeAudio,
      FileType.video => l10n.fileTypeVideo,
      FileType.document => l10n.fileTypeDocument,
      FileType.comic => l10n.fileTypeComic,
      FileType.text => l10n.fileTypeText,
      FileType.html => l10n.fileTypeHtml,
      FileType.image => l10n.fileTypeImage,
    };

/// Asks what a folder is for — which types an index of it records (UC-05).
///
/// The seven the core classifies into, not three buckets: "books but not
/// images" is exactly the answer the owner needs, because a folder of ebooks
/// has covers in it too. Every type is ticked by default, which is what a
/// folder registered before this choice existed still covers.
class IndexScopeDialog extends StatefulWidget {
  /// Creates the dialog.
  const IndexScopeDialog({super.key});

  /// Asks over [context] and resolves to the chosen types.
  ///
  /// An empty list is every type — the absence the core reads the same way,
  /// rather than a second spelling of the same answer. `null` is the owner
  /// cancelling, in every way of declining including the escape key, so a
  /// dismissal cannot be mistaken for a choice.
  static Future<List<FileType>?> show(BuildContext context) =>
      showDialog<List<FileType>>(
        context: context,
        builder: (context) => const IndexScopeDialog(),
      );

  @override
  State<IndexScopeDialog> createState() => _IndexScopeDialogState();
}

class _IndexScopeDialogState extends State<IndexScopeDialog> {
  /// The types currently ticked. All of them to begin with.
  final Set<FileType> _chosen = {...FileType.values};

  bool get _isEverything => _chosen.length == FileType.values.length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      // Scrollable rather than sized: seven rows plus the heading do not fit
      // the 640-high window NFR-07 requires the interface stay usable in, and
      // a dialog that overflows there is one the owner cannot answer.
      scrollable: true,
      title: Text(l10n.indexScopeTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.indexScopeBody, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            CheckboxListTile(
              value: _isEverything,
              // The owner reaches "all" in one action from any state; the
              // seven below say which "all" that is, rather than the choice
              // living in a mode they cannot see inside.
              //
              // Read before the set is touched: asking `_isEverything` after
              // clearing it answers about the cleared set, which turns this
              // row into one that never unticks anything.
              onChanged: (_) => setState(() {
                final everything = _isEverything;
                _chosen.clear();
                if (!everything) _chosen.addAll(FileType.values);
              }),
              title: Text(l10n.indexScopeAll),
            ),
            const Divider(),
            for (final type in FileType.values)
              CheckboxListTile(
                value: _chosen.contains(type),
                onChanged: (checked) => setState(() {
                  checked ?? false ? _chosen.add(type) : _chosen.remove(type);
                }),
                title: Text(fileTypeLabel(type, l10n)),
              ),
            if (_chosen.isEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.indexScopeEmpty,
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
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          autofocus: true,
          // A folder scoped to nothing would record nothing, which is not an
          // answer any owner means to give — so it is refused by being
          // unavailable rather than accepted and then explained.
          onPressed: _chosen.isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  // Everything is the absent scope, not a list of seven: one
                  // spelling on both sides of the boundary.
                  _isEverything
                      ? const <FileType>[]
                      : [
                          for (final type in FileType.values)
                            if (_chosen.contains(type)) type,
                        ],
                ),
          child: Text(l10n.indexScopeConfirm),
        ),
      ],
    );
  }
}
