import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/features/playback/presentation/media/cd_player_painter.dart';
import 'package:alexandria_ui/features/playback/presentation/media/device_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../flutter_test_config.dart';

/// The CD player, painted (UC-21, FR-PL-07).
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
    // `closed: 0` is the lid standing open on its hinge; `closed: 1` is the
    // lid shut flat over the disc. Split by [DeviceLayer] for the same
    // reason `turntable_painter_test.dart` splits its own goldens
    // (Finding 2): the well and the lid are two separate passes, and
    // checking them separately is what actually proves neither leaked into
    // the other.
    for (final (state, closed) in [('open', 0.0), ('closed', 1.0)]) {
      for (final layer in DeviceLayer.values) {
        final name = 'cd-player-$state-${layer.name}';

        testWidgets(
          'GivenThe${_pascal(name)}Painter_WhenItIsDrawn_ThenItMatchesItsGolden',
          (tester) async {
            await tester.pumpWidget(
              painted(
                CdPlayerPainter(palette: palette, closed: closed, layer: layer),
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

  group('the readout and the transport (FR-PL-09, main flow step 6)', () {
    testWidgets(
      'GivenATrackPlaying_WhenThePlayerIsDrawn_ThenTheReadoutAndPauseAreShown',
      (tester) async {
        // A golden of its own rather than a changed one above: the two
        // states of this face — waiting, and playing a track — differ in
        // both the display and the play cap, and a device that reads `01
        // 03:47` while nothing is playing is the defect this replaced.
        await tester.pumpWidget(
          painted(
            const CdPlayerPainter(
              palette: palette,
              closed: 1,
              layer: DeviceLayer.chassis,
              isPlaying: true,
              display: '03  01:24',
            ),
            const Size(320, 220),
          ),
        );

        await expectLater(
          find.byType(CustomPaint).last,
          matchesGoldenFile('goldens/cd-player-playing-chassis.png'),
        );
      },
      skip: !goldensAreComparable,
    );

    test('GivenAPainter_WhenOnlyTheReadoutChanges_ThenItRepaints', () {
      // The readout moves once a second while a track plays. A painter that
      // did not repaint for it would freeze the position on screen — which
      // is exactly how the old fixed string behaved.
      const first = CdPlayerPainter(
        palette: palette,
        closed: 1,
        layer: DeviceLayer.chassis,
        display: '01  00:01',
      );
      const second = CdPlayerPainter(
        palette: palette,
        closed: 1,
        layer: DeviceLayer.chassis,
        display: '01  00:02',
      );

      expect(second.shouldRepaint(first), isTrue);
    });

    test('GivenAPainter_WhenPlayingChanges_ThenItRepaints', () {
      const paused = CdPlayerPainter(
        palette: palette,
        closed: 1,
        layer: DeviceLayer.chassis,
      );
      const playing = CdPlayerPainter(
        palette: palette,
        closed: 1,
        layer: DeviceLayer.chassis,
        isPlaying: true,
      );

      expect(
        playing.shouldRepaint(paused),
        isTrue,
        reason: 'the play cap becomes a pause cap; the face has changed',
      );
    });
  });

  group('what closed means', () {
    test('GivenACdPlayerPainter_WhenOnlyClosedChanges_ThenItRepaints', () {
      const first = CdPlayerPainter(
        palette: palette,
        closed: 0,
        layer: DeviceLayer.chassis,
      );
      const second = CdPlayerPainter(
        palette: palette,
        closed: 0.3,
        layer: DeviceLayer.chassis,
      );

      expect(second.shouldRepaint(first), isTrue);
    });
  });

  // Finding 2: see `turntable_painter_test.dart`'s own group of the same
  // name.
  group('what layer means', () {
    test('GivenACdPlayerPainter_WhenOnlyLayerChanges_ThenItRepaints', () {
      const first = CdPlayerPainter(
        palette: palette,
        closed: 0,
        layer: DeviceLayer.chassis,
      );
      const second = CdPlayerPainter(
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
