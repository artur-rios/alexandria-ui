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

  /// The narrowest **listing** this layout is drawn in, in logical pixels.
  ///
  /// The listing, not the window: the navigation panel, the divider, and the
  /// screen padding come off the window's width before the rows are laid out,
  /// which is around two hundred pixels at every tier. A floor compared
  /// against the window would refuse this layout on windows where it fits and
  /// accept it on windows where it does not.
  ///
  /// Only the detailed list has a floor above zero. It puts a second column of
  /// detail beside each name, and a name and a path sharing less than this
  /// leave both ellipsized to the point of being unreadable — at which point
  /// the plain list says more. A listing narrower than the minimum supported
  /// window's own (NFR-07) still draws the list and the grid.
  double get minimumListingWidth => switch (this) {
    ViewLayout.list || ViewLayout.grid => 0,
    ViewLayout.detailedList => 900,
  };

  /// Whether this layout is drawn in a listing [width] logical pixels wide.
  bool fitsIn(double width) => width >= minimumListingWidth;

  /// The layout actually drawn in a listing [width] wide (UC-10 AF-01).
  ///
  /// The closest that fits, not the default: an owner who chose the detailed
  /// list on a wide window and then narrowed it wants the list, which is the
  /// same layout without the column that stopped fitting — not a grid, which
  /// is a different way of reading entirely.
  ViewLayout resolvedFor(double width) =>
      fitsIn(width) ? this : ViewLayout.list;

  /// Whether a listing [width] wide forces a layout other than this one.
  bool isSubstitutedAt(double width) => resolvedFor(width) != this;
}
