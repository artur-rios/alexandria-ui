import 'dart:typed_data';

import 'package:alexandria_ui/features/playback/domain/track_energy.dart';
import 'package:alexandria_ui/features/playback/presentation/sound_bars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bars that move with the music (UC-21, FR-PL-07, FR-MP-07).
///
/// They move with it literally now: the core measures the file and this reads
/// the levels back at the position playing. The cases below are about that
/// reading — a bar between two measured bands, an instrument with nothing to
/// show yet, and the two states nothing may tick in.
void main() {
  /// Four bands: silent, quiet, loud, silent — for one frame.
  TrackEnergy oneFrame() => TrackEnergy(
    bands: 4,
    frameMs: 100,
    levels: Uint8List.fromList([0, 128, 255, 0]),
  );

  Widget bars({
    required bool isPlaying,
    TrackEnergy? energy,
    Duration position = Duration.zero,
    bool reduceMotion = false,
  }) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SoundBars(
            isPlaying: isPlaying,
            position: position,
            energy: energy,
          ),
        ),
      ),
    ),
  );

  SoundBarsPainter painter({
    TrackEnergy? energy,
    double energyIn = 1,
    int bars = 8,
  }) => SoundBarsPainter(
    energy: energy,
    position: Duration.zero,
    energyIn: energyIn,
    bars: bars,
    hot: const Color(0xFF112233),
    cool: const Color(0xFF445566),
  );

  group('reading the sound', () {
    test('GivenNoEnvelope_WhenABarIsRead_ThenItRests', () {
      // The first play of a track waits a second or two while the core
      // measures it, and a file it cannot decode never gets one: in both
      // cases the instrument sits still rather than inventing something.
      final resting = painter().levelFor(3);

      expect(resting, greaterThan(0));
      expect(resting, lessThan(0.2));
    });

    test('GivenAnEnvelope_WhenTheBandsAreRead_ThenTheLoudOneStandsTallest', () {
      // The whole point: what is loud in the recording is tall on the
      // screen, at the moment it is loud.
      final drawn = painter(energy: oneFrame(), bars: 4);

      expect(drawn.levelFor(2), greaterThan(drawn.levelFor(1)));
      expect(drawn.levelFor(1), greaterThan(drawn.levelFor(3)));
    });

    test('GivenMoreBarsThanBands_WhenReadBetweenTwo_ThenItIsBlended', () {
      // Sixteen bands drawn as fifty-six bars: a bar between two bands is a
      // blend of them, because what the eye reads as a spectrum is a curve
      // and sixteen wide blocks is not one.
      final drawn = painter(energy: oneFrame(), bars: 7);
      // Bar 3 of 7 sits between band 1 (128) and band 2 (255).
      final between = drawn.levelFor(3);

      expect(between, greaterThan(drawn.levelFor(2)));
      expect(between, lessThan(drawn.levelFor(4)));
    });

    test('GivenTheBarsHaveNotRisen_WhenTheyAreRead_ThenTheyRest', () {
      // `energyIn` is the settle: a pause takes the bars down to rest rather
      // than freezing them at whatever the last frame held.
      final settled = painter(energy: oneFrame(), energyIn: 0, bars: 4);

      expect(settled.levelFor(2), lessThan(0.2));
    });
  });

  group('what it does on screen', () {
    testWidgets('GivenSomethingPlaying_WhenItIsShown_ThenItKeepsMoving', (
      tester,
    ) async {
      await tester.pumpWidget(bars(isPlaying: true, energy: oneFrame()));
      await tester.pump(const Duration(milliseconds: 16));

      expect(tester.binding.hasScheduledFrame, isTrue);
    });

    testWidgets('GivenPlaybackStops_WhenTheBarsSettle_ThenNothingTicksOn', (
      tester,
    ) async {
      // A stopped ticker is a frame never scheduled, which is the whole
      // reason to stop it: the player stays open while the owner reads the
      // lyrics beside it.
      await tester.pumpWidget(bars(isPlaying: true, energy: oneFrame()));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.pumpWidget(bars(isPlaying: false, energy: oneFrame()));
      for (var frame = 0; frame < 40; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('GivenReducedMotion_WhenItIsShown_ThenNothingMovesAtAll', (
      tester,
    ) async {
      // AF-03, honoured to the letter: the levels of the moment playback is
      // at, and none of the motion somebody asked the system not to show.
      await tester.pumpWidget(
        bars(isPlaying: true, energy: oneFrame(), reduceMotion: true),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    test('GivenAPainter_WhenThePositionMoves_ThenItRepaints', () {
      final first = painter(energy: oneFrame());
      final second = SoundBarsPainter(
        energy: first.energy,
        position: const Duration(milliseconds: 16),
        energyIn: 1,
        bars: 8,
        hot: const Color(0xFF112233),
        cool: const Color(0xFF445566),
      );

      expect(second.shouldRepaint(first), isTrue);
      expect(first.shouldRepaint(first), isFalse);
    });
  });
}
