import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_gateway.dart';
import 'login_harness.dart';

/// Drives the shell through the real application root.
///
/// The shell is reached the way the owner reaches it — startup settles, the
/// login screen appears, and a successful sign-in replaces it — rather than by
/// pumping the shell on its own. That is what makes these tests cover the
/// wiring in `app.dart` as well as the shell itself, and it is the same
/// approach the authentication screens' tests take.
extension PumpShell on WidgetTester {
  /// Signs in and lands on the shell.
  ///
  /// [surfaceSize] is applied to the view as well as to the render surface.
  /// `setSurfaceSize` alone changes what is rasterized but leaves
  /// `MediaQuery.sizeOf` reporting the default 800 × 600 test window, and the
  /// shell reads exactly that to pick its breakpoint — so a rail asserted to
  /// be collapsed would be collapsed because the test window is small, not
  /// because the layout adapts. The device pixel ratio is pinned to 1 so the
  /// logical and physical sizes agree and a golden comes out at the size it
  /// says it is.
  Future<ProviderContainer> pumpShell({
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    Size surfaceSize = const Size(1280, 800),
  }) async {
    view.devicePixelRatio = 1;
    view.physicalSize = surfaceSize;
    addTearDown(view.reset);

    final container = await pumpLoginScreen(
      gateway: FakeAuthGateway(),
      locale: locale,
      themeMode: themeMode,
      surfaceSize: surfaceSize,
    );

    await signIn();

    return container;
  }
}
