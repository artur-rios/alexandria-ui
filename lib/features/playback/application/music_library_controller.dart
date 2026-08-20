import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../catalog/domain/catalog_file.dart';
import '../../catalog/domain/catalog_gateway.dart';
import '../../catalog/domain/library_type.dart';
import '../../catalog/domain/music_metadata.dart';
import '../domain/music_grouping.dart';

/// Every audio file with the metadata a queue is grouped by (UC-20 main flow
/// step 3, FR-PL-06).
///
/// The core's listing answers `File` records and no metadata, and it publishes
/// no "files by album" query — so the album a track belongs to is only
/// knowable by reading each file. This does exactly that, once, and holds the
/// result for the run.
///
/// That is a real cost, and it is the core's shape rather than a choice made
/// here: BR-02 forbids inventing the narrower call this would rather have.
/// It is loaded when an album or an artist is first asked for, not at startup,
/// so an owner who only ever plays single tracks never pays it.
class MusicLibraryController extends AsyncNotifier<List<MusicEntry>> {
  @override
  Future<List<MusicEntry>> build() async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return const [];

    final gateway = ref.read(catalogGatewayProvider);
    final listing = await gateway.listFiles(
      type: LibraryType.audio,
      credential: credential,
    );

    final List<CatalogFile> files = switch (listing) {
      CatalogListingLoaded(:final files) => files,
      // A listing that failed groups nothing. The player reports the failure
      // it gets from playing, and the queue is a single track.
      CatalogListingFailed() => const [],
    };

    final entries = <MusicEntry>[];
    for (final file in files) {
      final details = await gateway.fileDetails(
        uuid: file.uuid,
        credential: credential,
      );

      // A file whose details will not come back is still a file that can be
      // played: it joins the library with no album and no artist, which makes
      // it an album of one rather than absent from its own queue.
      entries.add(
        MusicEntry(
          file: file,
          metadata: switch (details) {
            FileDetailsRead(:final details) => MusicMetadata.fromDetails(
              details.metadata,
            ),
            FileDetailsFailed() => const MusicMetadata(),
          },
        ),
      );
    }

    return entries;
  }
}
