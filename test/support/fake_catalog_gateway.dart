import 'package:alexandria_desktop/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_desktop/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_desktop/features/catalog/domain/file_details.dart';
import 'package:alexandria_desktop/features/catalog/domain/library_type.dart';
import 'package:alexandria_desktop/features/catalog/domain/listing_view.dart';
import 'package:alexandria_desktop/features/catalog/domain/music_metadata.dart';
import 'package:alexandria_desktop/features/catalog/domain/video_metadata.dart';

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
  }) async {
    detailsRequested.add(uuid);

    return details[uuid] ??
        FileDetailsOutcome.read(
          details: FileDetails(file: aFile(uuid: uuid)),
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
}

/// A file of [type], for a test that needs one in a listing.
CatalogFile aFile({
  String uuid = '6a1f8c30-5b2e-4d71-9f03-1c2b3a4d5e6f',
  String name = 'Kind of Blue.flac',
  String? path,
  LibraryType type = LibraryType.audio,
  String contentHash = 'a-content-hash',
  DateTime? indexedAt,
  DateTime? missingAt,
}) => CatalogFile(
  uuid: uuid,
  name: name,
  // Derived from the name unless a test says otherwise, so two fixture files
  // never share a path. A shared one makes a search match a file by a word
  // that is only in its neighbour name, which reads as a bug in the search.
  path: path ?? '/home/owner/music/$name',
  type: type,
  contentHash: contentHash,
  indexedAt: indexedAt,
  missingAt: missingAt,
);
