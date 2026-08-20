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
/// UC-28 then filled bookmarks, as that note predicted, and there is no
/// single-line destination left to move to: every other one is a file type
/// with a listing. Bookmarks stays, because with none saved it is the
/// emptiest area there is — one button and one sentence — and the images were
/// regenerated for it. If it grows, the next place to look is a file type
/// with an empty library.
///
/// Regenerate with `flutter test --update-goldens`, and look at the images.
void main() {
  const surfaces = <String, Size>{
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
