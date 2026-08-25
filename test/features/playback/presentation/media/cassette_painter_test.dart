import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/features/playback/presentation/media/cassette_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../flutter_test_config.dart';

/// The cassette, painted (UC-21, FR-PL-07).
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
    'GivenTheCassettePainter_WhenItIsDrawn_ThenItMatchesItsGolden',
    (tester) async {
      await tester.pumpWidget(
        painted(
          const CassettePainter(palette: palette, turns: 0),
          const Size(260, 132),
        ),
      );

      await expectLater(
        find.byType(CustomPaint).last,
        matchesGoldenFile('goldens/cassette.png'),
      );
    },
    skip: !goldensAreComparable,
  );

  group('what turning means', () {
    testWidgets(
      'GivenTheCassette_WhenItsReelsTurn_ThenItsShellDoesNot',
      (tester) async {
        // A cassette's reels turn inside a shell that does not move. The
        // whole-cassette rotation this replaces is the single most obviously
        // wrong thing about the animation it grew from.
        await tester.pumpWidget(
          painted(
            const CassettePainter(palette: palette, turns: 0.5),
            const Size(260, 132),
          ),
        );

        await expectLater(
          find.byType(CustomPaint).last,
          matchesGoldenFile('goldens/cassette-half-turn.png'),
        );
      },
      skip: !goldensAreComparable,
    );

    test('GivenAPainter_WhenOnlyItsTurnsChange_ThenItRepaints', () {
      const first = CassettePainter(palette: palette, turns: 0);
      const second = CassettePainter(palette: palette, turns: 0.25);

      expect(second.shouldRepaint(first), isTrue);
    });

    test('GivenAPainter_WhenNothingChanges_ThenItDoesNotRepaint', () {
      const painter = CassettePainter(palette: palette, turns: 0.25);

      expect(painter.shouldRepaint(painter), isFalse);
    });
  });
}
