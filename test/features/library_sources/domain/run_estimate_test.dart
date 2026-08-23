import 'package:alexandria_ui/features/library_sources/domain/run_estimate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('estimateRemaining', () {
    test('GivenTooFewSamples_WhenEstimated_ThenThereIsNoEstimate', () {
      final samples = [const RunSample(processed: 100, activeMillis: 1000)];

      expect(estimateRemaining(samples, total: 12264), isNull);
    });

    test(
      'GivenASteadyRate_WhenEstimated_ThenItIsTheRemainingWorkOverThatRate',
      () {
        // 100 entries per second, 900 left to do.
        final samples = [
          const RunSample(processed: 100, activeMillis: 1000),
          const RunSample(processed: 200, activeMillis: 2000),
          const RunSample(processed: 300, activeMillis: 3000),
        ];

        expect(
          estimateRemaining(samples, total: 1200),
          const Duration(seconds: 9),
        );
      },
    );

    test(
      'GivenNoProgressBetweenSamples_WhenEstimated_ThenThereIsNoEstimate',
      () {
        // A stalled window would divide by zero and report infinity.
        final samples = [
          const RunSample(processed: 300, activeMillis: 1000),
          const RunSample(processed: 300, activeMillis: 2000),
          const RunSample(processed: 300, activeMillis: 3000),
        ];

        expect(estimateRemaining(samples, total: 1200), isNull);
      },
    );

    test(
      'GivenNoActiveTimeBetweenSamples_WhenEstimated_ThenThereIsNoEstimate',
      () {
        // activeMillis stands still while a run is paused. Dividing by it would
        // be dividing by zero; reporting a figure from it would be reporting
        // progress made during a pause.
        final samples = [
          const RunSample(processed: 100, activeMillis: 5000),
          const RunSample(processed: 200, activeMillis: 5000),
          const RunSample(processed: 300, activeMillis: 5000),
        ];

        expect(estimateRemaining(samples, total: 1200), isNull);
      },
    );

    test('GivenAWildlySwingingRate_WhenEstimated_ThenThereIsNoEstimate', () {
      // The first window says 1000/sec, the last says 10/sec. An estimate
      // from this would swing by two orders of magnitude between polls, and
      // a number that moves like that is worse than no number.
      final samples = [
        const RunSample(processed: 1000, activeMillis: 1000),
        const RunSample(processed: 2000, activeMillis: 2000),
        const RunSample(processed: 2010, activeMillis: 3000),
      ];

      expect(estimateRemaining(samples, total: 12264), isNull);
    });

    test('GivenTheWorkIsDone_WhenEstimated_ThenItIsZero', () {
      final samples = [
        const RunSample(processed: 1198, activeMillis: 1000),
        const RunSample(processed: 1199, activeMillis: 2000),
        const RunSample(processed: 1200, activeMillis: 3000),
      ];

      expect(estimateRemaining(samples, total: 1200), Duration.zero);
    });
  });
}
