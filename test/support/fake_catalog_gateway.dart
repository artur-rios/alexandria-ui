import 'dart:async';

import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/domain/listing_view.dart';
import 'package:alexandria_ui/features/catalog/domain/video_metadata.dart';

/// A [CatalogGateway] that never reaches the core (Testing Specification §2.3).
///
/// Answers per type, because UC-09 is about types being listed independently:
/// one that fails must not take the others down with it (AF-02).
class FakeCatalogGateway implements CatalogGateway {
  /// Creates a gateway whose types are empty unless a test fills them.
  FakeCatalogGateway({
    Map<FileType, CatalogListing>? listings,
    Map<FileType, CatalogListing>? deleted,
  }) : listings = {...?listings},
       deleted = {...?deleted};

  /// What each type answers for active records. A type with no entry answers
  /// an empty listing.
  final Map<FileType, CatalogListing> listings;

  /// What each type answers for deleted records.
  ///
  /// Empty by default, which is what a library nobody has deleted from holds —
  /// and what makes UC-12 AF-01 reachable by filtering to it.
  final Map<FileType, CatalogListing> deleted;

  /// What [fileDetails] answers, keyed by uuid.
  ///
  /// A uuid with no entry answers the details of [aFile], so a test that only
  /// cares about the screen does not have to build one.
  final Map<String, FileDetailsOutcome> details = {};

  /// Every uuid asked for, in order.
  final List<String> detailsRequested = [];

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

  /// Every type asked for, in order. `null` is a call that asked for every
  /// type at once, which is how the counts panel reads.
  ///
  /// Empty is the assertion that matters when there is no session: no catalog
  /// call is made without one (FR-AU-07).
  final List<FileType?> requested = [];

  /// The credentials each call was made with.
  final List<String> credentials = [];

  /// The lifecycle filter each call was made with (UC-12).
  final List<LifecycleFilter> lifecycles = [];

  /// Whether each [listFiles] call asked to reach into libraries, in order.
  ///
  /// Recorded because it is the whole difference between a search that finds
  /// a library's files and one that cannot, and nothing else about the call
  /// shows it.
  final List<bool> libraryReaches = [];

  @override
  Future<CatalogListing> listFiles({
    required String credential,
    FileType? type,
    LifecycleFilter lifecycle = LifecycleFilter.active,
    bool includeLibraries = false,
  }) async {
    requested.add(type);
    credentials.add(credential);
    lifecycles.add(lifecycle);
    libraryReaches.add(includeLibraries);

    // No type is every type, as the core reads it — so the fake answers the
    // union of what it holds rather than a single bucket. The counts panel
    // asks this way, and a fake that answered nothing would let it pass
    // while showing the owner an empty catalog.
    if (type == null) {
      final files = <FileDetails>[];
      for (final each in FileType.values) {
        switch (_for(each, lifecycle)) {
          case CatalogListingLoaded(files: final rows):
            files.addAll(rows);
          // One type the core could not answer fails the whole call: there
          // is only one call, so there is no partial listing to report.
          case final CatalogListingFailed failed:
            return failed;
        }
      }
      return CatalogListing.loaded(files: files);
    }

    return _for(type, lifecycle);
  }

  CatalogListing _for(FileType type, LifecycleFilter lifecycle) =>
      switch (lifecycle) {
        LifecycleFilter.active =>
          listings[type] ?? const CatalogListing.loaded(files: []),
        LifecycleFilter.deleted =>
          deleted[type] ?? const CatalogListing.loaded(files: []),
        // Both together, which is what the core would answer.
        LifecycleFilter.all => switch ((listings[type], deleted[type])) {
          (
            final CatalogListingLoaded active,
            final CatalogListingLoaded gone,
          ) =>
            CatalogListing.loaded(files: [...active.files, ...gone.files]),
          (final CatalogListing only?, _) => only,
          _ => const CatalogListing.loaded(files: []),
        },
      };

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

  /// Adds a file of [type] to that type's listing, named by [name] on disk.
  ///
  /// Nothing is added to [details]: every type is named by its file name, so
  /// a search never has a reason to read one of these back.
  void addFile({
    required String uuid,
    required String name,
    FileType type = FileType.document,
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
      addFile(uuid: uuid, name: name, type: FileType.document);

  /// Makes [uuid]'s details answer a failure instead of a record.
  void failDetailsFor(String uuid) {
    details[uuid] = const FileDetailsOutcome.failed(
      failure: Failure.notFound(family: CoreStatusFamily.file, code: 4),
    );
  }

  /// Makes [type]'s listing answer a failure instead of files.
  void failListing({FileType type = FileType.text}) {
    listings[type] = const CatalogListing.failed(
      failure: Failure.notFound(family: CoreStatusFamily.file, code: 4),
    );
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
  String name = 'Kind of Blue.md',
  String? path,
  FileType type = FileType.text,
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
  path: path ?? '/home/owner/notes/$name',
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
/// instead of reaching in here.
CatalogListing loadedDetails(List<CatalogFile> files) => CatalogListing.loaded(
  files: [for (final file in files) FileDetails(file: file)],
);
