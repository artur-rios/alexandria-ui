import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/domain/file_type.dart';
import '../../catalog/presentation/file_details_view.dart';
import '../../catalog/presentation/music_display_name.dart';
import '../../shell/presentation/async_state_view.dart';
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
                      leading: Icon(
                        entry.file.type == FileType.audio
                            ? Icons.music_note_outlined
                            : Icons.insert_drive_file_outlined,
                      ),
                      // A track by its title, as everywhere else, with the
                      // file's own name beneath it: in a folder view the
                      // owner may be looking for the file they saw on disk.
                      title: Text(displayName(entry.file)),
                      subtitle: entry.file.type == FileType.audio
                          ? Text(entry.file.name)
                          : null,
                      // The same as a listing row: the file, with its details
                      // one press to the right (`openFile`). A track plays
                      // through the folder's other tracks, in tree order.
                      onTap: () => openFile(
                        context,
                        ref,
                        entry.file,
                        queue: [for (final each in loaded.files) each.file],
                      ),
                      trailing: FileDetailsButton(file: entry.file),
                    ),
                ],
              ),
      ),
    );
  }
}
