import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/features/playback/presentation/media/device_layer.dart';
import 'package:alexandria_ui/features/playback/presentation/media/turntable_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../flutter_test_config.dart';

/// The turntable, painted (UC-21, FR-PL-07).
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
    // `closed: 0` is the turntable open and waiting — tonearm parked;
    // `closed: 1` is the same turntable shut on its medium. The stage
    // paints [DeviceLayer.chassis] behind the medium and
    // [DeviceLayer.foreground] — the tonearm — in front of it (Finding 2),
    // so there is no single call that draws "the whole device" in one shot
    // — checking both passes separately is what actually proves the split.
    for (final (state, closed) in [('open', 0.0), ('closed', 1.0)]) {
      for (final layer in DeviceLayer.values) {
        final name = 'turntable-$state-${layer.name}';

        testWidgets(
          'GivenThe${_pascal(name)}Painter_WhenItIsDrawn_ThenItMatchesItsGolden',
          (tester) async {
            await tester.pumpWidget(
              painted(
                TurntablePainter(
                  palette: palette,
                  closed: closed,
                  layer: layer,
                ),
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
    test('GivenATurntablePainter_WhenOnlyClosedChanges_ThenItRepaints', () {
      const first = TurntablePainter(
        palette: palette,
        closed: 0,
        layer: DeviceLayer.chassis,
      );
      const second = TurntablePainter(
        palette: palette,
        closed: 1,
        layer: DeviceLayer.chassis,
      );

      expect(second.shouldRepaint(first), isTrue);
    });
  });

  // Finding 2: splitting a device painter into two passes is only safe if
  // each painter still repaints when the pass itself changes — a stage that
  // toggled `layer` between frames (it never does, but nothing stops a
  // future caller) must not have that change silently ignored the way a
  // `closed`-only `shouldRepaint` would.
  group('what layer means', () {
    test('GivenATurntablePainter_WhenOnlyLayerChanges_ThenItRepaints', () {
      const first = TurntablePainter(
        palette: palette,
        closed: 0,
        layer: DeviceLayer.chassis,
      );
      const second = TurntablePainter(
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
