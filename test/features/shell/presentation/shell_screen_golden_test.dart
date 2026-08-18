import 'package:alexandria_desktop/core/theme/breakpoints.dart';
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
          await tester.pumpShell(themeMode: mode, surfaceSize: surface.value);

          await expectLater(
            find.byType(ShellScreen),
            matchesGoldenFile('goldens/shell_${surface.key}_${mode.name}.png'),
          );
        },
      );
    }
  }
}
