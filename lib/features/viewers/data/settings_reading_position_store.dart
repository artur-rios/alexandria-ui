import 'dart:convert';

import 'package:logging/logging.dart';

import '../../../core/settings/settings_store.dart';
import '../domain/reading_position_store.dart';

/// The reading positions, in the local settings store (FR-VW-02).
///
/// The same shape as the playback positions beside it: one key holding a map
/// from file uuid to position, read once and held in memory, because it is
/// asked for every time a document is opened.
class SettingsReadingPositionStore implements ReadingPositionStore {
  /// Creates a store over [_settings], reading what is already there.
  SettingsReadingPositionStore(this._settings) {
    _positions.addAll(_read());
  }

  static final Logger _log = Logger('viewers');

  /// The settings key the positions are stored under.
  static const String settingsKey = 'readingPositions';

  final SettingsStore _settings;
  final Map<String, int> _positions = {};

  @override
  int? positionFor(String fileUuid) => _positions[fileUuid];

  @override
  Future<void> record(String fileUuid, int position) {
    _positions[fileUuid] = position;
    return _write();
  }

  @override
  Future<void> forget(String fileUuid) {
    _positions.remove(fileUuid);
    return _write();
  }

  Map<String, int> _read() {
    final stored = _settings.getString(settingsKey);
    if (stored == null) return const {};

    try {
      final decoded = jsonDecode(stored) as Map<String, dynamic>;

      return {
        for (final entry in decoded.entries) entry.key: entry.value as int,
      };
    } on Object catch (error) {
      // A position nobody can decode is a position nobody has, and it must not
      // stop the application starting.
      _log.warning('the reading positions could not be read', error);
      return const {};
    }
  }

  Future<void> _write() =>
      _settings.setString(settingsKey, jsonEncode(_positions));
}
