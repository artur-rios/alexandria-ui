import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/presentation/file_details_view.dart';
import '../../shell/presentation/async_state_view.dart';
import '../../library_sources/application/index_runs_state.dart';
import '../../library_sources/domain/folder_registration.dart';
import '../../library_sources/presentation/index_scope_dialog.dart';
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
        // At the top of a library, empty means something different from
        // empty three folders down: a library is browsed out of what the
        // catalog holds beneath its root, so a root with nothing in it is
        // almost always a folder that has never been indexed rather than a
        // folder with nothing in it. Saying "nothing in this folder" there
        // describes the disk, which the owner can see is not true.
        emptyBuilder: (context) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              _path.isEmpty ? l10n.libraryEmptyRoot : l10n.libraryEmptyFolder,
              textAlign: TextAlign.center,
            ),
          ),
        ),
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

/// The registered libraries, as the navigation panel's own area.
///
/// A destination rather than a screen behind a menu: a library is somewhere
/// the owner browses, like the type panels beside it, and reaching it took
/// two clicks through a menu of tools — which is where things you *do* live,
/// not where things you *have* live.
///
/// No scaffold and no title of its own: the content area draws the
/// destination's heading, and a second one inside it would say Libraries
/// twice.
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
                              tooltip: l10n.libraryScan,
                              icon: const Icon(Icons.youtube_searched_for),
                              onPressed: () => _scan(context, ref, library),
                            ),
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
    );
  }

  /// Makes a library out of a folder the owner picks.
  ///
  /// A library is browsed entirely out of what the catalog holds beneath its
  /// root: the tree is built from indexed files, not from a walk of the disk.
  /// So a folder that has never been indexed makes a library that shows
  /// nothing — no files and no folders either — which is what this button did
  /// when all it asked the core for was the library. Whether the folder is
  /// already a registered source is therefore the question that decides what
  /// happens next, and it is why the picker is here rather than inside
  /// `registerFolder`.
  ///
  /// Registered already: its files are in the catalog, so marking it is the
  /// whole of the work — the same thing the folder's own row does, through
  /// the same call, so the core learns about the library and the folder's row
  /// stops offering to mark it.
  ///
  /// Not registered: it is registered as a source first, with the scope
  /// question every registration asks, and then indexed. The library is
  /// created before the walk starts, which is what lets each file join it as
  /// it is recorded rather than waiting for a second pass.
  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    final path = await ref.read(folderPickerProvider).pickFolder();
    // AF-01 of every picker flow here: cancelling asks for nothing.
    if (path == null || !context.mounted) return;

    final registered = ref
        .read(librarySourcesControllerProvider)
        .sources
        .where((source) => source.path == path)
        .firstOrNull;

    if (registered == null) {
      await _registerAndIndex(context, ref, path);
      return;
    }

    if (registered.libraryName != null) {
      // Nothing to do, and saying so beats a button that appears to do
      // nothing: the library is already in the list behind the dialog.
      _say(context, l10n.libraryAlreadyOne);
      return;
    }

    // Suggested from the folder, editable before it is stored: a directory
    // called `2024-final-v2` is a path, not a title.
    final name = await askForLibraryName(
      context,
      suggestion: registered.label,
    );
    if (name == null || !context.mounted) return;

    final failure = await ref
        .read(librarySourcesControllerProvider.notifier)
        .markAsLibrary(path: path, name: name);
    if (failure == null || !context.mounted) return;

    _say(
      context,
      failure is ConflictFailure
          ? l10n.libraryOverlaps
          : failure.localizedMessage(l10n),
    );
  }

  /// Registers [path] as a source, as a library, and indexes it.
  ///
  /// One dialog for both questions, which is the dialog registration already
  /// asks: the library box comes ticked and the name filled in from the
  /// folder, because pressing "Add a library" is the owner answering that
  /// question already. What is still open is the scope — a course folder
  /// holds recordings and handouts, and which of them the index records is
  /// not something this button can assume.
  ///
  /// The index run is started here rather than inside the controller, for
  /// the reason the sources screen gives: registering and indexing stay
  /// separately testable, and this is the caller that wants both.
  Future<void> _registerAndIndex(
    BuildContext context,
    WidgetRef ref,
    String path,
  ) async {
    final l10n = AppLocalizations.of(context);

    final source = await ref
        .read(librarySourcesControllerProvider.notifier)
        .registerFolder(
          path: path,
          onOverlapConfirmed: (path, existing) async {
            if (!context.mounted) return false;

            return ConfirmationDialog.show(
              context,
              title: l10n.librarySourcesOverlapTitle,
              message: l10n.librarySourcesOverlapBody(path, existing.label),
              confirmLabel: l10n.librarySourcesOverlapConfirm,
            );
          },
          onScopeChosen: (path) async {
            if (!context.mounted) return null;

            return IndexScopeDialog.show(
              context,
              libraryName: _folderName(path),
            );
          },
        );

    if (source == null) {
      // Refused rather than cancelled: the sources screen renders its refusal
      // notice from the same state, and this screen has nowhere to put one —
      // so the reason is said here instead of being left to a button that
      // looks broken.
      if (!context.mounted) return;
      final refusal = _refusalMessage(ref, l10n);
      if (refusal != null) _say(context, refusal);
      return;
    }

    // A source folder that is not indexed is not in the library yet — and a
    // library made of one shows nothing at all, which is the failure this
    // whole path exists to avoid.
    await ref
        .read(indexRunsControllerProvider.notifier)
        .startIndex(source.path);

    if (!context.mounted) return;
    final refusal = _startRefusalMessage(ref, l10n, source.path);
    if (refusal != null) _say(context, refusal);
  }

  /// Indexes a library's folder, so what is on disk reaches the catalog and
  /// so the library.
  ///
  /// The way out of an empty library, offered where the empty library is
  /// seen. A library made before this screen registered and indexed the
  /// folder for you — or one whose folder was registered but never
  /// scanned — holds nothing at all, and the remedy was on another screen
  /// entirely.
  ///
  /// A folder that is not a registered source is registered first, because
  /// an index run is refused for a folder the application does not know.
  /// The scope is asked for the same way registration asks it, and the
  /// library question is not: this folder is already a library, and asking
  /// again would offer to make it one twice.
  Future<void> _scan(BuildContext context, WidgetRef ref, Library library) async {
    final root = library.rootPath;
    final known = ref
        .read(librarySourcesControllerProvider)
        .sources
        .any((source) => source.path == root);

    if (!known) {
      final source = await ref
          .read(librarySourcesControllerProvider.notifier)
          .registerFolder(
            path: root,
            onOverlapConfirmed: (path, existing) async => true,
            onScopeChosen: (path) async {
              if (!context.mounted) return null;

              return IndexScopeDialog.show(context);
            },
          );
      if (source == null || !context.mounted) return;
    }

    await ref.read(indexRunsControllerProvider.notifier).startIndex(root);

    // A run that was refused before the core was called says so here: this
    // screen has no row to carry the notice the sources screen puts under
    // the folder, and a scan that quietly does nothing is what sent the
    // owner looking in the first place.
    if (!context.mounted) return;
    final refusal = _startRefusalMessage(ref, l10nOf(context), root);
    if (refusal != null) _say(context, refusal);
  }

  /// The localizations, from a context this screen owns.
  AppLocalizations l10nOf(BuildContext context) => AppLocalizations.of(context);

  /// Why a run did not start, or `null` when one did.
  String? _startRefusalMessage(
    WidgetRef ref,
    AppLocalizations l10n,
    String root,
  ) {
    final runs = ref.read(indexRunsControllerProvider);
    if (runs.refusedSecondRunFor == root) return l10n.librarySourcesRunRefused;

    return switch (runs.startRefusalFor(root)) {
      IndexStartRefusal.unreadableScope =>
        l10n.librarySourcesStartUnreadableScope,
      IndexStartRefusal.notRegistered => l10n.librarySourcesStartNotRegistered,
      null => null,
    };
  }

  /// What the registration refused, or `null` when it was cancelled.
  ///
  /// The same three conditions FR-LB-02 requires be told apart, worded as
  /// the sources screen's own notice words them.
  String? _refusalMessage(WidgetRef ref, AppLocalizations l10n) {
    final state = ref.read(librarySourcesControllerProvider);
    final path = state.refusedPath ?? '';

    return switch (state.refusal) {
      FolderRegistrationVerdict.missing => l10n.librarySourcesMissing(path),
      FolderRegistrationVerdict.unreadable => l10n.librarySourcesUnreadable(
        path,
      ),
      FolderRegistrationVerdict.alreadyRegistered =>
        l10n.librarySourcesAlreadyRegistered,
      // Not refusals: one is the acceptable verdict and the other is
      // answered by the confirmation above. Both reach here only when the
      // owner cancelled, which is not something to report.
      FolderRegistrationVerdict.overlaps ||
      FolderRegistrationVerdict.acceptable ||
      null => null,
    };
  }

  /// Says [message] over whatever is showing.
  void _say(BuildContext context, String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

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
