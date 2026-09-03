import 'package:alexandria_ui/features/stats/domain/music_stats.dart';
import 'package:alexandria_ui/features/stats/domain/stats_gateway.dart';

/// A [StatsGateway] that never reaches the core (Testing Specification
/// §2.3).
class FakeStatsGateway implements StatsGateway {
  /// Creates a gateway answering [stats].
  FakeStatsGateway({MusicStats? stats})
    : stats = stats ?? const MusicStats(totalPlays: 0, distinctTracks: 0);

  /// What a read answers.
  MusicStats stats;

  /// What [read] answers instead, when a test says so.
  MusicStatsRead? readOutcome;

  /// What the next record answers, when a test says so.
  PlayRecorded? recordOutcome;

  /// Every play recorded, in order — the record a "counted once, and once
  /// per playthrough" assertion needs.
  final List<String> recorded = [];

  /// Every row limit asked for, in order.
  final List<int> limits = [];

  @override
  Future<PlayRecorded> record({
    required String fileUuid,
    required String credential,
  }) async {
    recorded.add(fileUuid);
    return recordOutcome ?? const PlayRecorded.done();
  }

  @override
  Future<MusicStatsRead> read({
    required int limit,
    required String credential,
  }) async {
    limits.add(limit);
    return readOutcome ?? MusicStatsRead.loaded(stats: stats);
  }
}
