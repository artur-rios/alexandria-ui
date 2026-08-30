import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../lifecycle/presentation/missing_files_screen.dart';
import '../../shell/presentation/confirmation_dialog.dart';
import '../../../core/failures/failure.dart';
import '../../../core/failures/failure_messages.dart';
import '../application/index_runs_state.dart';
import '../domain/library_source.dart';
import '../application/library_sources_state.dart';
import '../domain/folder_registration.dart';
import '../domain/index_run.dart';
import '../domain/run_priority.dart';
import 'index_scope_dialog.dart';

/// The library-sources screen (UC-05, FR-LB-01 … FR-LB-04, FR-LB-11).
///
/// Presented as a full-screen dialog reached from preferences. The registered
/// folders are application settings (System Requirements §4.11), and the
/// navigation panel is specified as the file types (FR-CT-01) — so this is not
/// a destination of its own.
class LibrarySourcesScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const LibrarySourcesScreen({super.key});

  /// Presents the screen over [context].
  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) =>
        const Dialog.fullscreen(child: LibrarySourcesScreen()),
  );

  @override
  ConsumerState<LibrarySourcesScreen> createState() =>
      _LibrarySourcesScreenState();
}

class _LibrarySourcesScreenState extends ConsumerState<LibrarySourcesScreen> {
  @override
  void initState() {
    super.initState();

    // AF-05: a run the core is still doing, or finished while the application
    // was closed, is picked up here rather than lost. The run belongs to the
    // core, so its outcome is waiting to be read.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(indexRunsControllerProvider.notifier).resumeRecordedRuns();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(librarySourcesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.librarySourcesTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.librarySourcesClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.refusal != null) ...[
              _RefusalNotice(state: state),
              const SizedBox(height: AppSpacing.md),
            ],

            // AF-02: a folder the core is still scanning cannot be removed
            // yet. Its own notice rather than the registration one's, because
            // it is about a different attempt and clears on its own.
            if (state.unregisterRefusedFor != null) ...[
              _NoticeBar(
                message: l10n.librarySourcesUnregisterRefused,
                onDismiss: () => ref
                    .read(librarySourcesControllerProvider.notifier)
                    .acknowledgeUnregisterRefusal(),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            const _RefreshReport(),

            Expanded(
              child: state.isEmpty
                  ? const _FirstRunGuidance()
                  : _SourceList(state: state),
            ),

            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                FilledButton.icon(
                  // The screen's primary action, focused so it is reachable from
                  // the keyboard (FR-UX-11).
                  autofocus: true,
                  onPressed: state.registering
                      ? null
                      : () => _addFolder(context),
                  icon: state.registering
                      ? const SizedBox.square(
                          dimension: AppSpacing.md,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.create_new_folder_outlined),
                  label: Text(l10n.librarySourcesAdd),
                ),
                const SizedBox(width: AppSpacing.md),
                // UC-07: catalog-wide, so it sits beside the folder list
                // rather than on any row (FR-LB-06).
                const _RefreshAction(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the picker, answering AF-04's question through the shell's
  /// confirmation modal when it is asked, and the scope question through the
  /// dialog that offers the seven types (main flow step 4).
  Future<void> _addFolder(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    final registered = await ref
        .read(librarySourcesControllerProvider.notifier)
        .registerFolder(
          onOverlapConfirmed: (path, existing) async {
            if (!context.mounted) return false;

            return ConfirmationDialog.show(
              context,
              title: l10n.librarySourcesOverlapTitle,
              // Both folders by name: the one being added and the one it
              // overlaps, so the owner can see which pair is at issue.
              message: l10n.librarySourcesOverlapBody(path, existing.label),
              confirmLabel: l10n.librarySourcesOverlapConfirm,
            );
          },
          // Asked last, once the folder is accepted: the answer describes what
          // the folder is for, and every later index of it uses it (UC-05).
          onScopeChosen: (path) async {
            if (!context.mounted) return null;

            return IndexScopeDialog.show(context);
          },
        );

    // Registering a folder is a request to have it in the library, and a
    // source folder that is not indexed is not in the library yet. Chained
    // here rather than inside either controller so registration and runs
    // stay separately testable.
    if (registered == null) return;
    await ref
        .read(indexRunsControllerProvider.notifier)
        .startIndex(registered.path);
  }
}

/// The first-run guidance, shown whenever nothing is registered (FR-LB-11).
class _FirstRunGuidance extends StatelessWidget {
  const _FirstRunGuidance();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: AppSpacing.xxl,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.librarySourcesEmptyTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.librarySourcesEmptyBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// The registered folders, each with its run (main flow steps 1, 3 and 6).
class _SourceList extends ConsumerWidget {
  const _SourceList({required this.state});

  final LibrarySourcesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final runs = ref.watch(indexRunsControllerProvider);

    return ListView.builder(
      itemCount: state.sources.length,
      itemBuilder: (context, index) {
        final source = state.sources[index];
        // UC-05 AF-03 highlights the entry the refused folder duplicated, so
        // the owner can see the one they already have rather than hunting.
        final highlighted = state.conflictingSource?.path == source.path;

        return Card(
          color: highlighted ? theme.colorScheme.secondaryContainer : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(source.label),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      source.path,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // What the folder is for, chosen when it was registered
                    // (UC-05). Shown on the row because it cannot be changed
                    // afterwards: an owner who scoped a folder wrongly has to
                    // be able to see that from the list.
                    Text(
                      _scopeOf(source, AppLocalizations.of(context)),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Keyed by path: without a key, Flutter can reuse a
                    // `_RunControlsState` — and the priority label it
                    // holds — for a different row at the same index once
                    // the list reorders (a folder added or removed).
                    _RunControls(
                      key: ValueKey(source.path),
                      root: source.path,
                      runs: runs,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _UnregisterAction(source: source),
                  ],
                ),
              ),
              _RunReport(root: source.path, runs: runs),
            ],
          ),
        );
      },
    );
  }
}

/// What an index of [source] records, as the row states it (UC-05).
///
/// An empty scope reads as every supported file rather than as nothing —
/// which is what it means, on this side and in the core.
String _scopeOf(LibrarySource source, AppLocalizations l10n) {
  // Asked before the emptiness test, because an unreadable scope resolves to
  // no types and would otherwise read as the widest possible answer — the
  // opposite of what the owner chose.
  if (source.scopeIsUnreadable) return l10n.librarySourcesScopeUnreadable;

  final types = source.scopeTypes;
  if (types.isEmpty) return l10n.librarySourcesScopeAll;

  return l10n.librarySourcesScopeOnly(
    types.map((type) => fileTypeLabel(type, l10n)).join(', '),
  );
}

/// The controls a folder's row offers, chosen from its own run state
/// (FR-LB-07, FR-LB-13, FR-LB-16 / core FR-FC-28, FR-FC-32 … FR-FC-34).
///
/// Each state offers only what it affords: running, this is pause, cancel
/// and priority; paused, it is resume and cancel; anything else — no run at
/// all, or one that is over — is Rescan. A row that offered a control its
/// state does not support (Rescan beside a running scan, Pause beside
/// nothing) is exactly the defect this shape exists to avoid, and it is what
/// makes a specific run addressable here once the activity strip collapses
/// to an aggregate and stops naming any one of them.
class _RunControls extends ConsumerStatefulWidget {
  const _RunControls({super.key, required this.root, required this.runs});

  final String root;
  final IndexRunsState runs;

  @override
  ConsumerState<_RunControls> createState() => _RunControlsState();
}

class _RunControlsState extends ConsumerState<_RunControls> {
  /// The pace the owner last asked for this folder, from the priority menu.
  ///
  /// Held here rather than read from the run, for the same reason the
  /// activity strip holds its own: the core does not report a run's
  /// priority, so a restart reads `normal` again — which is honest, since the
  /// application genuinely does not know otherwise.
  RunPriority _priority = RunPriority.normal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final run = widget.runs.runFor(widget.root);
    final starting = widget.runs.isStarting(widget.root);

    if (starting) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: AppSpacing.md,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(l10n.librarySourcesIndexing),
        ],
      );
    }

    if (run?.status == IndexRunStatus.running) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PriorityMenu(priority: _priority, onSelected: _repace),
          IconButton(
            tooltip: l10n.librarySourcesPause,
            icon: const Icon(Icons.pause),
            onPressed: () => ref
                .read(indexRunsControllerProvider.notifier)
                .pause(widget.root),
          ),
          IconButton(
            tooltip: l10n.librarySourcesCancelRun,
            icon: const Icon(Icons.close),
            onPressed: () => _confirmCancel(context, ref, widget.root),
          ),
        ],
      );
    }

    if (run?.status == IndexRunStatus.paused) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.librarySourcesResume,
            icon: const Icon(Icons.play_arrow),
            // No priority on a plain resume: null asks the core to keep the
            // pace the run already had, and passing the menu's last choice
            // would silently re-pace a scan the owner never touched here.
            onPressed: () => ref
                .read(indexRunsControllerProvider.notifier)
                .resume(widget.root),
          ),
          IconButton(
            tooltip: l10n.librarySourcesCancelRun,
            icon: const Icon(Icons.close),
            onPressed: () => _confirmCancel(context, ref, widget.root),
          ),
        ],
      );
    }

    // No run at all, or one that is over: a rescan is this folder's own job
    // now that the first index after registering happens on its own.
    return TextButton.icon(
      onPressed: () => ref
          .read(indexRunsControllerProvider.notifier)
          .startIndex(widget.root),
      icon: const Icon(Icons.sync),
      label: Text(l10n.librarySourcesRescan),
    );
  }

  /// Re-paces the running scan to [priority] (FR-FC-31).
  ///
  /// The core cannot change a running run's pace, so this is a pause
  /// followed by a resume, the same as the activity strip's own re-pacing.
  Future<void> _repace(RunPriority priority) async {
    final controller = ref.read(indexRunsControllerProvider.notifier);
    setState(() => _priority = priority);

    await controller.pause(widget.root);

    // The pause can be refused — most likely `RUN_ERR_INVALID_STATE`,
    // because the run moved on between the menu opening and the owner
    // choosing a pace. Reading the run back rather than assuming success is
    // what stops a resume from being sent against a run pause never
    // actually reached.
    final paused =
        ref.read(indexRunsControllerProvider).runFor(widget.root)?.status ==
        IndexRunStatus.paused;
    if (!paused) return;

    await controller.resume(widget.root, priority: priority);
  }
}

/// The pace a running scan is being asked to keep (FR-FC-31).
class _PriorityMenu extends StatelessWidget {
  const _PriorityMenu({required this.priority, required this.onSelected});

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

/// Confirms and then cancels [root]'s run (FR-LB-17 / core FR-FC-34).
///
/// Cancel is terminal and not resumable, unlike pause, so — like every other
/// destructive action (FR-UX-10) — it asks before doing anything the owner
/// cannot undo. The gateway is not reached until the dialog is answered.
Future<void> _confirmCancel(
  BuildContext context,
  WidgetRef ref,
  String root,
) async {
  final l10n = AppLocalizations.of(context);

  final confirmed = await ConfirmationDialog.show(
    context,
    title: l10n.librarySourcesCancelRunTitle,
    message: l10n.librarySourcesCancelRunConfirm,
    confirmLabel: l10n.librarySourcesCancelRunAction,
  );

  // Declining changes nothing at all.
  if (!confirmed) return;

  await ref.read(indexRunsControllerProvider.notifier).cancel(root);
}

/// A run's outcome, which stays until dismissed (FR-LB-08).
class _RunReport extends ConsumerWidget {
  const _RunReport({required this.root, required this.runs});

  final String root;
  final IndexRunsState runs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final run = runs.runFor(root);
    final failure = runs.failureFor(root);
    final refused = runs.refusedSecondRunFor == root;
    final startRefusal = runs.startRefusalFor(root);

    final message = switch ((run, failure, refused)) {
      // Refused before the core was called at all: the folder's scope could
      // not be read, or the folder is not registered any more. First, because
      // nothing was started — there is no run or failure to report over it.
      _ when startRefusal != null => switch (startRefusal) {
        IndexStartRefusal.unreadableScope =>
          l10n.librarySourcesStartUnreadableScope,
        IndexStartRefusal.notRegistered =>
          l10n.librarySourcesStartNotRegistered,
      },
      // AF-01.
      (_, _, true) => l10n.librarySourcesRunRefused,
      // AF-02 and AF-03: the core refused the start. AF-03's offer to
      // unregister the folder is `offersUnregister` below.
      (_, final Failure problem, _) =>
        '${l10n.librarySourcesStartFailed} ${problem.localizedMessage(l10n)}',
      (final IndexRun finished, _, _) when !finished.isInFlight => _outcomeOf(
        finished,
        l10n,
      ),
      _ => null,
    };

    if (message == null) return const SizedBox.shrink();

    // UC-06 AF-03: a folder the core could not scan is one the owner may want
    // rid of, so the failure carries the offer. Only on a start failure —
    // a finished run says nothing about whether the folder should stay.
    final offersUnregister =
        failure != null && !refused && startRefusal == null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
          if (offersUnregister)
            TextButton(
              onPressed: () => _confirmUnregister(context, ref, root),
              child: Text(l10n.librarySourcesUnregister),
            ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.dismiss,
            onPressed: () {
              final controller = ref.read(indexRunsControllerProvider.notifier);
              refused
                  ? controller.acknowledgeRefusal()
                  : controller.dismiss(root);
            },
          ),
        ],
      ),
    );
  }

  /// What a finished run reports (main flow step 5).
  ///
  /// The counts are the core's own for an index run — scanned, indexed,
  /// skipped, failed. FR-LB-08 asks for "added, updated, missing"; the core
  /// reports none of those three for this run kind, and only a refresh run
  /// (UC-07) reports anything missing at all.
  String _outcomeOf(IndexRun run, AppLocalizations l10n) {
    final counts = run.counts;

    final summary = switch (run.status) {
      // The core calls this `paused`, not `interrupted` — a run the
      // application was closed on is resumable, which "interrupted" never
      // was. The row's own resume control (in _RunControls) is the other
      // half of taking that fact seriously.
      IndexRunStatus.paused => l10n.librarySourcesRunPaused,
      IndexRunStatus.failed => l10n.librarySourcesRunFailed,

      // Core FR-FC-34: the core keeps a cancelled run's tally, so without this arm
      // the counts below fire and the owner who just abandoned a scan is told
      // it finished.
      IndexRunStatus.cancelled => l10n.librarySourcesRunCancelled,
      _ when counts == null => l10n.librarySourcesRunFailed,
      _ => l10n.librarySourcesRunComplete(
        counts.scanned,
        counts.indexed,
        counts.skipped,
      ),
    };

    if (counts == null || counts.failed == 0) return summary;

    return '$summary ${l10n.librarySourcesRunFailedCount(counts.failed)}';
  }
}

/// A message the owner can dismiss, in the screen's warning colours.
class _NoticeBar extends StatelessWidget {
  const _NoticeBar({
    required this.message,
    required this.onDismiss,
    this.action,
  });

  final String message;
  final VoidCallback onDismiss;

  /// What the message leads to, when it leads somewhere.
  ///
  /// UC-07 AF-03 asks that an outcome reporting missing files *link* to the
  /// review rather than only naming the count.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (action case final action?) ...[
            const SizedBox(width: AppSpacing.sm),
            action,
          ],
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.dismiss,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

/// Why the last registration attempt was refused (UC-05 AF-02, AF-03).
class _RefusalNotice extends ConsumerWidget {
  const _RefusalNotice({required this.state});

  final LibrarySourcesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final path = state.refusedPath ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              // FR-LB-02 requires the three refusals be told apart, so each
              // reads as the condition that failed rather than as one "no".
              switch (state.refusal!) {
                FolderRegistrationVerdict.missing => l10n.librarySourcesMissing(
                  path,
                ),
                FolderRegistrationVerdict.unreadable =>
                  l10n.librarySourcesUnreadable(path),
                FolderRegistrationVerdict.alreadyRegistered =>
                  l10n.librarySourcesAlreadyRegistered,
                // Neither reaches here: one is not a refusal and the other is
                // not a verdict the notice is shown for.
                FolderRegistrationVerdict.overlaps ||
                FolderRegistrationVerdict.acceptable => '',
              },
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            // Its own label rather than the screen's close: dismissing a
            // notice and closing the screen are different actions, and a
            // reader reaching for one must not find the other.
            icon: const Icon(Icons.close),
            tooltip: l10n.dismiss,
            onPressed: () => ref
                .read(librarySourcesControllerProvider.notifier)
                .acknowledgeRefusal(),
          ),
        ],
      ),
    );
  }
}

/// The control that unregisters a folder (UC-08 main flow step 1).
class _UnregisterAction extends ConsumerWidget {
  const _UnregisterAction({required this.source});

  final LibrarySource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return TextButton.icon(
      onPressed: () => _confirmUnregister(context, ref, source.path),
      icon: const Icon(Icons.delete_outline),
      label: Text(l10n.librarySourcesUnregister),
    );
  }
}

/// Confirms and then unregisters [path] (UC-08 main flow steps 2–4).
///
/// Through the shell's confirmation modal, which is where FR-UX-10 puts every
/// destructive action — and this one is destructive only in the narrow sense
/// that a registration goes away. The message says so: the catalog and the
/// disk are untouched, which is exactly what FR-LB-10 requires be stated.
Future<void> _confirmUnregister(
  BuildContext context,
  WidgetRef ref,
  String path,
) async {
  // AF-02 first: a folder the core is still scanning is refused before the
  // owner is asked anything. Confirming a removal that then quietly does not
  // happen is worse than being told up front, and the controller's own rule is
  // what answers — this does not restate it.
  if (ref.read(indexRunsControllerProvider).runFor(path)?.isInFlight ?? false) {
    await ref
        .read(librarySourcesControllerProvider.notifier)
        .unregisterFolder(path);
    return;
  }

  final l10n = AppLocalizations.of(context);
  final label = ref
      .read(librarySourcesControllerProvider)
      .sources
      .firstWhere(
        (source) => source.path == path,
        orElse: () => LibrarySource(
          path: path,
          label: path,
          registeredAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      )
      .label;

  final confirmed = await ConfirmationDialog.show(
    context,
    title: l10n.librarySourcesUnregisterTitle(label),
    message: l10n.librarySourcesUnregisterBody,
    confirmLabel: l10n.librarySourcesUnregisterConfirm,
  );

  // AF-01: cancelling changes nothing at all.
  if (!confirmed) return;

  await ref
      .read(librarySourcesControllerProvider.notifier)
      .unregisterFolder(path);
}

/// The control that starts a catalog-wide refresh (UC-07, FR-LB-06).
class _RefreshAction extends ConsumerWidget {
  const _RefreshAction();

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
      label: Text(
        busy ? l10n.librarySourcesRefreshing : l10n.librarySourcesRecheck,
      ),
    );
  }
}

/// What the refresh is doing, or did (UC-07 main flow step 4, FR-LB-08).
class _RefreshReport extends ConsumerWidget {
  const _RefreshReport();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final runs = ref.watch(indexRunsControllerProvider);
    final run = runs.refreshRun;

    final message = switch ((runs.refreshRefusal, runs.refreshFailure, run)) {
      // AF-01.
      (RefreshRefusal.alreadyRunning, _, _) =>
        l10n.librarySourcesRefreshRunning,
      // AF-02: nothing cataloged, so adding and indexing a folder is what the
      // owner needs — and both actions are already on this screen.
      (RefreshRefusal.catalogEmpty, _, _) => l10n.librarySourcesRefreshEmpty,
      (_, final Failure problem, _) =>
        '${l10n.librarySourcesRefreshFailed} ${problem.localizedMessage(l10n)}',
      (_, _, final IndexRun finished)
          when !finished.isInFlight && finished.counts != null =>
        _outcomeOf(finished.counts!, l10n),
      _ => null,
    };

    if (message == null) return const SizedBox.shrink();

    // AF-03: the outcome links to the missing-files review (UC-37). Offered
    // only when this run actually marked something missing — a link to an
    // empty review is a dead end.
    final markedMissing = (run?.counts?.markedMissing ?? 0) > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _NoticeBar(
        message: message,
        action: markedMissing
            ? TextButton.icon(
                onPressed: () => MissingFilesScreen.show(context),
                icon: const Icon(Icons.help_outline),
                label: Text(l10n.missingFilesOpen),
              )
            : null,
        onDismiss: () =>
            ref.read(indexRunsControllerProvider.notifier).dismissRefresh(),
      ),
    );
  }

  /// A finished refresh's tally, in the core's counts for a refresh run.
  ///
  /// The count of files now missing is part of the summary FR-LB-08 asks for;
  /// the link to the review beside it is AF-03's.
  String _outcomeOf(IndexRunCounts counts, AppLocalizations l10n) {
    final summary = l10n.librarySourcesRefreshComplete(
      counts.refreshed,
      counts.unchanged,
      counts.markedMissing,
    );

    return summary;
  }
}
