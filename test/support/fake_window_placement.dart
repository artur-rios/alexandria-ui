import 'dart:ui';

import 'package:alexandria_ui/features/shell/domain/window_geometry.dart';
import 'package:alexandria_ui/features/shell/domain/window_placement.dart';

/// A [WindowPlacement] that records what it was asked to do
/// (Testing Specification §6.2).
///
/// A hand-written fake rather than a `mocktail` stub: restoring a window is a
/// sequence of calls, and the order of two of them is the point — the minimum
/// size is applied before any geometry, so a stored size below the floor is
/// raised rather than honoured (UC-38 AF-01).
class FakeWindowPlacement implements WindowPlacement {
  /// Creates a fake with one display at the origin, 1920 × 1080.
  FakeWindowPlacement({List<Rect>? displays, this.current})
    : displays = displays ?? const [Rect.fromLTWH(0, 0, 1920, 1080)];

  /// What [visibleDisplayBounds] answers. Empty models displays that cannot
  /// be read at all.
  List<Rect> displays;

  /// What [currentGeometry] answers. `null` models bounds that cannot be read.
  WindowGeometry? current;

  /// Every call made, in order, named by method.
  final List<String> calls = [];

  /// The minimum size applied, if any.
  Size? minimumSize;

  /// The geometry applied, if any.
  WindowGeometry? applied;

  /// The default size applied, if any.
  Size? defaultSize;

  /// Whether the window was shown.
  bool shown = false;

  @override
  Future<void> applyMinimumSize(Size size) async {
    calls.add('applyMinimumSize');
    minimumSize = size;
  }

  @override
  Future<List<Rect>> visibleDisplayBounds() async {
    calls.add('visibleDisplayBounds');
    return displays;
  }

  @override
  Future<WindowGeometry?> currentGeometry() async {
    calls.add('currentGeometry');
    return current;
  }

  @override
  Future<void> applyGeometry(WindowGeometry geometry) async {
    calls.add('applyGeometry');
    applied = geometry;
  }

  @override
  Future<void> applyDefaultSize(Size size) async {
    calls.add('applyDefaultSize');
    defaultSize = size;
  }

  @override
  Future<void> show() async {
    calls.add('show');
    shown = true;
  }
}
