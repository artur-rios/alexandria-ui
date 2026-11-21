import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../indexing/application/index_runs_state.dart';
import '../../indexing/domain/index_run.dart';
import '../../indexing/presentation/run_failures_screen.dart';
import '../../lifecycle/presentation/missing_files_screen.dart';
import '../../shell/presentation/confirmation_dialog.dart';
import '../domain/library.dart';

/// What [library]'s index run is doing, under its row (libraries-only design
/// §3).
///
/// A run that is running or paused right now comes from the active-runs
/// listing, whichever session started it, and carries the controls. Once it
/// has left that listing, the outcome of a run this session followed stays
/// until it is dismissed. A library with neither shows nothing: the core
/// keeps no history of finished runs to show instead.
class LibraryRunStatus extends ConsumerWidget {
  /// Creates the status of [library]'s run.
  const LibraryRunStatus({super.key, required this.library});

  /// The library whose run this shows.
  final Library library;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final runs = ref.watch(indexRunsControllerProvider);
    final active = ref
        .watch(activeRunsControllerProvider)
        .runs
        .where((run) => run.libraryUuid == library.uuid)
        .firstOrNull;
    final followed = runs.runFor(library.uuid);

    if (active != null) return _Unfinished(run: active);

    if (runs.isStarting(library.uuid) ||
        (followed != null && !followed.status.isTerminal)) {
      // A still icon rather than a spinner: a run can take hours, and the
      // active-runs listing, which carries its progress, takes over as soon
      // as it lists the run.
      return _line(theme, [
        const Icon(Icons.sync, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            l10n.libraryRunStarting,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ]);
    }

    if (followed == null) return const SizedBox.shrink();

    final failed = followed.counts?.failed ?? 0;

    return _line(theme, [
      if (failed > 0) ...[
        Icon(
          Icons.warning_amber_outlined,
          size: 18,
          color: theme.colorScheme.error,
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      Expanded(
        child: Text(
          libraryRunOutcome(followed, l10n),
          style: failed > 0
              ? theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                )
              : theme.textTheme.bodySmall,
        ),
      ),
      // Which files, not just how many: those files are on disk and in no
      // listing, and this is the one place they are named (core FR-FC-42).
      if (failed > 0)
        TextButton(
          onPressed: () => RunFailuresScreen.show(
            context,
            followed.runId,
            reportedCount: failed,
          ),
          child: Text(l10n.runFailuresOpen),
        ),
      IconButton(
        icon: const Icon(Icons.close),
        tooltip: l10n.dismiss,
        onPressed: () => ref
            .read(indexRunsControllerProvider.notifier)
            .dismiss(library.uuid),
      ),
    ]);
  }
}

/// A running or paused run, with what can be done about it.
class _Unfinished extends ConsumerWidget {
  const _Unfinished({required this.run});

  final IndexRun run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(activeRunsControllerProvider.notifier);
    final paused = run.status == IndexRunStatus.paused;
    final total = run.total;

    final message = switch ((paused, total)) {
      (true, _) => l10n.libraryRunPaused,
      (false, final int total) => l10n.libraryRunProgress(
        run.processed ?? 0,
        total,
      ),
      (false, null) => l10n.libraryRunStarting,
    };

    return _line(theme, [
      Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
      if (paused)
        IconButton(
          tooltip: l10n.libraryRunResume,
          icon: const Icon(Icons.play_arrow),
          onPressed: () => controller.resume(run.runId),
        )
      else
        IconButton(
          tooltip: l10n.libraryRunPause,
          icon: const Icon(Icons.pause),
          onPressed: () => controller.pause(run.runId),
        ),
      IconButton(
        tooltip: l10n.libraryRunCancel,
        icon: const Icon(Icons.stop_circle_outlined),
        onPressed: () => confirmCancelRun(context, ref, run.runId),
      ),
    ]);
  }
}

Widget _line(ThemeData theme, List<Widget> children) => Padding(
  padding: const EdgeInsets.fromLTRB(
    AppSpacing.md,
    0,
    AppSpacing.sm,
    AppSpacing.sm,
  ),
  child: Row(children: children),
);

/// What a settled library run did, in a sentence.
String libraryRunOutcome(IndexRun run, AppLocalizations l10n) {
  final counts = run.counts;

  final summary = switch (run.status) {
    IndexRunStatus.paused => l10n.libraryRunPaused,
    IndexRunStatus.failed => l10n.libraryRunFailed,
    // The core keeps a cancelled run's tally (FR-FC-34); without this arm the
    // owner who just abandoned a scan is told it finished.
    IndexRunStatus.cancelled => l10n.libraryRunCancelled,
    _ when counts == null => l10n.libraryRunFailed,
    _ => l10n.libraryRunComplete(
      counts.scanned,
      counts.indexed,
      counts.skipped,
    ),
  };

  if (counts == null || counts.failed == 0) return summary;

  return '$summary ${l10n.libraryRunFailedCount(counts.failed)}';
}

/// Asks before cancelling [runId], which cannot be resumed afterwards.
Future<void> confirmCancelRun(
  BuildContext context,
  WidgetRef ref,
  String runId,
) async {
  final l10n = AppLocalizations.of(context);

  final confirmed = await ConfirmationDialog.show(
    context,
    title: l10n.libraryRunCancelTitle,
    message: l10n.libraryRunCancelConfirm,
    confirmLabel: l10n.libraryRunCancelAction,
  );
  if (!confirmed) return;

  await ref.read(activeRunsControllerProvider.notifier).cancel(runId);
}

/// Re-checks every library at once (UC-07).
class LibraryRefreshAction extends ConsumerWidget {
  /// Creates the button.
  const LibraryRefreshAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final runs = ref.watch(indexRunsControllerProvider);
    final busy = runs.isRefreshing || runs.refreshStarting;

    return OutlinedButton.icon(
      onPressed: busy
          ? null
          : () => ref.read(indexRunsControllerProvider.notifier).startRefresh(),
      icon: busy
          ? const SizedBox.square(
              dimension: AppSpacing.md,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.autorenew),
      label: Text(busy ? l10n.libraryRefreshing : l10n.libraryRefreshAll),
    );
  }
}

/// What the last refresh did, or why it did not start (UC-07 AF-01 … AF-03).
class LibraryRefreshReport extends ConsumerWidget {
  /// Creates the report.
  const LibraryRefreshReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final runs = ref.watch(indexRunsControllerProvider);
    final run = runs.refreshRun;

    final message = switch ((runs.refreshRefusal, runs.refreshFailure, run)) {
      (RefreshRefusal.alreadyRunning, _, _) => l10n.libraryRefreshRunning,
      (RefreshRefusal.catalogEmpty, _, _) => l10n.libraryRefreshEmpty,
      (_, final Failure problem, _) =>
        '${l10n.libraryRefreshFailed} ${problem.localizedMessage(l10n)}',
      (_, _, final IndexRun finished)
          when !finished.isInFlight && finished.counts != null =>
        _outcomeOf(finished.counts!, l10n),
      _ => null,
    };

    if (message == null) return const SizedBox.shrink();

    // AF-03: a refresh that marked files missing links to the review that
    // offers something to do about them; a link to an empty review is a dead
    // end, so it is offered only then.
    final markedMissing = (run?.counts?.markedMissing ?? 0) > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        color: theme.colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(child: Text(message)),
              if (markedMissing)
                TextButton.icon(
                  onPressed: () => MissingFilesScreen.show(context),
                  icon: const Icon(Icons.help_outline),
                  label: Text(l10n.missingFilesOpen),
                ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.dismiss,
                onPressed: () => ref
                    .read(indexRunsControllerProvider.notifier)
                    .dismissRefresh(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _outcomeOf(IndexRunCounts counts, AppLocalizations l10n) {
    final summary = l10n.libraryRefreshComplete(
      counts.refreshed,
      counts.unchanged,
      counts.markedMissing,
    );
    if (counts.failed == 0) return summary;

    return '$summary ${l10n.libraryRunFailedCount(counts.failed)}';
  }
}
