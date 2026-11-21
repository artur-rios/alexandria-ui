import 'dart:convert';

import 'package:alexandria_ui/features/playback/data/settings_playback_position_store.dart';
import 'package:alexandria_ui/features/playback/domain/playback_position_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/in_memory_settings_store.dart';

/// The resume positions, kept in the settings store (FR-PL-09).
void main() {
  const key = SettingsPlaybackPositionStore.settingsKey;

  final updatedAt = DateTime.utc(2026, 9, 1, 20, 30);

  PlaybackPosition position(
    String uuid, {
    Duration at = const Duration(minutes: 12),
    Duration? duration = const Duration(minutes: 90),
  }) => PlaybackPosition(
    fileUuid: uuid,
    position: at,
    duration: duration,
    updatedAt: updatedAt,
  );

  void expectSame(PlaybackPosition? actual, PlaybackPosition expected) {
    expect(actual, isNotNull);
    expect(actual!.fileUuid, expected.fileUuid);
    expect(actual.position, expected.position);
    expect(actual.duration, expected.duration);
    expect(actual.updatedAt, expected.updatedAt);
  }

  test('GivenNothingStored_WhenAPositionIsAskedFor_ThenThereIsNone', () {
    final store = SettingsPlaybackPositionStore(InMemorySettingsStore());

    expect(store.positionFor('f-1'), isNull);
  });

  test(
    'GivenARecordedPosition_WhenItIsAskedFor_ThenItIsAnsweredAtOnce',
    () async {
      final store = SettingsPlaybackPositionStore(InMemorySettingsStore());
      final recorded = position('f-1');

      await store.record(recorded);

      expectSame(store.positionFor('f-1'), recorded);
    },
  );

  test(
    'GivenARecordedPosition_WhenANewStoreReadsTheSettings_ThenItSurvives',
    () async {
      final settings = InMemorySettingsStore();
      final recorded = position('f-1');
      await SettingsPlaybackPositionStore(settings).record(recorded);

      final reopened = SettingsPlaybackPositionStore(settings);

      expectSame(reopened.positionFor('f-1'), recorded);
    },
  );

  test(
    'GivenAPositionWithNoDuration_WhenItIsStored_ThenTheDurationStaysUnknown',
    () async {
      final settings = InMemorySettingsStore();
      await SettingsPlaybackPositionStore(
        settings,
      ).record(position('f-1', duration: null));

      final stored = jsonDecode(settings.entries[key]!) as Map<String, dynamic>;
      expect(stored['f-1'], isNot(contains('durationMs')));
      expect(
        SettingsPlaybackPositionStore(settings).positionFor('f-1')!.duration,
        isNull,
      );
    },
  );

  test(
    'GivenTwoRecordsForOneFile_WhenItIsAskedFor_ThenTheLatestWins',
    () async {
      final store = SettingsPlaybackPositionStore(InMemorySettingsStore());
      await store.record(position('f-1', at: const Duration(minutes: 1)));

      await store.record(position('f-1', at: const Duration(minutes: 2)));

      expect(store.positionFor('f-1')!.position, const Duration(minutes: 2));
    },
  );

  test(
    'GivenAForgottenPosition_WhenANewStoreReadsTheSettings_ThenItIsGone',
    () async {
      final settings = InMemorySettingsStore();
      final store = SettingsPlaybackPositionStore(settings);
      await store.record(position('f-1'));
      await store.record(position('f-2'));

      await store.forget('f-1');

      expect(store.positionFor('f-1'), isNull);
      final reopened = SettingsPlaybackPositionStore(settings);
      expect(reopened.positionFor('f-1'), isNull);
      expect(reopened.positionFor('f-2'), isNotNull);
    },
  );

  test('GivenAnUnknownFile_WhenItIsForgotten_ThenNothingElseChanges', () async {
    final store = SettingsPlaybackPositionStore(InMemorySettingsStore());
    await store.record(position('f-1'));

    await store.forget('f-9');

    expect(store.positionFor('f-1'), isNotNull);
  });

  group('a stored value it cannot read', () {
    for (final entry in {
      'MalformedJson': '{',
      'AListInsteadOfAMap': '[]',
      'AnEntryWithNoPosition': '{"f-1": {"updatedAt": "2026-09-01T20:30:00Z"}}',
      'AnEntryWithAnUnparseableDate':
          '{"f-1": {"positionMs": 1000, "updatedAt": "yesterday"}}',
    }.entries) {
      test(
        'GivenAStoredValueOf${entry.key}_WhenTheStoreOpens_ThenItHoldsNoPositions',
        () async {
          // A resume point nobody can decode must not stop the application.
          final settings = InMemorySettingsStore(values: {key: entry.value});
          final store = SettingsPlaybackPositionStore(settings);

          expect(store.positionFor('f-1'), isNull);

          // And recording over it replaces it with a readable document.
          await store.record(position('f-2'));
          expect(
            SettingsPlaybackPositionStore(settings).positionFor('f-2'),
            isNotNull,
          );
        },
      );
    }
  });
}
