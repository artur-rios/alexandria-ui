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
/// destroy call is unconditional — a settings store that refuses to write must
/// not leave the owner with a window they cannot close.
class WindowCloseRecorder with WindowListener {
  /// Creates a recorder driving [controller].
  WindowCloseRecorder(this._controller);

  final WindowGeometryController _controller;

  /// Starts intercepting the close.
  Future<void> attach() async {
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
  }

  @override
  Future<void> onWindowClose() async {
    try {
      await _controller.record();
    } finally {
      await windowManager.destroy();
    }
  }
}
