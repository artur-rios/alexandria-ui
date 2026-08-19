import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'window_geometry.freezed.dart';

/// Where the window was when the application last closed (FR-UX-03).
///
/// Recorded in the local settings store and restored at the next launch. It is
/// the one piece of window state the application persists; everything else
/// about the window belongs to the window manager.
@freezed
sealed class WindowGeometry with _$WindowGeometry {
  /// Creates a geometry.
  const factory WindowGeometry({
    required double left,
    required double top,
    required double width,
    required double height,
  }) = _WindowGeometry;

  const WindowGeometry._();

  /// The rectangle this geometry describes, in logical pixels.
  Rect get bounds => Rect.fromLTWH(left, top, width, height);

  /// Whether this geometry can still be applied given the [displays] currently
  /// attached (UC-38 AF-02).
  ///
  /// The test is on the window's origin rather than on any overlap: a window
  /// whose top-left corner sits on a display is one the owner can see and
  /// grab, and the window manager clamps whatever hangs off the far edge. A
  /// window whose origin lands nowhere — because the position was saved on a
  /// second display that has since been unplugged, or because the arrangement
  /// changed — is unreachable, and the launch falls back to the default size
  /// on the primary display instead.
  bool isVisibleOn(List<Rect> displays) =>
      displays.any((display) => display.contains(Offset(left, top)));

  /// This geometry as the single string the settings store holds.
  ///
  /// A flat `left,top,width,height` rather than JSON: it is four numbers with a
  /// fixed order, and the store's value is read by nothing but [decode].
  String encode() => '$left,$top,$width,$height';

  /// The geometry [value] encodes, or `null` when there is none to restore.
  ///
  /// `null` covers every unreadable case — absent, the wrong number of parts,
  /// a part that is not a number, or a non-positive size. All of them mean the
  /// same thing to the caller: open at the default size (AF-02). A settings
  /// file edited by hand must not stop the application launching.
  static WindowGeometry? decode(String? value) {
    if (value == null) return null;

    final parts = value.split(',');
    if (parts.length != 4) return null;

    final numbers = <double>[];
    for (final part in parts) {
      final parsed = double.tryParse(part);
      if (parsed == null || !parsed.isFinite) return null;
      numbers.add(parsed);
    }

    if (numbers[2] <= 0 || numbers[3] <= 0) return null;

    return WindowGeometry(
      left: numbers[0],
      top: numbers[1],
      width: numbers[2],
      height: numbers[3],
    );
  }
}
