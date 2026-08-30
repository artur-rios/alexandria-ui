import 'package:freezed_annotation/freezed_annotation.dart';

import 'catalog_file.dart';

part 'file_details.freezed.dart';

/// What the core reports about one file (UC-13, FR-CT-05).
///
/// The listing's projection plus what only a single-file query answers: the
/// type-specific metadata, and the values the core extracted from the file
/// itself. This is where the metadata UC-11 and UC-12 could not reach lives —
/// a listing answers none of it, and this call answers all of it.
@freezed
abstract class FileDetails with _$FileDetails {
  /// Creates a detail record.
  const factory FileDetails({
    /// The file itself, as a listing would show it.
    required CatalogFile file,

    /// The library this file belongs to, or `null` when it belongs to none
    /// (libraries design, core FR-FC-38).
    ///
    /// The uuid rather than the name, which is what the core answers: a
    /// listing that repeated the name would go stale the moment a library
    /// was renamed. The name is looked up from the libraries list where a
    /// screen needs to show it.
    ///
    /// What it is for: a listing that reached into libraries has to be able
    /// to tell which rows it reached. The dashboard reads the same index the
    /// search does, and owes the owner a view without a course's files in
    /// it.
    String? libraryUuid,

    /// The type-specific metadata, as labelled fields.
    ///
    /// A map rather than a union per type, because this screen only reads it.
    /// Editing is UC-15's and UC-16's, and they are the use cases that should
    /// design the typed shape — building one here from a display would be
    /// guessing at what an editor needs.
    @Default(<String, String>{}) Map<String, String> metadata,

    /// The pixel width the core extracted, for an image.
    int? width,

    /// The pixel height the core extracted, for an image.
    int? height,

    /// The page count the core extracted, for a document or a comic.
    int? pageCount,

    /// The duration in seconds the core extracted, for a video.
    double? durationSeconds,

    /// Whether the core reports this record as soft-deleted (AF-02).
    @Default(false) bool isDeleted,
  }) = _FileDetails;

  const FileDetails._();

  /// Whether the file on disk is where the catalog says it is.
  ///
  /// A missing file's record is still active, so the actions that only need
  /// the record stay available while the ones that need the bytes do not
  /// (AF-03).
  bool get isMissing => file.isMissing;

  /// Whether an action that reads the file's bytes can run.
  ///
  /// Neither a deleted record nor a missing file can be opened, renamed, or
  /// played — every one of those needs the file to be both listed and there.
  bool get canReachTheFile => !isDeleted && !isMissing;
}
