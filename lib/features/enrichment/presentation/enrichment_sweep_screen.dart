import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/enrichment_sweep_controller.dart';

/// Looking music info up for the whole library (music enrichment design).
///
/// Its own screen rather than a menu item that just starts, because this is
/// the one operation in the application that reaches the network and the one
/// measured in hours. It says what it sends and why it is slow *before* it
/// starts, shows a count rather than a spinner while it runs, and can be
/// stopped without losing what it has done.
class EnrichmentSweepScreen extends ConsumerWidget {
  /// Creates the screen.
  const EnrichmentSweepScreen({super.key});

  /// Presents the screen over [context].
  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) =>
        const Dialog.fullscreen(child: EnrichmentSweepScreen()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(enrichmentSweepControllerProvider);
    final controller = ref.read(enrichmentSweepControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.enrichmentSweepTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.preferencesClose,
          // Closing does not stop it. The sweep belongs to the session, not
          // to this dialog — the same reason playback outlives the screen it
          // was started from (FR-PL-05) — so an owner can put it away and
          // carry on using the library while it works.
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Said before it runs, not after. This is the only thing here
            // that talks to anyone else, and the owner should be choosing it
            // knowingly rather than discovering it afterwards.
            Text(
              l10n.enrichmentSweepExplanation,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),

            if (state.isRunning) ...[
              LinearProgressIndicator(value: state.progress),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.enrichmentSweepProgress(
                  state.considered,
                  state.remaining,
                ),
                style: theme.textTheme.titleMedium,
              ),
            ],

            if (!state.isRunning)
              Text(
                switch (state.stage) {
                  SweepStage.finished => l10n.enrichmentSweepFinished(
                    state.found,
                    state.considered,
                  ),
                  SweepStage.stopped => l10n.enrichmentSweepStopped(
                    state.considered,
                  ),
                  SweepStage.unavailable => l10n.enrichmentUnavailable,
                  SweepStage.failed => l10n.enrichmentSweepFailed,
                  SweepStage.idle || SweepStage.running => '',
                },
                style: theme.textTheme.titleMedium,
              ),

            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                if (state.isRunning)
                  FilledButton.icon(
                    onPressed: controller.stop,
                    icon: const Icon(Icons.stop),
                    label: Text(l10n.enrichmentSweepStop),
                  )
                else
                  FilledButton.icon(
                    // Unavailable is the one state with nothing to try: the
                    // installation has not configured this, and pressing it
                    // again cannot change that.
                    onPressed: state.stage == SweepStage.unavailable
                        ? null
                        : () => unawaited(controller.start()),
                    icon: const Icon(Icons.travel_explore_outlined),
                    label: Text(l10n.enrichmentSweepStart),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
