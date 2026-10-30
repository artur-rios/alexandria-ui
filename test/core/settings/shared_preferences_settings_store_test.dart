import 'package:alexandria_ui/core/settings/shared_preferences_settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// IR-12: the store a real installation reads, over keys an older release
/// wrote.
void main() {
  group('keys an earlier release stored', () {
    test(
      'GivenStoredMusicLookupKeys_WhenSettingsLoad_ThenTheyAreIgnored',
      () async {
        // The music lookup was removed, and its two keys stay in the owner's
        // preferences untouched: nothing deletes what a downgrade might still
        // read. What this pins is that they no longer get in the way.
        SharedPreferences.setMockInitialValues({
          'settings.musicLookupEnabled': 'true',
          'settings.musicLookupContact': 'owner@example.com',
          'settings.themeMode': 'dark',
        });

        final store = await SharedPreferencesSettingsStore.load();

        expect(store.themeMode, ThemeMode.dark);
        expect(store.locale, isNull);
        expect(store.rechecksAtStartup, isTrue);
        expect(
          store.getString('settings.musicLookupContact'),
          'owner@example.com',
          reason: 'the stored value is left where it was, merely unread',
        );
      },
    );

    test(
      'GivenStoredOpensPlayerOnPlay_WhenSettingsLoad_ThenItIsIgnored',
      () async {
        // Music playback was removed, and with it the preference to open the
        // full player when a track starts. The key an earlier release wrote
        // stays where it was; what this pins is that the rest still loads.
        SharedPreferences.setMockInitialValues({
          'settings.opensPlayerOnPlay': false,
          'settings.themeMode': 'light',
          'settings.locale': 'pt_BR',
          'settings.rechecksAtStartup': 'false',
        });

        final store = await SharedPreferencesSettingsStore.load();

        expect(store.themeMode, ThemeMode.light);
        expect(store.locale, const Locale('pt', 'BR'));
        expect(store.rechecksAtStartup, isFalse);
        expect(
          (await SharedPreferences.getInstance()).getBool(
            'settings.opensPlayerOnPlay',
          ),
          isFalse,
          reason: 'the stored value is left where it was, merely unread',
        );
      },
    );
  });
}
