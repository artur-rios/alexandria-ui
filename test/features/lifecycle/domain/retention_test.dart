import 'package:alexandria_ui/features/lifecycle/domain/retention.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where a deleted record stands in its retention window (UC-34, FR-LC-03).
void main() {
  final now = DateTime.utc(2026, 9, 10, 12);

  group('Retention.since', () {
    test(
      'GivenADeletionInsideTheWindow_WhenItIsMeasured_ThenWhatIsLeftIsKnown',
      () {
        final retention = Retention.since(
          now.subtract(const Duration(days: 3)),
          now: now,
          days: 30,
        );

        expect(retention.remaining, const Duration(days: 27));
        expect(retention.isKnown, isTrue);
        expect(retention.hasElapsed, isFalse);
        expect(retention.daysRemaining, 27);
      },
    );

    test(
      'GivenNoDeletionTimestamp_WhenItIsMeasured_ThenTheStandingIsUnknown',
      () {
        final retention = Retention.since(null, now: now, days: 30);

        expect(retention.remaining, isNull);
        expect(retention.isKnown, isFalse);
        // Unknown is not elapsed: the record is still offered for restore.
        expect(retention.hasElapsed, isFalse);
        expect(retention.daysRemaining, 0);
      },
    );

    test('GivenNoWindow_WhenItIsMeasured_ThenTheStandingIsUnknown', () {
      final retention = Retention.since(now, now: now, days: null);

      expect(retention.isKnown, isFalse);
      expect(retention.hasElapsed, isFalse);
    });
  });

  group('the boundary of the window', () {
    test(
      'GivenExactlyTheWindowHasPassed_WhenItIsMeasured_ThenItIsStillRestorable',
      () {
        // The core's boundary: up to and including the window is restorable.
        final retention = Retention.since(
          now.subtract(const Duration(days: 30)),
          now: now,
          days: 30,
        );

        expect(retention.remaining, Duration.zero);
        expect(retention.hasElapsed, isFalse);
        expect(retention.daysRemaining, 0);
      },
    );

    test('GivenAMomentPastTheWindow_WhenItIsMeasured_ThenItHasElapsed', () {
      final retention = Retention.since(
        now.subtract(const Duration(days: 30, microseconds: 1)),
        now: now,
        days: 30,
      );

      expect(retention.hasElapsed, isTrue);
      expect(retention.daysRemaining, 0);
    });

    test(
      'GivenAZeroDayWindow_WhenARecordIsDeletedNow_ThenItIsStillRestorable',
      () {
        final retention = Retention.since(now, now: now, days: 0);

        expect(retention.hasElapsed, isFalse);
        expect(retention.daysRemaining, 0);
      },
    );
  });

  group('daysRemaining', () {
    test('GivenAnHourLeft_WhenTheDaysAreCounted_ThenItReadsAsOneDay', () {
      const retention = Retention(remaining: Duration(hours: 1));

      expect(retention.daysRemaining, 1);
    });

    test('GivenADayAndAMinuteLeft_WhenTheDaysAreCounted_ThenItRoundsUp', () {
      const retention = Retention(remaining: Duration(days: 1, minutes: 1));

      expect(retention.daysRemaining, 2);
    });

    test('GivenExactlyTwoDaysLeft_WhenTheDaysAreCounted_ThenItIsTwo', () {
      const retention = Retention(remaining: Duration(days: 2));

      expect(retention.daysRemaining, 2);
    });

    test('GivenAnElapsedWindow_WhenTheDaysAreCounted_ThenItIsZero', () {
      const retention = Retention(remaining: Duration(days: -3));

      expect(retention.daysRemaining, 0);
      expect(retention.hasElapsed, isTrue);
    });
  });
}
