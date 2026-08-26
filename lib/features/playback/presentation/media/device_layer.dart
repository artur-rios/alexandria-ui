/// Which pass of a device painter to draw (UC-21, FR-PL-07).
///
/// Every device — the turntable, the tape deck, the CD player — has a part
/// that has to sit in front of the medium the stage lays over it: the
/// tonearm has to be seen touching the record, the deck's door has to be
/// seen sliding down over the cassette, the player's lid has to be seen
/// closing over the disc. A single painter can only ever be one layer in a
/// `Stack`, so each device painter is split into two passes instead — the
/// stage paints [chassis] first, the medium above it, then [foreground] over
/// that — rather than drawing everything in one pass and leaving the
/// moving part buried under the very thing it is supposed to hold onto.
enum DeviceLayer {
  /// Everything that sits still and behind the medium: the body, the well
  /// or platter, the controls and the display.
  chassis,

  /// The part that has to be seen in front of the medium: the tonearm, the
  /// deck's door, the player's lid.
  foreground,
}
