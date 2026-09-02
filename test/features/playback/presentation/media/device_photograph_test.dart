import 'dart:ui' as ui;

import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:alexandria_ui/features/playback/presentation/media/device_artwork.dart';
import 'package:alexandria_ui/features/playback/presentation/media/device_photograph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../flutter_test_config.dart';
import '../../../../support/device_images.dart';

/// The three machines, painted (UC-21, FR-PL-07, FR-PL-12).
///
/// Replaces `console_painter_test.dart` and the three painter tests before
/// it. Those checked a drawing against a picture of the same drawing; this
/// checks the three things the application does *to* a photograph — the
/// medium turning in it, the screen saying what is playing, and the album's
/// art on the label — because everything else in the frame is the photograph
/// and needs no test at all.
void main() {
  late Map<AlbumMedium, ui.Image> devices;
  late ui.Image cover;

  setUpAll(() async {
    devices = await loadDeviceImages();
    cover = await _testCover();
  });

  Widget painted(CustomPainter painter, Size size) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: RepaintBoundary(
        child: CustomPaint(size: size, painter: painter),
      ),
    ),
  );

  DevicePhotograph photographOf(
    AlbumMedium medium, {
    double turns = 0,
    bool isPlaying = true,
    String status = 'TRACK 04   01:13',
    String trackTitle = 'Many Men (Wish Death)',
    ui.Image? cover,
  }) => DevicePhotograph(
    image: devices[medium]!,
    artwork: DeviceArtwork.of(medium),
    palette: AlbumPalette.standard,
    turns: turns,
    isPlaying: isPlaying,
    status: status,
    trackTitle: trackTitle,
    cover: cover,
  );

  group('what it looks like', () {
    for (final medium in AlbumMedium.values) {
      testWidgets(
        'GivenThe${_pascal(medium.name)}Machine_WhenItIsPlaying_ThenItMatchesItsGolden',
        (tester) async {
          final artwork = DeviceArtwork.of(medium);
          await tester.pumpWidget(
            painted(
              // A part-turn rather than none, so the golden holds the
              // rotation itself and not merely the photograph: at zero the
              // picture is untouched and the test would pass with the whole
              // transform deleted.
              photographOf(medium, turns: 0.15, cover: cover),
              Size(560, 560 / artwork.aspect),
            ),
          );

          await expectLater(
            find.byType(CustomPaint).last,
            matchesGoldenFile('goldens/machine-${medium.name}.png'),
          );
        },
        skip: !goldensAreComparable,
      );
    }
  });

  group('what a repaint is for', () {
    test('GivenAMachine_WhenTheMediumTurns_ThenItRepaints', () {
      // The medium turns every frame while audio runs; a painter that did not
      // repaint for it would show a record standing still.
      expect(
        photographOf(
          AlbumMedium.vinyl,
          turns: 0.2,
        ).shouldRepaint(photographOf(AlbumMedium.vinyl)),
        isTrue,
      );
    });

    test('GivenAMachine_WhenTheReadoutMoves_ThenItRepaints', () {
      expect(
        photographOf(
          AlbumMedium.disc,
          status: 'TRACK 04   01:14',
        ).shouldRepaint(photographOf(AlbumMedium.disc)),
        isTrue,
      );
    });

    test('GivenAMachine_WhenPlaybackPauses_ThenItRepaints', () {
      // The screen's first word changes with it.
      expect(
        photographOf(
          AlbumMedium.tape,
          isPlaying: false,
        ).shouldRepaint(photographOf(AlbumMedium.tape)),
        isTrue,
      );
    });

    test('GivenAMachine_WhenTheCoverArrives_ThenItRepaints', () {
      // The art goes on the label, so a cover that lands after the record is
      // already turning has to reach the paint.
      expect(
        photographOf(
          AlbumMedium.vinyl,
          cover: cover,
        ).shouldRepaint(photographOf(AlbumMedium.vinyl)),
        isTrue,
      );
    });

    test('GivenAMachine_WhenNothingChanges_ThenItDoesNot', () {
      expect(
        photographOf(
          AlbumMedium.vinyl,
        ).shouldRepaint(photographOf(AlbumMedium.vinyl)),
        isFalse,
      );
    });
  });
}

/// A stand-in album cover: four quarters, so a rotation of it is obvious in a
/// golden rather than a matter of opinion.
Future<ui.Image> _testCover() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const colours = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFFFDD835),
    Color(0xFF43A047),
  ];
  for (final (index, colour) in colours.indexed) {
    canvas.drawRect(
      Rect.fromLTWH((index % 2) * 50, (index ~/ 2) * 50, 50, 50),
      Paint()..color = colour,
    );
  }

  return recorder.endRecording().toImage(100, 100);
}

String _pascal(String value) =>
    value[0].toUpperCase() + value.substring(1).toLowerCase();
