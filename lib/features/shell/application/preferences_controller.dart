import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/di/providers.dart';
import '../../../core/settings/settings_store.dart';
import '../../../core/startup/startup_state.dart';
import 'preferences_state.dart';

/// The owner's theme and language (UC-39, FR-UX-04, FR-UX-05, FR-UX-12).
///
/// A notifier rather than the two read-only providers this replaces, because
/// main flow steps 3 and 5 require a change to apply *immediately, without
/// restarting*. Reading the settings store on every build gave the right
/// answer at launch and no answer at all afterwards: nothing rebuilt when the
/// stored value changed, so a preference screen could write the file and watch
/// the interface ignore it.
///
/// The state is the source of truth for what is on screen; the settings store
/// is where it is persisted for the next launch. That order is what makes
/// AF-02 expressible — the choice applies either way, and only the saving can
/// fail.
class PreferencesController extends Notifier<PreferencesState> {
  static final Logger _log = Logger('shell');

  @override
  PreferencesState build() {
    // Watched, not read: the settings store does not exist until startup step
    // 5 has run, and this has to pick the owner's stored choices up when it
    // does. Until then the defaults are AF-03's.
    final startup = ref.watch(startupControllerProvider);
    if (startup is! StartupReady) return const PreferencesState();

    final settings = _settings;
    return PreferencesState(
      themeMode: settings?.themeMode ?? ThemeMode.system,
      locale: settings?.locale,
    );
  }

  SettingsStore? get _settings =>
      ref.read(startupControllerProvider.notifier).settings;

  /// Applies [mode] now and records it for the next launch (main flow steps 2
  /// and 3).
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode, lastChangeUnsaved: false);
    await _persist((settings) => settings.setThemeMode(mode));
  }

  /// Applies [locale] now and records it for the next launch (main flow steps
  /// 4 and 5).
  ///
  /// A `null` [locale] is the owner choosing to follow the system again, which
  /// is a preference like any other and is stored as one.
  Future<void> setLocale(Locale? locale) async {
    state = state.copyWith(locale: locale, lastChangeUnsaved: false);
    await _persist((settings) => settings.setLocale(locale));
  }

  /// Clears the unsaved notice once the owner has seen it.
  void acknowledgeUnsaved() {
    if (!state.lastChangeUnsaved) return;
    state = state.copyWith(lastChangeUnsaved: false);
  }

  /// Writes through to the settings store, reporting a failure rather than
  /// undoing the change (AF-02).
  ///
  /// Rolling back would be the worse answer: the owner asked for a dark theme,
  /// and a dark theme is what they should get for this session even on a
  /// read-only disk. What they must not get is the silent belief that it was
  /// remembered.
  Future<void> _persist(Future<void> Function(SettingsStore) write) async {
    final settings = _settings;
    if (settings == null) {
      // Startup has not reached step 5, so there is nowhere to write yet. The
      // choice still applies; it is simply not saved.
      state = state.copyWith(lastChangeUnsaved: true);
      return;
    }

    try {
      await write(settings);
    } on Object catch (error) {
      // Broad by intent: shared_preferences surfaces a PlatformException, a
      // full or read-only disk surfaces a FileSystemException, and the owner
      // needs the same sentence either way.
      _log.warning('a preference applied but could not be saved', error);
      state = state.copyWith(lastChangeUnsaved: true);
    }
  }
}
