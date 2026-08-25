import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
