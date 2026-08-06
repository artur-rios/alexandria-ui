import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/startup/core_unavailable_screen.dart';
import 'core/startup/startup_state.dart';
import 'core/theme/app_theme.dart';

/// The application root.
///
/// It owns three things and no more: the themes (IR-10), the locales (IR-11),
/// and which of the startup states is on screen (IR-06). Everything the owner
/// actually does lives under the shell that UC-38 builds.
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
        StartupReady(:final coreVersion) => StartupReadyPlaceholder(
          coreVersion: coreVersion,
        ),
      },
    );
  }
}
