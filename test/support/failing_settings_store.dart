import 'package:alexandria_ui/core/settings/settings_store.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:flutter/material.dart';

/// A [SettingsStore] whose writes fail (UC-39 AF-02).
///
/// A hand-written fake rather than a `mocktail` stub because the interesting
/// property spans two calls: the write throws *and* the read keeps answering,
/// which is what makes "applied but not saved" distinguishable from "not
/// applied".
class FailingSettingsStore implements SettingsStore {
  /// Creates a store that reads normally and refuses every write.
  FailingSettingsStore({
    ThemeMode themeMode = ThemeMode.system,
    Locale? locale,
    AlbumAnimationMode albumAnimationMode = AlbumAnimationMode.byYear,
  })
    // The fields are private and a named parameter cannot be, so
    // `this._themeMode` is not expressible. Same reason as
    // in_memory_settings_store.dart.
    // ignore: prefer_initializing_formals
    : _themeMode = themeMode,
      // ignore: prefer_initializing_formals
      _locale = locale,
      // ignore: prefer_initializing_formals
      _albumAnimationMode = albumAnimationMode;

  final ThemeMode _themeMode;
  final Locale? _locale;
  final AlbumAnimationMode _albumAnimationMode;

  /// Every write attempted, so a test can assert the store really was asked.
  final List<String> attempted = [];

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    attempted.add('themeMode');
    throw const FileSystemException('the settings file is read-only');
  }

  @override
  Locale? get locale => _locale;

  @override
  Future<void> setLocale(Locale? locale) async {
    attempted.add('locale');
    throw const FileSystemException('the settings file is read-only');
  }

  @override
  AlbumAnimationMode get albumAnimationMode => _albumAnimationMode;

  @override
  Future<void> setAlbumAnimationMode(AlbumAnimationMode mode) async {
    attempted.add('albumAnimationMode');
    throw const FileSystemException('the settings file is read-only');
  }

  @override
  String? getString(String key) => null;

  @override
  Future<void> setString(String key, String value) async {
    attempted.add(key);
    throw const FileSystemException('the settings file is read-only');
  }

  @override
  Future<void> remove(String key) async {
    attempted.add(key);
    throw const FileSystemException('the settings file is read-only');
  }
}

/// The failure a store that cannot be written reports.
///
/// Its own type rather than `dart:io`'s, so the fake stays usable in a test
/// that does not import `dart:io` and so the message reads as the condition
/// rather than as a platform detail.
class FileSystemException implements Exception {
  /// Creates the exception.
  const FileSystemException(this.message);

  /// Why the write failed.
  final String message;

  @override
  String toString() => 'FileSystemException: $message';
}
