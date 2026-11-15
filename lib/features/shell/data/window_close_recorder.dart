import 'dart:io';

import 'package:logging/logging.dart';
import 'package:window_manager/window_manager.dart';

import '../application/window_geometry_controller.dart';

/// Records the window's geometry when the owner closes the application
/// (UC-38 main flow step 6, FR-UX-03).
///
/// The close is intercepted rather than the geometry being written on every
/// move: dragging a window emits a stream of positions, and persisting each
/// one would write to the settings store dozens of times a second to record
/// something only the last value of which is ever read.
///
/// Intercepting means the window will not close until this lets it, so the
/// close that follows the recording is unconditional — a settings store that
/// refuses to write must not leave the owner with a window they cannot close.
class WindowCloseRecorder {
  /// Creates a recorder driving [controller].
  WindowCloseRecorder(this._controller);

  static final Logger _log = Logger('shell');

  final WindowGeometryController _controller;

  Window? _window;

  /// Set while the close this recorder asked for is on its way, so its own
  /// request is let through rather than intercepted again.
  bool _closing = false;

  /// Starts intercepting the close.
  Future<void> attach() async {
    final window = WindowManager.instance.getCurrent();
    if (window == null) {
      _log.warning('no window to record the geometry of on close');
      return;
    }
    _window = window;
    window.addListener(_onWindowEvent);
  }

  Future<void> _onWindowEvent(WindowEvent event) async {
    if (event is! WindowCloseRequestedEvent) return;
    if (_closing) {
      _closing = false;
      return;
    }

    // Before anything is awaited: the request is answered from here, and an
    // answer given after the first await would come too late to hold the
    // window open while the geometry is read.
    event.request.cancel();
    try {
      await _controller.record();
    } finally {
      _close();
    }
  }

  void _close() {
    final window = _window;
    _closing = true;
    if (window != null && window.close()) return;

    // The native close refused, which leaves a window that ignores its own
    // close button. Ending the process is the honest fallback: the geometry has
    // been recorded, and nothing else is waiting on the window.
    _closing = false;
    _log.warning('the window would not close; exiting');
    exit(0);
  }
}
