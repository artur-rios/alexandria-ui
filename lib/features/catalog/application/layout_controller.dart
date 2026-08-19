import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/di/providers.dart';
import '../../../core/settings/settings_store.dart';
import '../../../core/startup/startup_state.dart';
import '../domain/library_type.dart';
import '../domain/view_layout.dart';

/// The layout chosen for each file type (UC-10, FR-CT-03, FR-CT-04).
///
/// Per type, not per application: an owner who reads their notes as a list and
/// their images as a grid is expressing two preferences, and a single setting
/// would make them fight each other.
class LayoutController extends Notifier<LayoutState> {
  static final Logger _log = Logger('catalog');

  /// The settings key the choices are stored under.
  ///
  /// `layoutByType` is the name System Requirements §4.11 gives it.
  static const String settingsKey = 'layoutByType';

  @override
  LayoutState build() {
    // Watched, not read: the settings store does not exist until startup step
    // 5, and the stored choices have to be picked up when it does.
    final startup = ref.watch(startupControllerProvider);
    if (startup is! StartupReady) return const LayoutState();

    return LayoutState(byType: _read());
  }

  SettingsStore? get _settings =>
      ref.read(startupControllerProvider.notifier).settings;

  Map<LibraryType, ViewLayout> _read() {
    final stored = _settings?.getString(settingsKey);
    if (stored == null) return const {};

    try {
      final decoded = jsonDecode(stored) as Map<String, dynamic>;
      final byType = <LibraryType, ViewLayout>{};
      for (final entry in decoded.entries) {
        final type = LibraryType.fromWire(entry.key);
        final layout = ViewLayout.byName(entry.value as String?);
        // A type or a layout this application does not know is skipped rather
        // than defaulted: the entry was written by some other version, and
        // guessing what it meant is worse than falling back to the default.
        if (type != null && layout != null) byType[type] = layout;
      }
      return byType;
    } on Object catch (error) {
      // Broad by intent: a hand-edited settings file must not stop a listing
      // rendering, and the default layout is a perfectly good answer.
      _log.warning('the stored layouts could not be read', error);
      return const {};
    }
  }

  /// Applies [layout] to [type] and records it (main flow steps 1–3).
  Future<void> choose(LibraryType type, ViewLayout layout) async {
    final byType = {...state.byType, type: layout};
    state = state.copyWith(byType: byType, lastChangeUnsaved: false);

    final settings = _settings;
    if (settings == null) {
      state = state.copyWith(lastChangeUnsaved: true);
      return;
    }

    try {
      await settings.setString(
        settingsKey,
        jsonEncode({
          for (final entry in byType.entries)
            entry.key.wireName: entry.value.name,
        }),
      );
    } on Object catch (error) {
      // AF-02: the layout still changed for this session. What must not happen
      // is the owner believing it will be there next time.
      _log.warning('a layout applied but could not be saved', error);
      state = state.copyWith(lastChangeUnsaved: true);
    }
  }

  /// Clears the unsaved notice once the owner has seen it.
  void acknowledgeUnsaved() {
    if (!state.lastChangeUnsaved) return;
    state = state.copyWith(lastChangeUnsaved: false);
  }
}

/// The layout each type is drawn in, and whether the last change was saved.
class LayoutState {
  /// Creates a state.
  const LayoutState({this.byType = const {}, this.lastChangeUnsaved = false});

  /// The layout chosen per type. A type with no entry uses [defaultLayout].
  final Map<LibraryType, ViewLayout> byType;

  /// Whether the last choice applied but could not be stored (AF-02).
  final bool lastChangeUnsaved;

  /// What a type is drawn in before the owner has chosen anything.
  ///
  /// The plain list: it is the one layout that fits every supported window,
  /// so the default is never itself a substitution.
  static const ViewLayout defaultLayout = ViewLayout.list;

  /// The layout [type] was chosen to be drawn in.
  ViewLayout chosenFor(LibraryType type) => byType[type] ?? defaultLayout;

  /// A copy with the given changes.
  LayoutState copyWith({
    Map<LibraryType, ViewLayout>? byType,
    bool? lastChangeUnsaved,
  }) => LayoutState(
    byType: byType ?? this.byType,
    lastChangeUnsaved: lastChangeUnsaved ?? this.lastChangeUnsaved,
  );
}
