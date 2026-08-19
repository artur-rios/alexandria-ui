import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/startup/core_unavailable_screen.dart';
import 'core/startup/startup_state.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_entry_controller.dart';
import 'features/auth/application/session_state.dart';
import 'features/auth/presentation/catalog_locked_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/sign_up_screen.dart';
import 'features/shell/presentation/shell_screen.dart';

/// The application root.
///
/// It owns three things and no more: the themes (IR-10), the locales (IR-11),
/// and which of the startup states is on screen (IR-06). Everything the owner
/// actually does lives under the shell (UC-38).
class AlexandriaApp extends ConsumerWidget {
  /// Creates the root widget.
  const AlexandriaApp({super.key});

  /// The languages the application ships.
  ///
  /// Brazilian Portuguese is declared with its country code even though the
  /// catalog is the base `pt` file — that is the locale the product supports,
  /// and Flutter resolves it to the `pt` messages.
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('pt', 'BR'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(startupControllerProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,

      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),

      locale: ref.watch(localeProvider),
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: switch (startup) {
        StartupIdle() || StartupRunning() => const StartupProgressScreen(),
        StartupFailed(:final failure) => CoreUnavailableScreen(
          failure: failure,
        ),
        // Startup ends where authentication begins: steps 6 and 7 of the
        // sequence — is there an account, and is its e-mail confirmed — are
        // answered by logging in (UC-02), not by the foundation.
        StartupReady() => switch (ref.watch(
          sessionControllerProvider,
        )) {
          // FR-AU-07: no session, so no catalog call. Which of the two
          // authentication screens depends on whether the core already holds
          // an account (FR-AU-01, UC-01 main flow step 1).
          SessionAbsent() => switch (ref.watch(authEntryProvider)) {
            AuthEntry.resolving => const StartupProgressScreen(),
            AuthEntry.signUp => const SignUpScreen(),
            AuthEntry.login => const LoginScreen(),
          },

          // FR-AU-12 / BR-25: authenticated but unconfirmed keeps the catalog
          // locked. UC-40 replaces this with the confirmation prompt.
          SessionActive(:final session, :final confirmation)
              when !session.emailConfirmed =>
            CatalogLockedScreen(
              email: session.email,
              confirmation: confirmation,
            ),

          // The shell (UC-38). Everything the owner actually does is inside
          // it, which is why this switch stops here.
          SessionActive() => const ShellScreen(),
        },
      },
    );
  }
}
