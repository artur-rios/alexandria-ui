import 'dart:ui';

import 'package:logging/logging.dart';

import '../../../core/settings/settings_store.dart';
import '../domain/window_geometry.dart';
import '../domain/window_placement.dart';

/// Restores the window at launch and records it at close (FR-UX-03).
///
/// Not a `Notifier`: nothing on screen depends on where the window is, and a
/// provider that rebuilt widgets every time the owner dragged the window would
/// be a rebuild storm in exchange for nothing. It is a plain collaborator the
/// bootstrap drives.
class WindowGeometryController {
  /// Creates a controller over [placement] and [settings].
  const WindowGeometryController({
    required WindowPlacement placement,
    required SettingsStore settings,
  })
    // The fields are private and a named parameter cannot be, so
    // `this._placement` is not expressible. Same reason as
    // test/support/in_memory_settings_store.dart.
    // ignore: prefer_initializing_formals
    : _placement = placement,
       // ignore: prefer_initializing_formals
       _settings = settings;

  static final Logger _log = Logger('shell');

  /// The settings key the geometry is stored under.
  static const String settingsKey = 'shell.windowGeometry';

  final WindowPlacement _placement;
  final SettingsStore _settings;

  /// Enforces the minimum size, places the window, and shows it.
  ///
  /// The order matters: the minimum is applied before the geometry, so a
  /// stored size smaller than the minimum — a settings file carried over from
  /// a build with a smaller floor — is raised rather than honoured (AF-01).
  ///
  /// A stored geometry that no longer lands on a display is discarded in
  /// favour of [defaultSize] centred on the primary display (AF-02). So is one
  /// that will not parse, and so is the case where the displays cannot be read
  /// at all: every one of them leaves the owner with a window they can see,
  /// which is the only outcome that matters here.
  Future<void> restore({
    required Size minimumSize,
    required Size defaultSize,
  }) async {
    await _placement.applyMinimumSize(minimumSize);

    final stored = WindowGeometry.decode(_settings.getString(settingsKey));
    if (stored == null) {
      await _placement.applyDefaultSize(defaultSize);
      await _placement.show();
      return;
    }

    final displays = await _placement.visibleDisplayBounds();
    if (!stored.isVisibleOn(displays)) {
      _log.info('stored window geometry is off-screen; opening at the default');
      await _placement.applyDefaultSize(defaultSize);
      await _placement.show();
      return;
    }

    await _placement.applyGeometry(stored);
    await _placement.show();
  }

  /// Records where the window is, so the next launch opens there.
  ///
  /// A window whose bounds cannot be read writes nothing rather than writing a
  /// guess: the previous geometry is a better answer than a wrong one.
  Future<void> record() async {
    final current = await _placement.currentGeometry();
    if (current == null) return;

    await _settings.setString(settingsKey, current.encode());
  }
}
