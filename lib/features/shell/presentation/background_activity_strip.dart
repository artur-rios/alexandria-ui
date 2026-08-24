import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../library_sources/application/active_runs_state.dart';
import '../../library_sources/domain/index_run.dart';
import '../../library_sources/domain/run_estimate.dart';
import '../../library_sources/domain/run_priority.dart';
import '../../library_sources/presentation/library_sources_screen.dart';

/// What the core is indexing, from anywhere in the application
/// (FR-LB-13 … FR-LB-16 / core FR-FC-28, FR-FC-31 … FR-FC-35).
///
/// A 418 GB library takes hours to scan, and the owner does not spend those
/// hours on the library-folders screen. This is the answer to both halves of
/// that: the scan is visible from everywhere, and leaving the screen it was
/// started from no longer hides it.
///
/// Unlike the playback bar below it, this takes *no* height when nothing is
/// running. The bar is persistent because a track can start at any moment and
/// a bar that appeared would reflow the listing behind it; the strip appears
/// only in answer to a scan the owner just started, so a reflow is expected
/// rather than surprising — and the animation is what makes it read as
/// intentional.
class BackgroundActivityStrip extends ConsumerStatefulWidget {
  /// Creates the strip.
  const BackgroundActivityStrip({super.key});

  /// The height the strip takes when there is nothing to report.
  ///
  /// Zero rather than a reserved sliver: the playback bar below holds the
  /// bottom of the shell from the first frame because a track can start at any
  /// moment, but nobody is owed a strip they will never see. Anyone not
  /// indexing gets the shell exactly as it was.
  static const double collapsedHeight = 0;

  /// The height of the row, in logical pixels.
  ///
  /// One line of text with its controls, and deliberately less than the
  /// playback bar's 64: this reports on work the owner set going and left, not
  /// something they are operating.
  static const double expandedHeight = 40;

  @override
  ConsumerState<BackgroundActivityStrip> createState() =>
      _BackgroundActivityStripState();
}

class _BackgroundActivityStripState
    extends ConsumerState<BackgroundActivityStrip> {
  /// How long a finished run's outcome stands before it clears itself.
  ///
  /// Long enough to read, short enough that it is gone by the time the owner
  /// looks away and back. A *failed* run gets no timer at all — see
  /// [_syncDismissal].
  static const Duration _dismissAfter = Duration(seconds: 4);

  Timer? _dismiss;
  String? _dismissingRunId;

  /// The pace the owner last asked for, per run.
  ///
  /// Held here because the core does not report a run's priority: `IndexRun`
  /// carries no such field, so the only thing that knows a run was throttled
  /// is the request that throttled it. A restart therefore reads `normal`
  /// again, which is honest — the application genuinely does not know.
  final Map<String, RunPriority> _priorities = {};

  String? _repacingRunId;
  RunPriority? _repacingTo;
  int _repacedFrom = 0;
  bool _repacingReset = false;

  @override
  void initState() {
    super.initState();

    // Every later reading arrives through the listener in [build], but the
    // first one is already in hand: a run can finish before this widget
    // exists, and a listener only fires on what changes after it is attached.
    _syncDismissal(ref.read(activeRunsControllerProvider).justFinished);
  }

  @override
  void dispose() {
    _dismiss?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(activeRunsControllerProvider);

    // Both of these act on a *change* rather than on a frame, and neither
    // belongs in a build: one starts and cancels a timer, the other calls
    // setState. A listener is where a side effect of a new reading goes.
    ref.listen(activeRunsControllerProvider, (_, next) {
      _followRepacing(next);
      _syncDismissal(next.justFinished);
    });

    final row = _row(state);

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: row == null
          ? const SizedBox.shrink()
          : Semantics(
              container: true,
              label: l10n.activityBarLabel,
              child: Material(
                color: theme.colorScheme.surfaceContainerHigh,
                child: SizedBox(
                  height: BackgroundActivityStrip.expandedHeight,
                  child: row,
                ),
              ),
            ),
    );
  }

  /// What the strip has to say, or null when it has nothing.
  Widget? _row(ActiveRunsState state) {
    // A failure outranks everything, including work still in flight. The strip
    // is one row, so with two folders indexing and one of them failing, the
    // other ordering drops the failure on the floor — and a failure the owner
    // never sees is the outcome this whole row exists to prevent. The run it
    // hides is still running, still polled, and back the moment the failure is
    // dismissed; the failure, once overwritten, is gone for good.
    if (state.justFinished case final finished?
        when finished.status == IndexRunStatus.failed) {
      return _OutcomeRow(
        run: finished,
        failed: true,
        onDismiss: ref
            .read(activeRunsControllerProvider.notifier)
            .dismissFinished,
      );
    }

    // Outstanding work outranks every *other* outcome: a completion is news
    // about something that is over, and it clears itself either way.
    if (state.runs.length > 1) return _AggregateRow(runs: state.runs);

    if (state.single case final run?) {
      return _RunRow(
        run: run,
        samples: state.samples[run.runId] ?? const [],
        priority: _priorities[run.runId] ?? RunPriority.normal,
        repacingTo: _repacingRunId == run.runId ? _repacingTo : null,
        onPause: () => unawaited(
          ref.read(activeRunsControllerProvider.notifier).pause(run.runId),
        ),
        // No priority on a plain resume: null asks the core to keep the pace
        // the run already had, and passing `normal` would silently speed up a
        // scan the owner deliberately throttled.
        onResume: () => unawaited(
          ref.read(activeRunsControllerProvider.notifier).resume(run.runId),
        ),
        onCancel: () => unawaited(
          ref.read(activeRunsControllerProvider.notifier).cancel(run.runId),
        ),
        onRepace: (priority) => unawaited(_repace(run, priority)),
      );
    }

    if (state.justFinished case final finished?
        when finished.status == IndexRunStatus.complete) {
      return _OutcomeRow(run: finished, failed: false);
    }

    // Anything else that dropped off the list — a cancelled run — is the
    // owner's own doing rather than news, and [_syncDismissal] clears it on
    // the next turn instead of announcing it.
    return null;
  }

  /// Re-paces [run] to [priority] (FR-FC-31).
  ///
  /// The core cannot change a running run's pace, so this is a pause followed
  /// by a resume — and a resume restarts the segment, which sends `processed`
  /// back to zero, clears `total` and puts the run back into discovery. The
  /// bar therefore visibly returns to zero, and the notice the row shows while
  /// this stands is what stops that reading as lost work.
  Future<void> _repace(IndexRun run, RunPriority priority) async {
    final controller = ref.read(activeRunsControllerProvider.notifier);

    setState(() {
      _priorities[run.runId] = priority;
      _repacingRunId = run.runId;
      _repacingTo = priority;
      _repacedFrom = run.processed ?? 0;
      _repacingReset = false;
    });

    await controller.pause(run.runId);
    await controller.resume(run.runId, priority: priority);
  }

  /// Drops the re-pacing notice once it has done its job.
  ///
  /// Not when the resume call returns: that happens long before the restarted
  /// segment has walked far enough to put a number back on the bar, and a
  /// notice that vanished in between would leave the reset unexplained. It
  /// stands until the count has been seen to fall back and then climb again —
  /// the moment the restart is over and no longer needs saying.
  void _followRepacing(ActiveRunsState state) {
    final runId = _repacingRunId;
    if (runId == null) return;

    IndexRun? repaced;
    for (final run in state.runs) {
      if (run.runId == runId) repaced = run;
    }

    // Gone from the active list: whatever it was doing, it is not re-pacing.
    if (repaced == null) {
      setState(_clearRepacing);

      return;
    }

    final processed = repaced.processed ?? 0;
    if (!_repacingReset && processed < _repacedFrom) _repacingReset = true;

    if (_repacingReset &&
        repaced.phase == IndexRunPhase.processing &&
        processed > 0) {
      setState(_clearRepacing);
    }
  }

  void _clearRepacing() {
    _repacingRunId = null;
    _repacingTo = null;
    _repacedFrom = 0;
    _repacingReset = false;
  }

  /// Starts or cancels the timer that clears [finished].
  ///
  /// A completed run clears itself; a failed one never does. A failure that
  /// vanishes before it is seen is worse than a strip that lingers, and the
  /// owner has a dismiss button either way.
  void _syncDismissal(IndexRun? finished) {
    // A failure is left standing, so it gets no timer and no run id here.
    final clearing =
        finished != null && finished.status != IndexRunStatus.failed
        ? finished
        : null;
    if (clearing?.runId == _dismissingRunId) return;

    _dismiss?.cancel();
    _dismissingRunId = clearing?.runId;
    if (clearing == null) return;

    // A cancelled run is cleared on the next turn rather than after the four
    // seconds a completion gets: the owner asked for it, and it is not news.
    final after = clearing.status == IndexRunStatus.complete
        ? _dismissAfter
        : Duration.zero;

    _dismiss = Timer(after, () {
      if (!mounted) return;
      ref.read(activeRunsControllerProvider.notifier).dismissFinished();
    });
  }
}

/// The one outstanding run: what it is doing, how far it has got, and the
/// controls for it (FR-LB-13, FR-LB-16, FR-LB-18 / core FR-FC-28, FR-FC-31,
/// FR-FC-34).
class _RunRow extends StatelessWidget {
  const _RunRow({
    required this.run,
    required this.samples,
    required this.priority,
    required this.repacingTo,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRepace,
  });

  final IndexRun run;
  final List<RunSample> samples;
  final RunPriority priority;

  /// The pace a re-pacing in flight is heading for, or null when none is.
  final RunPriority? repacingTo;

  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final ValueChanged<RunPriority> onRepace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final paused = run.status == IndexRunStatus.paused;

    // FR-FC-28: discovery has no total — the walk is still counting what it
    // will have to do — so there is nothing to divide by and a percentage here
    // would be invented. An indeterminate bar says "working" and claims
    // nothing else.
    final total = run.total;
    final processed = run.processed;
    final determinate =
        run.phase == IndexRunPhase.processing && total != null && total > 0;

    return Row(
      children: [
        const SizedBox(width: AppSpacing.md),
        Icon(
          run.kind == IndexRunKind.refresh
              ? Icons.refresh
              : Icons.folder_open_outlined,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            _folderName(l10n, run),
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: LinearProgressIndicator(
            // A paused run makes no progress, so an animating indeterminate
            // bar would say work is happening when none is. Held at zero
            // instead, which claims nothing.
            value: determinate ? (processed ?? 0) / total : (paused ? 0 : null),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          _status(l10n, paused: paused, determinate: determinate),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (_estimate(context) case final estimate?) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.activityRemaining(estimate),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.sm),
        _PriorityButton(priority: priority, onSelected: onRepace),
        _Control(
          tooltip: paused ? l10n.activityResume : l10n.activityPause,
          icon: paused ? Icons.play_arrow : Icons.pause,
          onPressed: paused ? onResume : onPause,
        ),
        _Control(
          tooltip: l10n.activityCancel,
          icon: Icons.close,
          onPressed: onCancel,
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  /// The line beside the bar: what the run is doing, in one phrase.
  String _status(
    AppLocalizations l10n, {
    required bool paused,
    required bool determinate,
  }) {
    // FR-FC-31: the segment restarted, and saying so is the difference between
    // a reset bar and thousands of files apparently thrown away.
    if (repacingTo case final pace?) {
      return pace == RunPriority.low
          ? l10n.activityRepacing
          : l10n.activityRepacingNormal;
    }

    if (!determinate) return l10n.activityDiscovering;

    final processed = run.processed ?? 0;
    final total = run.total!;

    return paused
        ? l10n.activityPaused(processed, total)
        : l10n.activityProgress(processed, total);
  }

  /// How long the run has left, or null when no honest estimate exists.
  String? _estimate(BuildContext context) {
    if (repacingTo != null) return null;
    if (run.status != IndexRunStatus.running) return null;
    if (run.phase != IndexRunPhase.processing) return null;

    final total = run.total;
    if (total == null) return null;

    final remaining = estimateRemaining(samples, total: total);

    return remaining == null ? null : _formatEstimate(context, remaining);
  }
}

/// Several runs at once, as one line (FR-LB-15 / core FR-FC-35).
///
/// One row rather than one row per run: the strip is forty pixels of the
/// shell, and a list of runs is the library-folders screen's job — which is
/// what the single action here opens.
class _AggregateRow extends StatelessWidget {
  const _AggregateRow({required this.runs});

  final List<IndexRun> runs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // FR-FC-29: two runs paused at launch — the exact state resuming is meant
    // for — are outstanding but not moving. "Indexing 2 folders" over them
    // asserts work is under way that is not, and the bar would animate for a
    // core doing nothing.
    final running = runs.any((run) => run.isInFlight);

    var processed = 0;
    int? total = 0;
    for (final run in runs) {
      processed += run.processed ?? 0;
      // One run still discovering makes the whole total unknown. Summing the
      // totals that exist would report a figure that is not the work
      // outstanding.
      final runTotal = run.total;
      total = (total == null || runTotal == null) ? null : total + runTotal;
    }

    return Row(
      children: [
        const SizedBox(width: AppSpacing.md),
        Icon(
          Icons.folder_copy_outlined,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          _line(l10n, total: total, processed: processed, running: running),
          style: theme.textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: LinearProgressIndicator(
            // Nothing running and nothing to divide by: an animating
            // indeterminate bar would say work is happening when none is, so
            // it is held at zero, which claims nothing — the same reading the
            // single-run row gives a paused scan.
            value: total == null || total == 0
                ? (running ? null : 0)
                : processed / total,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // No pause, resume or cancel: one row has no room to say which of the
        // runs a button would act on, and guessing is worse than sending the
        // owner where every run is named.
        TextButton(
          onPressed: () => unawaited(LibrarySourcesScreen.show(context)),
          child: Text(l10n.activityViewAll),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  /// The one line the several runs get, in the vocabulary of what they are
  /// actually doing.
  String _line(
    AppLocalizations l10n, {
    required int? total,
    required int processed,
    required bool running,
  }) {
    if (total == null) {
      return running
          ? l10n.activityAggregateDiscovering(runs.length)
          : l10n.activityAggregatePausedDiscovering(runs.length);
    }

    return running
        ? l10n.activityAggregate(runs.length, processed, total)
        : l10n.activityAggregatePaused(runs.length, processed, total);
  }
}

/// How a run ended (FR-LB-13).
class _OutcomeRow extends StatelessWidget {
  const _OutcomeRow({required this.run, required this.failed, this.onDismiss});

  final IndexRun run;
  final bool failed;

  /// Offered for a failure alone: a completion clears itself.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final folder = _folderName(l10n, run);

    return Row(
      children: [
        const SizedBox(width: AppSpacing.md),
        Icon(
          failed ? Icons.error_outline : Icons.check_circle_outline,
          size: 18,
          color: failed
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            failed
                ? l10n.activityFailed(folder)
                : l10n.activityComplete(folder),
            style: theme.textTheme.bodySmall?.copyWith(
              color: failed ? theme.colorScheme.error : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onDismiss case final dismiss?)
          TextButton(onPressed: dismiss, child: Text(l10n.activityDismiss)),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}

/// The pace the run is being asked to keep (FR-FC-31).
class _PriorityButton extends StatelessWidget {
  const _PriorityButton({required this.priority, required this.onSelected});

  final RunPriority priority;
  final ValueChanged<RunPriority> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    String label(RunPriority priority) => switch (priority) {
      RunPriority.normal => l10n.activityPriorityNormal,
      RunPriority.low => l10n.activityPriorityLow,
    };

    return PopupMenuButton<RunPriority>(
      tooltip: label(priority),
      padding: EdgeInsets.zero,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final option in RunPriority.values)
          PopupMenuItem(value: option, child: Text(label(option))),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Text(label(priority), style: theme.textTheme.labelSmall),
      ),
    );
  }
}

/// One of the row's icon buttons, sized to a forty-pixel row.
///
/// The Material default is a 48-pixel target, which the strip has no room for.
class _Control extends StatelessWidget {
  const _Control({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    icon: Icon(icon),
    iconSize: 18,
    padding: EdgeInsets.zero,
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
    onPressed: onPressed,
  );
}

/// What the run is working on, named the way the owner would name it.
///
/// A refresh covers everything already cataloged rather than one folder, so it
/// carries no root and is named for what it is (UC-07).
String _folderName(AppLocalizations l10n, IndexRun run) {
  final root = run.root;
  if (root.isEmpty) return l10n.activityCatalog;

  final segments = root.split(RegExp(r'[/\\]'))..removeWhere((s) => s.isEmpty);

  return segments.isEmpty ? root : segments.last;
}

/// An estimate, written out rather than as a clock reading.
///
/// Whole minutes, and whole hours beyond an hour: the figure is an
/// extrapolation, and "1:47:12 left" would claim a precision it does not have.
String _formatEstimate(BuildContext context, Duration remaining) {
  final l10n = AppLocalizations.of(context);
  if (remaining.inHours < 1) {
    return l10n.activityDurationMinutes(remaining.inMinutes);
  }

  return l10n.activityDurationHours((remaining.inMinutes / 60).round());
}
