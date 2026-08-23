import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/settings/settings_store.dart';
import 'package:alexandria_ui/features/catalog/application/layout_controller.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/catalog/domain/view_layout.dart';
import 'package:alexandria_ui/core/theme/breakpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/failing_settings_store.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/test_container.dart';

/// Choosing a layout per file type (UC-10, FR-CT-03, FR-CT-04).
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

  group('the layout itself', () {
    test('GivenNoStoredChoice_WhenATypeIsRead_ThenItIsTheList', () async {
      // The list is the one layout that fits every supported window, so the
      // default is never itself a substitution.
      final ref = await started();

      expect(
        ref.read(layoutControllerProvider).chosenFor(LibraryType.audio),
        ViewLayout.list,
      );
    });

    test('GivenAChosenLayout_WhenItIsChosen_ThenItApplies', () async {
      final ref = await started();

      await ref
          .read(layoutControllerProvider.notifier)
          .choose(LibraryType.image, ViewLayout.grid);

      expect(
        ref.read(layoutControllerProvider).chosenFor(LibraryType.image),
        ViewLayout.grid,
      );
    });

    test(
      'GivenTwoTypes_WhenEachIsChosen_ThenNeitherDisturbsTheOther',
      () async {
        // FR-CT-04 is per type: notes as a list and images as a grid are two
        // preferences, not one that keeps changing.
        final ref = await started();
        final controller = ref.read(layoutControllerProvider.notifier);

        await controller.choose(LibraryType.image, ViewLayout.grid);
        await controller.choose(LibraryType.text, ViewLayout.detailedList);

        final layouts = ref.read(layoutControllerProvider);
        expect(layouts.chosenFor(LibraryType.image), ViewLayout.grid);
        expect(layouts.chosenFor(LibraryType.text), ViewLayout.detailedList);
        expect(layouts.chosenFor(LibraryType.audio), ViewLayout.list);
      },
    );
  });

  group('remembering it (FR-CT-04)', () {
    test('GivenAChosenLayout_WhenItIsChosen_ThenItIsWritten', () async {
      final settings = InMemorySettingsStore();
      final ref = await started(settings: settings);

      await ref
          .read(layoutControllerProvider.notifier)
          .choose(LibraryType.image, ViewLayout.grid);

      expect(settings.entries[LayoutController.settingsKey], contains('grid'));
    });

    test(
      'GivenAStoredLayout_WhenTheApplicationStarts_ThenItIsRestored',
      () async {
        final ref = await started(
          settings: InMemorySettingsStore(
            values: {
              LayoutController.settingsKey: '{"image":"grid","text":"list"}',
            },
          ),
        );

        final layouts = ref.read(layoutControllerProvider);
        expect(layouts.chosenFor(LibraryType.image), ViewLayout.grid);
        expect(layouts.chosenFor(LibraryType.text), ViewLayout.list);
      },
    );

    test(
      'GivenAnUnreadableValue_WhenItIsRestored_ThenTheDefaultApplies',
      () async {
        // A hand-edited settings file must not stop a listing rendering.
        final ref = await started(
          settings: InMemorySettingsStore(
            values: {LayoutController.settingsKey: 'not json'},
          ),
        );

        expect(
          ref.read(layoutControllerProvider).chosenFor(LibraryType.image),
          ViewLayout.list,
        );
      },
    );

    test('GivenAnUnknownTypeOrLayout_WhenRestored_ThenItIsSkipped', () async {
      // Written by some other version; guessing what it meant is worse than
      // the default.
      final ref = await started(
        settings: InMemorySettingsStore(
          values: {
            LayoutController.settingsKey:
                '{"hologram":"grid","image":"carousel","text":"grid"}',
          },
        ),
      );

      final layouts = ref.read(layoutControllerProvider);
      expect(layouts.chosenFor(LibraryType.image), ViewLayout.list);
      expect(layouts.chosenFor(LibraryType.text), ViewLayout.grid);
    });
  });

  group('the store cannot be written (AF-02)', () {
    test(
      'GivenTheStoreRefuses_WhenALayoutIsChosen_ThenItStillApplies',
      () async {
        final ref = await started(settings: FailingSettingsStore());

        await ref
            .read(layoutControllerProvider.notifier)
            .choose(LibraryType.image, ViewLayout.grid);

        expect(
          ref.read(layoutControllerProvider).chosenFor(LibraryType.image),
          ViewLayout.grid,
        );
      },
    );

    test('GivenTheStoreRefuses_WhenALayoutIsChosen_ThenItIsReported', () async {
      final ref = await started(settings: FailingSettingsStore());

      await ref
          .read(layoutControllerProvider.notifier)
          .choose(LibraryType.image, ViewLayout.grid);

      expect(ref.read(layoutControllerProvider).lastChangeUnsaved, isTrue);
    });

    test(
      'GivenAWorkingStore_WhenALayoutIsChosen_ThenNothingIsReported',
      () async {
        final ref = await started();

        await ref
            .read(layoutControllerProvider.notifier)
            .choose(LibraryType.image, ViewLayout.grid);

        expect(ref.read(layoutControllerProvider).lastChangeUnsaved, isFalse);
      },
    );
  });

  group('the listing is too narrow (AF-01)', () {
    // Listing widths, not window widths: the panel, the divider, and the
    // screen padding come off the window before the rows are laid out, and
    // measuring the window is what made this decision wrong.
    //
    // At the minimum supported window (1024, NFR-07) the listing is about 820
    // wide; a comfortably wide window leaves it well past the floor.
    const atTheMinimumWindow = 820.0;
    const roomy = 1237.5;

    test('GivenTheList_WhenTheListingIsAtItsNarrowest_ThenItFits', () {
      expect(ViewLayout.list.fitsIn(atTheMinimumWindow), isTrue);
      expect(ViewLayout.grid.fitsIn(atTheMinimumWindow), isTrue);
    });

    test('GivenTheDetailedList_WhenTheListingIsNarrow_ThenItDoesNotFit', () {
      expect(ViewLayout.detailedList.fitsIn(atTheMinimumWindow), isFalse);
      expect(ViewLayout.detailedList.fitsIn(roomy), isTrue);
    });

    test('GivenTheFloor_WhenItIsRead_ThenItIsTheListingsAndNotTheWindows', () {
      // The regression this guards: borrowing the medium *window* breakpoint
      // as a listing floor refused the layout on a 1440 window, where the
      // listing is 1237.5 and the columns fit comfortably.
      expect(
        ViewLayout.detailedList.minimumListingWidth,
        lessThan(Breakpoint.mediumMinWidth),
      );
    });

    test('GivenTheDetailedList_WhenItDoesNotFit_ThenTheListIsDrawn', () {
      // The closest that fits: the same layout without the column that
      // stopped fitting, not a grid, which reads entirely differently.
      expect(
        ViewLayout.detailedList.resolvedFor(atTheMinimumWindow),
        ViewLayout.list,
      );
      expect(
        ViewLayout.detailedList.isSubstitutedAt(atTheMinimumWindow),
        isTrue,
      );
    });

    test('GivenALayoutThatFits_WhenItIsResolved_ThenItIsUnchanged', () {
      for (final layout in ViewLayout.values) {
        expect(layout.resolvedFor(roomy), layout);
        expect(layout.isSubstitutedAt(roomy), isFalse);
      }
    });

    test('GivenTheChoiceIsSubstituted_WhenTheWindowWidens_ThenItReturns', () {
      // The substitution is a drawing decision, not a change to the choice.
      expect(
        ViewLayout.detailedList.resolvedFor(roomy),
        ViewLayout.detailedList,
      );
    });
  });
}
