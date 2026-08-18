import 'dart:ui';

import 'package:logging/logging.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../domain/window_geometry.dart';
import '../domain/window_placement.dart';

/// [WindowPlacement] over `window_manager` and `screen_retriever`
/// (Technology Stack Document §3.5).
///
/// The only file in the application that talks to either package. Everything
/// above it — the restore rule, the off-screen check — is plain logic in the
/// domain and application layers, tested without a desktop window in sight.
class DesktopWindowPlacement implements WindowPlacement {
  /// Creates a placement over the running window.
  const DesktopWindowPlacement();

  static final Logger _log = Logger('shell');

  @override
  Future<void> applyMinimumSize(Size size) =>
      windowManager.setMinimumSize(size);

  @override
  Future<List<Rect>> visibleDisplayBounds() async {
    try {
      final displays = await screenRetriever.getAllDisplays();
      return [
        for (final display in displays)
          (display.visiblePosition ?? Offset.zero) &
              (display.visibleSize ?? display.size),
      ];
    } on Object catch (error) {
      // Broad by intent: this crosses a platform channel, and every way it can
      // fail means the same thing here — the displays are unknown, so stored
      // geometry cannot be shown to land on one, so the launch falls back to
      // the default (UC-38 AF-02). An unreadable display list must never stop
      // the window opening.
      _log.warning('the attached displays could not be read', error);
      return const [];
    }
  }

  @override
  Future<WindowGeometry?> currentGeometry() async {
    try {
      final bounds = await windowManager.getBounds();
      return WindowGeometry(
        left: bounds.left,
        top: bounds.top,
        width: bounds.width,
        height: bounds.height,
      );
    } on Object catch (error) {
      _log.warning('the window bounds could not be read', error);
      return null;
    }
  }

  @override
  Future<void> applyGeometry(WindowGeometry geometry) =>
      windowManager.setBounds(geometry.bounds);

  @override
  Future<void> applyDefaultSize(Size size) async {
    await windowManager.setSize(size);
    await windowManager.center();
  }

  @override
  Future<void> show() async {
    await windowManager.show();
    await windowManager.focus();
  }
}
