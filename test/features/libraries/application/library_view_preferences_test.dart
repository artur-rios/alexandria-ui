import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/settings/settings_store.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/catalog/domain/listing_view.dart';
import 'package:alexandria_ui/features/catalog/domain/view_layout.dart';
import 'package:alexandria_ui/features/libraries/application/library_view_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/failing_settings_store.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/test_container.dart';

/// The layout, type filter and order a library's folder is drawn with, kept
/// under `libraryView` (UC-10, UC-12, library navigation design §4).
void main() {
  Future<ProviderContainer> started({SettingsStore? settings}) async {
    final container = buildTestContainer(
      overrides: fakeCoreOverrides(
        settings: settings ?? InMemorySettingsStore(rechecksAtStartup: false),
      ),
    );
    await container.read(startupControllerProvider.notifier).start();
    return container;
  }

  LibraryViewPreferences read(ProviderContainer ref) =>
      ref.read(libraryViewPreferencesProvider);

  LibraryViewPreferencesController controller(ProviderContainer ref) =>
      ref.read(libraryViewPreferencesProvider.notifier);

  group('the choices themselves', () {
    test(
      'GivenNothingChosen_WhenRead_ThenItIsTheListOfEveryTypeByName',
      () async {
        // The list is the one layout that fits every supported window, so the
        // default is never itself a substitution.
        final ref = await started();

        final preferences = read(ref);
        expect(preferences.layout, ViewLayout.list);
        expect(preferences.type, isNull);
        expect(preferences.sortField, SortField.name);
        expect(preferences.direction, SortDirection.ascending);
      },
    );

    test(
      'GivenEachChoice_WhenItIsMade_ThenItAppliesAndLeavesTheOthers',
      () async {
        final ref = await started();

        await controller(ref).chooseLayout(ViewLayout.grid);
        await controller(ref).filterTo(FileType.comic);
        await controller(ref).sortBy(SortField.indexed);
        await controller(ref).orderIn(SortDirection.descending);

        final preferences = read(ref);
        expect(preferences.layout, ViewLayout.grid);
        expect(preferences.type, FileType.comic);
        expect(preferences.sortField, SortField.indexed);
        expect(preferences.direction, SortDirection.descending);
      },
    );

    test(
      'GivenAFilter_WhenItIsCleared_ThenEveryTypeReturnsAndTheOrderStays',
      () async {
        // Ordering hides nothing, so clearing the filter is not a reason to
        // un-order the folder.
        final ref = await started();
        await controller(ref).filterTo(FileType.comic);
        await controller(ref).sortBy(SortField.indexed);

        await controller(ref).filterTo(null);

        expect(read(ref).type, isNull);
        expect(read(ref).isFiltered, isFalse);
        expect(read(ref).sortField, SortField.indexed);
      },
    );
  });

  group('remembering them', () {
    test('GivenAChoice_WhenItIsMade_ThenItIsWrittenUnderLibraryView', () async {
      final settings = InMemorySettingsStore(rechecksAtStartup: false);
      final ref = await started(settings: settings);

      await controller(ref).chooseLayout(ViewLayout.grid);
      await controller(ref).filterTo(FileType.audio);

      expect(LibraryViewPreferencesController.settingsKey, 'libraryView');
      expect(
        settings.entries['libraryView'],
        '{"layout":"grid","type":"audio","sortField":"name",'
        '"direction":"ascending"}',
      );
    });

    test(
      'GivenStoredChoices_WhenTheApplicationStarts_ThenTheyAreRestored',
      () async {
        final ref = await started(
          settings: InMemorySettingsStore(
            rechecksAtStartup: false,
            values: {
              'libraryView':
                  '{"layout":"detailedList","type":"image",'
                  '"sortField":"indexed","direction":"descending"}',
            },
          ),
        );

        final preferences = read(ref);
        expect(preferences.layout, ViewLayout.detailedList);
        expect(preferences.type, FileType.image);
        expect(preferences.sortField, SortField.indexed);
        expect(preferences.direction, SortDirection.descending);
      },
    );

    test(
      'GivenAnUnreadableValue_WhenItIsRestored_ThenTheDefaultsApply',
      () async {
        // A hand-edited settings file must not stop a library rendering.
        final ref = await started(
          settings: InMemorySettingsStore(
            rechecksAtStartup: false,
            values: {'libraryView': 'not json'},
          ),
        );

        expect(read(ref).layout, ViewLayout.list);
        expect(read(ref).type, isNull);
      },
    );

    test('GivenUnknownValues_WhenRestored_ThenEachFallsBackOnItsOwn', () async {
      // Written by some other version; guessing what it meant is worse than
      // the default, and the values it does know are still the owner's.
      final ref = await started(
        settings: InMemorySettingsStore(
          rechecksAtStartup: false,
          values: {
            'libraryView':
                '{"layout":"carousel","type":"hologram",'
                '"sortField":"indexed","direction":"sideways"}',
          },
        ),
      );

      final preferences = read(ref);
      expect(preferences.layout, ViewLayout.list);
      expect(preferences.type, isNull);
      expect(preferences.sortField, SortField.indexed);
      expect(preferences.direction, SortDirection.ascending);
    });
  });

  group('the store cannot be written (UC-10 AF-02)', () {
    test('GivenTheStoreRefuses_WhenAChoiceIsMade_ThenItStillApplies', () async {
      final ref = await started(settings: FailingSettingsStore());

      await controller(ref).chooseLayout(ViewLayout.grid);

      expect(read(ref).layout, ViewLayout.grid);
    });

    test('GivenTheStoreRefuses_WhenAChoiceIsMade_ThenItIsReported', () async {
      final ref = await started(settings: FailingSettingsStore());

      await controller(ref).filterTo(FileType.video);

      expect(read(ref).lastChangeUnsaved, isTrue);
    });

    test(
      'GivenAWorkingStore_WhenAChoiceIsMade_ThenNothingIsReported',
      () async {
        final ref = await started();

        await controller(ref).chooseLayout(ViewLayout.grid);

        expect(read(ref).lastChangeUnsaved, isFalse);
      },
    );
  });
}
