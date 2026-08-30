import 'dart:convert';

import 'package:logging/logging.dart';

import '../../../core/settings/settings_store.dart';
import '../domain/library_source.dart';
import '../domain/library_source_store.dart';

/// The registered source folders, in the local settings store
/// (FR-LB-03, System Requirements §4.11).
///
/// A list under one key rather than a key per folder: the whole set is read at
/// once and written at once, and a per-folder scheme would need its own index
/// to enumerate them.
class SettingsLibrarySourceStore implements LibrarySourceStore {
  /// Creates a store over [settings].
  const SettingsLibrarySourceStore(this._settings);

  static final Logger _log = Logger('library_sources');

  /// The settings key the folders are stored under.
  static const String settingsKey = 'librarySources';

  final SettingsStore _settings;

  /// Every registered folder, in the order they were registered.
  ///
  /// An unreadable value answers an empty list rather than throwing: a
  /// hand-edited settings file must not stop the application starting, and an
  /// owner with no folders is a state the interface already handles (FR-LB-11).
  @override
  List<LibrarySource> read() {
    final stored = _settings.getString(settingsKey);
    if (stored == null) return const [];

    try {
      final decoded = jsonDecode(stored) as List<dynamic>;
      return [
        for (final entry in decoded)
          LibrarySource.fromJson(entry as Map<String, dynamic>),
      ];
    } on Object catch (error) {
      // Broad by intent: a malformed document surfaces as FormatException and
      // a wrongly-typed field as TypeError, and either way there is nothing
      // here to restore.
      _log.warning('the registered source folders could not be read', error);
      return const [];
    }
  }

  @override
  Future<void> write(List<LibrarySource> sources) => _settings.setString(
    settingsKey,
    jsonEncode([for (final source in sources) source.toJson()]),
  );
}
