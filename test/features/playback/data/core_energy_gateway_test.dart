import 'dart:convert';

import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/features/playback/data/core_energy_gateway.dart';
import 'package:alexandria_ui/features/playback/domain/track_energy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_core_client.dart';

/// Reading a track's sound across the FFI boundary (UC-21, FR-MP-07).
void main() {
  const credential = 'token';

  ({FakeCoreClient core, CoreEnergyGateway gateway}) build() {
    final core = FakeCoreClient();

    return (core: core, gateway: CoreEnergyGateway(core));
  }

  test('GivenAnEnvelope_WhenItIsRead_ThenTheLevelsComeBackAsBytes', () async {
    // Base64 because JSON cannot carry bytes, and bytes because a
    // four-minute track is thirty-eight thousand levels — as an array of
    // small integers that is four times the size and slower to parse at both
    // ends.
    final fixture = build();
    fixture.core.energyResponse = (
      status: PLAYBACK_OK,
      json: jsonEncode({
        'uuid': 'kob-1',
        'bands': 4,
        'frameMs': 100,
        'levelsBase64': base64Encode([0, 64, 128, 255]),
      }),
    );

    final read = await fixture.gateway.readEnergy(
      fileUuid: 'kob-1',
      credential: credential,
    );

    expect(read, isA<TrackEnergyLoaded>());
    final energy = (read as TrackEnergyLoaded).energy;
    expect(energy.bands, 4);
    expect(energy.frameMs, 100);
    expect(energy.levels, [0, 64, 128, 255]);
    expect(energy.frames, 1);
    expect(fixture.core.energyCalls.single.uuid, 'kob-1');
    expect(fixture.core.energyCalls.single.token, credential);
  });

  test('GivenTheCoreRefuses_WhenItIsRead_ThenNothingIsDrawn', () async {
    // A file the core will not decode still plays — mpv is not ffmpeg's
    // decoder — so this is a state, never an error raised at the owner.
    final fixture = build();
    fixture.core.energyResponse = (status: PLAYBACK_ERR_OTHER, json: null);

    final read = await fixture.gateway.readEnergy(
      fileUuid: 'kob-1',
      credential: credential,
    );

    expect(read, isA<TrackEnergyUnavailable>());
  });

  test('GivenNonsenseComesBack_WhenItIsRead_ThenNothingIsDrawn', () async {
    // The core and this application disagreeing about the envelope's shape
    // is the same outcome as a file that cannot be measured: bars at rest.
    final fixture = build();
    fixture.core.energyResponse = (
      status: PLAYBACK_OK,
      json: '{"bands":"four"}',
    );

    final read = await fixture.gateway.readEnergy(
      fileUuid: 'kob-1',
      credential: credential,
    );

    expect(read, isA<TrackEnergyUnavailable>());
  });
}
