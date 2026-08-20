import 'package:alexandria_desktop/features/tracking/domain/episode_progress.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether an episode number can be sent to the core (UC-30 AF-02).
void main() {
  group('the current episode', () {
    test('GivenAnEpisode_WhenItIsValidated_ThenItIsAccepted', () {
      expect(validateCurrentEpisode(const EpisodeDraft(current: '4')), isNull);
    });

    // An empty field is how the owner says they have not started, and the core
    // stores nothing for it.
    test('GivenNothing_WhenItIsValidated_ThenItIsAccepted', () {
      expect(validateCurrentEpisode(const EpisodeDraft()), isNull);
    });

    test('GivenWordsInsteadOfANumber_WhenValidated_ThenItIsRefused', () {
      expect(
        validateCurrentEpisode(const EpisodeDraft(current: 'four')),
        EpisodeError.notANumber,
      );
    });

    test('GivenZero_WhenItIsValidated_ThenItIsRefused', () {
      expect(
        validateCurrentEpisode(const EpisodeDraft(current: '0')),
        EpisodeError.notPositive,
      );
    });

    test('GivenANegativeEpisode_WhenItIsValidated_ThenItIsRefused', () {
      expect(
        validateCurrentEpisode(const EpisodeDraft(current: '-2')),
        EpisodeError.notPositive,
      );
    });

    test('GivenAnEpisodePastTheTotal_WhenValidated_ThenItIsRefused', () {
      expect(
        validateCurrentEpisode(const EpisodeDraft(current: '13', total: '12')),
        EpisodeError.beyondTotal,
      );
    });

    test('GivenTheLastEpisode_WhenItIsValidated_ThenItIsAccepted', () {
      expect(
        validateCurrentEpisode(const EpisodeDraft(current: '12', total: '12')),
        isNull,
      );
    });

    // With no total there is nothing to be past.
    test('GivenNoTotal_WhenAHighEpisodeIsValidated_ThenItIsAccepted', () {
      expect(
        validateCurrentEpisode(const EpisodeDraft(current: '900')),
        isNull,
      );
    });
  });

  group('the total', () {
    test('GivenATotal_WhenItIsValidated_ThenItIsAccepted', () {
      expect(validateTotalEpisodes(const EpisodeDraft(total: '12')), isNull);
    });

    test('GivenNothing_WhenItIsValidated_ThenItIsAccepted', () {
      expect(validateTotalEpisodes(const EpisodeDraft()), isNull);
    });

    test('GivenWordsInsteadOfANumber_WhenValidated_ThenItIsRefused', () {
      expect(
        validateTotalEpisodes(const EpisodeDraft(total: 'twelve')),
        EpisodeError.notANumber,
      );
    });

    test('GivenZero_WhenItIsValidated_ThenItIsRefused', () {
      expect(
        validateTotalEpisodes(const EpisodeDraft(total: '0')),
        EpisodeError.notPositive,
      );
    });
  });

  group('what would be sent', () {
    test('GivenFilledFields_WhenTheyAreRead_ThenTheyAreNumbers', () {
      const draft = EpisodeDraft(current: '3', total: '12');

      expect(draft.currentEpisode, 3);
      expect(draft.totalEpisodes, 12);
    });

    test('GivenEmptyFields_WhenTheyAreRead_ThenThereIsNothingToSend', () {
      const draft = EpisodeDraft();

      expect(draft.currentEpisode, isNull);
      expect(draft.totalEpisodes, isNull);
    });
  });
}
