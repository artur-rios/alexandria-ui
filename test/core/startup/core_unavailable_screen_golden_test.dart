import 'package:alexandria_ui/core/startup/core_unavailable_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/login_harness.dart';

/// The theme and layout of the core-unavailable state (Testing Specification
/// §7.1).
///
/// A key screen by the same measure as the authentication ones: it is the
/// first thing an owner sees when the core will not load, and it is the one
/// screen whose whole job is to be readable when something has gone wrong. Its
/// error colouring is also the most likely thing to go unnoticed in a theme
/// change, because nobody looks at it in a working build.
///
/// Regenerate with `flutter test --update-goldens`, and look at the images.
void main() {
  const surface = Size(1280, 800);

  for (final (name, mode) in [
    ('Light', ThemeMode.light),
    ('Dark', ThemeMode.dark),
  ]) {
    testWidgets(
      'GivenThe${name}Theme_WhenTheCoreIsUnavailable_ThenItMatchesItsGolden',
      (tester) async {
        await tester.pumpFailedStartup(themeMode: mode, surfaceSize: surface);

        await expectLater(
          find.byType(CoreUnavailableScreen),
          matchesGoldenFile('goldens/core_unavailable_${mode.name}.png'),
        );
      },
    );
  }
}
