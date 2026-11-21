import 'package:logging/logging.dart';

import '../../../core/settings/settings_store.dart';
import '../../shell/domain/session_activity.dart';

/// Drops the folder list a 0.5 build kept, once, at sign-in.
///
/// Before the 0.6.0 core, the application kept its own list of folders to
/// index, under [key]. That core indexes nothing that is not a library and
/// deleted those folders' records when it upgraded, so the list names paths
/// no screen shows and nothing will ever read again. It is removed without
/// being read: a list this build cannot use is not worth parsing, and a
/// malformed or very large one is no reason to fail a sign-in.
class SourceListCleanupActivity implements SessionActivity {
  /// Creates the activity over the settings the startup sequence loaded,
  /// read when the session begins.
  const SourceListCleanupActivity(this._settings);

  /// Where the 0.5 build stored its folder list.
  static const String key = 'librarySources';

  static final Logger _log = Logger('indexing');

  final SettingsStore? Function() _settings;

  @override
  bool get holdsUnsavedChanges => false;

  @override
  bool get continuesInTheCore => false;

  @override
  Future<void> begin() async {
    final settings = _settings();
    if (settings == null || settings.getString(key) == null) return;

    try {
      await settings.remove(key);
    } on Object catch (error) {
      // Left for the next sign-in to try again: nothing reads it meanwhile.
      _log.warning('the old folder list could not be removed: $error');
    }
  }

  @override
  Future<void> end() async {}
}
