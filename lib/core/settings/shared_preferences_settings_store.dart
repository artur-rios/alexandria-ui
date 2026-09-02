import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bindings/core_environment.dart';
import 'settings_store.dart';

/// The [SettingsStore] backed by `shared_preferences` (IR-12).
///
/// Reads are synchronous because the whole store is loaded once at startup
/// (Operations & Infrastructure Document §5.1 step 5): a screen asking for the
/// theme cannot await, and a preference read is not worth a rebuild.
class SharedPreferencesSettingsStore implements SettingsStore {
  /// Wraps an already-loaded [SharedPreferences] instance.
  SharedPreferencesSettingsStore(this._preferences);

  /// Loads the store from disk.
  ///
  /// Throws whatever `shared_preferences` throws when the backing file cannot
  /// be read; startup step 5 catches it and falls back to the system theme and
  /// language rather than failing the launch.
  static Future<SharedPreferencesSettingsStore> load() async =>
      SharedPreferencesSettingsStore(await SharedPreferences.getInstance());

  final SharedPreferences _preferences;

  static const _themeModeKey = 'settings.themeMode';
  static const _localeKey = 'settings.locale';
  static const _opensPlayerKey = 'settings.opensPlayerOnPlay';
  static const _rechecksAtStartupKey = 'settings.rechecksAtStartup';
  static const _musicLookupEnabledKey = 'settings.musicLookupEnabled';
  static const _musicLookupContactKey = 'settings.musicLookupContact';

  @override
  ThemeMode get themeMode => switch (_preferences.getString(_themeModeKey)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    // Covers both "the owner chose system" and "the owner has not chosen", and
    // also a value written by a future version this one does not understand.
    _ => ThemeMode.system,
  };

  @override
  Future<void> setThemeMode(ThemeMode mode) =>
      _preferences.setString(_themeModeKey, mode.name);

  @override
  Locale? get locale {
    final stored = _preferences.getString(_localeKey);
    if (stored == null || stored.isEmpty) return null;

    final parts = stored.split('_');
    return parts.length > 1
        ? Locale(parts.first, parts[1])
        : Locale(parts.first);
  }

  @override
  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await _preferences.remove(_localeKey);
      return;
    }

    final countryCode = locale.countryCode;
    await _preferences.setString(
      _localeKey,
      countryCode == null || countryCode.isEmpty
          ? locale.languageCode
          : '${locale.languageCode}_$countryCode',
    );
  }

  /// Absent reads as on: an owner who has never opened the dialog gets the
  /// player when they start something, which is the behaviour the screen
  /// exists for.
  @override
  bool get opensPlayerOnPlay =>
      _preferences.getBool(_opensPlayerKey) ?? true;

  @override
  Future<void> setOpensPlayerOnPlay(bool value) =>
      _preferences.setBool(_opensPlayerKey, value);

  /// Absent reads as on, which is the default the preference ships with: an
  /// owner who has never opened the dialog gets the re-check.
  @override
  bool get rechecksAtStartup =>
      _preferences.getString(_rechecksAtStartupKey) != 'false';

  @override
  Future<void> setRechecksAtStartup(bool value) =>
      _preferences.setString(_rechecksAtStartupKey, value.toString());

  /// Absent reads as on, the same way the re-check above does: lyrics and
  /// artist photography are what an owner opening a music player expects to
  /// see, and the lookup still reaches nothing until they ask for one.
  @override
  bool get musicLookupEnabled =>
      _preferences.getString(_musicLookupEnabledKey) != 'false';

  @override
  Future<void> setMusicLookupEnabled(bool value) =>
      _preferences.setString(_musicLookupEnabledKey, value.toString());

  @override
  String get musicLookupContact {
    final stored = _preferences.getString(_musicLookupContactKey)?.trim();

    return stored == null || stored.isEmpty
        ? defaultMusicLookupContact
        : stored;
  }

  @override
  Future<void> setMusicLookupContact(String contact) {
    final trimmed = contact.trim();

    // Cleared rather than stored blank: an empty contact is the owner asking
    // for the application's own again, and a stored empty string would be a
    // second way of saying that for every later read to remember.
    return trimmed.isEmpty
        ? _preferences.remove(_musicLookupContactKey)
        : _preferences.setString(_musicLookupContactKey, trimmed);
  }

  @override
  String? getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> remove(String key) => _preferences.remove(key);
}
