import 'dart:ui' as ui;

import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/features/playback/presentation/media/vinyl_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../flutter_test_config.dart';

/// The record, painted (UC-21, FR-PL-07).
void main() {
  Widget painted(CustomPainter painter, Size size) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: RepaintBoundary(
        child: CustomPaint(size: size, painter: painter),
      ),
    ),
  );

  const palette = AlbumPalette.standard;

  testWidgets(
    'GivenTheVinylPainter_WhenItIsDrawn_ThenItMatchesItsGolden',
    (tester) async {
      await tester.pumpWidget(
        painted(
          const VinylPainter(palette: palette, turns: 0),
          const Size(240, 240),
        ),
      );

      await expectLater(
        find.byType(CustomPaint).last,
        matchesGoldenFile('goldens/vinyl.png'),
      );
    },
    skip: !goldensAreComparable,
  );

  testWidgets(
    'GivenACover_WhenTheRecordIsDrawn_ThenItIsPrintedOnTheLabel',
    (tester) async {
      // Where a record carries its art. The case shows it too, but the case
      // is a beat of the insertion and then gone — the label is what stays
      // on screen for the rest of the album, and it used to be the same
      // drawing whatever was playing.
      final cover = await _aCover();
      addTearDown(cover.dispose);

      await tester.pumpWidget(
        painted(
          VinylPainter(palette: palette, turns: 0, cover: cover),
          const Size(240, 240),
        ),
      );

      await expectLater(
        find.byType(CustomPaint).last,
        matchesGoldenFile('goldens/vinyl-cover.png'),
      );
    },
    skip: !goldensAreComparable,
  );

  test('GivenAPainter_WhenTheCoverChanges_ThenItRepaints', () async {
    // Identity, not equality: `ui.Image` has none of its own, so a painter
    // comparing with `==` would report "no change" for a different picture.
    final first = await _aCover();
    addTearDown(first.dispose);
    final second = await _aCover();
    addTearDown(second.dispose);

    expect(
      VinylPainter(
        palette: palette,
        turns: 0,
        cover: second,
      ).shouldRepaint(VinylPainter(palette: palette, turns: 0, cover: first)),
      isTrue,
    );
  });

  group('what turning means', () {
    test('GivenAPainter_WhenOnlyItsTurnsChange_ThenItRepaints', () {
      // A painter that reported "no change" for a new angle would draw one
      // frame and then sit still while the controller ticked.
      const first = VinylPainter(palette: palette, turns: 0);
      const second = VinylPainter(palette: palette, turns: 0.25);

      expect(second.shouldRepaint(first), isTrue);
    });

    test('GivenAPainter_WhenNothingChanges_ThenItDoesNotRepaint', () {
      const painter = VinylPainter(palette: palette, turns: 0.25);

      expect(painter.shouldRepaint(painter), isFalse);
    });
  });
}

/// A small square picture, standing in for an album's own.
Future<ui.Image> _aCover() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 40, 40),
    Paint()..color = const Color(0xFF7E57C2),
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(40, 40);
  } finally {
    picture.dispose();
  }
}
