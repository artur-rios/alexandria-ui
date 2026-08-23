import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_stamp.freezed.dart';

/// What a file looked like on disk the last time the core looked at it.
///
/// It exists because a content hash no longer does: indexing stopped computing
/// one and moved change detection to `(size_bytes, mtime)`, so `content_hash`
/// is `NULL` for every file the owner has never edited. Anything here that
/// needs to know "did this file change since I read it" has to ask the same
/// question the core now asks.
///
/// It inherits that signal's blind spot: a file edited in place to exactly the
/// same byte length with its mtime preserved reads as unchanged. Re-indexing
/// accepts that trade, and so does everything comparing stamps.
///
/// Both fields are nullable because a core that answers without them must not
/// make the reading unusable — a stamp with nothing in it is "cannot tell",
/// not "unchanged".
@freezed
abstract class FileStamp with _$FileStamp {
  /// Creates a stamp.
  const factory FileStamp({
    /// The file's size in bytes.
    int? sizeBytes,

    /// When the file was last modified on disk.
    DateTime? mtime,
  }) = _FileStamp;

  const FileStamp._();

  /// Whether the core said anything at all about this file's shape on disk.
  ///
  /// A stamp that says nothing cannot be compared, and a comparison nobody
  /// could take is not evidence of a change.
  bool get isReadable => sizeBytes != null || mtime != null;
}
