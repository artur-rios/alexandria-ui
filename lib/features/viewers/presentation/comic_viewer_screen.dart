import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/playback_colors.dart';
import '../../catalog/domain/catalog_file.dart';
import '../application/comic_viewer_controller.dart';
import '../domain/file_viewer.dart';
import 'viewer_failure_view.dart';

/// The comic viewer (UC-23, FR-VW-03).
class ComicViewerScreen extends ConsumerWidget {
  /// Creates the screen.
  const ComicViewerScreen({super.key});

  /// Opens [file] (main flow step 1).
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    CatalogFile file,
  ) {
    // Taken once, and used for both ends. A dialog can be closed *for* the
    // owner — `SessionRouteGuard` does it when a session ends — and by then
    // the widget that lent this `ref` has gone with the shell, which makes
    // reading through it an error rather than a cleanup.
    final viewer = ref.read(comicViewerControllerProvider.notifier);

    unawaited(
      viewer.open(
        ViewerTarget(
          uuid: file.uuid,
          name: file.name,
          path: file.path,
          type: file.type,
        ),
      ),
    );

    // Step 5: nothing was extracted, and nothing is left behind.
    return showDialog<void>(
      context: context,
      builder: (context) => const Dialog.fullscreen(child: ComicViewerScreen()),
    ).whenComplete(viewer.close);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(comicViewerControllerProvider);
    final controller = ref.read(comicViewerControllerProvider.notifier);

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowRight): _TurnIntent(
          forward: true,
        ),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _TurnIntent(
          forward: false,
        ),
      },
      child: Actions(
        // FR-UX-11: a comic is read by turning pages, so the arrow keys turn
        // them.
        actions: {
          _TurnIntent: CallbackAction<_TurnIntent>(
            onInvoke: (intent) => unawaited(
              intent.forward ? controller.next() : controller.previous(),
            ),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: context.playbackColors.surround,
            appBar: AppBar(
              title: Text(state.target?.name ?? ''),
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.viewerClose,
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                // FR-VW-03's fit controls.
                IconButton(
                  tooltip: l10n.comicFitPage,
                  isSelected: state.fit == ComicFit.page,
                  icon: const Icon(Icons.fit_screen_outlined),
                  onPressed: () => controller.fit(ComicFit.page),
                ),
                IconButton(
                  tooltip: l10n.comicFitWidth,
                  isSelected: state.fit == ComicFit.width,
                  icon: const Icon(Icons.width_normal_outlined),
                  onPressed: () => controller.fit(ComicFit.width),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
            body: switch (state.stage) {
              ComicStage.closed => const SizedBox.shrink(),
              ComicStage.failed => ViewerFailureView(
                failure: state.failure ?? ViewerFailure.unreadable,
                name: state.target?.name ?? '',
              ),
              ComicStage.loading || ComicStage.open => const _Reader(),
            },
            bottomNavigationBar: state.stage == ComicStage.failed
                ? null
                : const _PageBar(),
          ),
        ),
      ),
    );
  }
}

class _TurnIntent extends Intent {
  const _TurnIntent({required this.forward});

  final bool forward;
}

/// The page itself.
class _Reader extends ConsumerWidget {
  const _Reader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(comicViewerControllerProvider);
    final bytes = state.bytes;

    if (state.stage == ComicStage.loading && bytes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (bytes == null) return const SizedBox.shrink();

    final page = Image.memory(
      bytes,
      // Fit to the page or to the width, which is the difference between
      // seeing the layout and reading the lettering.
      fit: state.fit == ComicFit.page ? BoxFit.contain : BoxFit.fitWidth,
      alignment: Alignment.topCenter,
      gaplessPlayback: true,
    );

    return switch (state.fit) {
      ComicFit.page => Center(child: page),
      // Fitted to the width, a page is taller than the window by design, so
      // it scrolls.
      ComicFit.width => SingleChildScrollView(
        child: SizedBox(width: double.infinity, child: page),
      ),
    };
  }
}

/// Where the owner is, and how they move (main flow step 3).
class _PageBar extends ConsumerWidget {
  const _PageBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(comicViewerControllerProvider);
    final controller = ref.read(comicViewerControllerProvider.notifier);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AF-04: the gap is marked rather than silently jumped — a comic
          // missing a page is something the owner should know about their file.
          if (state.skipped.isNotEmpty)
            Container(
              width: double.infinity,
              color: theme.colorScheme.errorContainer,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                l10n.comicPagesSkipped(
                  (state.skipped.toList()..sort()).join(', '),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: l10n.comicPreviousPage,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: state.hasPrevious
                      ? () => unawaited(controller.previous())
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  l10n.comicPageOf(state.page, state.pageCount),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton(
                  tooltip: l10n.comicNextPage,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: state.hasNext
                      ? () => unawaited(controller.next())
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
