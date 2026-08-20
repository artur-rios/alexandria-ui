import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/playback_colors.dart';
import '../../catalog/domain/catalog_file.dart';
import '../application/image_viewer_controller.dart';
import '../domain/file_viewer.dart';
import 'viewer_failure_view.dart';

/// The image viewer (UC-24, FR-VW-04).
class ImageViewerScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const ImageViewerScreen({super.key});

  /// Opens [file] out of the listing it was opened from (main flow step 1).
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    CatalogFile file,
    List<CatalogFile> listing,
  ) {
    ref.read(imageViewerControllerProvider.notifier).open(file, listing);

    return showDialog<void>(
      context: context,
      builder: (context) => const Dialog.fullscreen(child: ImageViewerScreen()),
    ).whenComplete(
      () => ref.read(imageViewerControllerProvider.notifier).close(),
    );
  }

  @override
  ConsumerState<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends ConsumerState<ImageViewerScreen> {
  /// Holds the zoom and the pan, so returning to fit is one call (FR-VW-04).
  final TransformationController _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  /// Step 4's "returns to fit".
  void _resetFit() => _transform.value = Matrix4.identity();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(imageViewerControllerProvider);
    final controller = ref.read(imageViewerControllerProvider.notifier);

    // Moving to another image starts it fitted rather than at the zoom the
    // last one was left at, which would drop the owner into the middle of a
    // picture they have not seen.
    ref.listen(imageViewerControllerProvider, (previous, next) {
      if (previous?.index != next.index) _resetFit();
    });

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowRight): _MoveIntent(
          forward: true,
        ),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveIntent(
          forward: false,
        ),
      },
      child: Actions(
        actions: {
          _MoveIntent: CallbackAction<_MoveIntent>(
            onInvoke: (intent) =>
                intent.forward ? controller.next() : controller.previous(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: context.playbackColors.surround,
            appBar: AppBar(
              title: Text(state.current?.name ?? ''),
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.viewerClose,
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  tooltip: l10n.imageFit,
                  icon: const Icon(Icons.fit_screen_outlined),
                  onPressed: _resetFit,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
            body: switch (state.stage) {
              ImageStage.closed => const SizedBox.shrink(),
              ImageStage.failed => _Failed(
                failure: state.failure ?? ViewerFailure.unreadable,
                name: state.current?.name ?? '',
              ),
              ImageStage.open => _Image(transform: _transform),
            },
            bottomNavigationBar: const _ImageBar(),
          ),
        ),
      ),
    );
  }
}

class _MoveIntent extends Intent {
  const _MoveIntent({required this.forward});

  final bool forward;
}

/// The image, fitted, zoomable, and pannable (FR-VW-04).
class _Image extends ConsumerWidget {
  const _Image({required this.transform});

  final TransformationController transform;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageViewerControllerProvider);
    final file = state.current;
    if (file == null) return const SizedBox.shrink();

    return InteractiveViewer(
      transformationController: transform,
      minScale: 1,
      maxScale: 8,
      child: Center(
        child: Image.file(
          File(file.path),
          // Step 3: fitted to the window, and the zoom is the transform above
          // rather than a different fit.
          fit: BoxFit.contain,
          // AF-03: a very large image is not decoded at its full size for a
          // window that cannot show it. The decoder is given the window, and
          // it refines from there rather than blocking on a hundred megapixels.
          cacheWidth: MediaQuery.sizeOf(context).width.round(),
          filterQuality: FilterQuality.medium,
          // AF-02: the decoder refused it. Raised into the controller, which
          // is what decides what the viewer shows.
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(imageViewerControllerProvider.notifier)
                  .reportUndecodable();
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

/// What AF-01 and AF-02 show.
///
/// AF-02 offers the next image, which the shared failure view does not — it is
/// the one answer a viewer with a listing behind it can give.
class _Failed extends ConsumerWidget {
  const _Failed({required this.failure, required this.name});

  final ViewerFailure failure;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(imageViewerControllerProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: ViewerFailureView(failure: failure, name: name),
        ),
        if (failure == ViewerFailure.unreadable && state.hasNext)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: FilledButton.icon(
              onPressed: ref.read(imageViewerControllerProvider.notifier).next,
              icon: const Icon(Icons.chevron_right),
              label: Text(l10n.imageNext),
            ),
          ),
      ],
    );
  }
}

/// Where the owner is in the listing, and how they move through it.
class _ImageBar extends ConsumerWidget {
  const _ImageBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(imageViewerControllerProvider);
    final controller = ref.read(imageViewerControllerProvider.notifier);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: l10n.imagePrevious,
              icon: const Icon(Icons.chevron_left),
              onPressed: state.hasPrevious ? controller.previous : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              l10n.imageOf(state.index + 1, state.files.length),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(width: AppSpacing.md),
            IconButton(
              tooltip: l10n.imageNext,
              icon: const Icon(Icons.chevron_right),
              onPressed: state.hasNext ? controller.next : null,
            ),
          ],
        ),
      ),
    );
  }
}
