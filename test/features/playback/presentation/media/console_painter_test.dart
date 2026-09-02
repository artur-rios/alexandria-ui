import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:alexandria_ui/features/playback/presentation/media/console_painter.dart';
import 'package:alexandria_ui/features/playback/presentation/media/device_layer.dart';
import 'package:alexandria_ui/features/playback/presentation/media/device_transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../flutter_test_config.dart';

/// The one machine (UC-21, FR-PL-07, FR-PL-12).
///
/// Replaces `turntable_painter_test.dart`, `tape_deck_painter_test.dart` and
/// `cd_player_painter_test.dart`, which tested three devices that no longer
/// exist: the stage draws a single console with a deck on top, a cassette bay
/// and a disc drawer on its fascia, and the medium playing decides which slot
/// has something in it rather than which machine is on screen.
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
  const size = Size(340, 315);

  group('what it looks like', () {
    // One chassis golden per medium, because the medium is what decides
    // which mechanism has moved: the lid is down and the drawer is shut for
    // a tape, the drawer is out for a disc, and the deck is what the record
    // lands on. The foreground pass is split out for the vinyl alone, where
    // the lid and the tonearm are the parts that actually travel.
    for (final medium in AlbumMedium.values) {
      testWidgets(
        'GivenA${_pascal(medium.name)}Console_WhenItIsDrawn_ThenItMatchesItsGolden',
        (tester) async {
          await tester.pumpWidget(
            painted(
              ConsolePainter(
                palette: palette,
                medium: medium,
                closed: 1,
                layer: DeviceLayer.chassis,
              ),
              size,
            ),
          );

          await expectLater(
            find.byType(CustomPaint).last,
            matchesGoldenFile('goldens/console-${medium.name}-chassis.png'),
          );
        },
        skip: !goldensAreComparable,
      );
    }

    for (final (state, closed) in [('open', 0.0), ('closed', 1.0)]) {
      testWidgets(
        'GivenTheLid${_pascal(state)}_WhenTheConsoleIsDrawn_ThenItMatchesItsGolden',
        (tester) async {
          await tester.pumpWidget(
            painted(
              ConsolePainter(
                palette: palette,
                medium: AlbumMedium.vinyl,
                closed: closed,
                layer: DeviceLayer.foreground,
              ),
              size,
            ),
          );

          await expectLater(
            find.byType(CustomPaint).last,
            matchesGoldenFile('goldens/console-lid-$state.png'),
          );
        },
        skip: !goldensAreComparable,
      );
    }

    testWidgets(
      'GivenATrackPlaying_WhenTheConsoleIsDrawn_ThenItSaysWhatIsOnIt',
      (tester) async {
        // The two lit windows and the pause cap, which are the whole of what
        // this machine says about itself while it runs.
        await tester.pumpWidget(
          painted(
            const ConsolePainter(
              palette: palette,
              medium: AlbumMedium.disc,
              closed: 1,
              layer: DeviceLayer.chassis,
              isPlaying: true,
              display: '03  01:24',
              trackTitle: 'Many Men (Wish Death)',
            ),
            size,
          ),
        );

        await expectLater(
          find.byType(CustomPaint).last,
          matchesGoldenFile('goldens/console-playing-chassis.png'),
        );
      },
      skip: !goldensAreComparable,
    );
  });

  group('the transport (main flow step 6)', () {
    test('GivenTheConsole_WhenItsCapsArePlaced_ThenTheyReadLeftToRight', () {
      // The order, which is the point of this test and was the owner's
      // report: the caps spent one release in a square of two by two, where
      // nothing says whether four controls are read across or down, and a
      // press landed on a different one than the eye picked. A row in the
      // transport's own order — back, play, stop, forward — is what every
      // machine with these four buttons has.
      const face = Rect.fromLTWH(0, 0, 340, 315);
      final bounds = transportBoundsFor(face);

      final centres = [
        for (final control in DeviceControl.values) bounds[control]!.center,
      ];
      expect(
        centres.map((centre) => centre.dy).toSet(),
        hasLength(1),
        reason: 'one row, so one height',
      );
      for (var i = 1; i < centres.length; i++) {
        expect(
          centres[i].dx,
          greaterThan(centres[i - 1].dx),
          reason:
              '${DeviceControl.values[i].name} sits right of '
              '${DeviceControl.values[i - 1].name}',
        );
      }
    });

    test('GivenTheCaps_WhenTheyArePlaced_ThenNoneOverlapsTheNext', () {
      const face = Rect.fromLTWH(0, 0, 340, 315);
      final bounds = transportBoundsFor(face);

      for (var i = 1; i < DeviceControl.values.length; i++) {
        expect(
          bounds[DeviceControl.values[i]]!.left,
          greaterThan(bounds[DeviceControl.values[i - 1]]!.right),
          reason:
              'a cap under another cap is a press that lands on the wrong '
              'one',
        );
      }
    });
  });

  group('where a medium sits', () {
    const face = Rect.fromLTWH(0, 0, 340, 315);

    test('GivenARecord_WhenItIsSeated_ThenItIsOnThePlatter', () {
      final seat = consoleSeatFor(AlbumMedium.vinyl, face);
      final (centre, radius) = ConsolePainter.platterOf(face);

      expect(seat.centre, centre);
      expect(
        seat.width,
        greaterThan(radius * 2),
        reason: 'a twelve-inch record overhangs every platter ever made',
      );
    });

    test('GivenACassette_WhenItIsSeated_ThenItIsInTheBay', () {
      final seat = consoleSeatFor(AlbumMedium.tape, face);
      final bay = ConsolePainter.bayOf(face);

      expect(bay.contains(seat.centre), isTrue);
      expect(
        seat.width,
        lessThan(bay.width),
        reason: 'a cassette wider than the bay is a cassette on the fascia',
      );
      expect(seat.height, lessThan(bay.height));
    });

    test('GivenADisc_WhenItIsSeated_ThenItLiesInTheOpenDrawer', () {
      final seat = consoleSeatFor(AlbumMedium.disc, face);
      final open = ConsolePainter.trayOf(face, 1);

      // Wholly inside the drawer at its full extension: a disc hanging over
      // the front lip reads as dropped rather than loaded, and one drawn
      // where the *shut* drawer is would be a disc inside the machine's
      // woodwork.
      expect(
        open.contains(seat.centre.translate(0, -seat.height / 2 + 1)),
        isTrue,
      );
      expect(
        open.contains(seat.centre.translate(0, seat.height / 2 - 1)),
        isTrue,
      );
      expect(
        ConsolePainter.trayOf(face, 0).height,
        lessThan(seat.height),
        reason: 'the shut drawer is a slot, not a bed',
      );
    });
  });

  group('what a repaint is for', () {
    ConsolePainter painterWith({
      AlbumMedium medium = AlbumMedium.vinyl,
      double closed = 1,
      bool isPlaying = false,
      String display = '',
      String trackTitle = '',
    }) => ConsolePainter(
      palette: palette,
      medium: medium,
      closed: closed,
      layer: DeviceLayer.chassis,
      isPlaying: isPlaying,
      display: display,
      trackTitle: trackTitle,
    );

    test('GivenAConsole_WhenTheReadoutMoves_ThenItRepaints', () {
      // The readout moves once a second while a track plays. A painter that
      // did not repaint for it would freeze the position on screen.
      expect(
        painterWith(
          display: '01  00:02',
        ).shouldRepaint(painterWith(display: '01  00:01')),
        isTrue,
      );
    });

    test('GivenAConsole_WhenTheMediumChanges_ThenItRepaints', () {
      // The mechanisms differ: a record's lid is up where a disc's drawer is
      // out, and a console that kept the last medium's would show a machine
      // in a state it is not in.
      expect(
        painterWith(
          medium: AlbumMedium.disc,
        ).shouldRepaint(painterWith(medium: AlbumMedium.vinyl)),
        isTrue,
      );
    });

    test('GivenAConsole_WhenPlayingChanges_ThenItRepaints', () {
      expect(
        painterWith(isPlaying: true).shouldRepaint(painterWith()),
        isTrue,
        reason: 'the play cap becomes a pause cap; the face has changed',
      );
    });

    test('GivenAConsole_WhenNothingChanges_ThenItDoesNot', () {
      expect(painterWith().shouldRepaint(painterWith()), isFalse);
    });
  });
}

String _pascal(String value) =>
    value[0].toUpperCase() + value.substring(1).toLowerCase();
