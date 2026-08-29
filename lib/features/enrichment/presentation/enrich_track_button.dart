import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../application/enrichment_run_controller.dart';

/// Asks the core to look this track up (music enrichment design).
///
/// The one control in the application that reaches the network, and it says
/// so by behaving like it: it goes into a spinner while it runs, and it
/// reports what it concluded rather than finishing silently. A lookup that
/// legitimately found nothing is otherwise indistinguishable from one that
/// never ran.
class EnrichTrackButton extends ConsumerWidget {
  /// Creates the button for [fileUuid].
  const EnrichTrackButton({
    required this.fileUuid,
    required this.artistName,
    super.key,
  });

  /// The track to look up.
  final String fileUuid;

  /// Whose image the panel will re-read afterwards.
  final String? artistName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(enrichmentRunControllerProvider);

    // Whatever the last lookup concluded, said once and then cleared. Shown
    // through the shell's own messenger rather than as a banner on the
    // player: it is the answer to a question the owner just asked, not a
    // state the screen is now in.
    ref.listen<EnrichmentRunState>(enrichmentRunControllerProvider, (
      previous,
      next,
    ) {
      final message = switch (next.stage) {
        EnrichmentRunStage.nothingFound => l10n.enrichmentNothingFound,
        EnrichmentRunStage.unavailable => l10n.enrichmentUnavailable,
        EnrichmentRunStage.failed => l10n.enrichmentUnavailable,
        EnrichmentRunStage.idle ||
        EnrichmentRunStage.running ||
        // Nothing to say: the words and the photograph appearing below is
        // the report.
        EnrichmentRunStage.found => null,
      };
      if (message == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      ref.read(enrichmentRunControllerProvider.notifier).acknowledge();
    });

    if (state.isRunning) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: Semantics(
              label: l10n.enrichmentLookingUp,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return IconButton(
      tooltip: l10n.enrichmentFindForTrack,
      icon: const Icon(Icons.travel_explore_outlined),
      onPressed: () => unawaited(
        ref
            .read(enrichmentRunControllerProvider.notifier)
            .runForTrack(fileUuid: fileUuid, artistName: artistName),
      ),
    );
  }
}
