import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/features/playback/presentation/media/disc_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../flutter_test_config.dart';

/// The compact disc, painted (UC-21, FR-PL-07).
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

  testWidgets('GivenTheDiscPainter_WhenItIsDrawn_ThenItMatchesItsGolden', (
    tester,
  ) async {
    await tester.pumpWidget(
      painted(
        const DiscPainter(palette: palette, turns: 0),
        const Size(240, 240),
      ),
    );

    await expectLater(
      find.byType(CustomPaint).last,
      matchesGoldenFile('goldens/disc.png'),
    );
  }, skip: !goldensAreComparable);

  group('what turning means', () {
    test('GivenAPainter_WhenOnlyItsTurnsChange_ThenItRepaints', () {
      const first = DiscPainter(palette: palette, turns: 0);
      const second = DiscPainter(palette: palette, turns: 0.25);

      expect(second.shouldRepaint(first), isTrue);
    });

    test('GivenAPainter_WhenNothingChanges_ThenItDoesNotRepaint', () {
      const painter = DiscPainter(palette: palette, turns: 0.25);

      expect(painter.shouldRepaint(painter), isFalse);
    });
  });
}
