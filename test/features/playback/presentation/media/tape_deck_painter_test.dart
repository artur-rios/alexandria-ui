import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/features/playback/presentation/media/device_layer.dart';
import 'package:alexandria_ui/features/playback/presentation/media/tape_deck_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../flutter_test_config.dart';

/// The tape deck, painted (UC-21, FR-PL-07).
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

  group('what it looks like', () {
    // `closed: 0` is the deck racked open, the well waiting; `closed: 1` is
    // the door slid down over the cassette. Split by [DeviceLayer] for the
    // same reason `turntable_painter_test.dart` splits its own goldens
    // (Finding 2): the chassis and the door are two separate passes, and
    // checking them separately is what actually proves neither leaked into
    // the other.
    for (final (state, closed) in [('open', 0.0), ('closed', 1.0)]) {
      for (final layer in DeviceLayer.values) {
        final name = 'tape-deck-$state-${layer.name}';

        testWidgets(
          'GivenThe${_pascal(name)}Painter_WhenItIsDrawn_ThenItMatchesItsGolden',
          (tester) async {
            await tester.pumpWidget(
              painted(
                TapeDeckPainter(palette: palette, closed: closed, layer: layer),
                const Size(320, 220),
              ),
            );

            await expectLater(
              find.byType(CustomPaint).last,
              matchesGoldenFile('goldens/$name.png'),
            );
          },
          skip: !goldensAreComparable,
        );
      }
    }
  });

  group('what closed means', () {
    test('GivenATapeDeckPainter_WhenNothingChanges_ThenItDoesNotRepaint', () {
      // Two distinct instances with identical fields, not the same instance
      // compared to itself — the latter would pass even if `==` were
      // broken, since `identical(this, other)` alone would satisfy it.
      const first = TapeDeckPainter(
        palette: palette,
        closed: 0.5,
        layer: DeviceLayer.foreground,
      );
      const second = TapeDeckPainter(
        palette: palette,
        closed: 0.5,
        layer: DeviceLayer.foreground,
      );

      expect(second.shouldRepaint(first), isFalse);
    });
  });

  // Finding 2: see `turntable_painter_test.dart`'s own group of the same
  // name.
  group('what layer means', () {
    test('GivenATapeDeckPainter_WhenOnlyLayerChanges_ThenItRepaints', () {
      const first = TapeDeckPainter(
        palette: palette,
        closed: 0,
        layer: DeviceLayer.chassis,
      );
      const second = TapeDeckPainter(
        palette: palette,
        closed: 0,
        layer: DeviceLayer.foreground,
      );

      expect(second.shouldRepaint(first), isTrue);
    });
  });
}

/// `dashed-name` to `DashedName`, for the readable half of a test name that
/// still identifies which golden it checks.
String _pascal(String dashed) => dashed
    .split('-')
    .map((word) => word[0].toUpperCase() + word.substring(1))
    .join();
