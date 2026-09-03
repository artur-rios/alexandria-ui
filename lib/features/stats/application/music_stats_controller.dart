import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/music_stats.dart';
import '../domain/stats_gateway.dart';

/// What the owner has played most (play history design).
///
/// Reads once when the screen opens and again when the owner asks. Nothing
/// keeps it live while music plays: a chart that reordered itself under the
/// reader's eyes would be harder to read than one that is a minute old, and
/// the refresh is one button away.
class MusicStatsController extends AsyncNotifier<MusicStats?> {
  /// How many rows each ranking asks for.
  ///
  /// Ten, matching the core's own default — named here rather than left to
  /// the core so the screen and the request cannot drift apart, and so the
  /// number is visible where the list it fills is built.
  static const int rowsPerRanking = 10;

  @override
  Future<MusicStats?> build() async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07).
    if (credential == null) return null;

    final outcome = await ref
        .read(statsGatewayProvider)
        .read(limit: rowsPerRanking, credential: credential);

    switch (outcome) {
      case MusicStatsReadLoaded(:final stats):
        return stats;

      // A rejected session returns the owner to login, as everywhere else.
      case MusicStatsReadFailed(failure: final UnauthorizedFailure failure):
        ref.read(sessionControllerProvider.notifier).invalidate(failure);
        return null;

      case MusicStatsReadFailed(:final failure):
        throw failure;
    }
  }

  /// Reads them again.
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}
