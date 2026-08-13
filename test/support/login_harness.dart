import 'package:alexandria_desktop/app.dart';
import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_gateway.dart';
import 'in_memory_settings_store.dart';
import 'test_container.dart';

/// Drives the login screen through the real application root.
///
/// The screen is reached the way the owner reaches it — startup runs, settles
/// ready, and finds no session — rather than by pumping [LoginScreen] on its
/// own. That is what makes these tests cover the wiring in `app.dart` as well
/// as the screen.
extension PumpLogin on WidgetTester {
  /// Pumps the application with [gateway] bound and startup already settled.
  Future<ProviderContainer> pumpLoginScreen({
    FakeAuthGateway? gateway,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    Size surfaceSize = const Size(1280, 800),
  }) async {
    await binding.setSurfaceSize(surfaceSize);
    addTearDown(() => binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        ...fakeCoreOverrides(
          settings: InMemorySettingsStore(
            themeMode: themeMode,
            locale: locale,
          ),
        ),
        authGatewayProvider.overrideWithValue(gateway ?? FakeAuthGateway()),
      ],
    );
    addTearDown(container.dispose);

    await pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlexandriaApp(),
      ),
    );

    await container.read(startupControllerProvider.notifier).start();
    await pumpAndSettle();

    return container;
  }

  /// Pumps the application with a core that cannot be loaded, so startup ends
  /// in its failure state.
  Future<ProviderContainer> pumpFailedStartup() async {
    await binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        // A path with no file behind it: startup step 1 checks the filesystem
        // before it loads anything.
        ...fakeCoreOverrides(libraryPath: 'no/such/library.dll'),
        authGatewayProvider.overrideWithValue(FakeAuthGateway()),
      ],
    );
    addTearDown(container.dispose);

    await pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlexandriaApp(),
      ),
    );

    await container.read(startupControllerProvider.notifier).start();
    await pumpAndSettle();

    return container;
  }

  /// The login form's e-mail field.
  TextField get emailField =>
      widget<TextField>(find.byType(TextField).first);

  /// The login form's password field.
  TextField get passwordField =>
      widget<TextField>(find.byType(TextField).last);

  /// Types [email] and [password] into the form without submitting.
  Future<void> enterCredentials({
    String email = 'owner@example.com',
    String password = 'correct horse',
  }) async {
    await enterText(find.byType(TextField).first, email);
    await enterText(find.byType(TextField).last, password);
    await pump();
  }

  /// Types the credentials and presses the form's primary action.
  Future<void> signIn({
    String email = 'owner@example.com',
    String password = 'correct horse',
  }) async {
    await enterCredentials(email: email, password: password);
    await tap(find.byType(FilledButton));
    await pumpAndSettle();
  }
}
