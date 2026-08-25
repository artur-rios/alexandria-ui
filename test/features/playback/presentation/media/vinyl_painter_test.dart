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
