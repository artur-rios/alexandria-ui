import 'dart:typed_data';

import 'package:alexandria_ui/features/playback/domain/track_energy.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sound of a track, as the player reads it (UC-21, FR-MP-07).
///
/// The core measures the file and hands over one byte per band per frame;
/// everything here is about reading that back at the moment being heard,
/// which is the half of the visualiser this application owns.
void main() {
  /// Two frames of four bands: silent, then loud.
  TrackEnergy twoFrames() => TrackEnergy(
    bands: 4,
    frameMs: 100,
    levels: Uint8List.fromList([0, 0, 0, 0, 255, 255, 255, 255]),
  );

  test('GivenAFrame_WhenItIsRead_ThenTheLevelIsTheOneMeasured', () {
    final energy = TrackEnergy(
      bands: 2,
      frameMs: 100,
      levels: Uint8List.fromList([0, 255]),
    );

    expect(energy.frames, 1);
    expect(energy.levelAt(band: 0, position: Duration.zero), 0);
    expect(energy.levelAt(band: 1, position: Duration.zero), 1);
  });

  test('GivenAMomentBetweenFrames_WhenItIsRead_ThenItIsInterpolated', () {
    // Ten frames a second against sixty on screen: without this the bars
    // would step six times for every level the core measured, which reads as
    // dropped frames rather than as music.
    final energy = twoFrames();

    expect(
      energy.levelAt(band: 0, position: const Duration(milliseconds: 50)),
      closeTo(0.5, 0.01),
    );
  });

  test('GivenAMomentPastTheEnd_WhenItIsRead_ThenNothingIsDrawn', () {
    // A bar standing at whatever the last frame held would be the loudest
    // moment of the track frozen on screen after the music stopped.
    final energy = twoFrames();

    expect(energy.levelAt(band: 0, position: const Duration(seconds: 9)), 0);
    expect(
      energy.levelAt(band: 0, position: const Duration(milliseconds: -10)),
      0,
    );
  });

  test('GivenABandThatIsNotThere_WhenItIsRead_ThenNothingIsDrawn', () {
    // The core decides how many bands it measures, and a player built
    // against a different count must not read past the end of the envelope.
    final energy = twoFrames();

    expect(energy.levelAt(band: 9, position: Duration.zero), 0);
    expect(energy.levelAt(band: -1, position: Duration.zero), 0);
  });

  test('GivenAnEmptyEnvelope_WhenItIsRead_ThenNothingIsDrawn', () {
    final energy = TrackEnergy(bands: 0, frameMs: 100, levels: Uint8List(0));

    expect(energy.frames, 0);
    expect(energy.levelAt(band: 0, position: Duration.zero), 0);
  });
}
