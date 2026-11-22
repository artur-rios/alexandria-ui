import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import 'catalog_file.dart';
import 'file_details.dart';
import 'file_type.dart';
import 'listing_view.dart';
import 'music_metadata.dart';
import 'video_metadata.dart';

part 'catalog_gateway.freezed.dart';

/// What listing a type produced: search's and the reviews' (UC-11, UC-34,
/// UC-37).
@freezed
sealed class CatalogListing with _$CatalogListing {
  /// The core answered with [files], which may be empty (AF-01).
  ///
  /// Each row is the same [FileDetails] record the single-file call answers:
  /// the file, its metadata, and the scalars the core extracted from it. The
  /// core's listing route answers this shape now, not a bare file — a caller
  /// that only ever wanted the file reads `.file` off each row.
  const factory CatalogListing.loaded({required List<FileDetails> files}) =
      CatalogListingLoaded;

  /// The core could not answer (AF-02, AF-04).
  const factory CatalogListing.failed({required Failure failure}) =
      CatalogListingFailed;
}

/// What reading one file produced (UC-13 main flow steps 2 and 3).
@freezed
sealed class FileDetailsOutcome with _$FileDetailsOutcome {
  /// The core answered with the record.
  const factory FileDetailsOutcome.read({required FileDetails details}) =
      FileDetailsRead;

  /// The core could not answer (AF-01, AF-05).
  const factory FileDetailsOutcome.failed({required Failure failure}) =
      FileDetailsFailed;
}

/// What editing an audio file's tags produced (UC-15 main flow step 6).
@freezed
sealed class MetadataEditOutcome with _$MetadataEditOutcome {
  /// The core validated, persisted, and echoed what it stored.
  ///
  /// It carries the stored tags rather than nothing, so the form reports what
  /// the core holds instead of what was sent.
  const factory MetadataEditOutcome.saved({required MusicMetadata metadata}) =
      MetadataEditSaved;

  /// The core refused the change (AF-02, AF-03, AF-05).
  const factory MetadataEditOutcome.failed({required Failure failure}) =
      MetadataEditFailed;
}

/// What editing a video file's metadata produced (UC-16 main flow step 5).
@freezed
sealed class VideoMetadataEditOutcome with _$VideoMetadataEditOutcome {
  /// The core validated, persisted, and echoed what it stored.
  const factory VideoMetadataEditOutcome.saved({
    required VideoMetadata metadata,
  }) = VideoMetadataEditSaved;

  /// The core refused the change (AF-02, AF-04, AF-05).
  const factory VideoMetadataEditOutcome.failed({required Failure failure}) =
      VideoMetadataEditFailed;
}

/// What renaming a file produced (UC-17 main flow step 4).
@freezed
sealed class FileRenameOutcome with _$FileRenameOutcome {
  /// The core renamed the file on disk and updated the record.
  ///
  /// It carries the record the core echoed rather than the name that was
  /// sent, so what the interface shows is what the catalog holds.
  const factory FileRenameOutcome.renamed({required CatalogFile file}) =
      FileRenamed;

  /// The core refused, or the disk did (AF-02, AF-03, AF-05).
  const factory FileRenameOutcome.failed({required Failure failure}) =
      FileRenameFailed;
}

/// The application's view of the core's catalog queries (IR-02, NFR-17).
abstract interface class CatalogGateway {
  /// The files of [type] in [lifecycle], across every library (FR-CT-06,
  /// FR-LC-03, FR-LB-04). Every file belongs to one (core 0.6.0), so nothing
  /// is left out for being in a library.
  ///
  /// [lifecycle] is the one filter the core applies itself. Defaults to active
  /// records; Deleted items asks for the deleted ones (UC-34).
  /// [type] is optional, and omitting it lists every type in one call, rather
  /// than serializing the whole catalog out of the core, across the FFI
  /// boundary and through a JSON decode once for every type. Home's counts no
  /// longer come from here: they are the core's statistics (FR-CT-22).
  Future<CatalogListing> listFiles({
    FileType? type,
    LifecycleFilter lifecycle = LifecycleFilter.active,
  });

  /// One file, with everything the core knows about it (FR-CT-05, UC-13).
  Future<FileDetailsOutcome> fileDetails({required String uuid});

  /// Replaces the video metadata of the file [uuid] identifies (FR-ME-02,
  /// UC-16).
  ///
  /// The patch is tagged `video`, and the core checks the tag against the
  /// file's own type and refuses a patch aimed at the wrong one. The whole
  /// record is sent, because the patch is a full replace: anything left out
  /// is cleared.
  Future<VideoMetadataEditOutcome> editVideoMetadata({
    required String uuid,
    required VideoMetadata metadata,
  });

  /// Replaces the tags of the audio file [uuid] identifies (FR-ME-01, UC-15).
  ///
  /// The same core call as the video edit, tagged `audio`. The whole record
  /// is sent, not the fields that changed: the patch is a full replace, so
  /// anything left out is cleared.
  Future<MetadataEditOutcome> editMusicMetadata({
    required String uuid,
    required MusicMetadata metadata,
  });

  /// Renames the file [uuid] identifies, on disk and in the catalog
  /// (FR-ME-04, UC-17).
  ///
  /// One call for both, because the core owns the file as well as the record:
  /// a disk failure leaves the catalog untouched, which is what AF-02 is able
  /// to promise.
  Future<FileRenameOutcome> renameFile({
    required String uuid,
    required String name,
  });
}
