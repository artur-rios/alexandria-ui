import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lifecycle/application/open_file_holds.dart';
import '../../../core/di/providers.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';
import '../../catalog/domain/catalog_file.dart';
import '../application/text_editor_controller.dart';

/// The Markdown and text editor (UC-18, FR-ME-07).
///
/// A full-screen dialog, like the library-sources screen: editing a file is a
/// task the owner is in until they leave it, not a panel beside the listing —
/// and the source and its preview need the width.
class TextEditorScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const TextEditorScreen({super.key});

  /// Opens [file] for editing (main flow steps 1 and 2).
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    CatalogFile file,
  ) {
    unawaited(
      ref
          .read(textEditorControllerProvider.notifier)
          .open(uuid: file.uuid, name: file.name, stamp: file.stamp),
    );

    // UC-33 AF-04: while the editor has the file open, a deletion knows about
    // it and can close it.
    final navigator = Navigator.of(context);
    final forget = ref
        .read(openFileHoldsProvider.notifier)
        .register(
          OpenFileHold(
            uuid: file.uuid,
            close: () async {
              if (navigator.canPop()) navigator.pop();
            },
          ),
        );

    return showDialog<void>(
      context: context,
      // Dismissing from outside would be a way past AF-02's warning, so the
      // only way out is the editor's own close.
      barrierDismissible: false,
      builder: (context) => const Dialog.fullscreen(child: TextEditorScreen()),
    ).whenComplete(forget);
  }

  @override
  ConsumerState<TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends ConsumerState<TextEditorScreen> {
  /// The owner's text. Seeded when the content arrives rather than at
  /// construction, because the read is in flight while this is first built.
  final TextEditingController _controller = TextEditingController();

  /// Whether [_controller] has been filled from the loaded content.
  bool _seeded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(textEditorControllerProvider);
    final editor = ref.read(textEditorControllerProvider.notifier);

    // The content arrives after the first frame, and a reload replaces it
    // wholesale. Neither is the owner typing, so both are safe to push into
    // the field; what is not safe is doing it on every rebuild, which would
    // move the cursor as they type.
    if (state.stage != EditorStage.loading &&
        (!_seeded || (state.stage == EditorStage.clean && !state.isDirty)) &&
        _controller.text != state.content) {
      _controller.text = state.content;
      _seeded = true;
    }

    // AF-06: the session went while the editor was open. Acknowledging it is
    // what closes the editor and takes the owner to the login screen.
    ref.listen(textEditorControllerProvider, (_, next) {
      if (!next.isOpen && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });

    // FR-UX-11: save is this screen's primary action, and the owner is typing
    // when they want it. Without the shortcut the only way to it was tabbing
    // out of the field.
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyS, control: true): _SaveIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, meta: true): _SaveIntent(),
      },
      child: Actions(
        actions: {
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_) {
              // The same guard the button carries: a save that is still
              // running, or content that never loaded, has nothing to write.
              if (state.isSaving || state.stage == EditorStage.loadFailed) {
                return null;
              }
              unawaited(editor.save());
              return null;
            },
          ),
        },
        child: _editor(context, l10n, state, editor),
      ),
    );
  }

  Widget _editor(
    BuildContext context,
    AppLocalizations l10n,
    TextEditorState state,
    TextEditorController editor,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(state.name),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.editorClose,
          onPressed: () {
            // AF-02: leaving with unsaved changes asks first.
            if (editor.close()) Navigator.of(context).pop();
          },
        ),
        actions: [
          if (state.isDirty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Center(child: Text(l10n.editorUnsaved)),
            ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: FilledButton.icon(
              onPressed: state.isSaving || state.stage == EditorStage.loadFailed
                  ? null
                  : () => unawaited(editor.save()),
              icon: state.isSaving
                  ? const SizedBox(
                      width: AppSpacing.md,
                      height: AppSpacing.md,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(l10n.editorSave),
            ),
          ),
        ],
      ),
      body: switch (state.stage) {
        EditorStage.loading => const Center(child: CircularProgressIndicator()),
        EditorStage.loadFailed => _LoadFailed(state: state),
        _ => Column(
          children: [
            if (state.question != EditorQuestion.none)
              _Question(state: state, editor: editor),
            // AF-03 / FR-ME-10: a failure that is not a question of its own
            // still has to be said, and the content below it is untouched.
            if (state.failure case final failure?
                when state.question == EditorQuestion.none)
              _Banner(
                message: failure.localizedMessage(l10n),
                isError: true,
                onDismiss: editor.dismissQuestion,
              ),
            Expanded(child: _SourceAndPreview(controller: _controller)),
          ],
        ),
      },
    );
  }
}

/// Saving the editor's content (UC-18 main flow step 5).
class _SaveIntent extends Intent {
  const _SaveIntent();
}

/// The source beside its rendered preview (FR-ME-07).
///
/// Side by side where there is room and stacked where there is not, which is
/// the same rule the rest of the application follows (FR-UX-02): the preview
/// is not dropped at the narrow tier, it moves below.
class _SourceAndPreview extends StatelessWidget {
  const _SourceAndPreview({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final source = _Source(controller: controller);

    if (Breakpoint.from(context) == Breakpoint.compact) {
      return Column(
        children: [
          Expanded(child: source),
          const Divider(height: 1, thickness: 1),
          const Expanded(child: _Preview()),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: source),
        const VerticalDivider(width: 1, thickness: 1),
        const Expanded(child: _Preview()),
      ],
    );
  }
}

/// The editable source (main flow steps 3 and 4).
class _Source extends ConsumerWidget {
  const _Source({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(textEditorControllerProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        controller: controller,
        enabled: !state.isSaving,
        autofocus: true,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        // The source is text about text: a monospaced face is what makes
        // Markdown's indentation and fences readable as structure.
        style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
        decoration: const InputDecoration(border: InputBorder.none),
        onChanged: ref.read(textEditorControllerProvider.notifier).edit,
      ),
    );
  }
}

/// The live rendered preview (FR-ME-07).
class _Preview extends ConsumerWidget {
  const _Preview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(
      textEditorControllerProvider.select((state) => state.content),
    );

    return Markdown(
      data: content,
      padding: const EdgeInsets.all(AppSpacing.md),
      // Every colour and size comes from the theme, so the preview reads in
      // both of them (IR-10).
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
      selectable: true,
    );
  }
}

/// What the editor is asking, above the content it is asking about.
class _Question extends StatelessWidget {
  const _Question({required this.state, required this.editor});

  final TextEditorState state;
  final TextEditorController editor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return switch (state.question) {
      // AF-01: there was nothing to write.
      EditorQuestion.nothingToSave => _Banner(
        message: l10n.editorNothingToSave,
        onDismiss: editor.dismissQuestion,
      ),

      // AF-02: save, discard, or cancel.
      EditorQuestion.leavingWithUnsavedChanges => _Banner(
        message: l10n.editorLeaveUnsaved,
        isError: true,
        onDismiss: editor.dismissQuestion,
        actions: [
          TextButton(
            onPressed: editor.dismissQuestion,
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: editor.discardAndClose,
            child: Text(l10n.editorDiscard),
          ),
          FilledButton(
            onPressed: () => unawaited(editor.saveAndClose()),
            child: Text(l10n.editorSaveAndClose),
          ),
        ],
      ),

      // AF-05: the file changed on disk since it was read.
      EditorQuestion.changedOnDisk => _Banner(
        message: l10n.editorChangedOnDisk,
        isError: true,
        onDismiss: editor.dismissQuestion,
        actions: [
          TextButton(
            onPressed: () => unawaited(editor.reloadFromDisk()),
            child: Text(l10n.editorReload),
          ),
          FilledButton(
            onPressed: () => unawaited(editor.save(overwriting: true)),
            child: Text(l10n.editorOverwrite),
          ),
        ],
      ),

      // AF-04: the record is gone, and what was typed stays on screen until
      // the owner says otherwise.
      EditorQuestion.recordIsGone => _Banner(
        message: l10n.editorRecordGone,
        isError: true,
        onDismiss: editor.dismissQuestion,
      ),

      // AF-06: the session was rejected, and acknowledging it lets it go.
      EditorQuestion.sessionRejected => _Banner(
        message: l10n.editorSessionRejected,
        isError: true,
        actions: [
          FilledButton(
            onPressed: editor.acceptSessionRejection,
            child: Text(l10n.editorSignInAgain),
          ),
        ],
      ),

      EditorQuestion.none => const SizedBox.shrink(),
    };
  }
}

/// A message across the top of the editor, with whatever it needs answering.
class _Banner extends StatelessWidget {
  const _Banner({
    required this.message,
    this.isError = false,
    this.onDismiss,
    this.actions = const [],
  });

  final String message;
  final bool isError;
  final VoidCallback? onDismiss;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isError
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.secondaryContainer;
    final foreground = isError
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSecondaryContainer;

    return Material(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            Text(message, style: TextStyle(color: foreground)),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                ...actions,
                if (onDismiss != null && actions.isEmpty)
                  TextButton(
                    onPressed: onDismiss,
                    child: Text(AppLocalizations.of(context).editorDismiss),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// What is shown when the content could not be read at all.
class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.state});

  final TextEditorState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final failure = state.failure;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: AppSpacing.xl,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.editorCouldNotRead,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (failure != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                failure.localizedMessage(l10n),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
