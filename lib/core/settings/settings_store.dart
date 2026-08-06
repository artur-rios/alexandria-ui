import 'package:flutter/material.dart';

/// The owner's local preferences (IR-12, FR-UX-12).
///
/// What this holds is owner-facing state changed in the interface: theme,
/// language, layout, sort and filter defaults, registered library folders,
/// playback resume points, and window geometry.
///
/// What it never holds is a credential or any catalog data. The salted password
/// hash lives in the core; the session credential lives in process memory for
/// the run of the application only; every file, collection, and list is read
/// through the core's FFI surface and never cached here. A settings store that
/// starts caching catalog rows becomes a second source of truth, and the two
/// disagree the first time an index run changes something.
///
/// This interface is declared here rather than in a feature so the composition
/// root can bind one implementation for the application and another for a test
/// (IR-07). Tests use the in-memory implementation in `test/support/`; no test
/// reads the developer's own settings.
abstract interface class SettingsStore {
  /// The theme the owner chose, or [ThemeMode.system] when they have not.
  ThemeMode get themeMode;

  /// Records the owner's theme choice. Applied immediately, without a restart.
  Future<void> setThemeMode(ThemeMode mode);

  /// The language the owner chose, or `null` to follow the system.
  Locale? get locale;

  /// Records the owner's language choice. Applied immediately.
  Future<void> setLocale(Locale? locale);

  /// Reads an arbitrary string preference.
  ///
  /// Features add their own typed accessors above rather than reaching for this
  /// from a screen; it exists so a feature can store its own defaults without
  /// this interface growing a method per use case.
  String? getString(String key);

  /// Writes an arbitrary string preference.
  Future<void> setString(String key, String value);

  /// Removes a preference, returning the owner to the default.
  Future<void> remove(String key);
}
