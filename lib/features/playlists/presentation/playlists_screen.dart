import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shell/presentation/async_state_view.dart';
import '../../shell/presentation/confirmation_dialog.dart';
import '../application/playlists_controller.dart';
import '../domain/playlist.dart';

/// The playlists screen (playlists design).
///
/// Reached from the Library menu, like collections and reading lists: a
/// playlist holds tracks rather than belonging to one file type, so it is not
/// a destination of its own (FR-CT-01).
class PlaylistsScreen extends ConsumerWidget {
  /// Creates the screen.
  const PlaylistsScreen({super.key});

  /// Presents the screen over [context].
  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => const Dialog.fullscreen(child: PlaylistsScreen()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playlists = ref.watch(playlistsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.playlistsTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.preferencesClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _NameField(),
            const _Notice(),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: AsyncStateView(
                value: playlists,
                onRetry: ref.read(playlistsControllerProvider.notifier).reload,
                isEmpty: (playlists) => playlists.isEmpty,
                emptyBuilder: (context) =>
                    Center(child: Text(l10n.playlistsNone)),
                builder: (context, playlists) => ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (context, index) =>
                      _PlaylistTile(playlist: playlists[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where a playlist is named — created, or renamed.
///
/// One field for both, because they are the same question asked twice: the
/// only difference is whether a playlist is open for renaming, and that is
/// what the state carries.
class _NameField extends ConsumerStatefulWidget {
  const _NameField();

  @override
  ConsumerState<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends ConsumerState<_NameField> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(playlistsFormProvider);
    final form = ref.read(playlistsFormProvider.notifier);
    final renaming = state.renaming != null;

    // Seeded when a rename opens, and cleared when a write succeeds — the two
    // times the field's text is not the owner's to keep.
    if (state.name != _name.text && !state.isWriting) {
      _name.text = state.name;
      _name.selection = TextSelection.collapsed(offset: _name.text.length);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _name,
            enabled: !state.isWriting,
            decoration: InputDecoration(
              labelText: renaming
                  ? l10n.playlistRenameLabel
                  : l10n.playlistNameLabel,
              // A blank name is marked and never sent (the same courtesy
              // reading lists and collections apply).
              errorText: state.nameError == null
                  ? null
                  : l10n.playlistNameEmpty,
            ),
            onChanged: form.editName,
            onSubmitted: (_) => unawaited(
              renaming ? form.renameSubmitted() : form.create(),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: FilledButton.icon(
            onPressed: state.isWriting
                ? null
                : () => unawaited(
                    renaming ? form.renameSubmitted() : form.create(),
                  ),
            icon: Icon(renaming ? Icons.check : Icons.add),
            label: Text(
              renaming ? l10n.playlistRenameSave : l10n.playlistCreate,
            ),
          ),
        ),
        if (renaming) ...[
          const SizedBox(width: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: TextButton(
              onPressed: form.cancelRenaming,
              child: Text(l10n.cancel),
            ),
          ),
        ],
      ],
    );
  }
}

/// Whatever the core refused, and nothing else — a blank name is answered
/// inline on the field itself.
class _Notice extends ConsumerWidget {
  const _Notice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(playlistsFormProvider);
    if (state.notice == PlaylistNotice.none) return const SizedBox.shrink();

    final message = switch (state.notice) {
      PlaylistNotice.notFound => l10n.playlistNotFound,
      PlaylistNotice.refused =>
        state.refusal?.localizedMessage(l10n) ?? l10n.playlistNotFound,
      PlaylistNotice.none => '',
    };

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: ref.read(playlistsFormProvider.notifier).acknowledge,
            child: Text(l10n.editorDismiss),
          ),
        ],
      ),
    );
  }
}

/// One playlist.
class _PlaylistTile extends ConsumerWidget {
  const _PlaylistTile({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: ListTile(
        leading: const Icon(Icons.queue_music_outlined),
        title: Text(playlist.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.playlistRename,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => ref
                  .read(playlistsFormProvider.notifier)
                  .startRenaming(
                    uuid: playlist.uuid,
                    currentName: playlist.name,
                  ),
            ),
            IconButton(
              tooltip: l10n.playlistDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => unawaited(_delete(context, ref)),
            ),
          ],
        ),
      ),
    );
  }

  /// The confirmation states that the tracks themselves are kept and only
  /// the playlist goes: the core deletes the playlist and its entries, never
  /// the files (FR-UX-10, BR-07).
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await ConfirmationDialog.show(
      context,
      title: l10n.playlistDelete,
      message: l10n.playlistDeleteMessage(playlist.name),
      confirmLabel: l10n.playlistDelete,
    );
    if (!confirmed) return;

    await ref.read(playlistsFormProvider.notifier).delete(playlist.uuid);
  }
}
