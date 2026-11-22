import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/di/providers.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/startup/core_unavailable_screen.dart';
import 'core/startup/startup_state.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/presentation/shell_screen.dart';
import 'features/updates/presentation/update_prompt_host.dart';

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
        ...GlobalMaterialLocalizations.delegates,
      ],

      // The Markdown preview, the HTML reader, the video controls and the
      // vendored page engine still draw with the SDK's
      // `package:flutter/material.dart`, whose `Theme` and
      // `MaterialLocalizations` are other classes than material_ui's. The
      // bridge hands them this application's theme and localizations, so they
      // keep its colours and find their strings. material_ui deprecates it on
      // purpose, as a migration aid; it goes when those packages move.
      // ignore: deprecated_member_use
      builder: (context, child) => MaterialUiCompatibilityBridge(child: child!),

      // The update prompt waits for an open dialog to close; it learns of
      // one closing from here.
      navigatorObservers: [updateRouteObserver],

      home: UpdatePromptHost(
        child: switch (startup) {
          StartupIdle() || StartupRunning() => const StartupProgressScreen(),
          StartupFailed(:final failure) => CoreUnavailableScreen(
            failure: failure,
          ),
          // The shell (UC-38). Everything the owner actually does is inside
          // it, and nothing stands between a ready startup and it.
          StartupReady() => const ShellScreen(),
        },
      ),
    );
  }
}
