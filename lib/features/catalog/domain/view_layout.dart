import '../../../core/theme/breakpoints.dart';

/// How a listing is drawn (FR-CT-03).
enum ViewLayout {
  /// One line per file: its name, and nothing else.
  list,

  /// A line per file with its path and details alongside.
  detailedList,

  /// Tiles in a grid.
  grid;

  /// The layout [name] names, or `null` when it names none.
  ///
  /// Used to read a stored choice back, where an unrecognized value means the
  /// owner's preference is simply unknown and the default applies.
  static ViewLayout? byName(String? name) {
    for (final layout in ViewLayout.values) {
      if (layout.name == name) return layout;
    }
    return null;
  }

  /// The narrowest window this layout is drawn in, in logical pixels.
  ///
  /// Only the detailed list has a floor above the minimum supported window:
  /// it puts a second column of detail beside each name, and below the medium
  /// tier that column has nowhere to go but on top of the name. A plain list
  /// and a grid of tiles both work at 1024 (NFR-07).
  double get minimumWidth => switch (this) {
    ViewLayout.list || ViewLayout.grid => Breakpoint.minimumWindowSize.width,
    ViewLayout.detailedList => Breakpoint.mediumMinWidth,
  };

  /// Whether this layout is drawn at [width] logical pixels.
  bool fitsIn(double width) => width >= minimumWidth;

  /// The layout actually drawn at [width] (UC-10 AF-01).
  ///
  /// The closest that fits, not the default: an owner who chose the detailed
  /// list on a wide window and then narrowed it wants the list, which is the
  /// same layout without the column that stopped fitting — not a grid, which
  /// is a different way of reading entirely.
  ViewLayout resolvedFor(double width) =>
      fitsIn(width) ? this : ViewLayout.list;

  /// Whether [width] forces a layout other than this one.
  bool isSubstitutedAt(double width) => resolvedFor(width) != this;
}
