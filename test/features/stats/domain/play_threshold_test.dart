import 'package:alexandria_ui/features/stats/domain/play_threshold.dart';
import 'package:flutter_test/flutter_test.dart';

/// When a track counts as played (play history design).
///
/// The whole rule lives in one function precisely so it can be pinned here,
/// rather than being inferred from what the player happens to do.
void main() {
  test('GivenLessThanHalfOfAShortTrack_ThenItDoesNotCount', () {
    // Forty seconds of a two-minute song is not listening to it.
    expect(
      countsAsPlayed(
        position: const Duration(seconds: 40),
        duration: const Duration(minutes: 2),
      ),
      isFalse,
    );
  });

  test('GivenHalfOfAShortTrack_ThenItCounts', () {
    expect(
      countsAsPlayed(
        position: const Duration(minutes: 1),
        duration: const Duration(minutes: 2),
      ),
      isTrue,
    );
  });

  test('GivenFourMinutesOfALongOne_ThenItCountsBeforeHalf', () {
    // An hour-long live set does not stop counting because the owner left
    // before the encore.
    expect(
      countsAsPlayed(
        position: playedAfter,
        duration: const Duration(hours: 1),
      ),
      isTrue,
    );
    expect(
      countsAsPlayed(
        position: playedAfter - const Duration(seconds: 1),
        duration: const Duration(hours: 1),
      ),
      isFalse,
    );
  });

  test('GivenNoLengthYet_ThenNothingCounts', () {
    // The engine has not worked the duration out. With no length to take
    // half of, every rule reduces to guessing — and the next status carries
    // the real value a moment later.
    expect(
      countsAsPlayed(position: const Duration(minutes: 10), duration: null),
      isFalse,
    );
    expect(
      countsAsPlayed(
        position: const Duration(minutes: 10),
        duration: Duration.zero,
      ),
      isFalse,
    );
  });

  test('GivenNothingHeard_ThenItDoesNotCount', () {
    expect(
      countsAsPlayed(
        position: Duration.zero,
        duration: const Duration(minutes: 3),
      ),
      isFalse,
    );
  });
}
