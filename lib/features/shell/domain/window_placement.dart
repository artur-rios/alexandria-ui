import 'dart:ui';

import 'window_geometry.dart';

/// The window itself, as the application is allowed to see it (FR-UX-03).
///
/// An interface here rather than a call to `window_manager` from a controller,
/// for the reason every outward dependency gets one: the restore rule in
/// UC-38 AF-01 and AF-02 is logic worth testing, and it cannot be tested
/// against a real desktop window. The implementation over `window_manager` and
/// `screen_retriever` lives in the data layer.
abstract interface class WindowPlacement {
  /// Holds the window at [size] or larger, whatever the owner drags
  /// (UC-38 AF-01, NFR-07).
  Future<void> applyMinimumSize(Size size);

  /// The bounds of every attached display, in logical pixels.
  ///
  /// Empty when they cannot be read, which [WindowGeometry.isVisibleOn] then
  /// treats as "this geometry is not restorable" — the same fallback an
  /// unplugged display produces.
  Future<List<Rect>> visibleDisplayBounds();

  /// The window's current bounds, or `null` when they cannot be read.
  Future<WindowGeometry?> currentGeometry();

  /// Moves and resizes the window to [geometry].
  Future<void> applyGeometry(WindowGeometry geometry);

  /// Sizes the window to [size] and centres it on the primary display.
  Future<void> applyDefaultSize(Size size);

  /// Shows the window, once its geometry has been settled.
  ///
  /// Separated from applying the geometry so the window is never painted at
  /// the wrong size first: it is created hidden, placed, and only then shown.
  Future<void> show();
}
