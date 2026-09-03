import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/settings/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import 'package:alexandria_ui/features/shell/presentation/library_menu.dart';
import 'package:alexandria_ui/features/shell/presentation/settings_menu.dart';

import 'failing_settings_store.dart';
import 'fake_auth_gateway.dart';
import 'fake_enrichment_gateway.dart';
import 'fake_library_gateway.dart';
import 'fake_playlist_gateway.dart';
import 'login_harness.dart';

/// Whether [overrides] already replaces [provider], so [pumpShell]'s own
/// default is skipped rather than colliding with a caller's own — Riverpod
/// rejects overriding the same provider twice in one container.
bool _overrides(List<Override> overrides, ProviderBase<Object?> provider) =>
    overrides.any((override) => override.origin == provider);

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
  ///
  /// [reduceMotion] defaults to `false` — the real, untouched default any
  /// owner starts a session with — so a test built on this harness exercises
  /// real motion unless it deliberately asks not to. UC-21's album animation
  /// (Task 7) spins for as long as something plays, which is forever from
  /// `pumpAndSettle`'s point of view; a caller whose own assertions do not
  /// depend on that motion should let it play and step past it with a bounded
  /// `pump(duration)` rather than flipping this flag — turning it on suite-
  /// wide once made every other suite's coverage of `AlbumStage` motionless
  /// by accident, which is exactly what this default now avoids.
  Future<ProviderContainer> pumpShell({
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    Size surfaceSize = const Size(1280, 800),
    SettingsStore? settings,
    FakeAuthGateway? gateway,
    List<Override> extraOverrides = const [],
    bool reduceMotion = false,
  }) async {
    view.devicePixelRatio = 1;
    view.physicalSize = surfaceSize;
    addTearDown(view.reset);

    if (reduceMotion) {
      platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(platformDispatcher.clearAccessibilityFeaturesTestValue);
    }

    final container = await pumpLoginScreen(
      gateway: gateway ?? FakeAuthGateway(),
      locale: locale,
      themeMode: themeMode,
      surfaceSize: surfaceSize,
      settings: settings,
      extraOverrides: [
        // No Chromium in a test binding: the page engine is a native texture
        // behind a plugin channel, and a test that pumped one would hang
        // rather than fail. Every shell test therefore reads a saved page
        // through the markup renderer — which is not a stand-in invented for
        // tests, but the same fallback an owner gets when the engine will not
        // start (`pageEngineEnabledProvider`).
        if (!_overrides(extraOverrides, pageEngineEnabledProvider))
          pageEngineEnabledProvider.overrideWithValue(false),
        // Task 5's add-to-playlist controls are reachable from the music
        // rows and the now-playing screen, both mounted well beyond the
        // playlists feature's own tests — so every shell test needs a
        // playlist gateway that answers cleanly by default, the same way the
        // catalog and auth gateways already do here. Skipped when a caller's
        // own `extraOverrides` already replaces it (the playlists tests'
        // own `FakePlaylistGateway`), since Riverpod rejects overriding the
        // same provider twice in one container.
        if (!_overrides(extraOverrides, playlistGatewayProvider))
          playlistGatewayProvider.overrideWithValue(FakePlaylistGateway()),
        // The now-playing screen reads a track's cached enrichment, so every
        // shell test that opens it needs a gateway — the real one throws
        // when read before a core is loaded. Answers "nothing stored" by
        // default, which is what most of a library holds and what a test
        // about something else should see.
        if (!_overrides(extraOverrides, enrichmentGatewayProvider))
          enrichmentGatewayProvider.overrideWithValue(FakeEnrichmentGateway()),
        // The Library menu builds its entries whether or not a test opens
        // them, and the real gateway throws when read before a core exists.
        if (!_overrides(extraOverrides, libraryGatewayProvider))
          libraryGatewayProvider.overrideWithValue(FakeLibraryGateway()),
        ...extraOverrides,
      ],
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
