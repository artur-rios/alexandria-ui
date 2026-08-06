import 'package:alexandria_desktop/core/settings/settings_store.dart';
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
    Map<String, String>? values,
  })
  // The fields are private and a named parameter cannot be, so `this._themeMode`
  // is not expressible.
  // ignore_for_file: prefer_initializing_formals
  : _themeMode = themeMode,
    _locale = locale,
    _values = {...?values};

  ThemeMode _themeMode;
  Locale? _locale;
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
