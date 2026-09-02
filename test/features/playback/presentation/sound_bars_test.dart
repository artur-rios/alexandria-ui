import 'package:alexandria_ui/features/playback/presentation/sound_bars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bars that move with the music (UC-21, FR-PL-07).
///
/// They are not a spectrum of the audio and the widget's own documentation
/// says so: nothing in this application can see the sound. What the cases
/// below hold is what the bars actually promise — that they run while the
/// music runs, that they settle rather than freeze when it stops, that a
/// track moves the same way every time it plays and two tracks do not move
/// the same way, and that a request for less motion is honoured to the letter
/// rather than by slowing anything down.
void main() {
  Widget bars({
    required bool isPlaying,
    int seed = 7,
    bool reduceMotion = false,
  }) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SoundBars(isPlaying: isPlaying, seed: seed),
        ),
      ),
    ),
  );

  group('the shape of it', () {
    test('GivenTheSameTrackAndMoment_WhenReadTwice_ThenItIsTheSame', () {
      // The seed is the whole reason this is a function and not a random
      // source: a visualiser that reshuffled on every rebuild would flicker
      // whenever anything else on the screen changed.
      double level() => SoundBarsPainter.levelFor(
        index: 5,
        bars: 40,
        seconds: 12.5,
        seed: 99,
        energy: 1,
      );

      expect(level(), level());
    });

    test('GivenTwoTracks_WhenReadAtTheSameMoment_ThenTheyDiffer', () {
      double level(int seed) => SoundBarsPainter.levelFor(
        index: 5,
        bars: 40,
        seconds: 12.5,
        seed: seed,
        energy: 1,
      );

      expect(level(1), isNot(level(2)));
    });

    test('GivenAnyMoment_WhenEveryBarIsRead_ThenNoneLeavesTheFrame', () {
      // A level outside 0..1 is a bar drawn past the top of the widget, or
      // one drawn upside down.
      for (var index = 0; index < 56; index++) {
        for (final seconds in [0.0, 0.37, 4.2, 61.9]) {
          final level = SoundBarsPainter.levelFor(
            index: index,
            bars: 56,
            seconds: seconds,
            seed: 3,
            energy: 1,
          );

          expect(level, inInclusiveRange(0, 1), reason: '$index at $seconds');
        }
      }
    });

    test('GivenNothingPlaying_WhenTheBarsAreRead_ThenTheyAllRest', () {
      // Not zero: a row of bars flat against the floor reads as a broken
      // widget rather than as silence.
      final levels = [
        for (var index = 0; index < 20; index++)
          SoundBarsPainter.levelFor(
            index: index,
            bars: 20,
            seconds: 3,
            seed: 5,
            energy: 0,
          ),
      ];

      expect(levels.toSet(), hasLength(1));
      expect(levels.first, greaterThan(0));
      expect(levels.first, lessThan(0.2));
    });

    test('GivenABandOfEach_WhenAveraged_ThenTheLowOnesStandTaller', () {
      // The tilt of a spectrum analyser at rest — bass loud on the left,
      // treble quiet on the right. Without it a row of equal bars reads as a
      // decoration rather than as an instrument.
      double average(int index) {
        var total = 0.0;
        for (var step = 0; step < 200; step++) {
          total += SoundBarsPainter.levelFor(
            index: index,
            bars: 40,
            seconds: step * 0.05,
            seed: 11,
            energy: 1,
          );
        }

        return total / 200;
      }

      expect(average(2), greaterThan(average(37)));
    });
  });

  group('what it does on screen', () {
    testWidgets('GivenSomethingPlaying_WhenItIsShown_ThenItKeepsMoving', (
      tester,
    ) async {
      await tester.pumpWidget(bars(isPlaying: true));
      await tester.pump(const Duration(milliseconds: 16));

      expect(tester.binding.hasScheduledFrame, isTrue);
    });

    testWidgets('GivenPlaybackStops_WhenTheBarsSettle_ThenNothingTicksOn', (
      tester,
    ) async {
      // A stopped clock is a frame never scheduled, which is the whole
      // reason to stop it: the screen stays open while the owner reads the
      // lyrics beside it, and a widget that kept painting a still picture
      // would burn a frame's work sixty times a second for nothing.
      await tester.pumpWidget(bars(isPlaying: true));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.pumpWidget(bars(isPlaying: false));
      // Past the settle, which is deliberately longer than the swell: the
      // sound falls away rather than being cut.
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('GivenReducedMotion_WhenItIsShown_ThenNothingMovesAtAll', (
      tester,
    ) async {
      // AF-03, honoured to the letter: not the same thing slower, but the
      // picture the instrument makes with no motion in it.
      await tester.pumpWidget(bars(isPlaying: true, reduceMotion: true));
      await tester.pump(const Duration(milliseconds: 16));

      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    test('GivenAPainter_WhenOnlyTheClockMoves_ThenItRepaints', () {
      const first = SoundBarsPainter(
        seconds: 1,
        energy: 1,
        seed: 4,
        bars: 40,
        hot: Color(0xFF112233),
        cool: Color(0xFF445566),
      );
      const second = SoundBarsPainter(
        seconds: 1.016,
        energy: 1,
        seed: 4,
        bars: 40,
        hot: Color(0xFF112233),
        cool: Color(0xFF445566),
      );

      expect(second.shouldRepaint(first), isTrue);
      expect(first.shouldRepaint(first), isFalse);
    });
  });
}
