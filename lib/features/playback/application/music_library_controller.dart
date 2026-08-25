import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
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

/// Every audio file with its metadata, once every file has been read (UC-20
/// main flow step 3, UC-46, FR-PL-06, FR-CT-13).
///
/// The core's listing answers `File` records and no metadata, and it publishes
/// no "files by album" query — so the album a track belongs to is only
/// knowable by reading each file. This does exactly that, once, and holds the
/// result for the run.
///
/// One file at a time, in the order the listing gave them, and never
/// concurrently: every core call — this one included — crosses into a single
/// worker isolate that serves requests FIFO (see `core_isolate.dart`), so
/// firing several `fileDetails`
/// calls at once buys no parallelism. It would only queue this scan ahead of
/// every other core call the application makes while it runs — playback
/// source resolution, a listing, a sign-in — behind it. The cost of N calls is
/// the core's own shape rather than a choice made here; BR-02 forbids
/// inventing the narrower call this would rather have.
///
/// `build` never assigns `state` before it returns. `AsyncNotifier.future`
/// resolves once, with the *first* state ever published, not with whatever
/// `build` eventually returns — publishing here would mean a reader who awaits
/// `.future`, such as `audio_playback_controller.dart`'s queue builder, could
/// permanently lock onto a library of one file. `musicLibraryProgressProvider`
/// is where "everything read so far" is published instead; a queue must never
/// be built from it.
class MusicLibraryController extends AsyncNotifier<MusicLibrary> {
  @override
  Future<MusicLibrary> build() async {
    // Set the moment this `build` stops being the live one: invalidating a
    // non-autoDispose provider — the area's own Retry, or sign-out — rebuilds
    // this *same* element in place rather than disposing it, so `ref.mounted`
    // never turns false here and cannot be the guard. `ref.onDispose` does
    // fire at that moment, though: `invalidateSelf` runs every registered
    // `onDispose` callback before it reruns `build`, which is exactly the
    // signal a still-running `build` from the run being replaced needs to
    // know it is now the orphan.
    var isCurrent = true;
    ref.onDispose(() => isCurrent = false);

    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return MusicLibrary.empty;

    final gateway = ref.read(catalogGatewayProvider);
    final listing = await gateway.listFiles(
      type: LibraryType.audio,
      credential: credential,
    );

    final List<CatalogFile> files;
    switch (listing) {
      case CatalogListingLoaded(files: final loaded):
        files = loaded;

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

    if (files.isEmpty) return MusicLibrary.empty;

    final progress = ref.read(musicLibraryProgressProvider.notifier);
    final entries = <MusicEntry>[];
    for (final file in files) {
      final details = await gateway.fileDetails(
        uuid: file.uuid,
        credential: credential,
      );

      // Checked right after the `await` that could have outlived this run:
      // without it, an orphaned scan would keep awaiting `fileDetails` for
      // every remaining file, queuing its calls ahead of whatever replaced it
      // on the single FIFO core isolate, and its next `publish` would throw
      // `UnmountedRefException` into the progress notifier a new run now
      // owns.
      if (!isCurrent) return MusicLibrary.empty;

      // A file whose details will not come back is still a file that can be
      // played: it joins the library with no album and no artist, which makes
      // it an album of one rather than absent from its own queue, and puts it
      // in the untagged group where browsing can find it.
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

      // Published to the progress provider rather than to this notifier's own
      // state: this is what lets the area show the artists it already knows
      // while the rest are still being read, without touching what `.future`
      // resolves to.
      progress.publish(
        MusicLibrary(entries: [...entries], total: files.length),
      );
    }

    return MusicLibrary(entries: entries, total: files.length);
  }
}

/// "Everything read so far", updated as [MusicLibraryController] reads each
/// file (UC-46).
///
/// The browsing area's rows and progress line are drawn from this while the
/// library is still loading; [musicLibraryProvider] is drawn from for
/// everything else, including any track queue, because it is the one that
/// answers "everything" — once, and only once complete. A plain [Notifier]
/// rather than another `AsyncNotifier`, because nothing should ever await this
/// one through `.future`: every watcher here is a live listener that sees
/// every publish in order, which a `Future` — resolved exactly once — cannot
/// offer.
class MusicLibraryProgress extends Notifier<MusicLibrary> {
  @override
  MusicLibrary build() => MusicLibrary.empty;

  /// Records another publish from [MusicLibraryController].
  void publish(MusicLibrary snapshot) => state = snapshot;
}
