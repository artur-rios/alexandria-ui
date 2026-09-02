import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/settings/settings_store.dart';
import 'package:alexandria_ui/features/catalog/domain/view_layout.dart';
import 'package:alexandria_ui/features/playback/application/music_layout_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/failing_settings_store.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/test_container.dart';

/// Choosing rows or tiles in the music area (UC-46, FR-CT-03, FR-CT-04).
void main() {
  Future<ProviderContainer> started({SettingsStore? settings}) async {
    final container = buildTestContainer(
      overrides: fakeCoreOverrides(
        settings: settings ?? InMemorySettingsStore(),
      ),
    );
    await container.read(startupControllerProvider.notifier).start();

    return container;
  }

  test('GivenNoStoredChoice_WhenTheAreaOpens_ThenItIsTheList', () async {
    // The denser of the two, and the one that says whose a record is in
    // words: the wall of sleeves is the choice an owner makes, not the one
    // they are given.
    final ref = await started();

    expect(ref.read(musicLayoutControllerProvider), ViewLayout.list);
  });

  test('GivenTilesAreChosen_WhenTheyAre_ThenTheyApply', () async {
    final ref = await started();

    await ref
        .read(musicLayoutControllerProvider.notifier)
        .choose(ViewLayout.grid);

    expect(ref.read(musicLayoutControllerProvider), ViewLayout.grid);
  });

  test('GivenTilesAreChosen_WhenTheyAre_ThenTheChoiceIsWritten', () async {
    final settings = InMemorySettingsStore();
    final ref = await started(settings: settings);

    await ref
        .read(musicLayoutControllerProvider.notifier)
        .choose(ViewLayout.grid);

    expect(settings.entries[MusicLayoutController.settingsKey], 'grid');
  });

  test(
    'GivenAStoredChoice_WhenTheApplicationStarts_ThenItIsRestored',
    () async {
      // FR-CT-04: an owner who browses their records as a wall of sleeves
      // means it next session too.
      final ref = await started(
        settings: InMemorySettingsStore(
          values: {MusicLayoutController.settingsKey: 'grid'},
        ),
      );

      expect(ref.read(musicLayoutControllerProvider), ViewLayout.grid);
    },
  );

  test('GivenAnUnreadableValue_WhenItIsRestored_ThenTheListApplies', () async {
    // Hand-edited, or written by some other version. Guessing what it meant
    // is worse than the default.
    final ref = await started(
      settings: InMemorySettingsStore(
        values: {MusicLayoutController.settingsKey: 'carousel'},
      ),
    );

    expect(ref.read(musicLayoutControllerProvider), ViewLayout.list);
  });

  test('GivenTheStoreRefuses_WhenTilesAreChosen_ThenTheyStillApply', () async {
    // A preference that could not be saved still applies for this session,
    // which is the rule every other stored choice here follows.
    final ref = await started(settings: FailingSettingsStore());

    await ref
        .read(musicLayoutControllerProvider.notifier)
        .choose(ViewLayout.grid);

    expect(ref.read(musicLayoutControllerProvider), ViewLayout.grid);
  });
}
