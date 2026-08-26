import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The WCAG contrast ratio of [color] against opaque white, computed from
/// relative luminance the same way a browser or a design tool would:
/// `(L_lighter + 0.05) / (L_darker + 0.05)`. White's luminance is 1.0, so
/// this simplifies to `1.05 / (L(color) + 0.05)`.
double _contrastAgainstWhite(Color color) =>
    1.05 / (color.computeLuminance() + 0.05);

/// The colours the album artwork is painted in (FR-UX-07, BR-18).
void main() {
  test('GivenEitherTheme_WhenItIsBuilt_ThenTheAlbumPaletteIsAttached', () {
    // The painters read it off the theme; a theme without it would be a
    // crash on the first frame of the animation rather than a wrong colour.
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      expect(theme.extension<AlbumPalette>(), isNotNull);
    }
  });

  test('GivenTheTwoThemes_WhenTheirPalettesAreCompared_ThenTheyAgree', () {
    // Deliberate, and the same reasoning PlaybackColors records: a walnut
    // plinth is brown in both brightnesses. The devices are objects in a
    // room, not surfaces the theme tints.
    expect(
      AppTheme.light.extension<AlbumPalette>(),
      AppTheme.dark.extension<AlbumPalette>(),
    );
  });

  test('GivenThePalette_WhenTheSleeveHuesAreRead_ThenThereAreSeveral', () {
    // The jacket picks from these by the album's name; one colour would make
    // every record in the library look like the same record.
    expect(AlbumPalette.standard.sleeveHues.length, greaterThanOrEqualTo(6));
  });

  test(
    'GivenEverySleeveHue_WhenWhiteTitleTextIsLaidOverIt_ThenItIsLegible',
    () {
      // Task 4 typesets the album title and artist directly on the sleeve
      // in white — the jacket is the one place in the artwork where text
      // sits on a palette colour rather than on a device panel chosen for
      // contrast. WCAG's 4.5:1 is the normal-text threshold; pinning it
      // here means a future retune of a hue cannot make a title illegible
      // without a test failing first.
      for (final hue in AlbumPalette.standard.sleeveHues) {
        expect(
          _contrastAgainstWhite(hue),
          greaterThanOrEqualTo(4.5),
          reason: 'sleeve hue $hue is too light to carry white text',
        );
      }
    },
  );
}
