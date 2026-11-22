import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../indexing/domain/index_run.dart';
import '../../shell/domain/shell_destination.dart';
import '../../shell/presentation/async_state_view.dart';
import '../../shell/presentation/confirmation_dialog.dart';
import '../domain/library.dart';
import '../domain/library_order.dart';
import 'library_name_dialog.dart';
import 'library_run_status.dart';
import 'rename_library.dart';

/// Opens Manage libraries, the dialog listing every library.
///
/// Reached from the Library menu and from the activity strip's "View all".
/// Each row renames, scans again, moves and removes its library, and shows its
/// run.
Future<void> openManageLibraries(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => const _ManageLibrariesDialog(),
);

class _ManageLibrariesDialog extends StatelessWidget {
  const _ManageLibrariesDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      // The snackbars below are drawn to the dialog's rounded edge.
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
        // A messenger and a scaffold of its own, so what an add, a scan, a
        // move or a removal answers is said inside the dialog: the shell's
        // scaffold is under the modal barrier, where a snackbar is dimmed
        // and, at the minimum window, mostly covered.
        //
        // The scaffold lets the dialog's own surface show through. Zero alpha
        // rather than `Colors.transparent`: BR-18 keeps every color literal
        // out of the widget tree.
        child: ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0),
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.libraryMenuLibraries,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Expanded(child: LibrariesView()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The libraries, as the Manage libraries dialog's content.
///
/// The one place a folder gets into Alexandria besides the Library menu's
/// "Add library…": the 0.6.0 core indexes nothing that is not a library. Each
/// library is renamed, scanned again, moved and removed from its row here, and
/// its run is shown under it.
///
/// No scaffold and no title of its own: the dialog draws both.
class LibrariesView extends ConsumerWidget {
  /// Creates the view.
  const LibrariesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final libraries = ref.watch(librariesControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.librariesExplanation, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.icon(
              // The screen's primary action, focused so it is reachable from
              // the keyboard (FR-UX-11).
              autofocus: true,
              onPressed: () => addLibrary(context, ref),
              icon: const Icon(Icons.create_new_folder_outlined),
              label: Text(l10n.libraryAdd),
            ),
            const LibraryRefreshAction(),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const LibraryRefreshReport(),
        Expanded(
          child: AsyncStateView(
            value: libraries,
            onRetry: ref.read(librariesControllerProvider.notifier).reload,
            isEmpty: (libraries) => libraries.isEmpty,
            emptyBuilder: (context) => Center(child: Text(l10n.librariesNone)),
            builder: (context, libraries) {
              // A–Z as the left menu and home list them, not in the core's
              // order: it sorts byte by byte, so "alpha" would follow "Zeta".
              final sorted = [...libraries]..sort(byLibraryName);

              return ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (context, index) =>
                    _LibraryRow(library: sorted[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LibraryRow extends ConsumerWidget {
  const _LibraryRow({required this.library});

  final Library library;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.folder_special_outlined),
            title: Text(library.name),
            subtitle: Text(library.rootPath),
            // Its folders, in the main area (library navigation design §4),
            // with the dialog out of the way.
            onTap: () {
              Navigator.of(context).pop();
              ref
                  .read(shellControllerProvider.notifier)
                  .go(LibraryDestination(library.uuid));
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.libraryRenameEntry,
                  icon: const Icon(Icons.drive_file_rename_outline),
                  onPressed: () =>
                      unawaited(renameLibrary(context, ref, library)),
                ),
                IconButton(
                  tooltip: l10n.libraryScan,
                  icon: const Icon(Icons.youtube_searched_for),
                  onPressed: () => scanLibrary(context, ref, library),
                ),
                IconButton(
                  tooltip: l10n.libraryMove,
                  icon: const Icon(Icons.drive_file_move_outlined),
                  onPressed: () => moveLibrary(context, ref, library),
                ),
                IconButton(
                  tooltip: l10n.libraryRemove,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => removeLibrary(context, ref, library),
                ),
              ],
            ),
          ),
          LibraryRunStatus(library: library),
        ],
      ),
    );
  }
}

/// Starts adding a library, where the owner is.
///
/// What the "add a library" offers on the empty dashboard, the search and
/// the left menu, and the Library menu, do: a library is the only way anything
/// gets into the catalog. No screen opens for it: the picker and the name
/// dialog open over the one showing, and [context] is the offer's own, which
/// stays mounted until the folder comes back.
void openLibrariesAndAdd(BuildContext context, WidgetRef ref) =>
    unawaited(addLibrary(context, ref));

/// Adds a folder the owner picks as a library (core FR-FC-36).
///
/// The core starts the library's first index run with it, and the run is
/// followed under the new row. A refusal — the folder is missing, outside
/// the core's root, or overlapping another library — is said over the
/// screen, and nothing is stored.
Future<void> addLibrary(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);

  final path = await ref.read(folderPickerProvider).pickFolder();
  // Cancelling the picker asks for nothing.
  if (path == null || !context.mounted) return;

  // Suggested from the folder, editable before it is stored: a directory
  // called `2024-final-v2` is a path, not a title.
  final name = await askForLibraryName(context, suggestion: _folderName(path));
  if (name == null || !context.mounted) return;

  final failure = await ref
      .read(librariesControllerProvider.notifier)
      .register(name: name, rootPath: path);
  if (failure == null || !context.mounted) return;

  _say(
    context,
    failure is ConflictFailure
        ? l10n.libraryOverlaps
        : failure.localizedMessage(l10n),
  );
}

/// Scans [library]'s folder again, and says why when the core refuses.
Future<void> scanLibrary(
  BuildContext context,
  WidgetRef ref,
  Library library,
) async {
  final l10n = AppLocalizations.of(context);

  final failure = await ref
      .read(indexRunsControllerProvider.notifier)
      .startLibraryIndex(library.uuid);
  if (failure == null || !context.mounted) return;

  _say(
    context,
    failure is ConflictFailure
        ? l10n.libraryScanConflict
        : '${l10n.libraryScanFailed} ${failure.localizedMessage(l10n)}',
  );
}

/// Points [library] at the folder it moved to.
///
/// A folder picker rather than a text field: the owner is naming somewhere
/// that exists, and typing a path is how you get a library pointed at a
/// folder that is one character wrong.
Future<void> moveLibrary(
  BuildContext context,
  WidgetRef ref,
  Library library,
) async {
  final l10n = AppLocalizations.of(context);
  final to = await ref.read(folderPickerProvider).pickFolder();
  if (to == null || !context.mounted) return;

  final failure = await ref
      .read(librariesControllerProvider.notifier)
      .move(uuid: library.uuid, rootPath: to);
  if (failure == null || !context.mounted) return;

  // A conflict is a folder overlapping another library, or a library whose
  // run is not finished: the core refuses to move a folder it is walking.
  _say(
    context,
    failure is ConflictFailure
        ? l10n.libraryMoveConflict
        : failure.localizedMessage(l10n),
  );
}

/// Removes [library] once the owner has read what that deletes.
Future<void> removeLibrary(
  BuildContext context,
  WidgetRef ref,
  Library library,
) async {
  final l10n = AppLocalizations.of(context);

  // The core deletes a paused run with its library, and the owner may be
  // counting on resuming it: said, so it is not a surprise.
  final hasPausedRun = ref
      .read(activeRunsControllerProvider)
      .runs
      .any(
        (run) =>
            run.libraryUuid == library.uuid &&
            run.status == IndexRunStatus.paused,
      );

  final confirmed = await ConfirmationDialog.show(
    context,
    title: l10n.libraryRemove,
    message: hasPausedRun
        ? '${l10n.libraryRemoveMessage(library.name)} '
              '${l10n.libraryRemovePausedNote}'
        : l10n.libraryRemoveMessage(library.name),
    confirmLabel: l10n.libraryRemove,
  );
  if (!confirmed) return;

  final failure = await ref
      .read(librariesControllerProvider.notifier)
      .remove(library.uuid);
  if (failure == null || !context.mounted) return;

  // The one conflict a removal answers: a scan of the library is running.
  _say(
    context,
    failure is ConflictFailure
        ? l10n.libraryRemoveRunning
        : failure.localizedMessage(l10n),
  );
}

/// Says [message] over whatever is showing.
///
/// On the nearest messenger: inside Manage libraries, the dialog's own; from
/// a library's header, the shell's.
void _say(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));

/// The last segment of [path], which is what the folder is called.
///
/// Both separators, and trailing ones dropped: a Windows path picked at a
/// drive's root arrives as `D:\courses\` and its name is `courses`, not the
/// empty string after the final slash.
String _folderName(String path) {
  final segments = path
      .split(RegExp(r'[/\\]'))
      .where((segment) => segment.isNotEmpty);

  return segments.isEmpty ? path : segments.last;
}
