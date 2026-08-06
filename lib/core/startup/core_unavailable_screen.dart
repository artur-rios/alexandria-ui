import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import '../failures/failure.dart';
import '../failures/failure_messages.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/breakpoints.dart';

/// The `CoreUnavailable` state (IR-06, UC-38 AF-04).
///
/// A first-class application state rather than an error dialog over a broken
/// window: no catalog call is attempted from here, and the retry re-runs the
/// startup sequence from step 1
/// (Operations & Infrastructure Document §5.2).
class CoreUnavailableScreen extends ConsumerWidget {
  /// Creates the screen for [failure].
  const CoreUnavailableScreen({required this.failure, super.key});

  /// What went wrong. Its message is localized; the status code behind it goes
  /// to the log, never to the screen.
  final Failure failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          // Bounded so the message stays readable on a wide display rather than
          // running the full width of the window.
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.report_outlined,
                  size: AppSpacing.xxl,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.coreUnavailableTitle,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  failure.localizedMessage(l10n),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                // Autofocused so the screen's primary action is reachable from
                // the keyboard without a pointer (FR-UX-11).
                FilledButton.icon(
                  autofocus: true,
                  onPressed: () => ref
                      .read(startupControllerProvider.notifier)
                      .retry(),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The state shown while the startup sequence runs (FR-UX-08).
class StartupProgressScreen extends StatelessWidget {
  /// Creates the progress state.
  const StartupProgressScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}

/// A placeholder for the shell, which UC-38 (issue #39) builds.
///
/// The foundation's job ends when the core is verified; this is the seam the
/// shell lands in, and it exists so the startup sequence has a terminal state
/// to reach rather than the foundation growing a shell it was not asked for.
class StartupReadyPlaceholder extends StatelessWidget {
  /// Creates the placeholder for a core reporting [coreVersion].
  const StartupReadyPlaceholder({required this.coreVersion, super.key});

  /// The verified core version.
  final String coreVersion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(
            Breakpoint.from(context) == Breakpoint.compact
                ? AppSpacing.lg
                : AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.appTitle, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(coreVersion, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
