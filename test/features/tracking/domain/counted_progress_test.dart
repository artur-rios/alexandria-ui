import 'package:alexandria_ui/features/tracking/domain/counted_progress.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether a position in a numbered sequence can be sent to the core
/// (UC-30 AF-02 for episodes, UC-32 AF-02 for issues — one rule, tested
/// once, since the two are now one implementation).
void main() {
  group('the current position', () {
    test('GivenAnEpisode_WhenItIsValidated_ThenItIsAccepted', () {
      expect(
        validateCurrentCount(const CountedProgressDraft(current: '4')),
        isNull,
      );
    });

    // An empty field is how the owner says they have not started, and the core
    // stores nothing for it.
    test('GivenNothing_WhenItIsValidated_ThenItIsAccepted', () {
      expect(validateCurrentCount(const CountedProgressDraft()), isNull);
    });

    test('GivenWordsInsteadOfANumber_WhenValidated_ThenItIsRefused', () {
      expect(
        validateCurrentCount(const CountedProgressDraft(current: 'four')),
        CountedProgressError.notANumber,
      );
    });

    test('GivenZero_WhenItIsValidated_ThenItIsRefused', () {
      expect(
        validateCurrentCount(const CountedProgressDraft(current: '0')),
        CountedProgressError.notPositive,
      );
    });

    test('GivenANegativeEpisode_WhenItIsValidated_ThenItIsRefused', () {
      expect(
        validateCurrentCount(const CountedProgressDraft(current: '-2')),
        CountedProgressError.notPositive,
      );
    });

    test('GivenAnEpisodePastTheTotal_WhenValidated_ThenItIsRefused', () {
      expect(
        validateCurrentCount(
          const CountedProgressDraft(current: '13', total: '12'),
        ),
        CountedProgressError.beyondTotal,
      );
    });

    test('GivenTheLastEpisode_WhenItIsValidated_ThenItIsAccepted', () {
      expect(
        validateCurrentCount(
          const CountedProgressDraft(current: '12', total: '12'),
        ),
        isNull,
      );
    });

    // With no total there is nothing to be past.
    test('GivenNoTotal_WhenAHighEpisodeIsValidated_ThenItIsAccepted', () {
      expect(
        validateCurrentCount(const CountedProgressDraft(current: '900')),
        isNull,
      );
    });
  });

  group('the total', () {
    test('GivenATotal_WhenItIsValidated_ThenItIsAccepted', () {
      expect(
        validateTotalCount(const CountedProgressDraft(total: '12')),
        isNull,
      );
    });

    test('GivenNothing_WhenItIsValidated_ThenItIsAccepted', () {
      expect(validateTotalCount(const CountedProgressDraft()), isNull);
    });

    test('GivenWordsInsteadOfANumber_WhenValidated_ThenItIsRefused', () {
      expect(
        validateTotalCount(const CountedProgressDraft(total: 'twelve')),
        CountedProgressError.notANumber,
      );
    });

    test('GivenZero_WhenItIsValidated_ThenItIsRefused', () {
      expect(
        validateTotalCount(const CountedProgressDraft(total: '0')),
        CountedProgressError.notPositive,
      );
    });
  });

  group('what would be sent', () {
    test('GivenFilledFields_WhenTheyAreRead_ThenTheyAreNumbers', () {
      const draft = CountedProgressDraft(current: '3', total: '12');

      expect(draft.currentValue, 3);
      expect(draft.totalValue, 12);
    });

    test('GivenEmptyFields_WhenTheyAreRead_ThenThereIsNothingToSend', () {
      const draft = CountedProgressDraft();

      expect(draft.currentValue, isNull);
      expect(draft.totalValue, isNull);
    });
  });
}
