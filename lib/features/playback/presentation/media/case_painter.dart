import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/album_palette.dart';
import '../../domain/album_medium.dart';


/// The face the sleeve is typeset in, bundled with the application
/// (`pubspec.yaml`'s `fonts:` block).
///
/// Every `TextStyle` on the case names it. A `TextPainter` does not inherit
/// from a `Theme` — it carries the style it is given — so leaving the family
/// null does not fall back to the application's typeface, it falls back to
/// the host's, which is a different face on each platform and is what made
/// these goldens fail on Linux while passing on the machine that made them.
///
/// The name is this application's, not the typeface's: the files are Roboto,
/// but a bundled family actually *called* Roboto is what Material's default
/// typography resolves to, so it would restyle every screen in the
/// application rather than this one drawing.
const String _sleeveFontFamily = 'AlexandriaSleeve';

/// The case the medium comes out of and goes back into (UC-21, FR-PL-07).
///
/// One painter for all three shapes rather than three, because the shape is
/// the only thing that changes by medium — the fill, the lit edge, the drop
/// shadow and the typeset title and artist are drawn the same way regardless
/// of which case they sit on.
class CasePainter extends CustomPainter {
  /// Creates the painter.
  const CasePainter({
    required this.palette,
    required this.medium,
    required this.sleeve,
    required this.title,
    required this.artist,
    required this.direction,
    this.cover,
  });

  /// The artwork's colours (FR-UX-07) — used here for the lit edge and the
  /// drop shadow; the jacket's own face colour is [sleeve] when there is no
  /// [cover] to draw instead.
  final AlbumPalette palette;

  /// Which case shape to draw.
  final AlbumMedium medium;

  /// The jacket's face colour, picked by `sleeveIndexFor` from
  /// [AlbumPalette.sleeveHues] — the designed jacket's fill, used whenever
  /// [cover] is `null` (design section 4: no picture embedded, the fetch
  /// failing, or it simply not having arrived yet, are all this case).
  final Color sleeve;

  /// The album title, wrapped over up to two lines.
  final String title;

  /// The artist, on one line beneath the title.
  final String artist;

  /// The text direction the title and artist are laid out in, taken from
  /// the caller rather than assumed, so a right-to-left album title reads
  /// correctly on the jacket.
  final TextDirection direction;

  /// The album's own embedded picture, decoded and ready to paint — drawn
  /// over the whole sleeve, cropped to fill it, in place of [sleeve]'s flat
  /// colour. `null` draws the designed jacket, which is this case's normal
  /// fallback rather than an error state (design section 4).
  ///
  /// Ownership of the image stays with whoever passed it in — this painter
  /// only ever reads it, never disposes it, because the same instance is
  /// handed to a fresh [CasePainter] on every repaint for as long as the
  /// album it belongs to keeps playing.
  final ui.Image? cover;

  /// The case's own aspect ratio, by medium — a jacket is square, a
  /// cassette case is taller than it is wide, and a jewel case is a little
  /// taller than it is wide with room for its spine.
  static double aspectFor(AlbumMedium medium) => switch (medium) {
    AlbumMedium.vinyl => 1,
    AlbumMedium.tape => 0.66,
    AlbumMedium.disc => 0.90,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final margin = w * 0.04;
    final bounds = Rect.fromLTWH(margin, margin, w - margin * 2, h - margin * 2);

    _paintShadow(canvas, bounds);

    switch (medium) {
      case AlbumMedium.disc:
        _paintJewelCase(canvas, bounds);
      case AlbumMedium.tape:
        _paintCassetteCase(canvas, bounds);
      case AlbumMedium.vinyl:
        _paintJacket(canvas, bounds);
    }

    // The embedded cover and the designed jacket are alternatives, not a
    // base plus an overlay (design section 4): the typeset title and artist
    // exist only because the designed jacket has nothing else on it to say
    // what it is. A real cover already carries its own lettering, and
    // `palette.sleeveInk` was picked to read against the *derived* sleeve
    // hues, not an arbitrary photograph — printing it over a light or busy
    // cover would as often as not be illegible.
    if (cover == null) _paintText(canvas, bounds);
  }

  void _paintShadow(Canvas canvas, Rect bounds) {
    final shadowRect = bounds.shift(Offset(bounds.width * 0.03, bounds.height * 0.04));
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, Radius.circular(bounds.width * 0.02)),
      Paint()
        ..color = palette.contactShadow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, bounds.width * 0.02),
    );
  }

  void _paintJacket(Canvas canvas, Rect bounds) {
    _paintFace(canvas, RRect.fromRectAndRadius(bounds, Radius.circular(bounds.width * 0.015)));
  }

  void _paintCassetteCase(Canvas canvas, Rect bounds) {
    _paintFace(canvas, RRect.fromRectAndRadius(bounds, Radius.circular(bounds.width * 0.03)));
  }

  void _paintJewelCase(Canvas canvas, Rect bounds) {
    final spineWidth = bounds.width * 0.10;
    final caseRect = Rect.fromLTWH(
      bounds.left + spineWidth,
      bounds.top,
      bounds.width - spineWidth,
      bounds.height,
    );
    _paintFace(canvas, RRect.fromRectAndRadius(caseRect, Radius.circular(bounds.width * 0.01)));

    // The hinge spine: a narrower, darker strip along the case's left edge
    // — the ribbed hinge a jewel case shows side-on — kept unhued so it
    // reads as clear plastic over the booklet rather than as a second
    // sleeve colour.
    final spineRect = Rect.fromLTWH(bounds.left, bounds.top, spineWidth, bounds.height);
    canvas.drawRect(
      spineRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [palette.panelDark, palette.panelEdge, palette.panelDark],
        ).createShader(spineRect),
    );
    final rib = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = spineWidth * 0.06
      ..color = palette.chromeDark.withValues(alpha: 0.5);
    for (var i = 1; i < 6; i++) {
      final y = bounds.top + bounds.height * i / 6;
      canvas.drawLine(Offset(spineRect.left, y), Offset(spineRect.right, y), rib);
    }
  }

  /// The fill, lit top edge and outline shared by every case shape.
  void _paintFace(Canvas canvas, RRect shape) {
    final cover = this.cover;
    if (cover == null) {
      canvas.drawRRect(shape, Paint()..color = sleeve);
    } else {
      // Cropped to fill the sleeve — the same `BoxFit.cover` behaviour an
      // `Image` widget would give a picture whose own aspect ratio rarely
      // matches the case it is going on.
      canvas.save();
      canvas.clipRRect(shape);
      paintImage(canvas: canvas, rect: shape.outerRect, image: cover, fit: BoxFit.cover);
      canvas.restore();
    }

    canvas.drawRRect(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.sleeveInk.withValues(alpha: 0.16),
            palette.sleeveInk.withValues(alpha: 0),
          ],
          stops: const [0, 0.18],
        ).createShader(shape.outerRect),
    );

    canvas.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = shape.width * 0.006
        ..color = palette.panelEdge.withValues(alpha: 0.7),
    );
  }

  void _paintText(Canvas canvas, Rect bounds) {
    final textLeft = medium == AlbumMedium.disc
        ? bounds.left + bounds.width * 0.10 + bounds.width * 0.10
        : bounds.left + bounds.width * 0.10;
    final textWidth = bounds.right - bounds.width * 0.10 - textLeft;
    final textTop = bounds.top + bounds.height * 0.60;

    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          // Named, not inherited. A `TextPainter` builds its own style, so
          // a null family here is not "the app's font" — it is whatever the
          // host offers, which typeset this sleeve in a different face on
          // Windows than on Linux and made the goldens un-comparable
          // between them. See the `fonts:` block in `pubspec.yaml`.
          fontFamily: _sleeveFontFamily,
          color: palette.sleeveInk,
          fontSize: bounds.width * 0.09,
          fontWeight: FontWeight.w600,
          height: 1.15,
        ),
      ),
      textDirection: direction,
      textAlign: TextAlign.start,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: textWidth);
    titlePainter.paint(canvas, Offset(textLeft, textTop));

    final ruleY = textTop + titlePainter.height + bounds.height * 0.03;
    canvas.drawLine(
      Offset(textLeft, ruleY),
      Offset(textLeft + textWidth, ruleY),
      Paint()
        ..strokeWidth = bounds.height * 0.006
        ..color = palette.sleeveInk.withValues(alpha: 0.4),
    );

    final artistPainter = TextPainter(
      text: TextSpan(
        text: artist,
        style: TextStyle(
          fontFamily: _sleeveFontFamily,
          color: palette.sleeveInk.withValues(alpha: 0.85),
          fontSize: bounds.width * 0.07,
        ),
      ),
      textDirection: direction,
      textAlign: TextAlign.start,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: textWidth);
    artistPainter.paint(canvas, Offset(textLeft, ruleY + bounds.height * 0.03));
  }

  @override
  bool shouldRepaint(CasePainter oldDelegate) =>
      oldDelegate.palette != palette ||
      oldDelegate.medium != medium ||
      oldDelegate.sleeve != sleeve ||
      oldDelegate.title != title ||
      oldDelegate.artist != artist ||
      oldDelegate.direction != direction ||
      // Identity, not `==`: `ui.Image` has none of its own, and a cover
      // that arrived since the last frame is a different instance from
      // `null`, which is exactly the swap this has to catch.
      !identical(oldDelegate.cover, cover);
}
