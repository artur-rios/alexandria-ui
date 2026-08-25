import 'package:alexandria_ui/core/settings/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import 'package:alexandria_ui/features/shell/presentation/library_menu.dart';
import 'package:alexandria_ui/features/shell/presentation/settings_menu.dart';

import 'failing_settings_store.dart';
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
    SettingsStore? settings,
    FakeAuthGateway? gateway,
    List<Override> extraOverrides = const [],
  }) async {
    view.devicePixelRatio = 1;
    view.physicalSize = surfaceSize;
    addTearDown(view.reset);

    final container = await pumpLoginScreen(
      gateway: gateway ?? FakeAuthGateway(),
      locale: locale,
      themeMode: themeMode,
      surfaceSize: surfaceSize,
      settings: settings,
      extraOverrides: extraOverrides,
    );

    await signIn();

    return container;
  }

  /// Opens one of the library-wide screens (UC-37 main flow step 1).
  ///
  /// The Library menu is the one entry point every one of them has, so a test
  /// that needs collections, deleted items, or the missing-files review opens
  /// it the way the owner does rather than through whichever screen happens to
  /// link to it.
  Future<void> openLibraryTool(String label) async {
    await tap(find.byType(LibraryMenu));
    await pumpAndSettle();

    await tap(find.text(label).last);
    await pumpAndSettle();
  }

  /// Chooses [label] from the shell's Settings menu (UC-39 main flow step 1).
  Future<void> openSettingsMenuEntry(String label) async {
    await tap(find.byType(SettingsMenu));
    await pumpAndSettle();

    await tap(find.text(label).last);
    await pumpAndSettle();
  }

  /// Signs in and lands on the shell over a settings store that refuses every
  /// write (UC-39 AF-02).
  Future<ProviderContainer> pumpShellWithFailingSettings({
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) => pumpShell(
    locale: locale,
    themeMode: themeMode,
    settings: FailingSettingsStore(themeMode: themeMode, locale: locale),
  );
}
