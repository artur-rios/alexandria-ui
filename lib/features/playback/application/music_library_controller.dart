import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../catalog/domain/catalog_file.dart';
import '../../catalog/domain/catalog_gateway.dart';
import '../../catalog/domain/file_type.dart';
import '../../catalog/domain/music_metadata.dart';
import '../domain/music_grouping.dart';

/// Every audio file the catalog holds (UC-46 main flow step 1).
class MusicLibrary {
  /// Creates a library.
  const MusicLibrary({required this.entries});

  /// Nothing catalogued.
  static const MusicLibrary empty = MusicLibrary(entries: []);

  /// The tracks, each with its metadata.
  final List<MusicEntry> entries;

  /// [file]'s own entry, or an untitled placeholder when the library holds
  /// nothing for it — not loaded yet, or the file was never catalogued as
  /// audio.
  ///
  /// The one lookup every reader of a track's metadata shares — the bar, the
  /// search results and `AlbumAnimationController` alike (UC-20, UC-21,
  /// FR-CT-13) — so which file a candidate matches is decided in exactly one
  /// place.
  MusicEntry entryFor(CatalogFile file) => entries.firstWhere(
    (candidate) => candidate.file.uuid == file.uuid,
    orElse: () => MusicEntry(file: file, metadata: const MusicMetadata()),
  );
}

/// Every audio file with its metadata (UC-20 main flow step 3, UC-46,
/// FR-PL-06, FR-CT-13).
///
/// One gateway call: the core's listing answers each row with the same
/// metadata the single-file call does, so the album a track belongs to is
/// known from the listing itself and nothing further has to be asked per
/// file.
class MusicLibraryController extends AsyncNotifier<MusicLibrary> {
  @override
  Future<MusicLibrary> build() async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return MusicLibrary.empty;

    final gateway = ref.read(catalogGatewayProvider);
    final listing = await gateway.listFiles(
      type: FileType.audio,
      credential: credential,
    );

    switch (listing) {
      case CatalogListingLoaded(:final files):
        return MusicLibrary(
          entries: [
            for (final row in files)
              MusicEntry(
                file: row.file,
                metadata: MusicMetadata.fromDetails(row.metadata),
              ),
          ],
        );

      // AF-04-equivalent: the core rejected the session. Discarding it
      // returns the owner to login, as `ListingController` does; the failure
      // is still thrown so this does not read as an empty library on the
      // way out.
      case CatalogListingFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        throw failure;

      // Thrown rather than returned empty: every other type's listing does
      // the same (UC-09 AF-02), and a disk or core failure reading as "No
      // audio files are catalogued yet" would be a lie the owner has no way
      // to tell from the truth.
      case CatalogListingFailed(:final failure):
        throw failure;
    }
  }
}
