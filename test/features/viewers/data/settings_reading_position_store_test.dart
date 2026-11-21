import 'package:alexandria_ui/features/viewers/data/settings_reading_position_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/in_memory_settings_store.dart';

/// The reading positions, kept in the settings store (FR-VW-02).
void main() {
  const key = SettingsReadingPositionStore.settingsKey;

  test('GivenNothingStored_WhenAPositionIsAskedFor_ThenThereIsNone', () {
    final store = SettingsReadingPositionStore(InMemorySettingsStore());

    expect(store.positionFor('f-1'), isNull);
  });

  test(
    'GivenARecordedPosition_WhenItIsAskedFor_ThenItIsAnsweredAtOnce',
    () async {
      final store = SettingsReadingPositionStore(InMemorySettingsStore());

      await store.record('f-1', 42);

      expect(store.positionFor('f-1'), 42);
    },
  );

  test(
    'GivenARecordedPosition_WhenANewStoreReadsTheSettings_ThenItSurvives',
    () async {
      final settings = InMemorySettingsStore();
      await SettingsReadingPositionStore(settings).record('f-1', 42);

      expect(SettingsReadingPositionStore(settings).positionFor('f-1'), 42);
      expect(settings.entries[key], '{"f-1":42}');
    },
  );

  test(
    'GivenTwoRecordsForOneFile_WhenItIsAskedFor_ThenTheLatestWins',
    () async {
      final store = SettingsReadingPositionStore(InMemorySettingsStore());
      await store.record('f-1', 3);

      await store.record('f-1', 7);

      expect(store.positionFor('f-1'), 7);
    },
  );

  test(
    'GivenAForgottenPosition_WhenANewStoreReadsTheSettings_ThenItIsGone',
    () async {
      final settings = InMemorySettingsStore();
      final store = SettingsReadingPositionStore(settings);
      await store.record('f-1', 3);
      await store.record('f-2', 5);

      await store.forget('f-1');

      expect(store.positionFor('f-1'), isNull);
      final reopened = SettingsReadingPositionStore(settings);
      expect(reopened.positionFor('f-1'), isNull);
      expect(reopened.positionFor('f-2'), 5);
    },
  );

  group('a stored value it cannot read', () {
    for (final entry in {
      'MalformedJson': '{',
      'AListInsteadOfAMap': '[1, 2]',
      'APositionThatIsNotANumber': '{"f-1": "page 3"}',
    }.entries) {
      test(
        'GivenAStoredValueOf${entry.key}_WhenTheStoreOpens_ThenItHoldsNoPositions',
        () async {
          // A position nobody can decode must not stop the application.
          final settings = InMemorySettingsStore(values: {key: entry.value});
          final store = SettingsReadingPositionStore(settings);

          expect(store.positionFor('f-1'), isNull);

          await store.record('f-2', 1);
          expect(SettingsReadingPositionStore(settings).positionFor('f-2'), 1);
        },
      );
    }
  });
}
