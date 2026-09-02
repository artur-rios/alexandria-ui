import 'dart:ui' as ui;

import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:alexandria_ui/features/playback/presentation/media/device_artwork.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// The three machines, decoded from the bundle (Testing Specification §2.3).
///
/// Called from `setUpAll` and never from inside a test body, which is not a
/// style preference: `rootBundle.load` is real asynchronous work, and a test
/// body runs in a zone whose clock the test drives — awaiting a bundle read
/// in there hangs the case until the runner gives up on it. `setUpAll` runs
/// outside that zone, so the read completes the way it would anywhere else.
Future<Map<AlbumMedium, ui.Image>> loadDeviceImages() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  return {
    for (final medium in AlbumMedium.values)
      medium: await _decode(DeviceArtwork.of(medium).asset),
  };
}

Future<ui.Image> _decode(String asset) async {
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());

  return (await codec.getNextFrame()).image;
}
