import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import '../../catalog/domain/catalog_file.dart';

part 'text_content_gateway.freezed.dart';

/// What reading a text file's content produced (UC-18 main flow step 2).
@freezed
sealed class TextContentRead with _$TextContentRead {
  /// The core read the file and answered its content.
  const factory TextContentRead.loaded({required String content}) =
      TextContentLoaded;

  /// The core could not read it (AF-04, AF-06, and a disk that refused).
  const factory TextContentRead.failed({required Failure failure}) =
      TextContentReadFailed;
}

/// What writing edited content produced (UC-18 main flow step 7).
@freezed
sealed class TextContentWrite with _$TextContentWrite {
  /// The core wrote the file and refreshed the record.
  ///
  /// It carries the refreshed record because its content hash is what the
  /// *next* save compares against (AF-05): the file on disk is now what this
  /// editor wrote, and the hash it had when the editor opened is stale the
  /// moment the write lands.
  const factory TextContentWrite.written({required CatalogFile file}) =
      TextContentWritten;

  /// The core refused, or the disk did (AF-03, AF-04, AF-06).
  const factory TextContentWrite.failed({required Failure failure}) =
      TextContentWriteFailed;
}

/// The application's view of the core's text content operations
/// (FR-ME-06, FR-ME-08).
///
/// Reading and writing a file's bytes is the core's, not the application's:
/// BR-06 lets this application write text content and its own settings, and
/// even that goes through the core rather than through `dart:io`.
abstract interface class TextContentGateway {
  /// Reads the content of the text file [uuid] identifies (FR-ME-06).
  Future<TextContentRead> readContent({
    required String uuid,
    required String credential,
  });

  /// Writes [content] back to the text file [uuid] identifies (FR-ME-08).
  Future<TextContentWrite> writeContent({
    required String uuid,
    required String content,
    required String credential,
  });
}
