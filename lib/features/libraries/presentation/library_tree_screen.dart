import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/presentation/file_details_view.dart';
import '../../shell/presentation/async_state_view.dart';
import '../../shell/presentation/confirmation_dialog.dart';
import '../domain/library.dart';
import 'library_name_dialog.dart';

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
        onRetry: () => ref.invalidate(libraryTreeControllerProvider(location)),
        isEmpty: (loaded) => loaded != null && loaded.isEmpty,
        emptyBuilder: (context) => Center(child: Text(l10n.libraryEmptyFolder)),
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
                      // The same as a listing row: the file, with its details
                      // one press to the right (`openFile`).
                      onTap: () => openFile(context, ref, entry.file),
                      trailing: FileDetailsButton(file: entry.file),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Said before anything is marked. Marking a folder empties part
            // of a type panel, and that is not visible until afterwards.
            Text(l10n.librariesExplanation, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                // The screen's primary action, focused so it is reachable
                // from the keyboard (FR-UX-11). Here as well as on the
                // sources screen: making a library was reachable only while
                // registering a folder or from that folder's own row, which
                // is not where an owner looking at their libraries goes to
                // add one.
                autofocus: true,
                onPressed: () => _add(context, ref),
                icon: const Icon(Icons.create_new_folder_outlined),
                label: Text(l10n.libraryAdd),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: AsyncStateView(
                value: libraries,
                onRetry: ref.read(librariesControllerProvider.notifier).reload,
                isEmpty: (libraries) => libraries.isEmpty,
                // Points at the button above rather than at another screen:
                // an empty list with nothing said reads as a broken screen.
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: l10n.libraryMove,
                              icon: const Icon(Icons.drive_file_move_outlined),
                              onPressed: () => _move(context, ref, library),
                            ),
                            IconButton(
                              tooltip: l10n.libraryRemove,
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _remove(context, ref, library),
                            ),
                          ],
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

  /// Makes a library out of a folder the owner picks.
  ///
  /// Through the sources controller rather than straight to the libraries
  /// one, which is what the folder's own row does: registering with the core
  /// and marking the folder are one action, and doing only the first leaves
  /// the sources screen still offering to mark a folder that is already a
  /// library. The mark is written only when the folder is a registered
  /// source — a library can be made of a folder that is not one.
  ///
  /// A folder picker rather than a text field, for the reason [_move] gives:
  /// the owner is naming somewhere that exists.
  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    final path = await ref.read(folderPickerProvider).pickFolder();
    // AF-01 of every picker flow here: cancelling asks for nothing.
    if (path == null || !context.mounted) return;

    // Suggested from the folder, editable before it is stored: a directory
    // called `2024-final-v2` is a path, not a title.
    final name = await askForLibraryName(context, suggestion: _folderName(path));
    if (name == null || !context.mounted) return;

    final failure = await ref
        .read(librarySourcesControllerProvider.notifier)
        .markAsLibrary(path: path, name: name);
    if (failure == null || !context.mounted) return;

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

  /// The last segment of [path], which is what the folder is called.
  ///
  /// Both separators, and trailing ones dropped: a Windows path picked at a
  /// drive's root arrives as `D:\courses\` and its name is `courses`, not
  /// the empty string after the final slash.
  String _folderName(String path) {
    final segments = path
        .split(RegExp(r'[/\\]'))
        .where((segment) => segment.isNotEmpty);

    return segments.isEmpty ? path : segments.last;
  }

  /// Points [library] at the folder it moved to.
  ///
  /// A folder picker rather than a text field: the owner is naming somewhere
  /// that exists, and typing a path is how you get a library pointed at a
  /// folder that is one character wrong.
  Future<void> _move(
    BuildContext context,
    WidgetRef ref,
    Library library,
  ) async {
    final l10n = AppLocalizations.of(context);
    final from = library.rootPath;
    final to = await ref.read(folderPickerProvider).pickFolder();
    if (to == null || !context.mounted) return;

    final failure = await ref
        .read(librariesControllerProvider.notifier)
        .move(uuid: library.uuid, rootPath: to);

    if (failure != null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failure is ConflictFailure
                ? l10n.libraryMoveConflict
                : failure.localizedMessage(l10n),
          ),
        ),
      );
      return;
    }

    // The folder's registration follows, or the next scan of it walks a
    // folder that is no longer there.
    await ref
        .read(librarySourcesControllerProvider.notifier)
        .followLibraryMove(from: from, to: to);
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

    final failure = await ref
        .read(librariesControllerProvider.notifier)
        .remove(library.uuid);

    // Surfaced and stopped here, as `_move` above does with its own refusal.
    // The two records this method changes have to move together: clearing
    // the mark after a removal the core refused leaves the folder's row
    // saying it is no longer a library while the core still has it
    // registered, and nothing on screen says the removal did not happen.
    if (failure != null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.localizedMessage(l10n))));
      return;
    }

    // The folder's own row stops claiming to be a library. Kept in step here
    // rather than by the sources controller watching the core, because the
    // two records answer different questions — the core owns what a library
    // is, the store owns what the owner chose about a folder — and only this
    // action changes both at once.
    await ref
        .read(librarySourcesControllerProvider.notifier)
        .clearLibraryMark(library.rootPath);
  }
}
