import 'package:alexandria_ui/core/settings/settings_store.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:flutter/material.dart';

/// The in-memory [SettingsStore] every unit and widget test binds
/// (Testing Specification §6.2).
///
/// No test reads or writes the developer's own settings; that is a defect in
/// the test, not a configuration to work around (§7.3).
class InMemorySettingsStore implements SettingsStore {
  /// Creates a store, optionally pre-populated.
  InMemorySettingsStore({
    ThemeMode themeMode = ThemeMode.system,
    Locale? locale,
    AlbumAnimationMode albumAnimationMode = AlbumAnimationMode.byYear,
    // On, matching the real default (`SettingsStore.rechecksAtStartup`'s own
    // doc) — the honest default any owner starts a session with. This is a
    // live coupling worth knowing about: `pumpShell` (shell_harness.dart)
    // signs in over a store built with this default, so every widget test
    // built on it fires a real startup re-check through whatever fake index
    // gateway that container happens to have. Benign today because the
    // default fake gateway answers with nothing to refresh, but a test that
    // adds a stateful fake gateway to a `pumpShell`-based suite inherits this
    // call whether or not it has anything to do with FR-LB-21.
    bool rechecksAtStartup = true,
    Map<String, String>? values,
  })
    // The fields are private and a named parameter cannot be, so `this._themeMode`
    // is not expressible.
    // ignore_for_file: prefer_initializing_formals
    : _themeMode = themeMode,
       _locale = locale,
       _albumAnimationMode = albumAnimationMode,
       _rechecksAtStartup = rechecksAtStartup,
       _values = {...?values};

  ThemeMode _themeMode;
  Locale? _locale;
  AlbumAnimationMode _albumAnimationMode;
  bool _rechecksAtStartup;
  final Map<String, String> _values;

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  Future<void> setThemeMode(ThemeMode mode) async => _themeMode = mode;

  @override
  Locale? get locale => _locale;

  @override
  Future<void> setLocale(Locale? locale) async => _locale = locale;

  @override
  AlbumAnimationMode get albumAnimationMode => _albumAnimationMode;

  @override
  Future<void> setAlbumAnimationMode(AlbumAnimationMode mode) async =>
      _albumAnimationMode = mode;

  @override
  bool get rechecksAtStartup => _rechecksAtStartup;

  @override
  Future<void> setRechecksAtStartup(bool value) async =>
      _rechecksAtStartup = value;

  @override
  String? getString(String key) => _values[key];

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);

  /// Everything currently stored, so a test can assert what was written — and,
  /// for IR-12, what was not.
  Map<String, String> get entries => Map.unmodifiable(_values);
}
