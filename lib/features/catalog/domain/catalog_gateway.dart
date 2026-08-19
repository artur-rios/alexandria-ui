import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import 'catalog_file.dart';
import 'file_details.dart';
import 'library_type.dart';
import 'listing_view.dart';
import 'music_metadata.dart';

part 'catalog_gateway.freezed.dart';

/// What listing a type produced (UC-09 main flow steps 3 and 4).
@freezed
sealed class CatalogListing with _$CatalogListing {
  /// The core answered with [files], which may be empty (AF-01).
  const factory CatalogListing.loaded({required List<CatalogFile> files}) =
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
}
