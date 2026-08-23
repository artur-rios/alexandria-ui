import 'package:alexandria_ui/features/library_sources/domain/index_run.dart';
import 'package:alexandria_ui/features/library_sources/domain/run_priority.dart';
import 'package:flutter_test/flutter_test.dart';

/// The core's vocabulary for a run's status, phase, and priority
/// (System Requirements §4.8, FR-FC-28, FR-FC-31).
void main() {
  group('IndexRunStatus.parse', () {
    test('GivenAPausedStatus_WhenParsed_ThenItIsPaused', () {
      expect(IndexRunStatus.parse('paused'), IndexRunStatus.paused);
    });

    test('GivenACancelledStatus_WhenParsed_ThenItIsCancelled', () {
      expect(IndexRunStatus.parse('cancelled'), IndexRunStatus.cancelled);
    });

    // The core removed `interrupted`; a run left by a closed application now
    // comes back `paused`. Falling back to `failed` for a word we do not know
    // stays right, but it must not swallow one we now do.
    test('GivenAnUnknownStatus_WhenParsed_ThenItIsFailed', () {
      expect(IndexRunStatus.parse('elsewhere'), IndexRunStatus.failed);
    });

    test('GivenAPausedRun_WhenAskedIfInFlight_ThenItIsNot', () {
      expect(IndexRunStatus.paused.isInFlight, isFalse);
    });
  });

  group('IndexRunPhase.parse', () {
    test('GivenDiscovering_WhenParsed_ThenItIsDiscovering', () {
      expect(IndexRunPhase.parse('discovering'), IndexRunPhase.discovering);
    });

    test('GivenNoPhase_WhenParsed_ThenItIsNull', () {
      expect(IndexRunPhase.parse(null), isNull);
    });
  });

  group('RunPriority', () {
    test('GivenLowPriority_WhenSpelledForTheWire_ThenItIsLowercase', () {
      expect(RunPriority.low.wire, 'low');
    });
  });
}
