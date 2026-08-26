import 'dart:async';

import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/catalog/domain/listing_view.dart';
import 'package:alexandria_ui/features/catalog/domain/music_metadata.dart';
import 'package:alexandria_ui/features/catalog/domain/video_metadata.dart';

/// A [CatalogGateway] that never reaches the core (Testing Specification §2.3).
///
/// Answers per type, because UC-09 is about types being listed independently:
/// one that fails must not take the others down with it (AF-02).
class FakeCatalogGateway implements CatalogGateway {
  /// Creates a gateway whose types are empty unless a test fills them.
  FakeCatalogGateway({
    Map<LibraryType, CatalogListing>? listings,
    Map<LibraryType, CatalogListing>? deleted,
  }) : listings = {...?listings},
       deleted = {...?deleted};

  /// What each type answers for active records. A type with no entry answers
  /// an empty listing.
  final Map<LibraryType, CatalogListing> listings;

  /// What each type answers for deleted records.
  ///
  /// Empty by default, which is what a library nobody has deleted from holds —
  /// and what makes UC-12 AF-01 reachable by filtering to it.
  final Map<LibraryType, CatalogListing> deleted;

  /// What [fileDetails] answers, keyed by uuid.
  ///
  /// A uuid with no entry answers the details of [aFile], so a test that only
  /// cares about the screen does not have to build one.
  final Map<String, FileDetailsOutcome> details = {};

  /// Every uuid asked for, in order.
  final List<String> detailsRequested = [];

  /// What [editMusicMetadata] answers, in order.
  ///
  /// A list rather than one outcome, so a test can have the core refuse once
  /// and accept the retry — which is the whole of AF-02: the form stays open
  /// and the owner corrects it.
  final List<MetadataEditOutcome> editOutcomes = [];

  /// Every edit asked for, in order.
  ///
  /// Empty is the assertion AF-01 and AF-04 need: neither one calls the core.
  final List<({String uuid, MusicMetadata metadata})> edits = [];

  /// What [editVideoMetadata] answers, in order (UC-16).
  ///
  /// A list rather than one outcome, so a test can have the core refuse once
  /// and accept the retry — which is the whole of AF-02.
  final List<VideoMetadataEditOutcome> videoEditOutcomes = [];

  /// Every video edit asked for, in order.
  ///
  /// Empty is the assertion AF-01 and AF-03's refusal need: neither calls the
  /// core.
  final List<({String uuid, VideoMetadata metadata})> videoEdits = [];

  /// What [renameFile] answers, in order (UC-17).
  final List<FileRenameOutcome> renameOutcomes = [];

  /// Every rename asked for, in order.
  ///
  /// Empty is the assertion AF-01 and AF-04 need: neither calls the core.
  final List<({String uuid, String name})> renames = [];

  /// Every type asked for, in order.
  ///
  /// Empty is the assertion that matters when there is no session: no catalog
  /// call is made without one (FR-AU-07).
  final List<LibraryType> requested = [];

  /// The credentials each call was made with.
  final List<String> credentials = [];

  /// The lifecycle filter each call was made with (UC-12).
  final List<LifecycleFilter> lifecycles = [];

  /// Every call to [listFiles], in order.
  ///
  /// What the music library's "one call" assertion counts. Counts every
  /// type asked for, not just audio — meaningful on its own only for a
  /// fixture that lists one type, such as the music library's. The paired
  /// `expect(gateway.detailsRequested, isEmpty)` is what actually catches a
  /// regression to per-file reads.
  int get listCalls => requested.length;

  @override
  Future<CatalogListing> listFiles({
    required LibraryType type,
    required String credential,
    LifecycleFilter lifecycle = LifecycleFilter.active,
  }) async {
    requested.add(type);
    credentials.add(credential);
    lifecycles.add(lifecycle);

    return switch (lifecycle) {
      LifecycleFilter.active =>
        listings[type] ?? const CatalogListing.loaded(files: []),
      LifecycleFilter.deleted =>
        deleted[type] ?? const CatalogListing.loaded(files: []),
      // Both together, which is what the core would answer.
      LifecycleFilter.all => switch ((listings[type], deleted[type])) {
        (final CatalogListingLoaded active, final CatalogListingLoaded gone) =>
          CatalogListing.loaded(files: [...active.files, ...gone.files]),
        (final CatalogListing only?, _) => only,
        _ => const CatalogListing.loaded(files: []),
      },
    };
  }

  @override
  Future<FileDetailsOutcome> fileDetails({
    required String uuid,
    required String credential,
  }) {
    detailsRequested.add(uuid);

    return Future.value(
      details[uuid] ??
          FileDetailsOutcome.read(
            details: FileDetails(file: aFile(uuid: uuid)),
          ),
    );
  }

  /// Adds an audio file that answers [title]/[artist]/… when its details are
  /// read, to both the audio listing and [details] in one call.
  ///
  /// The two are otherwise separate maps a test has to keep in step by hand;
  /// a music library test only ever wants "a file with these tags".
  ///
  /// [name] defaults to a name derived from [uuid]; a music area test passes
  /// one explicitly when it needs a name unmistakable enough to prove FR-CT-13
  /// by its absence from the screen.
  ///
  /// [indexedAt] lets a dashboard test (FR-CT-11, FR-CT-13) order a fixture
  /// among recently added files without building its own [aFile].
  void addAudio({
    required String uuid,
    String? name,
    String? title,
    String? artist,
    String? album,
    int? year,
    String? genre,
    int? track,
    DateTime? indexedAt,
    DateTime? missingAt,
  }) {
    final file = aFile(
      uuid: uuid,
      name: name ?? '$uuid.flac',
      indexedAt: indexedAt,
      missingAt: missingAt,
    );
    final row = FileDetails(
      file: file,
      metadata: {
        MusicField.title.wireName: ?title,
        MusicField.artist.wireName: ?artist,
        MusicField.album.wireName: ?album,
        MusicField.year.wireName: ?year?.toString(),
        MusicField.genre.wireName: ?genre,
        MusicField.track.wireName: ?track?.toString(),
      },
    );
    final existing = listings[LibraryType.audio];
    final files = existing is CatalogListingLoaded
        ? existing.files
        : const <FileDetails>[];
    listings[LibraryType.audio] = CatalogListing.loaded(files: [...files, row]);

    details[uuid] = FileDetailsOutcome.read(details: row);
  }

  /// Adds a file of [type] to that type's listing, named by [name] on disk.
  ///
  /// Unlike [addAudio], nothing is added to [details]: every type but audio is
  /// named by its file name, so a search never has a reason to read one of
  /// these back.
  void addFile({
    required String uuid,
    required String name,
    LibraryType type = LibraryType.document,
    DateTime? indexedAt,
  }) {
    final file = aFile(
      uuid: uuid,
      name: name,
      type: type,
      indexedAt: indexedAt,
    );
    final existing = listings[type];
    final files = existing is CatalogListingLoaded
        ? existing.files
        : const <FileDetails>[];
    listings[type] = CatalogListing.loaded(
      files: [
        ...files,
        FileDetails(file: file),
      ],
    );
  }

  /// Adds a document file to the document listing, named by [name] on disk.
  void addDocument({required String uuid, required String name}) =>
      addFile(uuid: uuid, name: name, type: LibraryType.document);

  /// Makes [uuid]'s details answer a failure instead of a record.
  void failDetailsFor(String uuid) {
    details[uuid] = const FileDetailsOutcome.failed(
      failure: Failure.notFound(family: CoreStatusFamily.file, code: 4),
    );
  }

  /// Makes [type]'s listing answer a failure instead of files.
  void failListing({LibraryType type = LibraryType.audio}) {
    listings[type] = const CatalogListing.failed(
      failure: Failure.notFound(family: CoreStatusFamily.file, code: 4),
    );
  }

  @override
  Future<MetadataEditOutcome> editMusicMetadata({
    required String uuid,
    required MusicMetadata metadata,
    required String credential,
  }) async {
    edits.add((uuid: uuid, metadata: metadata));
    credentials.add(credential);

    // Accepting by echoing what was sent is what the core does on success: a
    // patch is a full replace, so what it stored is what it was given.
    if (editOutcomes.isEmpty) {
      return MetadataEditOutcome.saved(metadata: metadata);
    }

    return editOutcomes.removeAt(0);
  }

  @override
  Future<VideoMetadataEditOutcome> editVideoMetadata({
    required String uuid,
    required VideoMetadata metadata,
    required String credential,
  }) async {
    videoEdits.add((uuid: uuid, metadata: metadata));
    credentials.add(credential);

    if (videoEditOutcomes.isEmpty) {
      return VideoMetadataEditOutcome.saved(metadata: metadata);
    }

    return videoEditOutcomes.removeAt(0);
  }

  @override
  Future<FileRenameOutcome> renameFile({
    required String uuid,
    required String name,
    required String credential,
  }) async {
    renames.add((uuid: uuid, name: name));
    credentials.add(credential);

    // Accepting by echoing the record with the new name is what the core does
    // on success.
    if (renameOutcomes.isEmpty) {
      return FileRenameOutcome.renamed(
        file: aFile(uuid: uuid, name: name),
      );
    }

    return renameOutcomes.removeAt(0);
  }

  /// What [fileThumbnail] answers, keyed by uuid.
  ///
  /// A uuid with no entry answers `InvalidInput` — the core's own answer for
  /// a file with no embedded picture, and the ordinary case a test does not
  /// have to opt into.
  final Map<String, FileThumbnailOutcome> thumbnails = {};

  /// Every uuid a thumbnail was asked for, in order.
  final List<String> thumbnailsRequested = [];

  /// Held open to keep a [fileThumbnail] call in flight, so a test can
  /// observe the case mid-fetch — in particular, a cover arriving after an
  /// insertion has already begun (design section 4). Completed by
  /// [releaseThumbnail].
  Completer<void>? _thumbnailGate;

  /// Makes the next [fileThumbnail] call hang until [releaseThumbnail].
  void holdThumbnail() => _thumbnailGate = Completer<void>();

  /// Lets a held [fileThumbnail] call finish.
  void releaseThumbnail() => _thumbnailGate?.complete();

  @override
  Future<FileThumbnailOutcome> fileThumbnail({
    required String uuid,
    required String credential,
  }) async {
    thumbnailsRequested.add(uuid);
    credentials.add(credential);
    await _thumbnailGate?.future;

    return thumbnails[uuid] ??
        const FileThumbnailOutcome.failed(
          failure: Failure.invalidInput(
            family: CoreStatusFamily.playback,
            code: 1,
          ),
        );
  }
}

/// A file of [type], for a test that needs one in a listing.
CatalogFile aFile({
  String uuid = '6a1f8c30-5b2e-4d71-9f03-1c2b3a4d5e6f',
  String name = 'Kind of Blue.flac',
  String? path,
  LibraryType type = LibraryType.audio,
  String contentHash = 'a-content-hash',
  int? sizeBytes,
  DateTime? mtime,
  DateTime? indexedAt,
  DateTime? missingAt,
  DateTime? deletedAt,
  bool isDeleted = false,
}) => CatalogFile(
  uuid: uuid,
  name: name,
  // Derived from the name unless a test says otherwise, so two fixture files
  // never share a path. A shared one makes a search match a file by a word
  // that is only in its neighbour name, which reads as a bug in the search.
  path: path ?? '/home/owner/music/$name',
  type: type,
  contentHash: contentHash,
  sizeBytes: sizeBytes,
  mtime: mtime,
  indexedAt: indexedAt,
  missingAt: missingAt,
  deletedAt: deletedAt,
  isDeleted: isDeleted,
);

/// A listing of [files], each wrapped as a [FileDetails] row with no
/// metadata — the shape [CatalogListing.loaded] now carries.
///
/// Most fixtures only care about the file half of a row; this is the one
/// place a bare [CatalogFile] list becomes what the gateway actually answers,
/// so a test that wants metadata alongside a file builds a [FileDetails]
/// (or uses [FakeCatalogGateway.addAudio]) instead of reaching in here.
CatalogListing loadedDetails(List<CatalogFile> files) => CatalogListing.loaded(
  files: [for (final file in files) FileDetails(file: file)],
);
