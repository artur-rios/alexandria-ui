import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../catalog/domain/catalog_file.dart';
import '../../catalog/domain/listing_view.dart';
import '../../shell/domain/shell_destination.dart';
import '../domain/library.dart';
import 'library_view_preferences.dart';

/// Which folder of each library is open (library navigation design §4).
///
/// Per library and for as long as the application runs: leaving a library and
/// coming back returns to the folder the owner was in, but nothing is stored,
/// so a restart opens every library at its top.
class LibraryViewController extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const {};

  /// Opens [path], relative to the root, in the library [uuid].
  void openFolder(String uuid, String path) {
    if (folderOf(uuid) == path) return;
    state = {...state, uuid: path};
  }

  /// The folder open in the library [uuid]: its top until another is opened.
  String folderOf(String uuid) => state[uuid] ?? '';
}

/// One library folder as the library view draws it.
class LibraryFolderView {
  /// Creates the view of [listing] as [preferences] ask for it.
  LibraryFolderView(this.listing, LibraryViewPreferences preferences)
    : folders = [...listing.folders]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
      files = sortFiles([
        for (final entry in listing.files)
          if (preferences.type == null || entry.file.type == preferences.type)
            entry.file,
      ], preferences.order);

  /// The folder as the core answered it.
  final LibraryListing listing;

  /// Its folders, A–Z, which always come first and are never filtered.
  final List<LibraryFolder> folders;

  /// Its files of the chosen type, in the chosen order.
  final List<CatalogFile> files;

  /// Whether the folder holds nothing at all.
  bool get isEmpty => listing.isEmpty;

  /// Whether the folder has files, but none of the chosen type.
  bool get filteredToNothing => listing.files.isNotEmpty && files.isEmpty;
}

/// The library [uuid]'s open folder, filtered and ordered (spec §4).
///
/// Derived rather than held: the folder, the preferences and the core's
/// answer each change on their own, and this is the one place they meet.
AsyncValue<LibraryFolderView> libraryFolder(Ref ref, String uuid) {
  final path = ref.watch(
    libraryViewControllerProvider.select((open) => open[uuid] ?? ''),
  );
  final preferences = ref.watch(libraryViewPreferencesProvider);

  return ref
      .watch(libraryTreeControllerProvider((uuid: uuid, path: path)))
      .whenData((listing) => LibraryFolderView(listing, preferences));
}

/// The files the open library folder shows, in its order, or `null` when no
/// library is shown.
///
/// What an image opened from its details moves through: the same images its
/// row was drawn among.
List<CatalogFile>? filesShownInTheOpenFolder(WidgetRef ref) =>
    switch (ref.read(shellControllerProvider)) {
      LibraryDestination(:final uuid) =>
        ref.read(libraryFolderProvider(uuid)).value?.files,
      _ => null,
    };
