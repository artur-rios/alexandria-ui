import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/theme/breakpoints.dart';
import 'package:alexandria_desktop/features/shell/domain/shell_destination.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/shell_harness.dart';

/// The theme and layout of the shell (Testing Specification §7.1).
///
/// The key screen by definition: it frames every other one, so a spacing or
/// colour regression here is a regression everywhere. Captured at the medium
/// tier, where the navigation panel is labelled, and again at the minimum
/// supported window, where it collapses to icons — the two layouts FR-UX-02
/// promises, which a single image would not tell apart.
///
/// Captured on a destination whose content is a single line, rather than on
/// home. What this golden asserts is the frame: the panel, the theme's
/// colours, the spacing between them. The content inside the frame belongs to
/// whichever use case built it and is covered by that use case's own tests —
/// and letting it into the image makes this golden fail for reasons that have
/// nothing to do with the shell.
///
/// That is not hypothetical. These four goldens ran at 0.186% against Linux
/// for as long as home was one line of placeholder text; UC-14 filled it with
/// the dashboard's first-run block and they went to 0.59%, past the 0.5%
/// tolerance, on antialiasing alone. Text is what rasterizes differently
/// across platforms, so the more text a golden holds the less of its budget is
/// left for the regressions it exists to catch.
///
/// UC-28 then filled bookmarks, as that note predicted, and the goldens moved
/// to it as the emptiest area there was. UC-28's collection filing has since
/// added a filter beside the add button, so the images were regenerated
/// again. The panel has since grown a library-tools button beside preferences
/// and an extended arrangement at the widest tier, and the bookmarks area has
/// lost the catalog search field it could not answer — all three visible in
/// these images.
///
/// That note's advice — move to a file type with an empty library — was tried
/// and rejected on the evidence: an empty `music` renders a heading, a search
/// field, an add-folder link, a layout bar, and the empty sentence, which is
/// more text than bookmarks carries, not less. Bookmarks remains the emptiest
/// area there is. If it grows again, the honest next step is a golden that
/// masks the content area rather than another destination to move to.
///
/// Regenerate with `flutter test --update-goldens`, and look at the images.
void main() {
  const surfaces = <String, Size>{
    // The three arrangements FR-UX-02 promises: labels beside the icons,
    // labels beneath them, and icons with tooltips. The expanded tier had no
    // image because it had no behaviour of its own; it has both now.
    'expanded': Size(1700, 1000),
    'medium': Size(1280, 800),
    'minimum': Breakpoint.minimumWindowSize,
  };

  for (final surface in surfaces.entries) {
    for (final (name, mode) in [
      ('Light', ThemeMode.light),
      ('Dark', ThemeMode.dark),
    ]) {
      testWidgets(
        'GivenThe${name}ThemeAtThe${surface.key}Window_WhenTheShellOpens_ThenItMatchesItsGolden',
        (tester) async {
          final container = await tester.pumpShell(
            themeMode: mode,
            surfaceSize: surface.value,
          );

          container
              .read(shellControllerProvider.notifier)
              .go(ShellDestination.bookmarks);
          await tester.pumpAndSettle();

          await expectLater(
            find.byType(ShellScreen),
            matchesGoldenFile('goldens/shell_${surface.key}_${mode.name}.png'),
          );
        },
      );
    }
  }
}
