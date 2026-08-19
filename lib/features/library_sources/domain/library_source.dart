import 'package:freezed_annotation/freezed_annotation.dart';

part 'library_source.freezed.dart';
part 'library_source.g.dart';

/// A folder on disk the owner has registered as a source of files to index
/// (System Requirements §4.7, FR-LB-01, FR-LB-03).
///
/// Application-owned, not a projection: the core indexes what it is pointed
/// at, and which folders those are is the application's to remember. Keyed by
/// [path], which is what naturally identifies a folder and what makes
/// "already registered" answerable without an identifier nobody assigned.
@freezed
abstract class LibrarySource with _$LibrarySource {
  /// Creates a source.
  const factory LibrarySource({
    /// The absolute folder path. Also the key.
    required String path,

    /// The owner-supplied name, defaulting to the folder's own name.
    required String label,

    /// When it was registered.
    required DateTime registeredAt,

    /// The identifier of the most recent run over this folder (UC-06).
    String? lastRunId,

    /// Whether that run finished or failed (UC-06).
    String? lastRunOutcome,

    /// When that run finished (UC-06).
    DateTime? lastRunAt,
  }) = _LibrarySource;

  /// Reads a source from the local settings store.
  factory LibrarySource.fromJson(Map<String, dynamic> json) =>
      _$LibrarySourceFromJson(json);
}
