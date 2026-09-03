import 'package:alexandria_ui/core/bindings/core_environment.dart';
import 'package:alexandria_ui/core/settings/settings_store.dart';
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
    bool opensPlayerOnPlay = true,
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
    // On, matching the real default (`SettingsStore.musicLookupEnabled`):
    // a test that asserts what the core was initialized with is asserting
    // the shipped configuration, not one the test invented.
    bool musicLookupEnabled = true,
    String musicLookupContact = defaultMusicLookupContact,
    Map<String, String>? values,
  })
    // The fields are private and a named parameter cannot be, so `this._themeMode`
    // is not expressible.
    // ignore_for_file: prefer_initializing_formals
    : _themeMode = themeMode,
       _locale = locale,
       _opensPlayerOnPlay = opensPlayerOnPlay,
       _rechecksAtStartup = rechecksAtStartup,
       _musicLookupEnabled = musicLookupEnabled,
       _musicLookupContact = musicLookupContact,
       _values = {...?values};

  ThemeMode _themeMode;
  Locale? _locale;
  bool _opensPlayerOnPlay;
  bool _rechecksAtStartup;
  bool _musicLookupEnabled;
  String _musicLookupContact;
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
  bool get opensPlayerOnPlay => _opensPlayerOnPlay;

  @override
  Future<void> setOpensPlayerOnPlay(bool value) async =>
      _opensPlayerOnPlay = value;

  @override
  bool get rechecksAtStartup => _rechecksAtStartup;

  @override
  Future<void> setRechecksAtStartup(bool value) async =>
      _rechecksAtStartup = value;

  @override
  bool get musicLookupEnabled => _musicLookupEnabled;

  @override
  Future<void> setMusicLookupEnabled(bool value) async =>
      _musicLookupEnabled = value;

  @override
  String get musicLookupContact => _musicLookupContact;

  @override
  Future<void> setMusicLookupContact(String contact) async =>
      _musicLookupContact = contact.trim().isEmpty
      ? defaultMusicLookupContact
      : contact.trim();

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
