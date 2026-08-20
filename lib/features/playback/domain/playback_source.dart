import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';

part 'playback_source.freezed.dart';

/// Everything a local player needs to open a file (FR-PL-01, FR-PL-05).
///
/// A path rather than bytes: the core's own note on
/// `alexandria_file_playback_source` says the FFI surface carries no stream,
/// and this application runs on the same machine as the file. Zero bytes
/// cross the boundary, which is also what makes playback without transcoding
/// possible at all.
@freezed
abstract class PlaybackSource with _$PlaybackSource {
  /// Creates a source.
  const factory PlaybackSource({
    required String uuid,
    required String path,
    String? mimeType,
    int? sizeBytes,
  }) = _PlaybackSource;
}

/// What resolving a file to a playable source produced (UC-19 step 3).
@freezed
sealed class PlaybackSourceOutcome with _$PlaybackSourceOutcome {
  /// The core answered where the file is.
  const factory PlaybackSourceOutcome.resolved({
    required PlaybackSource source,
  }) = PlaybackSourceResolved;

  /// The core could not (UC-19 AF-01, UC-20 AF-01).
  const factory PlaybackSourceOutcome.failed({required Failure failure}) =
      PlaybackSourceFailed;
}

/// Where a file is, for a player to open (FR-PL-01, FR-PL-05).
abstract interface class PlaybackSourceGateway {
  /// Resolves the file [uuid] identifies to something a player can open.
  Future<PlaybackSourceOutcome> resolve({
    required String uuid,
    required String credential,
  });
}
