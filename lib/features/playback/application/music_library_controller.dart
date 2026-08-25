import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../catalog/domain/catalog_file.dart';
import '../../catalog/domain/catalog_gateway.dart';
import '../../catalog/domain/library_type.dart';
import '../../catalog/domain/music_metadata.dart';
import '../domain/music_grouping.dart';

/// The library as far as it has been read (UC-46 main flow step 1).
///
/// Entries and a total rather than a bare list, because the area draws itself
/// from a partial answer: what it has, and how much is still coming.
class MusicLibrary {
  /// Creates a library.
  const MusicLibrary({required this.entries, required this.total});

  /// Nothing read yet.
  static const MusicLibrary empty = MusicLibrary(entries: [], total: 0);

  /// The tracks whose metadata has arrived.
  final List<MusicEntry> entries;

  /// How many audio files the listing found.
  final int total;

  /// Whether every file's metadata has been read.
  bool get isComplete => entries.length >= total;
}

/// Every audio file with its metadata (UC-20 main flow step 3, UC-46,
/// FR-PL-06, FR-CT-13).
///
/// The core's listing answers `File` records and no metadata, and it publishes
/// no "files by album" query — so the album a track belongs to is only
/// knowable by reading each file. This does exactly that, once, and holds the
/// result for the run.
///
/// It publishes the entries as they arrive rather than one all-or-nothing
/// future: browsing needs this data to draw its first screen, and a library of
/// a few thousand tracks is a few thousand calls. An area that fills in is the
/// difference between a wait and a hang. The cost itself is the core's shape
/// rather than a choice made here — BR-02 forbids inventing the narrower call
/// this would rather have.
class MusicLibraryController extends AsyncNotifier<MusicLibrary> {
  @override
  Future<MusicLibrary> build() async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return MusicLibrary.empty;

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

    if (files.isEmpty) {
      return const MusicLibrary(entries: [], total: 0);
    }

    final resolved = <String, MusicEntry>{};

    // Fired for every file up front rather than one at a time: a reader is
    // free to read `state` while this is still running (that is the whole
    // point), but `AsyncNotifier.future` resolves with the *first* state this
    // publishes and then never again — a Riverpod guarantee, not a choice
    // made here. Firing sequentially would make that first publish whatever
    // the single earliest reply happened to be, which the code below has no
    // way to distinguish from "that is the whole library". Firing every call
    // together and waiting a beat before the first publish lets replies that
    // land close together — the common case, since nothing here is genuinely
    // slower than anything else — settle into one complete publish, so a
    // reader who only ever awaits `.future` still gets the whole library
    // rather than whichever file happened to answer first.
    final pending = <String, Future<void>>{
      for (final file in files)
        file.uuid: gateway
            .fileDetails(uuid: file.uuid, credential: credential)
            .then((details) {
              // A file whose details will not come back is still a file that
              // can be played: it joins the library with no album and no
              // artist, which makes it an album of one rather than absent
              // from its own queue, and puts it in the untagged group where
              // browsing can find it.
              resolved[file.uuid] = MusicEntry(
                file: file,
                metadata: switch (details) {
                  FileDetailsRead(:final details) => MusicMetadata.fromDetails(
                    details.metadata,
                  ),
                  FileDetailsFailed() => const MusicMetadata(),
                },
              );
            }),
    };

    // In file order, not arrival order: two owners browsing the same library
    // should see the same list grow in the same place, not tracks jumping in
    // wherever their reply happened to land.
    List<MusicEntry> entriesSoFar() => [
      for (final file in files)
        if (resolved.containsKey(file.uuid)) resolved[file.uuid]!,
    ];

    while (resolved.length < files.length) {
      // At least one reply has to land before there is anything new to
      // publish.
      await Future.any(
        pending.entries
            .where((entry) => !resolved.containsKey(entry.key))
            .map((entry) => entry.value),
      );
      // The beat mentioned above: give replies that were already on their way
      // a turn of the event loop to land too, so they join this publish
      // instead of trailing it by one.
      await Future<void>.delayed(Duration.zero);

      state = AsyncData(
        MusicLibrary(entries: entriesSoFar(), total: files.length),
      );
    }

    return MusicLibrary(entries: entriesSoFar(), total: files.length);
  }
}
