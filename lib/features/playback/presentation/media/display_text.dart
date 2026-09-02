import 'package:flutter/material.dart';

import 'device_lettering.dart';

/// Lights a line of type inside [bounds] (FR-PL-12).
///
/// Sized to the row it is given and shrunk to a floor before it is ever cut:
/// a track title is as long as it happens to be, and the screens these are
/// drawn on are as wide as the machine's fascia. `Many Men (Wish De…` is what
/// a fixed size gives for a perfectly ordinary title, which is the defect the
/// nameplate before this one was rebuilt around.
///
/// [alignEnd] puts the line against the right edge instead of the left, which
/// is where every one of these machines prints the track number and the time.
void paintFittedText(
  Canvas canvas, {
  required Rect bounds,
  required String text,
  required Color colour,
  bool alignEnd = false,
}) {
  if (text.trim().isEmpty) return;

  /// The same lettering at whatever size, in the bundled face — for the
  /// reason [deviceFontFamily] records: a screen that let the host choose
  /// would break a title at a different word on each platform.
  TextPainter lettering(double size, {double? maxWidth}) => TextPainter(
    text: TextSpan(
      text: text.trim(),
      style: TextStyle(
        color: colour,
        fontSize: size,
        fontFamily: deviceFontFamily,
        // Digits that do not shuffle as the seconds tick: the line is
        // rewritten every second, and proportional figures would make the
        // whole of it twitch each time a 1 became a 2.
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: size * 0.06,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth ?? double.infinity);

  const floor = 0.6;
  const step = 0.96;
  final nominal = bounds.height * 0.86;
  var size = nominal;
  final natural = lettering(size).width;
  if (natural > bounds.width) size = nominal * (bounds.width / natural);
  while (size > nominal * floor && lettering(size).width > bounds.width) {
    size *= step;
  }
  size = size.clamp(nominal * floor, nominal);

  final lit = lettering(size, maxWidth: bounds.width);
  lit.paint(
    canvas,
    Offset(
      alignEnd ? bounds.right - lit.width : bounds.left,
      bounds.center.dy - lit.height / 2,
    ),
  );
}
