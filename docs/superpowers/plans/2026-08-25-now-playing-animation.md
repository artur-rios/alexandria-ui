# Now-Playing Animation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 360-pixel player dialog with a full-window now-playing screen where the album's medium is pulled from its case, inserted into its device, and turns for as long as the track plays — with the same medium turning in a visor in the playback bar, and one preference choosing the medium by release year, pinning it, or turning it all off.

**Architecture:** The artwork is authored vector, painted in Dart as layered `CustomPainter`s whose moving parts are separable from their still ones, over a palette that lives in the theme. An `AlbumStage` widget drives two timelines — a one-shot insertion and a continuous spin — from the playback state. An `AlbumAnimationController` answers the one question the stage cannot: whether an insertion is owed, which is true on the session's first play and whenever the album or artist changes.

**Tech Stack:** Flutter 3.47.1, Material 3, `CustomPainter`, `AnimationController`, Riverpod, `gen_l10n`, the project's tolerant golden comparator.

## Global Constraints

- **Design document:** `docs/superpowers/specs/2026-08-25-now-playing-animation-design.md`. It is the authority; this plan implements it.
- **Test naming:** every test is one identifier in Given-When-Then form — `GivenSomeCondition_WhenSomeAction_ThenSomeOutcome`. A test that cannot fail for the reason its name claims is a defect, not coverage.
- **Test location:** the test tree mirrors `lib/` exactly, with `_test` appended.
- **Localization:** every user-visible string comes from `AppLocalizations`, present in BOTH `lib/core/l10n/app_en.arb` (with an `@key` description block — an undescribed message is a generation failure) and `lib/core/l10n/app_pt.arb` (without). Regenerate with `flutter gen-l10n`; generated files under `lib/core/l10n/generated/` are committed. `@key` descriptions are doc comments for strings and must stay true.
- **No colour literals** anywhere under `lib/` outside `lib/core/theme/` (BR-18 / FR-UX-07, enforced by `test/core/theme/no_color_literal_test.dart`). This binds the artwork absolutely: every colour a painter uses arrives from `AlbumPalette`.
- **Never a file name for audio** (FR-CT-13): the now-playing screen names its track by metadata, through the existing `musicTitleForFile` / `queueLabelOf` helpers in `lib/features/playback/presentation/music_display_name.dart`.
- **Reduced motion:** `MediaQuery.disableAnimationsOf(context)` is honoured everywhere motion is introduced — the medium is shown seated and still, and no ticker runs.
- **Doc comments explain WHY**, and must be true of the code they sit on.
- **Verification:** run `flutter analyze` and `flutter test` and read the output. Never claim done on an unrun test.
- **Goldens:** regenerate with `flutter test --update-goldens`, then LOOK at the images. A golden blessed over a broken frame is worse than a failing test.
- **Commits:** conventional commit subject in lowercase, ≤50 characters, imperative; body wrapped at 72. End every commit message with `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.

## Reference values

The mockups agreed during design are the reference for staging and timing.

| Value | Setting |
| --- | --- |
| Insertion duration | 4.4s total |
| Beat boundaries | case in 0–16%, medium out 21–42%, hold 42–54%, travel 54–82%, device closes 82–94% |
| Vinyl spin | 1.5s per turn |
| Compact disc spin | 0.9s per turn |
| Cassette reels | 1.8s per turn |
| Medium's scale inside the case | 0.60 (0.48 for the cassette) |
| Visor size | 64 logical pixels square |

---

## File Structure

| File | Responsibility |
| --- | --- |
| `lib/core/theme/album_palette.dart` | **New.** Every colour the artwork uses, as a `ThemeExtension`. |
| `lib/features/playback/domain/album_medium.dart` | Gains `AlbumAnimationMode` and `mediumFor(mode, year)`; keeps `mediumForYear`. |
| `lib/features/playback/domain/sleeve_design.dart` | **New.** The deterministic jacket colour for an album name. |
| `lib/core/settings/settings_store.dart` + `shared_preferences_settings_store.dart` | Read and write the mode. |
| `lib/features/shell/application/preferences_state.dart` + `preferences_controller.dart` | Carry and set the mode. |
| `lib/features/playback/presentation/media/` | **New.** One painter per medium (`vinyl_painter.dart`, `cassette_painter.dart`, `disc_painter.dart`), one per device (`turntable_painter.dart`, `tape_deck_painter.dart`, `cd_player_painter.dart`), and `case_painter.dart` for the three cases and the jacket. |
| `lib/features/playback/presentation/album_stage.dart` | **New.** The insertion and spin timelines over those painters. |
| `lib/features/playback/application/album_animation_controller.dart` | **New.** Whether an insertion is owed. |
| `lib/features/playback/presentation/now_playing_screen.dart` | **New.** The full-window route. Replaces `album_player_screen.dart`. |
| `lib/features/playback/presentation/album_visor.dart` | **New.** The bar's window. |

---

### Task 1: The mode, end to end

Everything the owner can choose, with no artwork involved: the enum, the persistence, the preference, and what each mode resolves to.

**Files:**
- Modify: `lib/features/playback/domain/album_medium.dart`
- Modify: `lib/core/settings/settings_store.dart`, `lib/core/settings/shared_preferences_settings_store.dart`
- Modify: `lib/features/shell/application/preferences_state.dart`, `preferences_controller.dart`
- Modify: `lib/features/shell/presentation/preferences_dialog.dart`
- Modify: `lib/core/l10n/app_en.arb`, `lib/core/l10n/app_pt.arb`
- Test: `test/features/playback/domain/album_medium_test.dart` (added group), `test/features/shell/presentation/preferences_dialog_test.dart` (added group)

**Interfaces:**
- Consumes: `AlbumMedium`, `mediumForYear(int?)`, `SettingsStore`, `PreferencesState`, `PreferencesController`.
- Produces:
  - `enum AlbumAnimationMode { byYear, vinyl, tape, disc, off }`
  - `AlbumMedium? mediumFor(AlbumAnimationMode mode, int? year)` — the medium to show, or `null` when the mode is `off`.
  - `AlbumAnimationMode get SettingsStore.albumAnimationMode` and `Future<void> setAlbumAnimationMode(AlbumAnimationMode)`.
  - `PreferencesState.albumAnimation` (default `AlbumAnimationMode.byYear`) and `PreferencesController.setAlbumAnimation(AlbumAnimationMode)`.
  - Localization keys `animationLabel`, `animationByYear`, `animationVinyl`, `animationTape`, `animationDisc`, `animationOff`.

- [ ] **Step 1: Write the failing domain test**

Add to `test/features/playback/domain/album_medium_test.dart`:

```dart
  group('the mode the owner chose (FR-PL-11)', () {
    test('GivenTheByYearMode_WhenAMediumIsPicked_ThenTheYearDecides', () {
      // The rule that already exists, now reached through the mode rather
      // than called directly.
      expect(mediumFor(AlbumAnimationMode.byYear, 1971), AlbumMedium.vinyl);
      expect(mediumFor(AlbumAnimationMode.byYear, 1988), AlbumMedium.tape);
      expect(mediumFor(AlbumAnimationMode.byYear, 2001), AlbumMedium.disc);
    });

    test('GivenAPinnedMode_WhenAMediumIsPicked_ThenTheYearIsIgnored', () {
      // The point of pinning: an owner who wants records wants records, and
      // the album's year is not an argument against that.
      expect(mediumFor(AlbumAnimationMode.vinyl, 2001), AlbumMedium.vinyl);
      expect(mediumFor(AlbumAnimationMode.tape, 1971), AlbumMedium.tape);
      expect(mediumFor(AlbumAnimationMode.disc, 1971), AlbumMedium.disc);
    });

    test('GivenTheOffMode_WhenAMediumIsPicked_ThenThereIsNone', () {
      expect(mediumFor(AlbumAnimationMode.off, 1971), isNull);
    });

    test('GivenNoYear_WhenTheModeIsByYear_ThenItIsADisc', () {
      // Unchanged from `mediumForYear`: the medium a file most likely came
      // from, and the one an owner is least likely to find surprising.
      expect(mediumFor(AlbumAnimationMode.byYear, null), AlbumMedium.disc);
    });
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/playback/domain/album_medium_test.dart`
Expected: FAIL — `AlbumAnimationMode` and `mediumFor` do not exist.

- [ ] **Step 3: Add the mode to the domain**

In `lib/features/playback/domain/album_medium.dart`, beside `mediumForYear`:

```dart
/// What the owner chose the animation should show (FR-PL-11, UC-21).
///
/// The medium and the *choice of* medium are different things: [AlbumMedium]
/// is what is on screen, and this is how the application decided. Keeping them
/// apart is what lets the by-year rule stay one function that the pinned modes
/// simply do not call.
enum AlbumAnimationMode {
  /// The album's year decides, which is the default.
  byYear,

  /// Always a record.
  vinyl,

  /// Always a cassette.
  tape,

  /// Always a compact disc.
  disc,

  /// No animation at all.
  off;

  /// The mode [name] names, or `null` when it names none.
  ///
  /// Used to read a stored choice back, where an unrecognized value means the
  /// owner's preference is simply unknown and the default applies.
  static AlbumAnimationMode? byName(String? name) {
    for (final mode in AlbumAnimationMode.values) {
      if (mode.name == name) return mode;
    }
    return null;
  }
}

/// The medium [mode] shows for an album of [year], or `null` when the owner
/// has turned the animation off (FR-PL-11).
///
/// `null` rather than a medium plus a separate "is it on" flag: there is
/// exactly one question here — what, if anything, to draw — and a caller that
/// has to ask two of them is a caller that can get the answer half right.
AlbumMedium? mediumFor(AlbumAnimationMode mode, int? year) => switch (mode) {
  AlbumAnimationMode.byYear => mediumForYear(year),
  AlbumAnimationMode.vinyl => AlbumMedium.vinyl,
  AlbumAnimationMode.tape => AlbumMedium.tape,
  AlbumAnimationMode.disc => AlbumMedium.disc,
  AlbumAnimationMode.off => null,
};
```

- [ ] **Step 4: Persist it**

In `lib/core/settings/settings_store.dart`, beside `themeMode`:

```dart
  /// The animation the owner chose, or [AlbumAnimationMode.byYear] when they
  /// have not (FR-PL-11).
  AlbumAnimationMode get albumAnimationMode;

  /// Records [mode] for the next launch.
  Future<void> setAlbumAnimationMode(AlbumAnimationMode mode);
```

In `lib/core/settings/shared_preferences_settings_store.dart`, following exactly how `_themeModeKey` is declared, read and written:

```dart
  static const _albumAnimationKey = 'settings.albumAnimation';

  @override
  AlbumAnimationMode get albumAnimationMode =>
      AlbumAnimationMode.byName(_preferences.getString(_albumAnimationKey)) ??
      AlbumAnimationMode.byYear;

  @override
  Future<void> setAlbumAnimationMode(AlbumAnimationMode mode) =>
      _preferences.setString(_albumAnimationKey, mode.name);
```

Then fix every other `SettingsStore` implementation the analyzer names — the test tree has at least `test/support/in_memory_settings_store.dart` and `test/support/failing_settings_store.dart`, and both must implement the new pair the way they implement the theme pair.

- [ ] **Step 5: Carry it in preferences**

In `lib/features/shell/application/preferences_state.dart`, add to the `@freezed` factory:

```dart
    @Default(AlbumAnimationMode.byYear) AlbumAnimationMode albumAnimation,
```

Run: `dart run build_runner build --delete-conflicting-outputs`

In `preferences_controller.dart`, read it in `build` beside the theme and the locale:

```dart
      albumAnimation: settings?.albumAnimationMode ?? AlbumAnimationMode.byYear,
```

and add the setter, following `setThemeMode` exactly:

```dart
  /// Applies [mode] now and records it for the next launch (FR-PL-11).
  Future<void> setAlbumAnimation(AlbumAnimationMode mode) async {
    state = state.copyWith(albumAnimation: mode, lastChangeUnsaved: false);
    await _persist((settings) => settings.setAlbumAnimationMode(mode));
  }
```

- [ ] **Step 6: Add the strings**

`lib/core/l10n/app_en.arb`:

```json
  "animationLabel": "Album animation",
  "@animationLabel": {
    "description": "Group label in preferences for the medium the now-playing animation shows."
  },
  "animationByYear": "Match the album's year",
  "@animationByYear": {
    "description": "Animation preference: the album's release year picks the medium — vinyl, cassette or compact disc."
  },
  "animationVinyl": "Always vinyl",
  "@animationVinyl": {
    "description": "Animation preference: every album arrives on a record whatever its year."
  },
  "animationTape": "Always cassette",
  "@animationTape": {
    "description": "Animation preference: every album arrives on a cassette whatever its year."
  },
  "animationDisc": "Always compact disc",
  "@animationDisc": {
    "description": "Animation preference: every album arrives on a compact disc whatever its year."
  },
  "animationOff": "Off",
  "@animationOff": {
    "description": "Animation preference: no animation, and the player never opens itself."
  },
```

`lib/core/l10n/app_pt.arb`:

```json
  "animationLabel": "Animação do álbum",
  "animationByYear": "Seguir o ano do álbum",
  "animationVinyl": "Sempre vinil",
  "animationTape": "Sempre fita cassete",
  "animationDisc": "Sempre CD",
  "animationOff": "Desligada",
```

Run: `flutter gen-l10n`

- [ ] **Step 7: Offer it in the preferences dialog**

Add a third group to `preferences_dialog.dart`, built exactly like the theme and language groups already there — read that file and follow its `_GroupLabel` plus radio/segmented pattern rather than inventing a fourth control style. The five options are the five modes, labelled with the strings from step 6.

- [ ] **Step 8: Write the failing preferences test**

Add to `test/features/shell/presentation/preferences_dialog_test.dart`, using its existing `openFromShell` helper:

```dart
  group('the album animation (FR-PL-11)', () {
    testWidgets(
      'GivenPreferences_WhenTheyOpen_ThenEveryAnimationModeIsOffered',
      (tester) async {
        await openFromShell(tester);
        final l10n = AppLocalizations.of(tester.element(find.byType(PreferencesDialog)));

        for (final label in [
          l10n.animationByYear,
          l10n.animationVinyl,
          l10n.animationTape,
          l10n.animationDisc,
          l10n.animationOff,
        ]) {
          expect(find.text(label), findsOneWidget, reason: label);
        }
      },
    );

    testWidgets(
      'GivenPreferences_WhenAModeIsChosen_ThenItIsAppliedAndStored',
      (tester) async {
        await openFromShell(tester);
        final l10n = AppLocalizations.of(tester.element(find.byType(PreferencesDialog)));
        final container = ProviderScope.containerOf(
          tester.element(find.byType(PreferencesDialog)),
        );

        await tester.tap(find.text(l10n.animationVinyl));
        await tester.pumpAndSettle();

        expect(
          container.read(preferencesControllerProvider).albumAnimation,
          AlbumAnimationMode.vinyl,
        );
      },
    );
  });
```

Read the file first: if it already has a helper for reading the container or for asserting a stored preference, use that instead of the lines above.

- [ ] **Step 9: Run the tests, the suite, and analyze**

Run: `flutter test test/features/playback/domain test/features/shell && flutter test && flutter analyze`
Expected: PASS and "No issues found!".

- [ ] **Step 10: Commit**

```bash
git add lib test
git commit -m "feat: let the owner choose the album animation"
```

---

### Task 2: The palette

**Files:**
- Create: `lib/core/theme/album_palette.dart`
- Modify: `lib/core/theme/app_theme.dart`
- Test: `test/core/theme/album_palette_test.dart`

**Interfaces:**
- Consumes: `ThemeExtension`, the existing `PlaybackColors` as the pattern to follow.
- Produces: `class AlbumPalette extends ThemeExtension<AlbumPalette>` with `static const AlbumPalette standard`, registered in both themes, carrying every colour the artwork needs:
  `plinthTop`, `plinthBottom`, `plinthEdge`, `deckFaceTop`, `deckFaceBottom`, `chromeLight`, `chromeMid`, `chromeDark`, `wellDark`, `panelDark`, `panelEdge`, `matInner`, `matOuter`, `vinylSheenTop`, `vinylSheenBottom`, `groove`, `labelInk`, `labelPaper`, `discSheenA` … `discSheenE`, `discHub`, `discRing`, `shellTop`, `shellBottom`, `reelHub`, `reelTeeth`, `tapePack`, `tapeLabel`, `tapeLabelInk`, `glassTint`, `glassSheen`, `specular`, `contactShadow`, `displayInk`, `indicator`, and the sleeve palette `sleeveHues` (a `List<Color>` the jacket picks from).

- [ ] **Step 1: Write the failing test**

Create `test/core/theme/album_palette_test.dart`:

```dart
import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The colours the album artwork is painted in (FR-UX-07, BR-18).
void main() {
  test('GivenEitherTheme_WhenItIsBuilt_ThenTheAlbumPaletteIsAttached', () {
    // The painters read it off the theme; a theme without it would be a
    // crash on the first frame of the animation rather than a wrong colour.
    for (final brightness in Brightness.values) {
      final theme = AppTheme.of(brightness);

      expect(
        theme.extension<AlbumPalette>(),
        isNotNull,
        reason: brightness.name,
      );
    }
  });

  test('GivenTheTwoThemes_WhenTheirPalettesAreCompared_ThenTheyAgree', () {
    // Deliberate, and the same reasoning PlaybackColors records: a walnut
    // plinth is brown in both brightnesses. The devices are objects in a
    // room, not surfaces the theme tints.
    expect(
      AppTheme.of(Brightness.light).extension<AlbumPalette>(),
      AppTheme.of(Brightness.dark).extension<AlbumPalette>(),
    );
  });

  test('GivenThePalette_WhenTheSleeveHuesAreRead_ThenThereAreSeveral', () {
    // The jacket picks from these by the album's name; one colour would make
    // every record in the library look like the same record.
    expect(AlbumPalette.standard.sleeveHues.length, greaterThanOrEqualTo(6));
  });
}
```

`AppTheme.of(Brightness)` may not be that file's actual API — read `lib/core/theme/app_theme.dart` first and use whatever it really exposes to build each theme.

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/theme/album_palette_test.dart`
Expected: FAIL — `album_palette.dart` does not exist.

- [ ] **Step 3: Write the palette**

Create `lib/core/theme/album_palette.dart` following `playback_colors.dart` exactly in shape — a `@immutable` `ThemeExtension` with `copyWith`, `lerp`, `==` and `hashCode` — carrying the fields listed under **Interfaces** above as `Color` (and `sleeveHues` as `List<Color>`). Its doc comment says why it exists: BR-18 puts every colour in `lib/core/theme/`, and these are not Material scheme colours because they are the colours of *objects* — walnut, brushed aluminium, vinyl, magnetic tape — which do not change with the theme.

Pick the values from the agreed mockups. They are the reference for the artwork, and every painter reads them from here.

- [ ] **Step 4: Register it in both themes**

In `lib/core/theme/app_theme.dart`, add `AlbumPalette.standard` to the `extensions:` list of both themes, beside `PlaybackColors.standard`.

- [ ] **Step 5: Run the tests, the suite, and analyze**

Run: `flutter test test/core/theme && flutter test && flutter analyze`
Expected: PASS and "No issues found!".

- [ ] **Step 6: Commit**

```bash
git add lib test
git commit -m "feat: add the album artwork palette"
```

---

### Task 3: The media painters

The three things that move. Each painter takes its colours and a `turns` value, and draws only the medium.

**Files:**
- Create: `lib/features/playback/presentation/media/vinyl_painter.dart`, `cassette_painter.dart`, `disc_painter.dart`
- Test: `test/features/playback/presentation/media/media_painters_test.dart`
- Test: `test/features/playback/presentation/media/goldens/` (new images)

**Interfaces:**
- Consumes: `AlbumPalette`.
- Produces, each a `CustomPainter`:
  - `VinylPainter({required AlbumPalette palette, required double turns})`
  - `DiscPainter({required AlbumPalette palette, required double turns})`
  - `CassettePainter({required AlbumPalette palette, required double turns})` — rotates its **reels only**; the shell is drawn unrotated.
  - Each exposes `static const double aspect` (1 for the round media, 130/66 for the cassette) so the stage can size them.

**What each must draw.** The mockups are the reference; this is the layer list every painter owes:

| Painter | Still layers | Moving layers |
| --- | --- | --- |
| `VinylPainter` | The specular sweep across the whole record | Record body with its radial sheen, ~11 groove rings of varying opacity, the label with its printed arc and text bar, the spindle hole |
| `DiscPainter` | The specular sweep | Diffraction field, four fine ring highlights, the clear stacking ring, the data area, the hub, the bright arc that shows it turning |
| `CassettePainter` | Shell body with its top-to-bottom gradient, four screw dimples, the printed paper label, the window recess, the pressure pad, the tape path between the reels | Two reel hubs with six teeth each, and their tape packs — the left pack drawn larger than the right |

- [ ] **Step 1: Write the failing test**

Create `test/features/playback/presentation/media/media_painters_test.dart`:

```dart
import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/features/playback/presentation/media/cassette_painter.dart';
import 'package:alexandria_ui/features/playback/presentation/media/disc_painter.dart';
import 'package:alexandria_ui/features/playback/presentation/media/vinyl_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../flutter_test_config.dart';

/// The three media, painted (UC-21, FR-PL-07).
void main() {
  Widget painted(CustomPainter painter, Size size) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: RepaintBoundary(
        child: CustomPaint(size: size, painter: painter),
      ),
    ),
  );

  const palette = AlbumPalette.standard;

  group('what they look like', () {
    for (final (name, painter, size) in [
      ('vinyl', VinylPainter(palette: palette, turns: 0), const Size(240, 240)),
      ('disc', DiscPainter(palette: palette, turns: 0), const Size(240, 240)),
      ('cassette', CassettePainter(palette: palette, turns: 0), const Size(260, 132)),
    ]) {
      testWidgets(
        'GivenThe${name}Painter_WhenItIsDrawn_ThenItMatchesItsGolden',
        (tester) async {
          await tester.pumpWidget(painted(painter, size));

          await expectLater(
            find.byType(CustomPaint).last,
            matchesGoldenFile('goldens/$name.png'),
          );
        },
        skip: !goldensAreComparable,
      );
    }
  });

  group('what turning means', () {
    testWidgets(
      'GivenTheCassette_WhenItsReelsTurn_ThenItsShellDoesNot',
      (tester) async {
        // A cassette's reels turn inside a shell that does not move. The
        // whole-cassette rotation this replaces is the single most obviously
        // wrong thing about the animation it grew from.
        await tester.pumpWidget(
          painted(
            const CassettePainter(palette: palette, turns: 0.5),
            const Size(260, 132),
          ),
        );

        await expectLater(
          find.byType(CustomPaint).last,
          matchesGoldenFile('goldens/cassette-half-turn.png'),
        );
      },
      skip: !goldensAreComparable,
    );

    test('GivenAPainter_WhenOnlyItsTurnsChange_ThenItRepaints', () {
      // A painter that reported "no change" for a new angle would draw one
      // frame and then sit still while the controller ticked.
      const first = VinylPainter(palette: palette, turns: 0);
      const second = VinylPainter(palette: palette, turns: 0.25);

      expect(second.shouldRepaint(first), isTrue);
    });

    test('GivenAPainter_WhenNothingChanges_ThenItDoesNotRepaint', () {
      const painter = DiscPainter(palette: palette, turns: 0.25);

      expect(painter.shouldRepaint(painter), isFalse);
    });
  });
}
```

The import of `flutter_test_config.dart` is for `goldensAreComparable`; check the path is right from this test's directory and fix it if not.

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/playback/presentation/media/media_painters_test.dart`
Expected: FAIL — none of the three painters exist.

- [ ] **Step 3: Write the vinyl painter**

Create `lib/features/playback/presentation/media/vinyl_painter.dart`. This is the pattern the other two follow — the separation of still from moving, the exact `shouldRepaint`, and every colour from the palette:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/album_palette.dart';

/// A record, turning (UC-21, FR-PL-07).
///
/// Painted rather than shipped as an image because the part that turns has to
/// be separable from the part that does not: the specular sweep stays where
/// the light is while the grooves move underneath it, and that one detail is
/// most of what makes this read as a spinning object rather than a rotating
/// picture.
class VinylPainter extends CustomPainter {
  /// Creates the painter.
  const VinylPainter({required this.palette, required this.turns});

  /// The artwork's colours (FR-UX-07).
  final AlbumPalette palette;

  /// How far through a turn the record is, in whole turns.
  final double turns;

  /// The record is round, so it is drawn in a square.
  static const double aspect = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(turns * 2 * math.pi);
    canvas.translate(-centre.dx, -centre.dy);
    _paintTurning(canvas, centre, radius);
    canvas.restore();

    // Outside the rotation on purpose: a highlight that turned with the
    // record would be a mark painted on it.
    _paintSpecular(canvas, centre, radius);
  }

  void _paintTurning(Canvas canvas, Offset centre, double radius) {
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.vinylSheenTop, palette.vinylSheenBottom],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );

    // Rings rather than a spiral: at this size a spiral is a texture and
    // rings are what the eye reads as a record.
    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.011
      ..color = palette.groove;
    for (var ring = 0.50; ring < 0.96; ring += 0.042) {
      canvas.drawCircle(centre, radius * ring, groove);
    }

    canvas.drawCircle(centre, radius * 0.36, Paint()..color = palette.labelPaper);
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius * 0.27),
      -math.pi / 2,
      math.pi / 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.037
        ..color = palette.labelInk,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: centre.translate(0, radius * 0.11),
        width: radius * 0.46,
        height: radius * 0.03,
      ),
      Paint()..color = palette.labelInk,
    );
    canvas.drawCircle(centre, radius * 0.05, Paint()..color = palette.wellDark);
  }

  void _paintSpecular(Canvas canvas, Offset centre, double radius) {
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.34, -0.46),
          radius: 0.62,
          colors: [
            palette.specular,
            palette.specular.withValues(alpha: 0.04),
            palette.specular.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(VinylPainter oldDelegate) =>
      oldDelegate.turns != turns || oldDelegate.palette != palette;
}
```

- [ ] **Step 4: Write the disc and cassette painters**

Create `disc_painter.dart` and `cassette_painter.dart` in the same shape — the same constructor signature, the same still/moving split, the same exact `shouldRepaint` — drawing the layers named in the table above.

Two things they must get right, and which the tests check:

- The **disc's diffraction** is a sweep gradient through `palette.discSheenA`…`E` under the rotation, with the specular arc outside it.
- The **cassette rotates nothing but its reels**. Draw the shell, the label, the window and the tape path unrotated; rotate only each reel hub about its own centre. The left tape pack is drawn at a larger radius than the right, because a tape part-way through is wound onto one side.

- [ ] **Step 5: Generate the goldens and look at them**

Run: `flutter test test/features/playback/presentation/media/media_painters_test.dart --update-goldens`

Then open all four images. Each must look like the object it names, with the light coming from the same direction in all of them. The cassette at a half turn must show its reel teeth rotated and its shell, label and window in exactly the same place as at zero. An image that does not is a bug in the painter, not a golden to accept.

- [ ] **Step 6: Run the tests, the suite, and analyze**

Run: `flutter test && flutter analyze`
Expected: PASS and "No issues found!".

- [ ] **Step 7: Commit**

```bash
git add lib test
git commit -m "feat: paint the three album media"
```

---

### Task 4: The devices, the cases and the jacket

**Files:**
- Create: `lib/features/playback/presentation/media/turntable_painter.dart`, `tape_deck_painter.dart`, `cd_player_painter.dart`, `case_painter.dart`
- Create: `lib/features/playback/domain/sleeve_design.dart`
- Test: `test/features/playback/domain/sleeve_design_test.dart`
- Test: `test/features/playback/presentation/media/device_painters_test.dart` and its goldens

**Interfaces:**
- Consumes: `AlbumPalette`.
- Produces:
  - `int sleeveIndexFor(String? album, int hueCount)` — a stable index into `AlbumPalette.sleeveHues`, derived from the album's name; the same album always yields the same index, and a `null` or empty album yields a defined one.
  - `TurntablePainter({required AlbumPalette palette, required double closed})` — `closed` runs 0 (tonearm lifted away) to 1 (down on the record).
  - `TapeDeckPainter({required AlbumPalette palette, required double closed})` — `closed` slides the glass door down.
  - `CdPlayerPainter({required AlbumPalette palette, required double closed})` — `closed` shuts the lid.
  - `CasePainter({required AlbumPalette palette, required AlbumMedium medium, required Color sleeve, required String title, required String artist, required TextDirection direction})` — the jacket, the cassette case or the jewel case, with the album and artist typeset on it.

- [ ] **Step 1: Write the failing sleeve test**

Create `test/features/playback/domain/sleeve_design_test.dart`:

```dart
import 'package:alexandria_ui/features/playback/domain/sleeve_design.dart';
import 'package:flutter_test/flutter_test.dart';

/// The jacket the case shows until the core carries cover art (UC-21).
void main() {
  test('GivenAnAlbum_WhenItsSleeveIsPicked_ThenTheSameAlbumAlwaysMatches', () {
    // The point of deriving it: a record that looked different every time it
    // was played would read as a bug, not as a design.
    expect(sleeveIndexFor('OK Computer', 8), sleeveIndexFor('OK Computer', 8));
  });

  test('GivenTwoAlbums_WhenTheirSleevesArePicked_ThenTheyDifferInGeneral', () {
    // Not a guarantee for any given pair — a hash into eight buckets will
    // collide — but a library whose every sleeve came out the same colour
    // would mean the derivation was not deriving anything.
    final indexes = {
      for (final album in [
        'OK Computer', 'Kind of Blue', 'Hounds of Love', 'Dummy',
        'In Rainbows', 'Blue Lines', 'Loveless', 'Spiderland',
      ])
        sleeveIndexFor(album, 8),
    };

    expect(indexes.length, greaterThan(1));
  });

  test('GivenNoAlbumName_WhenASleeveIsPicked_ThenItIsStillInRange', () {
    for (final album in [null, '', '   ']) {
      final index = sleeveIndexFor(album, 8);

      expect(index, inInclusiveRange(0, 7), reason: '$album');
    }
  });

  test('GivenAnyAlbum_WhenASleeveIsPicked_ThenItIsInRange', () {
    for (final album in ['a', 'Z', '日本語', '🎵', 'a' * 500]) {
      expect(sleeveIndexFor(album, 8), inInclusiveRange(0, 7), reason: album);
    }
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/playback/domain/sleeve_design_test.dart`
Expected: FAIL — `sleeve_design.dart` does not exist.

- [ ] **Step 3: Write the sleeve derivation**

Create `lib/features/playback/domain/sleeve_design.dart`:

```dart
/// Which jacket colour an album gets (UC-21).
///
/// The core carries no cover art for audio, so the case shows a designed
/// jacket instead of an empty square. Derived from the album's own name rather
/// than picked at random, because a record whose sleeve changed colour between
/// two plays would read as a bug — and derived rather than stored, because
/// there is nothing here worth a row in a settings file.
///
/// Replaced wholesale when the core starts answering with the picture the file
/// usually already contains; nothing else about the case changes then.
int sleeveIndexFor(String? album, int hueCount) {
  final name = album?.trim() ?? '';

  // An unnamed album is not an error and gets a colour like any other. The
  // first one, deliberately: every untitled record looking alike is right,
  // because as far as the catalog knows they are alike.
  if (name.isEmpty) return 0;

  // FNV-1a: stable across runs and platforms, which `hashCode` is not
  // promised to be — and this value decides what the owner sees.
  var hash = 0x811c9dc5;
  for (final unit in name.toLowerCase().codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }

  return hash % hueCount;
}
```

- [ ] **Step 4: Write the device and case painters**

Create the four painters. Each takes `palette` and its own parameters, splits still from moving exactly as Task 3's do, and declares an exact `shouldRepaint`. What each owes, with the mockups as the reference:

| Painter | Layers |
| --- | --- |
| `TurntablePainter` | Plinth with a top-to-bottom wood gradient, a lit top edge and two feet; platter well; rubber mat with its radial gradient and eight strobe dots; spindle; power indicator and the 33 and 45 buttons; **moving:** the tonearm assembly — pivot, counterweight, chrome tube, headshell, cartridge and stylus — rotating about its pivot by `closed` |
| `TapeDeckPainter` | Brushed face with its four-stop gradient and lit top edge; VU meter recess with its two needles and scale; four transport buttons with their glyphs; the well; **moving:** the glass door, tinted and with a diagonal sheen, sliding down by `closed` |
| `CdPlayerPainter` | Brushed face; display recess with the track and time in the indicator colour; three transport buttons; the disc well and its hub; **moving:** the lid dropping by `closed` |
| `CasePainter` | The medium's case shape — a square jacket, a taller cassette case, a jewel case with its hinge spine — filled with `sleeve`, with a lit top edge, a drop shadow behind it, the album title wrapped over up to two lines, a rule beneath it, and the artist below |

`CasePainter` needs `TextPainter` for the two strings. Take the `TextDirection` from the caller rather than assuming `ltr`, and lay the title out with `maxLines: 2` and `TextOverflow.ellipsis` so a long album name cannot overflow the jacket.

- [ ] **Step 5: Write the device golden test**

Create `test/features/playback/presentation/media/device_painters_test.dart` in the same shape as Task 3's, with a golden per device at `closed: 0` and at `closed: 1`, and one per case. Its group doc says what the two states mean: a device open and waiting, and a device closed on its medium.

- [ ] **Step 6: Generate the goldens and look at them**

Run: `flutter test test/features/playback/presentation/media/device_painters_test.dart --update-goldens`

Open every image. The three devices must look like they are lit from the same direction and belong in the same room; the case must be readable at its drawn size. Say in the task report what you saw.

- [ ] **Step 7: Run the tests, the suite, and analyze**

Run: `flutter test && flutter analyze`
Expected: PASS and "No issues found!".

- [ ] **Step 8: Commit**

```bash
git add lib test
git commit -m "feat: paint the devices, the cases and the jacket"
```

---

### Task 5: The stage

The two timelines over the painters: a one-shot insertion, then a continuous spin.

**Files:**
- Create: `lib/features/playback/presentation/album_stage.dart`
- Test: `test/features/playback/presentation/album_stage_test.dart` and its goldens

**Interfaces:**
- Consumes: every painter from Tasks 3 and 4, `AlbumMedium`, `AlbumPalette`, `sleeveIndexFor`.
- Produces: `class AlbumStage extends StatefulWidget` —
  `const AlbumStage({required AlbumMedium medium, required bool isPlaying, required bool insert, required String title, required String artist, required String? album, double size = 420, VoidCallback? onInserted, super.key})`.
  `insert` true plays the insertion once on mount and then spins; false starts already seated and spinning. `onInserted` fires when the insertion finishes.

- [ ] **Step 1: Write the failing test**

Create `test/features/playback/presentation/album_stage_test.dart`:

```dart
import 'package:alexandria_ui/core/theme/album_palette.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:alexandria_ui/features/playback/presentation/album_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../flutter_test_config.dart';

/// The insertion and the spin (UC-21 main flow, FR-PL-07).
void main() {
  Widget staged({
    required AlbumMedium medium,
    required bool insert,
    bool isPlaying = true,
    bool reduceMotion = false,
  }) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: MaterialApp(
      theme: ThemeData(extensions: const [AlbumPalette.standard]),
      home: Scaffold(
        body: Center(
          child: AlbumStage(
            medium: medium,
            isPlaying: isPlaying,
            insert: insert,
            title: 'Paranoid Android',
            artist: 'Radiohead',
            album: 'OK Computer',
          ),
        ),
      ),
    ),
  );

  group('the insertion (main flow steps 2 and 3)', () {
    testWidgets(
      'GivenAnInsertion_WhenItBegins_ThenTheCaseIsShownAndTheDeviceIsOpen',
      (tester) async {
        await tester.pumpWidget(staged(medium: AlbumMedium.disc, insert: true));
        await tester.pump(const Duration(milliseconds: 700));

        await expectLater(
          find.byType(AlbumStage),
          matchesGoldenFile('goldens/insertion-begins.png'),
        );
      },
      skip: !goldensAreComparable,
    );

    testWidgets(
      'GivenAnInsertion_WhenItFinishes_ThenTheCaseIsGoneAndTheDeviceIsClosed',
      (tester) async {
        await tester.pumpWidget(staged(medium: AlbumMedium.disc, insert: true));
        await tester.pump(const Duration(milliseconds: 4400));

        await expectLater(
          find.byType(AlbumStage),
          matchesGoldenFile('goldens/insertion-ends.png'),
        );
      },
      skip: !goldensAreComparable,
    );

    testWidgets(
      'GivenAnInsertion_WhenItFinishes_ThenItSaysSo',
      (tester) async {
        // The screen has to know: it is what decides that the next track of
        // the same record does not get another insertion.
        var done = false;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(),
            child: MaterialApp(
              theme: ThemeData(extensions: const [AlbumPalette.standard]),
              home: Scaffold(
                body: AlbumStage(
                  medium: AlbumMedium.vinyl,
                  isPlaying: true,
                  insert: true,
                  title: 'Airbag',
                  artist: 'Radiohead',
                  album: 'OK Computer',
                  onInserted: () => done = true,
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 4500));

        expect(done, isTrue);
      },
    );

    testWidgets(
      'GivenNoInsertionIsOwed_WhenTheStageOpens_ThenTheMediumIsAlreadySeated',
      (tester) async {
        // Skipping to the next track of a record already on the platter does
        // not take it off and put it back.
        await tester.pumpWidget(staged(medium: AlbumMedium.vinyl, insert: false));
        await tester.pump(const Duration(milliseconds: 16));

        await expectLater(
          find.byType(AlbumStage),
          matchesGoldenFile('goldens/seated.png'),
        );
      },
      skip: !goldensAreComparable,
    );
  });

  group('the spin (main flow steps 4 and 5)', () {
    testWidgets(
      'GivenAPlayingStage_WhenTimePasses_ThenTheMediumHasTurned',
      (tester) async {
        await tester.pumpWidget(staged(medium: AlbumMedium.vinyl, insert: false));
        await tester.pump(const Duration(milliseconds: 16));
        final first = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byType(AlbumStage),
            matching: find.byType(CustomPaint),
          ).last,
        );

        await tester.pump(const Duration(milliseconds: 400));
        final later = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byType(AlbumStage),
            matching: find.byType(CustomPaint),
          ).last,
        );

        expect(later.painter, isNot(equals(first.painter)));
      },
    );

    testWidgets(
      'GivenAPausedStage_WhenTimePasses_ThenItHoldsWhereItStopped',
      (tester) async {
        // Held, not reset: the record stays where the needle left it.
        await tester.pumpWidget(
          staged(medium: AlbumMedium.vinyl, insert: false, isPlaying: false),
        );
        await tester.pump(const Duration(milliseconds: 16));

        await expectLater(
          find.byType(AlbumStage),
          matchesGoldenFile('goldens/paused.png'),
        );

        await tester.pump(const Duration(milliseconds: 900));

        await expectLater(
          find.byType(AlbumStage),
          matchesGoldenFile('goldens/paused.png'),
        );
      },
      skip: !goldensAreComparable,
    );
  });

  group('reduced motion (AF-04)', () {
    testWidgets(
      'GivenReducedMotion_WhenTheStageOpens_ThenTheMediumIsSeatedAndStill',
      (tester) async {
        await tester.pumpWidget(
          staged(medium: AlbumMedium.tape, insert: true, reduceMotion: true),
        );
        await tester.pump(const Duration(milliseconds: 16));

        await expectLater(
          find.byType(AlbumStage),
          matchesGoldenFile('goldens/reduced-motion.png'),
        );

        // No ticker may be running: a controller repeating under a still
        // medium burns a frame's work every frame for something nobody sees.
        expect(tester.binding.hasScheduledFrame, isFalse);
      },
      skip: !goldensAreComparable,
    );
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/playback/presentation/album_stage_test.dart`
Expected: FAIL — `album_stage.dart` does not exist.

- [ ] **Step 3: Write the stage**

Create `lib/features/playback/presentation/album_stage.dart`. Its shape:

- Two `AnimationController`s: `_insertion` (4.4s, one shot) and `_spin` (per-medium period, repeating).
- On mount: if reduced motion or `insert` is false, `_insertion` is left at 1 and never run; otherwise `_insertion.forward()`, and `onInserted` fires on completion.
- `_spin` repeats only while `isPlaying` and motion is allowed; stopping it holds its value, which is what "frozen where it is" means. `didUpdateWidget` starts and stops it as `isPlaying` changes.
- A `Stack` of three layers, each in its own `RepaintBoundary`: the device painter (driven by the insertion's `closed` curve), the medium (positioned and scaled along the insertion's path, rotated by `_spin`), and the case (positioned and faded along the insertion's path).
- The beat boundaries from **Reference values** are `Interval`s on `_insertion`.
- A `Semantics` label naming the medium, as `AlbumAnimation` already does — reuse `l10n.albumMediumVinyl` and its siblings.

Delete `lib/features/playback/presentation/album_animation.dart` and its test once nothing imports them; `AlbumStage` replaces it whole.

- [ ] **Step 4: Generate the goldens and look at them**

Run: `flutter test test/features/playback/presentation/album_stage_test.dart --update-goldens`

Open all six. `insertion-begins` must show the case and an open device; `insertion-ends` and `seated` must show a closed device with no case; `paused` and `reduced-motion` must show a seated medium. Report what you saw.

- [ ] **Step 5: Run the tests, the suite, and analyze**

Run: `flutter test && flutter analyze`
Expected: PASS and "No issues found!".

- [ ] **Step 6: Commit**

```bash
git add lib test
git commit -m "feat: stage the album insertion and spin"
```

---

### Task 6: Whether an insertion is owed

**Files:**
- Create: `lib/features/playback/application/album_animation_controller.dart`
- Modify: `lib/core/di/providers.dart`
- Test: `test/features/playback/application/album_animation_controller_test.dart`

**Interfaces:**
- Consumes: `audioPlaybackControllerProvider`, `preferencesControllerProvider`, `PlaybackQueue` (`kind`, `label`, `year`), `mediumFor`.
- Produces:
  - `class AlbumAnimationState { final AlbumMedium? medium; final bool insertionOwed; }`
  - `class AlbumAnimationController extends Notifier<AlbumAnimationState>` with `void insertionShown()` — called when the stage finishes, so the next track of the same record does not get another.
  - `albumAnimationControllerProvider`.

The rule: an insertion is owed when nothing has been shown yet this session, or when the queue's `(kind, label)` differs from the one the last insertion was shown for. A track change within the same album leaves both equal and owes nothing.

- [ ] **Step 1: Write the failing test**

Create `test/features/playback/application/album_animation_controller_test.dart`:

```dart
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/playback/application/album_animation_controller.dart';
import 'package:alexandria_ui/features/playback/domain/album_medium.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/test_container.dart';

/// Whether the medium has to be put in again (UC-21 main flow step 2).
void main() {
  // Build the container and drive playback the way this suite's siblings do —
  // read `test/features/playback/presentation/audio_player_test.dart` first
  // and reuse its fixture helpers rather than writing a second set.

  test(
    'GivenNothingHasPlayed_WhenTheFirstTrackStarts_ThenAnInsertionIsOwed',
    () async {
      // The session's first play, which is what the brainstorm asked always
      // shows the animation.
    },
  );

  test(
    'GivenARecordIsPlaying_WhenTheNextTrackOfItStarts_ThenNoInsertionIsOwed',
    () async {
      // A record already on the platter is not taken off and put back for its
      // next track.
    },
  );

  test(
    'GivenARecordIsPlaying_WhenAnotherAlbumStarts_ThenAnInsertionIsOwed',
    () async {},
  );

  test(
    'GivenAnArtistIsPlaying_WhenAnotherArtistStarts_ThenAnInsertionIsOwed',
    () async {},
  );

  test(
    'GivenAnInsertionWasShown_WhenItIsAcknowledged_ThenNoneIsOwed',
    () async {},
  );

  test(
    'GivenTheModeIsOff_WhenAnythingPlays_ThenThereIsNoMediumAndNothingIsOwed',
    () async {},
  );

  test(
    'GivenAPinnedMode_WhenAnAlbumOfAnotherEraPlays_ThenTheMediumIsThePinnedOne',
    () async {},
  );
}
```

Fill each body in as you write the controller — the names and the comments are the specification, and every one must be able to fail for the reason its name claims. Do not leave a body empty.

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/playback/application/album_animation_controller_test.dart`
Expected: FAIL — the controller does not exist.

- [ ] **Step 3: Write the controller**

Create `lib/features/playback/application/album_animation_controller.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/album_medium.dart';

/// What the animation should be showing, and whether it owes an insertion
/// (UC-21 main flow step 2, FR-PL-07, FR-PL-11).
class AlbumAnimationState {
  /// Creates a state.
  const AlbumAnimationState({this.medium, this.insertionOwed = false});

  /// The medium to draw, or `null` when the owner turned the animation off.
  final AlbumMedium? medium;

  /// Whether the medium has to be put into its device before it turns.
  final bool insertionOwed;
}

/// Whether the medium has to go in again (UC-21 main flow step 2).
///
/// An insertion is owed on the session's first play, and whenever the album or
/// the artist changes — never between the tracks of one record, which is what
/// a record already on the platter does not need. The queue's kind and label
/// are what say which record is playing: two queues with the same pair are the
/// same record continuing.
class AlbumAnimationController extends Notifier<AlbumAnimationState> {
  /// What the last insertion was shown for, as `(kind, label)`.
  ///
  /// `null` until one has been shown, which is what makes the session's first
  /// play owe one.
  (Object, String?)? _shownFor;

  @override
  AlbumAnimationState build() {
    final queue = ref.watch(audioPlaybackControllerProvider).queue;
    final mode = ref.watch(preferencesControllerProvider).albumAnimation;
    final medium = mediumFor(mode, queue.year);

    if (medium == null || queue.isEmpty) {
      return const AlbumAnimationState();
    }

    return AlbumAnimationState(
      medium: medium,
      insertionOwed: _shownFor != (queue.kind, queue.label),
    );
  }

  /// Records that the insertion for what is playing has been shown.
  void insertionShown() {
    final queue = ref.read(audioPlaybackControllerProvider).queue;
    _shownFor = (queue.kind, queue.label);
    state = AlbumAnimationState(medium: state.medium);
  }
}
```

Bind `albumAnimationControllerProvider` in `lib/core/di/providers.dart` beside the other playback providers.

- [ ] **Step 4: Run the tests, the suite, and analyze**

Run: `flutter test && flutter analyze`
Expected: PASS and "No issues found!".

- [ ] **Step 5: Commit**

```bash
git add lib test
git commit -m "feat: decide when the medium goes in again"
```

---

### Task 7: The now-playing screen

**Files:**
- Create: `lib/features/playback/presentation/now_playing_screen.dart`
- Delete: `lib/features/playback/presentation/album_player_screen.dart`
- Modify: `lib/features/shell/presentation/playback_bar.dart` (its open-player button)
- Modify: `test/features/playback/presentation/album_animation_test.dart` → renamed to `now_playing_screen_test.dart`
- Modify: `lib/core/l10n/app_en.arb`, `app_pt.arb` (if the screen needs a string the dialog did not)

**Interfaces:**
- Consumes: `AlbumStage`, `albumAnimationControllerProvider`, `audioPlaybackControllerProvider`, `musicTitleForFile`, `queueLabelOf`.
- Produces: `class NowPlayingScreen extends ConsumerWidget` with `static Future<void> show(BuildContext context)` — pushes the full-window route.

- [ ] **Step 1: Write the failing test**

Rename `album_animation_test.dart` to `now_playing_screen_test.dart` and rewrite its group headers for the new screen, keeping every assertion about playback behaviour that still holds. Add:

```dart
  testWidgets(
    'GivenSomethingPlaying_WhenThePlayerIsOpened_ThenItFillsTheWindow',
    (tester) async {
      // A dialog cannot give the animation the room it needs, which is why
      // this stopped being one.
      await playSomething(tester);
      await tester.tap(find.byIcon(Icons.expand_less));
      await tester.pumpAndSettle();

      expect(find.byType(NowPlayingScreen), findsOneWidget);
      expect(
        tester.getSize(find.byType(NowPlayingScreen)).width,
        tester.getSize(find.byType(MaterialApp)).width,
      );
    },
  );

  testWidgets(
    'GivenThePlayerIsOpen_WhenItIsClosed_ThenTheQueueAndTheBarAreUntouched',
    (tester) async {
      // AF-03: closing the player is not stopping playback.
      final container = await playSomething(tester);
      await tester.tap(find.byIcon(Icons.expand_less));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(closeLabel(tester)));
      await tester.pumpAndSettle();

      expect(container.read(audioPlaybackControllerProvider).isPlaying, isTrue);
      expect(find.byType(PlaybackBar), findsOneWidget);
    },
  );

  testWidgets(
    'GivenTheAnimationIsOff_WhenThePlayerIsOpened_ThenNoStageIsShown',
    (tester) async {
      // FR-PL-11: off means off, on every surface.
      await playSomething(tester, mode: AlbumAnimationMode.off);
      await tester.tap(find.byIcon(Icons.expand_less));
      await tester.pumpAndSettle();

      expect(find.byType(AlbumStage), findsNothing);
      expect(find.byType(NowPlayingScreen), findsOneWidget);
    },
  );
```

Write `playSomething` and `closeLabel` to match the helpers the file already has.

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/playback/presentation/now_playing_screen_test.dart`
Expected: FAIL — `NowPlayingScreen` does not exist.

- [ ] **Step 3: Write the screen**

Create `lib/features/playback/presentation/now_playing_screen.dart`. Its shape:

- `static Future<void> show(BuildContext context)` pushes a `MaterialPageRoute` (a full-window route, not a dialog).
- A `Scaffold` whose body is a `Column`: the `AlbumStage` centred and given the largest square the window allows short of crowding the text, then the track title from `musicTitleForFile`, then the album or artist from `queueLabelOf`, then the transport controls the dialog already had — previous, play/pause, next — at a larger size.
- The stage's `medium` and `insert` come from `albumAnimationControllerProvider`; `onInserted` calls `insertionShown()`.
- When the state's `medium` is `null` — the mode is off — no stage is built at all, and the screen is the metadata and the controls.
- A close control, and the route pops on it.

Then point the playback bar's open-player button at `NowPlayingScreen.show` and delete `album_player_screen.dart`.

- [ ] **Step 4: Auto-open on an owed insertion**

The screen opens itself when playback starts something that owes an insertion. Put that where playback is started from — a listener on `albumAnimationControllerProvider` in the shell, so every way of starting audio gets it and no call site has to remember. It must not open when the mode is off, and it must not open for a track change within a record.

Cover it:

```dart
  testWidgets(
    'GivenNothingHasPlayed_WhenATrackIsStarted_ThenThePlayerOpensItself',
    (tester) async {},
  );

  testWidgets(
    'GivenARecordIsPlaying_WhenTheNextTrackStarts_ThenThePlayerDoesNotOpen',
    (tester) async {},
  );

  testWidgets(
    'GivenTheAnimationIsOff_WhenATrackIsStarted_ThenThePlayerDoesNotOpen',
    (tester) async {},
  );
```

Fill the bodies in as you implement; each must fail for the reason its name claims.

- [ ] **Step 5: Run the tests, the suite, and analyze**

Run: `flutter test && flutter analyze`
Expected: PASS and "No issues found!". Some shell goldens may move because the bar's button now opens a route; regenerate only after looking at what changed.

- [ ] **Step 6: Commit**

```bash
git add lib test
git commit -m "feat: give the player the whole window"
```

---

### Task 8: The visor

**Files:**
- Create: `lib/features/playback/presentation/album_visor.dart`
- Modify: `lib/features/shell/presentation/playback_bar.dart`
- Test: `test/features/playback/presentation/album_visor_test.dart`
- Modify: `test/features/shell/presentation/goldens/*.png` if the bar's height changes

**Interfaces:**
- Consumes: the three media painters, `albumAnimationControllerProvider`, `audioPlaybackControllerProvider`.
- Produces: `class AlbumVisor extends ConsumerStatefulWidget` — `const AlbumVisor({double size = 64, super.key})`. Draws the same medium at the same rate as the stage, in a recessed window; renders nothing when the mode is off or nothing is playing.

- [ ] **Step 1: Write the failing test**

Create `test/features/playback/presentation/album_visor_test.dart` with:

- `GivenSomethingPlaying_WhenTheBarIsShown_ThenTheVisorShowsItsMedium` — the visor is in the bar and draws the medium the state names.
- `GivenTheAnimationIsOff_WhenTheBarIsShown_ThenThereIsNoVisor`.
- `GivenNothingPlaying_WhenTheBarIsShown_ThenThereIsNoVisor`.
- `GivenAPausedTrack_WhenTimePasses_ThenTheVisorHoldsWhereItStopped` — a golden pumped twice, as Task 5's paused test does.
- `GivenReducedMotion_WhenTheVisorIsShown_ThenItIsStill` — and `hasScheduledFrame` is false.

Write the bodies out in full, following Task 5's test file for how to build a themed host and how to assert a held frame.

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/playback/presentation/album_visor_test.dart`
Expected: FAIL — `album_visor.dart` does not exist.

- [ ] **Step 3: Write the visor**

Create `lib/features/playback/presentation/album_visor.dart`: a `size`-square recess — dark fill, a one-pixel border in the palette's panel edge, an inner shadow, and a diagonal glass sheen over the top — containing the medium's painter driven by its own repeating controller at the same period the stage uses. Reduced motion and pause hold it exactly as the stage does.

Put it at the left of the playback bar's row, before the track title, replacing the bare `Icon(Icons.music_note)` that is there now.

- [ ] **Step 4: Check the bar's height at the minimum window**

The visor is 64 logical pixels and the bar was shorter. Run the shell golden suite and look at what moved:

Run: `flutter test test/features/shell/presentation/shell_screen_golden_test.dart`

If the images fail, regenerate them and LOOK: the bar is taller, and that has to still leave the content area usable at the 1024×640 minimum (NFR-07). If it does not, the visor shrinks — say so in the report rather than accepting a cramped shell.

- [ ] **Step 5: Run the tests, the suite, and analyze**

Run: `flutter test && flutter analyze`
Expected: PASS and "No issues found!".

- [ ] **Step 6: Commit**

```bash
git add lib test
git commit -m "feat: show the turning medium in the bar"
```

---

### Task 9: The requirements, and the whole thing on a screen

**Files:**
- Modify: `docs/requirements/System Requirements Document.md`
- Modify: `docs/requirements/Use Case Specification Document.md` (UC-21)

- [ ] **Step 1: Amend FR-PL-07**

It currently reads: *"The system shall display, for the duration of album or artist playback, an animation of a disc, vinyl record, or tape on its matching player, which turns while audio plays and stops while it is paused."*

Rewrite it so it is true of what was built: the medium is drawn on its device; it is taken from its case and inserted on the session's first play and whenever the album or artist changes; it turns while audio plays and holds its position while paused; and the same medium is shown in the playback bar. Keep the register of the requirements around it.

- [ ] **Step 2: Add FR-PL-11**

```md
| FR-PL-11 | The system shall let the owner choose the medium the album animation shows — by the album's release year, pinned to one medium, or off — and shall show no animation and open no player while it is off. |
```

Then add it to every traceability table that lists FR-PL-10, the way FR-PL-09 and FR-PL-10 appear in them. Search the document for all of them.

- [ ] **Step 3: Amend UC-21**

Read UC-21 and add to its main flow: the player opening itself when an insertion is owed, and the insertion itself as the step before the medium turns. Add an alternative flow for the mode being off. Leave AF-03 and AF-04 alone — closing the player and reduced motion are unchanged.

- [ ] **Step 4: Run the whole suite**

Run: `flutter test && flutter analyze`
Expected: PASS and "No issues found!".

- [ ] **Step 5: Commit**

```bash
git add docs
git commit -m "docs: specify the now-playing animation"
```

- [ ] **Step 6: Run the application and watch it**

Run: `flutter run -d windows`

Play a record. Watch the insertion at full size, on a real window, and then watch it spin for a minute. Check: the light falls the same way on all three devices; the case is readable; the medium seats rather than lands; pausing freezes it rather than snapping it; the visor keeps time with the screen; and switching the mode in preferences changes what arrives next. This is the step the whole plan is for — a stage that passes every test and looks wrong is a finding to report, not a task to tick.

---

## Self-Review

**Spec coverage**

| Spec section | Task |
| --- | --- |
| §1 The player becomes a full-window route | 7 |
| §2 The insertion, six beats | 5 |
| §3 When the insertion plays, and the auto-open | 6, 7 |
| §4 The spin, three rates, held on pause | 3, 5 |
| §5 The visor | 8 |
| §6 The artwork, layered, palette in the theme | 2, 3, 4 |
| §7 The sleeve and the designed jacket | 4 |
| §8 The setting, five modes | 1 |
| §9 Reduced motion | 5, 8 |
| Requirements impact | 9 |
| Testing | 1–8, with the manual watch in 9 |

**Placeholders:** the artwork tasks (3, 4) specify each painter by its layer list rather than by a full listing, with one painter written out in full as the pattern every other follows. That is deliberate: a painter's body is artwork, and a plan that dictated every gradient stop would be worse art and a worse plan. Every *behaviour* — the still/moving split, the exact `shouldRepaint`, the palette-only colours, what each golden must show — is specified. Tasks 6, 7 and 8 name tests whose bodies the implementer fills in; each carries its name and its reason, and the step says explicitly that no body may be left empty.

**Type consistency:** `AlbumAnimationMode` and `mediumFor` (Task 1) are used in Tasks 6, 7, 8. `AlbumPalette` (Task 2) is the sole colour source for Tasks 3 and 4. The painters' constructors (`palette` + `turns`, `palette` + `closed`) are consumed by `AlbumStage` (Task 5) and `AlbumVisor` (Task 8). `AlbumStage`'s `insert`/`onInserted` pair (Task 5) is driven by `AlbumAnimationState.insertionOwed` and `insertionShown()` (Task 6) from `NowPlayingScreen` (Task 7). `sleeveIndexFor(String?, int)` (Task 4) indexes `AlbumPalette.sleeveHues` (Task 2).
