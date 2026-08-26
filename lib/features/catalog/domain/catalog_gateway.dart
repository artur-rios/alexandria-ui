import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import 'catalog_file.dart';
import 'file_details.dart';
import 'library_type.dart';
import 'listing_view.dart';
import 'music_metadata.dart';
import 'video_metadata.dart';

part 'catalog_gateway.freezed.dart';

/// What listing a type produced (UC-09 main flow steps 3 and 4).
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

/// What editing a file's metadata produced (UC-15 main flow step 6).
@freezed
sealed class MetadataEditOutcome with _$MetadataEditOutcome {
  /// The core validated, persisted, and echoed what it stored.
  ///
  /// It carries the stored metadata rather than nothing, so the form reports
  /// what the core holds instead of what was sent — the two agree today, and
  /// the day they do not, this is the one that is true.
  const factory MetadataEditOutcome.saved({required MusicMetadata metadata}) =
      MetadataEditSaved;

  /// The core refused the change (AF-02, AF-03, AF-05).
  const factory MetadataEditOutcome.failed({required Failure failure}) =
      MetadataEditFailed;
}

/// What editing a video file's metadata produced (UC-16 main flow step 5).
///
/// Its own union rather than a reuse of [MetadataEditOutcome]: the two carry
/// different metadata shapes, and a single outcome holding either would push
/// the "which kind is this?" question into every caller that reads a success.
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

/// What reading a file's embedded picture produced (UC-21, FR-PL-07,
/// FR-MP-05).
@freezed
sealed class FileThumbnailOutcome with _$FileThumbnailOutcome {
  /// The core answered with the picture.
  const factory FileThumbnailOutcome.read({
    required Uint8List bytes,
    required String mimeType,
  }) = FileThumbnailRead;

  /// The core could not answer.
  ///
  /// Carries a plain [Failure] rather than distinguishing "no picture
  /// embedded" from any other reason — a file with none answers
  /// `InvalidInput`, which is common enough that the caller (Task 4's
  /// `AlbumCoverController`) treats every member of this variant, whatever
  /// the code, as "show the designed jacket instead" rather than as
  /// something worth telling the owner about.
  const factory FileThumbnailOutcome.failed({required Failure failure}) =
      FileThumbnailFailed;
}

/// The application's view of the core's catalog queries (IR-02, NFR-17).
abstract interface class CatalogGateway {
  /// The files of [type] in [lifecycle], merged across every registered
  /// folder (FR-CT-02, FR-CT-07, FR-LB-04).
  ///
  /// [lifecycle] is the one filter the core applies itself; everything else
  /// UC-12 offers is applied to what it returns. Defaults to active records,
  /// which is what a listing opens on.
  Future<CatalogListing> listFiles({
    required LibraryType type,
    required String credential,
    LifecycleFilter lifecycle = LifecycleFilter.active,
  });

  /// One file, with everything the core knows about it (FR-CT-05, UC-13).
  Future<FileDetailsOutcome> fileDetails({
    required String uuid,
    required String credential,
  });

  /// Replaces the music metadata of the audio file [uuid] identifies
  /// (FR-ME-01, UC-15).
  ///
  /// The whole record is sent, not the fields that changed: the core's patch
  /// is a full replace, so anything left out is cleared.
  Future<MetadataEditOutcome> editMusicMetadata({
    required String uuid,
    required MusicMetadata metadata,
    required String credential,
  });

  /// Replaces the video metadata of the file [uuid] identifies (FR-ME-02,
  /// UC-16).
  ///
  /// The same core call as the music edit, tagged `video` instead — the core
  /// checks the tag against the file's own type and refuses a patch aimed at
  /// the wrong one. As there, the whole record is sent, because the patch is
  /// a full replace.
  Future<VideoMetadataEditOutcome> editVideoMetadata({
    required String uuid,
    required VideoMetadata metadata,
    required String credential,
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
    required String credential,
  });

  /// The picture embedded in the file [uuid] identifies, if it carries one
  /// (FR-PL-07, UC-21).
  ///
  /// A file with none answers `InvalidInput` — common, not exceptional — so
  /// this is not named `thumbnailOrFail`: refusing is as normal an answer as
  /// reading the bytes.
  Future<FileThumbnailOutcome> fileThumbnail({
    required String uuid,
    required String credential,
  });
}
