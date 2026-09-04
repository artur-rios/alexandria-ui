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

/// What the owner said a folder is for: which types an index of it records,
/// and whether it is browsed as a library.
///
/// One record rather than two return values, because it is one answer to one
/// dialog — and a caller that received them separately could act on half of
/// it.
typedef FolderPurpose = ({List<FileType> types, String? libraryName});

/// Asks what a folder is for — which types an index of it records (UC-05),
/// and whether it is browsed as a library (libraries design).
///
/// The seven the core classifies into, not three buckets: "books but not
/// images" is exactly the answer the owner needs, because a folder of ebooks
/// has covers in it too. Every type is ticked by default, which is what a
/// folder registered before this choice existed still covers.
class IndexScopeDialog extends StatefulWidget {
  /// Creates the dialog, offering [libraryName] when the owner has already
  /// said this folder is one.
  const IndexScopeDialog({this.libraryName, super.key});

  /// The library name to open with, or `null` when the question is still
  /// open.
  ///
  /// Set when the folder is being added from the Libraries screen: the owner
  /// pressed "Add a library", so the box is ticked and the name filled in
  /// from the folder. Asking again there would be asking a question they
  /// have already answered — and leaving it unticked would register the
  /// folder as an ordinary source, which is not what they pressed.
  final String? libraryName;

  /// What the owner said this folder is for.
  ///
  /// One answer rather than two dialogs in a row: "which types" and "is this
  /// a library" are both the same question — what is this folder — and
  /// asking them separately would make registering a course two modal steps
  /// for one decision.
  ///
  /// Asks over [context] and resolves to the chosen types.
  ///
  /// An empty list is every type — the absence the core reads the same way,
  /// rather than a second spelling of the same answer. `null` is the owner
  /// cancelling, in every way of declining including the escape key, so a
  /// dismissal cannot be mistaken for a choice.
  static Future<FolderPurpose?> show(
    BuildContext context, {
    String? libraryName,
  }) => showDialog<FolderPurpose>(
    context: context,
    builder: (context) => IndexScopeDialog(libraryName: libraryName),
  );

  @override
  State<IndexScopeDialog> createState() => _IndexScopeDialogState();
}

class _IndexScopeDialogState extends State<IndexScopeDialog> {
  /// The types currently ticked. All of them to begin with.
  final Set<FileType> _chosen = {...FileType.values};

  /// Whether this folder is to be browsed as a library.
  late bool _asLibrary = widget.libraryName != null;

  late final TextEditingController _libraryName = TextEditingController(
    text: widget.libraryName ?? '',
  );

  bool get _isEverything => _chosen.length == FileType.values.length;

  /// Whether the answer can be given as it stands.
  ///
  /// A library has to be called something: marked but unnamed is not a state
  /// the store can hold, so it is refused by the button being unavailable
  /// rather than accepted and then explained.
  bool get _isAnswerable =>
      _chosen.isNotEmpty && (!_asLibrary || _libraryName.text.trim().isNotEmpty);

  @override
  void dispose() {
    _libraryName.dispose();
    super.dispose();
  }

  /// Answers the dialog with what the owner chose.
  ///
  /// A method rather than a closure on the button, because Return in the
  /// library-name field answers it too (FR-UX-11) and an answer assembled
  /// twice is an answer that can be assembled differently.
  void _confirm() {
    if (!_isAnswerable) return;

    Navigator.of(context).pop((
      // Everything is the absent scope, not a list of seven: one spelling
      // on both sides of the boundary.
      types: _isEverything
          ? const <FileType>[]
          : [
              for (final type in FileType.values)
                if (_chosen.contains(type)) type,
            ],
      libraryName: _asLibrary ? _libraryName.text.trim() : null,
    ));
  }

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

            const Divider(),
            // Asked here rather than in a screen of its own, because it is
            // the same question as the types above: what is this folder. A
            // course is not "some video and some documents" — it is one
            // thing, and saying so is what keeps its classes together.
            CheckboxListTile(
              value: _asLibrary,
              onChanged: (checked) =>
                  setState(() => _asLibrary = checked ?? false),
              title: Text(l10n.indexScopeAsLibrary),
              subtitle: Text(l10n.indexScopeAsLibraryBody),
            ),
            if (_asLibrary)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                child: TextField(
                  controller: _libraryName,
                  decoration: InputDecoration(
                    labelText: l10n.libraryNameLabel,
                  ),
                  onChanged: (_) => setState(() {}),
                  // Return confirms, from the one field this dialog has
                  // (FR-UX-11). It does nothing while the name is empty,
                  // which is the same rule the action below is disabled by.
                  onSubmitted: (_) => _confirm(),
                ),
              ),
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
          onPressed: !_isAnswerable ? null : _confirm,
          child: Text(l10n.indexScopeConfirm),
        ),
      ],
    );
  }
}
