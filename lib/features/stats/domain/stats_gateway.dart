import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/failures/failure.dart';
import 'music_stats.dart';

part 'stats_gateway.freezed.dart';

/// What reading the statistics produced.
@freezed
sealed class MusicStatsRead with _$MusicStatsRead {
  /// The core answered, possibly with nothing played.
  const factory MusicStatsRead.loaded({required MusicStats stats}) =
      MusicStatsReadLoaded;

  /// The core could not answer.
  const factory MusicStatsRead.failed({required Failure failure}) =
      MusicStatsReadFailed;
}

/// What recording a play produced.
@freezed
sealed class PlayRecorded with _$PlayRecorded {
  /// The core wrote it.
  const factory PlayRecorded.done() = PlayRecordedDone;

  /// The core refused, or could not be reached.
  const factory PlayRecorded.failed({required Failure failure}) =
      PlayRecordedFailed;
}

/// The core's play history operations (play history design).
abstract interface class StatsGateway {
  /// Records that the track [fileUuid] identifies was played.
  ///
  /// No timestamp: the core stamps the moment from its own clock, so this
  /// application says what was played and never when.
  Future<PlayRecorded> record({
    required String fileUuid,
    required String credential,
  });

  /// What was played most, each ranking cut to [limit] rows.
  Future<MusicStatsRead> read({required int limit, required String credential});
}
