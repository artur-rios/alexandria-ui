import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/settings/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/failing_settings_store.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/test_container.dart';

/// The owner's theme and language (UC-39, FR-UX-04, FR-UX-05, FR-UX-12).
void main() {
  /// A container whose startup has settled over [settings].
  Future<ProviderContainer> started({SettingsStore? settings}) async {
    final container = buildTestContainer(
      overrides: fakeCoreOverrides(
        settings: settings ?? InMemorySettingsStore(),
      ),
    );
    await container.read(startupControllerProvider.notifier).start();
    return container;
  }

  group('reading what was stored', () {
    test(
      'GivenNoStoredPreference_WhenTheGraphIsRead_ThenItFollowsTheSystem',
      () async {
        // AF-03: nothing has ever been chosen.
        final container = await started();

        expect(container.read(themeModeProvider), ThemeMode.system);
        expect(container.read(localeProvider), isNull);
      },
    );

    test('GivenAStoredTheme_WhenStartupSettles_ThenItIsApplied', () async {
      final container = await started(
        settings: InMemorySettingsStore(themeMode: ThemeMode.dark),
      );

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('GivenAStoredLanguage_WhenStartupSettles_ThenItIsApplied', () async {
      final container = await started(
        settings: InMemorySettingsStore(locale: const Locale('pt', 'BR')),
      );

      expect(container.read(localeProvider), const Locale('pt', 'BR'));
    });

    test(
      'GivenStartupHasNotSettled_WhenTheThemeIsRead_ThenItFollowsTheSystem',
      () {
        // Guessing would flash the wrong theme on every launch.
        final container = buildTestContainer();

        expect(container.read(themeModeProvider), ThemeMode.system);
        expect(container.read(localeProvider), isNull);
      },
    );
  });

  group('choosing a theme', () {
    test(
      'GivenTheSystemTheme_WhenDarkIsChosen_ThenItAppliesImmediately',
      () async {
        final container = await started();

        await container
            .read(preferencesControllerProvider.notifier)
            .setThemeMode(ThemeMode.dark);

        expect(container.read(themeModeProvider), ThemeMode.dark);
      },
    );

    test(
      'GivenAChosenTheme_WhenItIsChosen_ThenItIsWrittenForTheNextLaunch',
      () async {
        final settings = InMemorySettingsStore();
        final container = await started(settings: settings);

        await container
            .read(preferencesControllerProvider.notifier)
            .setThemeMode(ThemeMode.light);

        expect(settings.themeMode, ThemeMode.light);
      },
    );

    test('GivenEveryThemeOption_WhenEachIsChosen_ThenEachApplies', () async {
      final container = await started();
      final controller = container.read(preferencesControllerProvider.notifier);

      for (final mode in ThemeMode.values) {
        await controller.setThemeMode(mode);
        expect(container.read(themeModeProvider), mode);
      }
    });
  });

  group('choosing a language', () {
    test(
      'GivenEnglish_WhenPortugueseIsChosen_ThenItAppliesImmediately',
      () async {
        final container = await started();

        await container
            .read(preferencesControllerProvider.notifier)
            .setLocale(const Locale('pt', 'BR'));

        expect(container.read(localeProvider), const Locale('pt', 'BR'));
      },
    );

    test(
      'GivenAChosenLanguage_WhenItIsChosen_ThenItIsWrittenForTheNextLaunch',
      () async {
        final settings = InMemorySettingsStore();
        final container = await started(settings: settings);

        await container
            .read(preferencesControllerProvider.notifier)
            .setLocale(const Locale('en'));

        expect(settings.locale, const Locale('en'));
      },
    );

    test(
      'GivenAChosenLanguage_WhenTheSystemIsChosenAgain_ThenItFollowsTheSystem',
      () async {
        final settings = InMemorySettingsStore(locale: const Locale('en'));
        final container = await started(settings: settings);

        await container
            .read(preferencesControllerProvider.notifier)
            .setLocale(null);

        expect(container.read(localeProvider), isNull);
        expect(settings.locale, isNull);
      },
    );
  });

  group('a store that cannot be written (AF-02)', () {
    test(
      'GivenTheStoreRefusesAWrite_WhenAThemeIsChosen_ThenItStillApplies',
      () async {
        final container = await started(settings: FailingSettingsStore());

        await container
            .read(preferencesControllerProvider.notifier)
            .setThemeMode(ThemeMode.dark);

        expect(
          container.read(themeModeProvider),
          ThemeMode.dark,
          reason:
              'the owner asked for a dark theme; a read-only disk is no reason '
              'to refuse them one for this session',
        );
      },
    );

    test(
      'GivenTheStoreRefusesAWrite_WhenAThemeIsChosen_ThenItIsReported',
      () async {
        final container = await started(settings: FailingSettingsStore());

        await container
            .read(preferencesControllerProvider.notifier)
            .setThemeMode(ThemeMode.dark);

        expect(
          container.read(preferencesControllerProvider).lastChangeUnsaved,
          isTrue,
        );
      },
    );

    test(
      'GivenTheStoreRefusesAWrite_WhenALanguageIsChosen_ThenItIsReported',
      () async {
        final store = FailingSettingsStore();
        final container = await started(settings: store);

        await container
            .read(preferencesControllerProvider.notifier)
            .setLocale(const Locale('pt', 'BR'));

        expect(container.read(localeProvider), const Locale('pt', 'BR'));
        expect(
          container.read(preferencesControllerProvider).lastChangeUnsaved,
          isTrue,
        );
        expect(store.attempted, ['locale']);
      },
    );

    test(
      'GivenAWorkingStore_WhenAThemeIsChosen_ThenNothingIsReported',
      () async {
        final container = await started();

        await container
            .read(preferencesControllerProvider.notifier)
            .setThemeMode(ThemeMode.dark);

        expect(
          container.read(preferencesControllerProvider).lastChangeUnsaved,
          isFalse,
          reason: 'a write that worked must not warn about not having worked',
        );
      },
    );

    test(
      'GivenAReportedFailure_WhenTheOwnerHasSeenIt_ThenItIsCleared',
      () async {
        final container = await started(settings: FailingSettingsStore());
        final controller = container.read(
          preferencesControllerProvider.notifier,
        );
        await controller.setThemeMode(ThemeMode.dark);

        controller.acknowledgeUnsaved();

        expect(
          container.read(preferencesControllerProvider).lastChangeUnsaved,
          isFalse,
        );
      },
    );

    test(
      'GivenStartupHasNotSettled_WhenAThemeIsChosen_ThenItAppliesAndIsReported',
      () async {
        // There is no settings store yet, so there is nowhere to write.
        final container = buildTestContainer();

        await container
            .read(preferencesControllerProvider.notifier)
            .setThemeMode(ThemeMode.dark);

        expect(container.read(themeModeProvider), ThemeMode.dark);
        expect(
          container.read(preferencesControllerProvider).lastChangeUnsaved,
          isTrue,
        );
      },
    );
  });
}
