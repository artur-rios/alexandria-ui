import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/in_memory_settings_store.dart';

/// IR-12: the settings store reads and writes, and holds no credential or
/// catalog data.
void main() {
  group('the theme preference', () {
    test('GivenNoStoredChoice_WhenTheThemeIsRead_ThenItFollowsTheSystem', () {
      expect(InMemorySettingsStore().themeMode, ThemeMode.system);
    });

    test('GivenAStoredChoice_WhenTheThemeIsRead_ThenItIsReturned', () async {
      final store = InMemorySettingsStore();

      await store.setThemeMode(ThemeMode.dark);

      expect(store.themeMode, ThemeMode.dark);
    });
  });

  group('the language preference', () {
    test('GivenNoStoredChoice_WhenTheLocaleIsRead_ThenItIsNull', () {
      expect(InMemorySettingsStore().locale, isNull);
    });

    test(
      'GivenAStoredLocale_WhenItIsRead_ThenTheCountryCodeSurvives',
      () async {
        final store = InMemorySettingsStore();

        await store.setLocale(const Locale('pt', 'BR'));

        expect(store.locale, const Locale('pt', 'BR'));
      },
    );

    test(
      'GivenAStoredLocale_WhenItIsCleared_ThenItFollowsTheSystemAgain',
      () async {
        final store = InMemorySettingsStore(locale: const Locale('en'));

        await store.setLocale(null);

        expect(store.locale, isNull);
      },
    );
  });

  group('arbitrary preferences', () {
    test('GivenAWrittenValue_WhenItIsRead_ThenItComesBack', () async {
      final store = InMemorySettingsStore();

      await store.setString('catalog.sort', 'name');

      expect(store.getString('catalog.sort'), 'name');
    });

    test('GivenAnAbsentKey_WhenItIsRead_ThenTheResultIsNull', () {
      expect(InMemorySettingsStore().getString('never.written'), isNull);
    });

    test('GivenAStoredValue_WhenItIsRemoved_ThenItIsGone', () async {
      final store = InMemorySettingsStore(values: {'a': 'b'});

      await store.remove('a');

      expect(store.getString('a'), isNull);
    });
  });

  group('what the store must never hold (IR-12)', () {
    // The interface itself is the enforcement: it exposes no method that takes
    // a credential or a catalog record, so storing one would mean changing
    // SettingsStore — a change a reviewer sees. These tests cover the part a
    // reviewer cannot see, which is what actually ends up in the store.
    test('GivenAFreshStore_WhenItIsInspected_ThenNothingIsStored', () {
      expect(InMemorySettingsStore().entries, isEmpty);
    });

    test(
      'GivenOwnerPreferences_WhenTheyAreStored_ThenNoCredentialIsAmongThem',
      () async {
        final store = InMemorySettingsStore();

        await store.setThemeMode(ThemeMode.light);
        await store.setLocale(const Locale('en'));
        await store.setString('catalog.layout', 'grid');

        // The salted hash lives in the core and the session credential lives in
        // process memory for the run only; neither has a home here.
        expect(
          store.entries.keys,
          everyElement(
            isNot(
              anyOf(
                contains('password'),
                contains('token'),
                contains('session'),
              ),
            ),
          ),
        );
      },
    );
  });
}
