import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:alexandria_ui/features/playback/presentation/media/device_artwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The measurements taken off the three photographs (UC-21, FR-PL-07,
/// FR-PL-12).
///
/// Numbers read off a picture are the one kind of geometry nothing else can
/// check: a drawn machine put its own buttons where the code said, so the two
/// could not disagree, where a photographed one has its buttons wherever the
/// camera found them and this table says where that is. Every case below is
/// about the table being *possible* — a hit target on the fascia rather than
/// out on the wood, a medium inside the machine rather than beside it — which
/// is what catches a fraction typed wrong.
void main() {
  /// A device rect of the artwork's own proportions, so a fraction resolves
  /// to the same shape the stage draws.
  Rect deviceFor(DeviceArtwork artwork) =>
      Rect.fromLTWH(0, 0, 900, 900 / artwork.aspect);

  for (final medium in AlbumMedium.values) {
    final artwork = DeviceArtwork.of(medium);

    group('the ${medium.name} machine', () {
      test('GivenItsPicture_WhenItIsRead_ThenEverythingIsOnIt', () {
        // Fractions, so every one of them is between nothing and all of it.
        final rects = [
          artwork.seat,
          artwork.statusRow,
          artwork.titleRow,
          ...artwork.buttons.values,
        ];
        for (final rect in rects) {
          expect(rect.left, inInclusiveRange(0, 1));
          expect(rect.top, inInclusiveRange(0, 1));
          expect(rect.right, inInclusiveRange(0, 1));
          expect(rect.bottom, inInclusiveRange(0, 1));
          expect(rect.width, greaterThan(0));
          expect(rect.height, greaterThan(0));
        }
      });

      test('GivenTheButtons_WhenTheyArePlaced_ThenTheyReadLeftToRight', () {
        // The order the owner reads them in, which is the order every one of
        // these machines prints them in: back, play, forward — with stop to
        // the left of the three, where the picture has it. A press that
        // landed on the button beside the one aimed at was the complaint
        // that got the transport rebuilt once already.
        final device = deviceFor(artwork);
        final placed =
            [
                  DeviceControl.stop,
                  DeviceControl.previous,
                  DeviceControl.playPause,
                  DeviceControl.next,
                ]
                .map(
                  (control) =>
                      DeviceArtwork.resolve(artwork.buttons[control]!, device),
                )
                .toList();

        for (var i = 1; i < placed.length; i++) {
          expect(
            placed[i].left,
            greaterThan(placed[i - 1].right),
            reason: 'a target over the next button is a press on the wrong one',
          );
        }
        expect(
          placed.map((rect) => rect.center.dy).toSet(),
          hasLength(1),
          reason: 'one row, so one height',
        );
      });

      test('GivenTheScreen_WhenItIsRead_ThenItsTwoLinesDoNotOverlap', () {
        expect(
          artwork.titleRow.top,
          greaterThanOrEqualTo(artwork.statusRow.bottom),
        );
        expect(
          artwork.statusRow.left,
          artwork.titleRow.left,
          reason: 'both lines are printed against the same left edge',
        );
      });

      test('GivenTheSeat_WhenItIsRead_ThenItHoldsWhatIsSpinning', () {
        // Every spinner belongs to the medium, so every one of them has to be
        // inside the place the medium sits: a reel outside the cassette, or a
        // label off the record, is a fraction typed wrong.
        final device = deviceFor(artwork);
        final seat = DeviceArtwork.resolve(artwork.seat, device);

        for (final spin in artwork.spins) {
          final ellipse = DeviceArtwork.ellipseOf(spin, device);
          expect(
            seat.contains(ellipse.center),
            isTrue,
            reason: 'what turns, turns inside the machine',
          );
          expect(seat.inflate(1).contains(ellipse.topLeft), isTrue);
          expect(seat.inflate(1).contains(ellipse.bottomRight), isTrue);
        }
      });
    });
  }

  test('GivenTheThreeMachines_WhenTheyAreListed_ThenEachHasItsOwnPicture', () {
    final assets = {
      for (final medium in AlbumMedium.values) DeviceArtwork.of(medium).asset,
    };

    expect(assets, hasLength(AlbumMedium.values.length));
    for (final asset in assets) {
      expect(asset, startsWith('assets/devices/'));
    }
  });
}
