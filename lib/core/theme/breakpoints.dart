import 'package:flutter/widgets.dart';

/// The width thresholds at which the shell changes layout (IR-10, FR-UX-02).
///
/// The floor is fixed by NFR-07: the application stays fully usable at
/// 1024 × 640 logical pixels, with no control clipped or unreachable. There is
/// consequently no phone-sized tier — the narrowest tier *is* the minimum
/// supported window, and the navigation panel collapses there rather than
/// anything being hidden.
enum Breakpoint {
  /// 1024 up to 1279: the minimum supported window. The navigation panel is a
  /// rail of icons.
  compact,

  /// 1280 up to 1599: the navigation panel is labelled.
  medium,

  /// 1600 and wider: the panel is labelled and the content area may show a
  /// secondary pane.
  expanded;

  /// The narrowest window the application supports, in logical pixels (NFR-07).
  static const Size minimumWindowSize = Size(1024, 640);

  /// The width at or above which [Breakpoint.medium] applies.
  static const double mediumMinWidth = 1280;

  /// The width at or above which [Breakpoint.expanded] applies.
  static const double expandedMinWidth = 1600;

  /// The tier a window of [width] logical pixels falls into.
  ///
  /// A width below the minimum still resolves to [Breakpoint.compact]: the
  /// window manager holds the window at the minimum (UC-38 AF-01), and a layout
  /// that threw or fell through here would turn a resize into a crash.
  static Breakpoint of(double width) {
    if (width >= expandedMinWidth) return Breakpoint.expanded;
    if (width >= mediumMinWidth) return Breakpoint.medium;
    return Breakpoint.compact;
  }

  /// The tier the nearest enclosing [MediaQuery] falls into.
  static Breakpoint from(BuildContext context) =>
      of(MediaQuery.sizeOf(context).width);

  /// Whether the navigation panel shows labels alongside its icons.
  bool get showsNavigationLabels => this != Breakpoint.compact;
}
