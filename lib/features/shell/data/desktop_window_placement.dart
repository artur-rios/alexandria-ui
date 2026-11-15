import 'dart:ui';

import 'package:logging/logging.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../domain/window_geometry.dart';
import '../domain/window_placement.dart';

/// [WindowPlacement] over `window_manager` and `screen_retriever`
/// (Technology Stack Document §3.5).
///
/// The only file in the application that talks to either package, apart from
/// the close interception in `window_close_recorder.dart`. Everything above it
/// — the restore rule, the off-screen check — is plain logic in the domain and
/// application layers, tested without a desktop window in sight.
///
/// Both packages are bindings to the same native core (nativeapi): the calls
/// are synchronous and act on the native window directly, so nothing here
/// waits on a platform channel.
class DesktopWindowPlacement implements WindowPlacement {
  /// Creates a placement over the running window.
  DesktopWindowPlacement();

  static final Logger _log = Logger('shell');

  Window? _current;

  /// The application's window, resolved on first use and kept, because every
  /// lookup makes a new native wrapper. Null until the platform has a window,
  /// and the calls below then do nothing.
  Window? get _window => _current ??= WindowManager.instance.getCurrent();

  @override
  Future<void> applyMinimumSize(Size size) async {
    _window?.minimumSize = size.toNative();
  }

  @override
  Future<List<Rect>> visibleDisplayBounds() async {
    try {
      final displays = DisplayManager.instance.getAll();
      try {
        // The work area: the display minus its taskbar, menu bar or panels.
        return [for (final display in displays) display.workArea.toRect()];
      } finally {
        for (final display in displays) {
          display.dispose();
        }
      }
    } on Object catch (error) {
      // Broad by intent: this crosses into native code, and every way it can
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
      final window = _window;
      if (window == null) return null;
      final bounds = window.bounds.toRect();
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
  Future<void> applyGeometry(WindowGeometry geometry) async {
    _window?.bounds = geometry.bounds.toNative();
  }

  @override
  Future<void> applyDefaultSize(Size size) async {
    final window = _window;
    if (window == null) return;
    window.setSize(size.toNative(), false);
    _centre(window);
  }

  @override
  Future<void> show() async {
    final window = _window;
    if (window == null) return;
    if (window.isMinimized) window.restore();
    window.show();
    window.focus();
  }

  /// Centres [window] in the work area of the display the cursor is on, or of
  /// the primary display when the cursor is on none.
  ///
  /// What `windowManager.center()` did in window_manager 0.5, kept rather than
  /// taking the native `Window.center()`, which picks a different display on
  /// each platform (the primary monitor's full area on Linux, the window's own
  /// monitor on Windows).
  void _centre(Window window) {
    const displayManager = DisplayManager.instance;
    final displays = displayManager.getAll();
    try {
      final cursor = displayManager.getCursorPosition().toOffset();
      Display? target;
      for (final display in displays) {
        final bounds = display.position.toOffset() & display.size.toSize();
        if (bounds.contains(cursor)) {
          target = display;
          break;
        }
      }
      final primary = target == null ? displayManager.getPrimary() : null;
      try {
        final workArea = (target ?? primary)?.workArea.toRect();
        if (workArea == null) return;
        final size = window.size.toSize();
        window.position = Offset(
          workArea.left + (workArea.width - size.width) / 2,
          workArea.top + (workArea.height - size.height) / 2,
        ).toNative();
      } finally {
        primary?.dispose();
      }
    } finally {
      for (final display in displays) {
        display.dispose();
      }
    }
  }
}
