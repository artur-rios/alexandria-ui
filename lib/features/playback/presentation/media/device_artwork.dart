import 'package:flutter/material.dart';

import '../../domain/album_medium.dart';

/// What a device's own buttons do (UC-21 main flow, FR-PL-06).
enum DeviceControl {
  /// The previous track in the queue.
  previous,

  /// Running or paused — the one button whose glyph depends on the state.
  playPause,

  /// Stop, which empties the queue as the bar's own stop does.
  stop,

  /// The next track in the queue.
  next,
}

/// A circle on the photograph that turns while the music plays.
///
/// The medium is *in* the picture — a record on the platter, a disc in its
/// well, the reels behind a cassette's window — so making it spin is a matter
/// of turning those pixels rather than of drawing a medium over them. [radius]
/// is the circle in the machine's own world; [flattening] is how much of it
/// the camera left, so a record photographed from a low angle turns inside the
/// ellipse it actually occupies instead of sweeping outside it.
class DeviceSpin {
  /// Creates a spinner.
  const DeviceSpin({
    required this.centre,
    required this.radius,
    this.flattening = 1,
    this.carriesCover = false,
    this.hub,
  });

  /// Where it turns, as a fraction of the artwork's width and height.
  final Offset centre;

  /// How big it is, as a fraction of the artwork's *width* — so a circle
  /// stays a circle whatever the aspect of the picture around it.
  final double radius;

  /// The ratio of the ellipse's height to its width, 1 being a circle seen
  /// square on.
  final double flattening;

  /// Whether the album's own picture is printed here.
  ///
  /// True for a record's label, which is the one part of a record that shows
  /// it is turning at all: the grooves are concentric and a photograph of
  /// them looks identical at every angle, so a record with a plain label
  /// spins invisibly. The album's art on the label is what makes the motion
  /// legible — and it is what a record actually carries there.
  ///
  /// A spinner that carries the cover turns the cover *instead of* the
  /// photograph underneath it: what is under a record label is a spindle
  /// standing up through it, and a pin is the one thing on a turntable that
  /// a rotation smears into a streak rather than turning.
  final bool carriesCover;

  /// A patch of the photograph to lay back over the spinner, unturned.
  ///
  /// The spindle: it stands still while the record goes round it, and the
  /// art is printed with a hole for it. As a fraction of the artwork.
  final Rect? hub;
}

/// Everything about one photographed machine that the application has to know
/// (UC-21, FR-PL-07, FR-PL-12).
///
/// The three devices are photographs now, not drawings: `ConsolePainter` and
/// the three painters before it drew a machine out of gradients and rounded
/// rectangles, and next to a rendered one they read as a diagram of a machine.
/// What a drawing gave for free, though, a photograph does not — the
/// application still has to know where the record sits, where the screen is,
/// and which dark circle is the play button. That is what this is: the
/// measurements taken off each picture, as fractions of it, so they hold at
/// any size the stage draws.
class DeviceArtwork {
  /// Creates an artwork description.
  const DeviceArtwork({
    required this.asset,
    required this.aspect,
    required this.spins,
    required this.seat,
    required this.statusRow,
    required this.titleRow,
    required this.buttons,
  });

  /// The bundled picture.
  final String asset;

  /// Its width divided by its height.
  final double aspect;

  /// What turns while the music plays.
  final List<DeviceSpin> spins;

  /// Where the medium comes to rest, for the insertion to travel to — the
  /// record's own ellipse, the disc, the cassette in its window.
  final Rect seat;

  /// The screen's top line: what the machine is doing, and where it is.
  final Rect statusRow;

  /// The screen's second line: what is playing.
  final Rect titleRow;

  /// The buttons on the fascia, as circles.
  ///
  /// Every one of these machines carries five — stop, back, play/pause,
  /// forward, eject — and this application has four of them to offer: there
  /// is nothing to eject. The eject key stays in the picture, because it is
  /// part of the machine, and nothing is laid over it.
  final Map<DeviceControl, Rect> buttons;

  /// The artwork for [medium].
  static DeviceArtwork of(AlbumMedium medium) => switch (medium) {
    AlbumMedium.vinyl => _vinyl,
    AlbumMedium.tape => _cassette,
    AlbumMedium.disc => _disc,
  };

  /// [fraction] of [device], in the stage's own coordinates.
  static Rect resolve(Rect fraction, Rect device) => Rect.fromLTRB(
    device.left + device.width * fraction.left,
    device.top + device.height * fraction.top,
    device.left + device.width * fraction.right,
    device.top + device.height * fraction.bottom,
  );

  /// Where [spin] turns on [device], as an ellipse.
  static Rect ellipseOf(DeviceSpin spin, Rect device) {
    final radius = device.width * spin.radius;

    return Rect.fromCenter(
      center: Offset(
        device.left + device.width * spin.centre.dx,
        device.top + device.height * spin.centre.dy,
      ),
      width: radius * 2,
      height: radius * 2 * spin.flattening,
    );
  }
}

/// Measured off `device-images/vinyl-player.png`, 1200 × 348.
///
/// The label rather than the whole record: a record seen from this angle is a
/// strongly foreshortened ellipse, and the projection of a circle at that
/// angle is not an ellipse a rotation can be faked inside — the label's centre
/// sits eighteen pixels above the record's own, which is perspective and not
/// something a squash can reproduce. Near the middle the error is small
/// enough to disappear, and the middle is the only part that shows motion
/// anyway.
const DeviceArtwork _vinyl = DeviceArtwork(
  asset: 'assets/devices/vinyl-player.png',
  aspect: 1200 / 348,
  spins: [
    DeviceSpin(
      centre: Offset(0.4408, 0.2629),
      radius: 0.0967,
      flattening: 0.1336,
      carriesCover: true,
      hub: Rect.fromLTRB(0.4283, 0.1954, 0.4483, 0.2845),
    ),
  ],
  seat: Rect.fromLTRB(0.1525, 0.1379, 0.7292, 0.4943),
  statusRow: Rect.fromLTRB(0.2000, 0.6379, 0.5333, 0.7241),
  titleRow: Rect.fromLTRB(0.2000, 0.7414, 0.5333, 0.8506),
  buttons: {
    DeviceControl.stop: Rect.fromLTRB(0.5658, 0.6954, 0.6208, 0.8851),
    DeviceControl.previous: Rect.fromLTRB(0.6492, 0.6954, 0.7042, 0.8851),
    DeviceControl.playPause: Rect.fromLTRB(0.7308, 0.6954, 0.7858, 0.8851),
    DeviceControl.next: Rect.fromLTRB(0.8125, 0.6954, 0.8675, 0.8851),
  },
);

/// Measured off `device-images/cd-player.png`, 1600 × 426.
const DeviceArtwork _disc = DeviceArtwork(
  asset: 'assets/devices/cd-player.png',
  aspect: 1600 / 426,
  spins: [DeviceSpin(centre: Offset(0.3406, 0.4812), radius: 0.0894)],
  seat: Rect.fromLTRB(0.2512, 0.1455, 0.4300, 0.8169),
  statusRow: Rect.fromLTRB(0.4844, 0.1408, 0.7781, 0.2160),
  titleRow: Rect.fromLTRB(0.4844, 0.2183, 0.7781, 0.3521),
  buttons: {
    DeviceControl.stop: Rect.fromLTRB(0.5150, 0.6854, 0.5625, 0.8638),
    DeviceControl.previous: Rect.fromLTRB(0.5700, 0.6854, 0.6175, 0.8638),
    DeviceControl.playPause: Rect.fromLTRB(0.6313, 0.6854, 0.6788, 0.8638),
    DeviceControl.next: Rect.fromLTRB(0.6888, 0.6854, 0.7363, 0.8638),
  },
);

/// Measured off `device-images/cassette-player.png`, 1400 × 389.
const DeviceArtwork _cassette = DeviceArtwork(
  asset: 'assets/devices/cassette-player.png',
  aspect: 1400 / 389,
  spins: [
    DeviceSpin(centre: Offset(0.3121, 0.3496), radius: 0.0250),
    DeviceSpin(centre: Offset(0.4136, 0.3496), radius: 0.0243),
  ],
  seat: Rect.fromLTRB(0.2536, 0.2005, 0.4714, 0.5527),
  statusRow: Rect.fromLTRB(0.5343, 0.2005, 0.7786, 0.2725),
  titleRow: Rect.fromLTRB(0.5343, 0.2879, 0.7786, 0.3908),
  buttons: {
    DeviceControl.stop: Rect.fromLTRB(0.3643, 0.6812, 0.4143, 0.8612),
    DeviceControl.previous: Rect.fromLTRB(0.4486, 0.6812, 0.4986, 0.8612),
    DeviceControl.playPause: Rect.fromLTRB(0.5336, 0.6812, 0.5836, 0.8612),
    DeviceControl.next: Rect.fromLTRB(0.6193, 0.6812, 0.6693, 0.8612),
  },
);
