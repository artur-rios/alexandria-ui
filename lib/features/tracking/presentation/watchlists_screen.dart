import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shell/presentation/async_state_view.dart';
import '../../shell/presentation/confirmation_dialog.dart';
import '../application/watchlists_controller.dart';
import '../domain/watchlist.dart';

/// The watchlists screen (UC-29, FR-TR-01 … FR-TR-04).
///
/// A full-screen dialog reached from the videos area, like the library-sources
/// screen: a watchlist is not a file type, so it is not a destination in the
/// navigation panel (FR-CT-01), and it is not a setting either.
class WatchlistsScreen extends ConsumerWidget {
  /// Creates the screen.
  const WatchlistsScreen({super.key});

  /// Presents the screen over [context] (main flow step 1).
  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => const Dialog.fullscreen(child: WatchlistsScreen()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final watchlists = ref.watch(watchlistsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.watchlistsTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.preferencesClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CreateField(),
            const _Notice(),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: AsyncStateView(
                value: watchlists,
                onRetry: ref.read(watchlistsControllerProvider.notifier).reload,
                isEmpty: (watchlists) => watchlists.isEmpty,
                emptyBuilder: (context) =>
                    Center(child: Text(l10n.watchlistsNone)),
                builder: (context, watchlists) => ListView.builder(
                  itemCount: watchlists.length,
                  itemBuilder: (context, index) =>
                      _WatchlistTile(watchlist: watchlists[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where a watchlist is created (main flow steps 1 and 2).
class _CreateField extends ConsumerStatefulWidget {
  const _CreateField();

  @override
  ConsumerState<_CreateField> createState() => _CreateFieldState();
}

class _CreateFieldState extends ConsumerState<_CreateField> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(watchlistsFormProvider);
    final form = ref.read(watchlistsFormProvider.notifier);

    // Cleared when the create succeeds, which is the one time the field's text
    // is not the owner's to keep.
    if (state.name.isEmpty && _name.text.isNotEmpty && !state.isCreating) {
      _name.clear();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _name,
            enabled: !state.isCreating,
            decoration: InputDecoration(
              labelText: l10n.watchlistNameLabel,
              // AF-01: marked, and the core is not called.
              errorText: state.nameError == null
                  ? null
                  : l10n.watchlistNameEmpty,
            ),
            onChanged: form.editName,
            onSubmitted: (_) => unawaited(form.create()),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: FilledButton.icon(
            onPressed: state.isCreating ? null : () => unawaited(form.create()),
            icon: const Icon(Icons.add),
            label: Text(l10n.watchlistCreate),
          ),
        ),
      ],
    );
  }
}

/// AF-03 and AF-04, and anything else the core refused.
class _Notice extends ConsumerWidget {
  const _Notice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(watchlistsFormProvider);
    if (state.notice == WatchlistNotice.none) return const SizedBox.shrink();

    final message = switch (state.notice) {
      WatchlistNotice.alreadyTracked => l10n.watchlistAlreadyTracked,
      WatchlistNotice.notFound => l10n.watchlistNotFound,
      WatchlistNotice.refused =>
        state.refusal?.localizedMessage(l10n) ?? l10n.watchlistNotFound,
      WatchlistNotice.none => '',
    };

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: ref.read(watchlistsFormProvider.notifier).acknowledge,
            child: Text(l10n.editorDismiss),
          ),
        ],
      ),
    );
  }
}

/// One watchlist, and what it tracks.
class _WatchlistTile extends ConsumerWidget {
  const _WatchlistTile({required this.watchlist});

  final Watchlist watchlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: ExpansionTile(
        title: Text(watchlist.name),
        subtitle: Text(l10n.watchlistItemCount(watchlist.items.length)),
        trailing: IconButton(
          tooltip: l10n.watchlistDelete,
          icon: const Icon(Icons.delete_outline),
          onPressed: () => unawaited(_delete(context, ref)),
        ),
        children: [
          if (watchlist.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(l10n.watchlistEmpty),
            )
          else
            for (final item in watchlist.items)
              _ItemTile(watchlist: watchlist, progress: item),
        ],
      ),
    );
  }

  /// Step 6: the confirmation states that the videos are preserved and only
  /// the tracking goes (FR-TR-02, BR-07). AF-05 is cancelling it.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await ConfirmationDialog.show(
      context,
      title: l10n.watchlistDelete,
      message: l10n.watchlistDeleteMessage(watchlist.name),
      confirmLabel: l10n.watchlistDelete,
    );
    if (!confirmed) return;

    await ref.read(watchlistsFormProvider.notifier).delete(watchlist.uuid);
  }
}

/// One tracked video inside a watchlist.
class _ItemTile extends ConsumerWidget {
  const _ItemTile({required this.watchlist, required this.progress});

  final Watchlist watchlist;
  final WatchProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return ListTile(
      dense: true,
      leading: const Icon(Icons.movie_outlined),
      // The video's name is the catalog's, and a watchlist carries only the
      // uuid the core tracks it by. UC-30 is what puts the progress on screen
      // beside it; this shows what the list holds.
      title: Text(progress.videoUuid),
      subtitle: Text(_stateLabel(l10n)),
      trailing: IconButton(
        tooltip: l10n.watchlistRemoveVideo,
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: () => unawaited(
          ref
              .read(watchlistsFormProvider.notifier)
              .removeVideo(
                watchlistUuid: watchlist.uuid,
                videoUuid: progress.videoUuid,
              ),
        ),
      ),
    );
  }

  String _stateLabel(AppLocalizations l10n) => switch (progress.state) {
    WatchState.pending => l10n.watchStatePending,
    WatchState.watching => l10n.watchStateWatching,
    WatchState.watched => l10n.watchStateWatched,
  };
}
