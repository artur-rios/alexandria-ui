import 'package:alexandria_ui/features/tracking/domain/watch_progress_gateway.dart';

/// A [WatchProgressGateway] that never reaches the core (Testing Specification
/// §2.3).
///
/// UC-16 AF-03 turns on one boolean, so this answers one — how the real
/// gateway arrives at it is `CoreWatchProgressGateway`'s own test.
class FakeWatchProgressGateway implements WatchProgressGateway {
  /// Creates a gateway answering [recordsEpisodes] to every video.
  FakeWatchProgressGateway({this.recordsEpisodes = false});

  /// What the gateway answers.
  bool recordsEpisodes;

  /// Every video asked about, in order.
  ///
  /// Empty is the assertion that a marking change costing nothing does not go
  /// looking: the question is only asked on the way from series to movie.
  final List<String> asked = [];

  @override
  Future<bool> episodesRecordedFor({
    required String uuid,
    required String credential,
  }) async {
    asked.add(uuid);
    return recordsEpisodes;
  }
}
