import 'package:alexandria_ui/app.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/settings/settings_store.dart';
import 'package:alexandria_ui/features/auth/domain/auth_gateway.dart';
import 'package:alexandria_ui/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

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
  /// Pumps the application on the sign-up screen (UC-01).
  ///
  /// The screen is reached the way a fresh installation reaches it: startup
  /// settles, no session is found, and the core reports no account.
  Future<ProviderContainer> pumpSignUpScreen({
    FakeAuthGateway? gateway,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    Size surfaceSize = const Size(1280, 800),
  }) => pumpLoginScreen(
    gateway: (gateway ?? FakeAuthGateway())
      ..existence = AccountExistence.absent,
    locale: locale,
    themeMode: themeMode,
    surfaceSize: surfaceSize,
  );

  /// Pumps the application with [gateway] bound and startup already settled.
  ///
  /// Lands on the login screen unless the gateway reports no account, because
  /// [FakeAuthGateway] says an account exists by default.
  Future<ProviderContainer> pumpLoginScreen({
    FakeAuthGateway? gateway,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    Size surfaceSize = const Size(1280, 800),
    SettingsStore? settings,
    List<Override> extraOverrides = const [],
  }) async {
    await binding.setSurfaceSize(surfaceSize);
    addTearDown(() => binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        ...fakeCoreOverrides(
          // A caller-supplied store replaces the default rather than being
          // merged into it: that is how a test asks for one that cannot be
          // written (UC-39 AF-02).
          settings:
              settings ??
              InMemorySettingsStore(themeMode: themeMode, locale: locale),
        ),
        authGatewayProvider.overrideWithValue(gateway ?? FakeAuthGateway()),
        // Appended, so a caller can substitute a feature's own dependencies
        // without restating the whole fake set.
        ...extraOverrides,
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
  Future<ProviderContainer> pumpFailedStartup({
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    Size surfaceSize = const Size(1280, 800),
  }) async {
    await binding.setSurfaceSize(surfaceSize);
    addTearDown(() => binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        // A path with no file behind it: startup step 1 checks the filesystem
        // before it loads anything.
        ...fakeCoreOverrides(
          libraryPath: 'no/such/library.dll',
          settings: InMemorySettingsStore(themeMode: themeMode, locale: locale),
        ),
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
  TextField get emailField => widget<TextField>(find.byType(TextField).first);

  /// The login form's password field.
  TextField get passwordField => widget<TextField>(find.byType(TextField).last);

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

  /// The sign-up form's repeated-password field.
  TextField get passwordConfirmationField =>
      widget<TextField>(find.byType(TextField).at(2));

  /// Fills the sign-up form without submitting.
  Future<void> enterRegistration({
    String email = 'owner@example.com',
    String password = 'a decent long passphrase',
    String? passwordConfirmation,
  }) async {
    await enterText(find.byType(TextField).at(0), email);
    await enterText(find.byType(TextField).at(1), password);
    await enterText(
      find.byType(TextField).at(2),
      passwordConfirmation ?? password,
    );
    await pump();
  }

  /// Fills the sign-up form and presses its primary action.
  Future<void> signUp({
    String email = 'owner@example.com',
    String password = 'a decent long passphrase',
    String? passwordConfirmation,
  }) async {
    await enterRegistration(
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    await tap(find.byType(FilledButton));
    await pumpAndSettle();
  }
}
