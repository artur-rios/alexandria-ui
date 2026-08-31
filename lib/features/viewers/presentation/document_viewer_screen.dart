import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/domain/catalog_file.dart';
import '../application/document_viewer_controller.dart';
import '../domain/document_gateway.dart';
import '../domain/file_viewer.dart';
import 'viewer_failure_view.dart';

/// The document viewer (UC-22, FR-VW-02).
///
/// A full-screen dialog, like the editor: reading is what the owner is doing
/// while it is open, and a document needs the width.
class DocumentViewerScreen extends ConsumerWidget {
  /// Creates the screen.
  const DocumentViewerScreen({super.key});

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
    final viewer = ref.read(documentViewerControllerProvider.notifier);

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

    // Step 6: nothing is retained once the viewer closes (FR-VW-07).
    return showDialog<void>(
      context: context,
      builder: (context) =>
          const Dialog.fullscreen(child: DocumentViewerScreen()),
    ).whenComplete(viewer.close);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(documentViewerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.target?.name ?? ''),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.viewerClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: switch (state.stage) {
        DocumentStage.closed => const SizedBox.shrink(),
        DocumentStage.opening => const Center(
          child: CircularProgressIndicator(),
        ),
        DocumentStage.failed => ViewerFailureView(
          failure: state.failure ?? ViewerFailure.unreadable,
          name: state.target?.name ?? '',
        ),
        DocumentStage.open => switch (state.document) {
          DocumentIsPdf(:final path) => _PdfView(path: path),
          DocumentIsBook() => const _BookView(),
          _ => const SizedBox.shrink(),
        },
      },
    );
  }
}

/// A PDF, with the renderer's own page navigation (FR-VW-02).
class _PdfView extends ConsumerWidget {
  const _PdfView({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(documentViewerControllerProvider.notifier);
    final position = ref.read(documentViewerControllerProvider).position;

    return PdfViewer.file(
      path,
      // Pages are one-based in the viewer and zero-based in the store, which
      // is the only place the two ever meet.
      initialPageNumber: position + 1,
      // AF-03: an encrypted document is reported, and no password is prompted
      // for or stored. Returning null is how the renderer is told there is
      // none to try, which is what turns an encrypted file into an error
      // rather than into a prompt.
      passwordProvider: () async => null,
      params: PdfViewerParams(
        // Step 5: the position follows the owner rather than being asked for.
        onPageChanged: (page) =>
            unawaited(controller.goTo(page == null ? 0 : page - 1)),
        // AF-02 and AF-03 both arrive here, and the renderer's own exception
        // is what tells them apart.
        errorBannerBuilder: (context, error, stackTrace, documentRef) =>
            ViewerFailureView(
              failure: error is PdfPasswordException
                  ? ViewerFailure.encrypted
                  : ViewerFailure.unreadable,
              name:
                  ref.read(documentViewerControllerProvider).target?.name ?? '',
            ),
      ),
    );
  }
}

/// An e-book, one chapter at a time (FR-VW-02).
class _BookView extends ConsumerWidget {
  const _BookView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(documentViewerControllerProvider);
    final controller = ref.read(documentViewerControllerProvider.notifier);
    final chapter = state.currentChapter;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: ConstrainedBox(
                // A measure rather than the window's width: a line of text
                // running the width of a desktop display is unreadable.
                constraints: const BoxConstraints(maxWidth: 720),
                child: HtmlWidget(chapter?.html ?? ''),
              ),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: l10n.viewerPrevious,
                icon: const Icon(Icons.chevron_left),
                onPressed: state.position > 0
                    ? () => unawaited(controller.previous())
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                l10n.viewerChapterOf(state.position + 1, state.chapters.length),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(width: AppSpacing.md),
              IconButton(
                tooltip: l10n.viewerNext,
                icon: const Icon(Icons.chevron_right),
                onPressed: state.position + 1 < state.chapters.length
                    ? () => unawaited(controller.next())
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
