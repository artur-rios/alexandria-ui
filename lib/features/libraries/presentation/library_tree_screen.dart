import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/presentation/file_details_view.dart';
import '../../../core/failures/failure.dart';
import '../../../core/failures/failure_messages.dart';
import '../../shell/presentation/async_state_view.dart';
import '../../shell/presentation/confirmation_dialog.dart';
import '../domain/library.dart';

/// One library, browsed as the folders it is (libraries design).
///
/// A dialog over whatever reached it, the shape every library-wide screen
/// uses. Holds which folder is open itself: it is where the owner is, not
/// something the catalog knows, and putting it in a provider would mean a
/// second library opened elsewhere shared this one's position.
class LibraryTreeScreen extends ConsumerStatefulWidget {
  /// Creates the screen for the library [uuid] identifies.
  const LibraryTreeScreen({required this.uuid, super.key});

  /// The library being browsed.
  final String uuid;

  /// Presents the screen over [context].
  static Future<void> show(BuildContext context, String uuid) =>
      showDialog<void>(
        context: context,
        builder: (context) =>
            Dialog.fullscreen(child: LibraryTreeScreen(uuid: uuid)),
      );

  @override
  ConsumerState<LibraryTreeScreen> createState() => _LibraryTreeScreenState();
}

class _LibraryTreeScreenState extends ConsumerState<LibraryTreeScreen> {
  String _path = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final location = (uuid: widget.uuid, path: _path);
    final listing = ref.watch(libraryTreeControllerProvider(location));
    final loaded = listing.value;

    return Scaffold(
      appBar: AppBar(
        // The library's name, then where in it — so the title says both
        // which course this is and which class, which is what the owner
        // needs when they are four folders deep.
        title: Text(
          _path.isEmpty
              ? (loaded?.library.name ?? '')
              : '${loaded?.library.name ?? ''} — $_path',
        ),
        leading: _path.isEmpty
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.preferencesClose,
                onPressed: () => Navigator.of(context).pop(),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: l10n.libraryUp,
                // Up a folder rather than out of the screen: the back
                // control has to mean the same thing as the tree it sits
                // over, or four levels down it throws the owner out.
                onPressed: () =>
                    setState(() => _path = loaded?.parentPath ?? ''),
              ),
      ),
      body: AsyncStateView<LibraryListing?>(
        value: listing,
        onRetry: () =>
            ref.invalidate(libraryTreeControllerProvider(location)),
        isEmpty: (loaded) => loaded != null && loaded.isEmpty,
        emptyBuilder: (context) =>
            Center(child: Text(l10n.libraryEmptyFolder)),
        builder: (context, loaded) => loaded == null
            ? const SizedBox.shrink()
            : ListView(
                children: [
                  // Folders first, then files. A tree draws them
                  // differently and the folders are how the owner moves.
                  for (final folder in loaded.folders)
                    ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(folder.name),
                      onTap: () => setState(() => _path = folder.path),
                    ),
                  for (final entry in loaded.files)
                    ListTile(
                      leading: const Icon(Icons.insert_drive_file_outlined),
                      // The file's own name here, not its metadata title:
                      // in a folder view the owner is looking for the file
                      // they saw on disk, and a lecture recording tagged
                      // with something else would be unfindable.
                      title: Text(entry.file.name),
                      onTap: () => FileDetailsView.show(
                        context,
                        ref,
                        entry.file.uuid,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// The list of registered libraries.
class LibrariesScreen extends ConsumerWidget {
  /// Creates the screen.
  const LibrariesScreen({super.key});

  /// Presents the screen over [context].
  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => const Dialog.fullscreen(child: LibrariesScreen()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final libraries = ref.watch(librariesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.librariesTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.preferencesClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: l10n.libraryAdd,
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => _add(context, ref),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Said before anything is marked. Marking a folder empties part
            // of a type panel, and that is not visible until afterwards.
            Text(
              l10n.librariesExplanation,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: AsyncStateView(
                value: libraries,
                onRetry: ref.read(librariesControllerProvider.notifier).reload,
                isEmpty: (libraries) => libraries.isEmpty,
                emptyBuilder: (context) =>
                    Center(child: Text(l10n.librariesNone)),
                builder: (context, libraries) => ListView.builder(
                  itemCount: libraries.length,
                  itemBuilder: (context, index) {
                    final library = libraries[index];

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.folder_special_outlined),
                        title: Text(library.name),
                        subtitle: Text(library.rootPath),
                        onTap: () =>
                            LibraryTreeScreen.show(context, library.uuid),
                        trailing: IconButton(
                          tooltip: l10n.libraryRemove,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _remove(context, ref, library),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Picks a folder, names it, and registers it.
  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final path = await ref.read(folderPickerProvider).pickFolder();
    if (path == null || !context.mounted) return;

    final name = await _askForName(context, path);
    if (name == null || !context.mounted) return;

    final failure = await ref
        .read(librariesControllerProvider.notifier)
        .register(name: name, rootPath: path);
    if (failure == null || !context.mounted) return;

    // A conflict is the one refusal worth its own sentence: "that folder is
    // already inside another library" is something the owner can act on,
    // where the generic message would leave them guessing which folder.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure is ConflictFailure
              ? l10n.libraryOverlaps
              : failure.localizedMessage(l10n),
        ),
      ),
    );
  }

  /// The owner's name for the library, defaulting to the folder's own.
  Future<String?> _askForName(BuildContext context, String path) {
    final l10n = AppLocalizations.of(context);
    final suggestion = path.split(RegExp(r'[/\\]')).where((p) => p.isNotEmpty);
    final controller = TextEditingController(
      text: suggestion.isEmpty ? '' : suggestion.last,
    );

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
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.libraryAdd),
          ),
        ],
      ),
    ).then((value) => (value == null || value.isEmpty) ? null : value);
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    Library library,
  ) async {
    final l10n = AppLocalizations.of(context);

    // The confirmation says the files come back. Removing must not read as
    // discarding them, or nobody undoes a folder they marked by mistake.
    final confirmed = await ConfirmationDialog.show(
      context,
      title: l10n.libraryRemove,
      message: l10n.libraryRemoveMessage(library.name),
      confirmLabel: l10n.libraryRemove,
    );
    if (!confirmed) return;

    await ref.read(librariesControllerProvider.notifier).remove(library.uuid);
  }
}
