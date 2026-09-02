import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/bindings/core_environment.dart';
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
      opensPlayerOnPlay: settings?.opensPlayerOnPlay ?? true,
      rechecksAtStartup: settings?.rechecksAtStartup ?? true,
      musicLookupEnabled: settings?.musicLookupEnabled ?? true,
      musicLookupContact:
          settings?.musicLookupContact ?? defaultMusicLookupContact,
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

  /// Applies [value] now and records it for the next launch (FR-PL-11).
  ///
  /// What the album-animation choice used to be. That preference picked which
  /// medium the animation showed — a record, a tape or a disc — and the
  /// animation is gone: what is left of the choice is the half of it that was
  /// about behaviour rather than decoration, which is whether starting a
  /// track puts the player on screen.
  Future<void> setOpensPlayerOnPlay(bool value) async {
    state = state.copyWith(opensPlayerOnPlay: value, lastChangeUnsaved: false);
    await _persist((settings) => settings.setOpensPlayerOnPlay(value));
  }

  /// Applies [value] now and records it for the next launch (FR-LB-21).
  Future<void> setRechecksAtStartup(bool value) async {
    state = state.copyWith(rechecksAtStartup: value, lastChangeUnsaved: false);
    await _persist((settings) => settings.setRechecksAtStartup(value));
  }

  /// Applies [value] now and records it for the next launch (music
  /// enrichment design).
  ///
  /// "Now" is two things, and both are needed. The interface stops offering
  /// lookups the moment this turns false, which is what the owner asked
  /// for; and the core is reconfigured behind it, because the core reads
  /// this setting once at initialization and would otherwise keep answering
  /// "switched off for this installation" to a switch the owner has just
  /// turned on.
  Future<void> setMusicLookupEnabled(bool value) async {
    state = state.copyWith(musicLookupEnabled: value, lastChangeUnsaved: false);
    await _persist((settings) => settings.setMusicLookupEnabled(value));
    await _applyToCore();
  }

  /// Records the contact the lookup services are given, and reconfigures the
  /// core with it.
  ///
  /// An empty [contact] returns the application's own, which is what the
  /// settings store answers for a cleared preference — the state is set from
  /// the store rather than from the argument so the field cannot show blank
  /// while the core is using something else.
  Future<void> setMusicLookupContact(String contact) async {
    state = state.copyWith(
      musicLookupContact: _contactOrDefault(contact),
      lastChangeUnsaved: false,
    );
    await _persist((settings) => settings.setMusicLookupContact(contact));
    await _applyToCore();
  }

  /// The contact a store that could not be written would have answered.
  String _contactOrDefault(String contact) =>
      contact.trim().isEmpty ? defaultMusicLookupContact : contact.trim();

  /// Hands the core the music-lookup configuration now stored.
  ///
  /// Does nothing before startup has a core to reconfigure, and nothing when
  /// the configuration has not actually changed — see
  /// `StartupController.applyMusicLookup`.
  Future<void> _applyToCore() =>
      ref.read(startupControllerProvider.notifier).applyMusicLookup();

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
