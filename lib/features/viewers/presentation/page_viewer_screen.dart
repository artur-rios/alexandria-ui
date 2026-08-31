import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/domain/catalog_file.dart';
import '../../editing/presentation/text_editor_screen.dart';
import '../application/page_viewer_controller.dart';
import '../domain/file_viewer.dart';
import 'viewer_failure_view.dart';

/// The page viewer (UC-25, FR-VW-05, FR-VW-06).
///
/// Widgets rather than a browser engine, which is what makes "executes no
/// script" a property of the renderer instead of a setting somebody has to
/// remember to keep off (Technology Stack Document §3.4).
class PageViewerScreen extends ConsumerWidget {
  /// Creates the screen.
  const PageViewerScreen({super.key});

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
    final viewer = ref.read(pageViewerControllerProvider.notifier);

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

    return showDialog<void>(
      context: context,
      builder: (context) => const Dialog.fullscreen(child: PageViewerScreen()),
    ).whenComplete(viewer.close);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(pageViewerControllerProvider);
    final file = state.target;

    return Scaffold(
      appBar: AppBar(
        title: Text(file?.name ?? ''),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.viewerClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Step 4: a Markdown file may be switched into the editor. An HTML
          // page may not — this application does not edit one (BR-06).
          if (state.isEditable && file != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: TextButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final target = CatalogFile(
                    uuid: file.uuid,
                    name: file.name,
                    path: file.path,
                    type: file.type,
                  );

                  navigator.pop();
                  await TextEditorScreen.show(context, ref, target);
                },
                icon: const Icon(Icons.edit_note_outlined),
                label: Text(l10n.editorOpen),
              ),
            ),
        ],
      ),
      body: switch (state.stage) {
        PageStage.closed => const SizedBox.shrink(),
        PageStage.opening => const Center(child: CircularProgressIndicator()),
        PageStage.failed => ViewerFailureView(
          failure: state.failure ?? ViewerFailure.unreadable,
          name: file?.name ?? '',
        ),
        PageStage.open => const _Page(),
      },
    );
  }
}

/// The rendered page, and what it could not show.
class _Page extends ConsumerWidget {
  const _Page();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(pageViewerControllerProvider).content;
    if (content == null) return const SizedBox.shrink();

    return Column(
      children: [
        // AF-03: nothing here runs script, and the owner is told rather than
        // left to wonder why the page's buttons do nothing.
        if (content.hasScript) const _Notice(kind: _NoticeKind.script),

        // AF-04: what could be parsed is drawn, and the rest is admitted to.
        if (content.isMalformed) const _Notice(kind: _NoticeKind.malformed),

        // AF-02: the page renders without them, and says which.
        if (content.missingAssets.isNotEmpty)
          _Notice(
            kind: _NoticeKind.missingAssets,
            detail: content.missingAssets.join(', '),
          ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: ConstrainedBox(
                // A measure, as in the e-book viewer: a saved article running
                // the width of a desktop display is unreadable.
                constraints: const BoxConstraints(maxWidth: 800),
                child: HtmlWidget(content.html),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Which of the three things the viewer has to say.
enum _NoticeKind { script, malformed, missingAssets }

/// A line above the page, saying what it is not showing.
class _Notice extends StatelessWidget {
  const _Notice({required this.kind, this.detail});

  final _NoticeKind kind;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final message = switch (kind) {
      _NoticeKind.script => l10n.pageScriptsNotRun,
      _NoticeKind.malformed => l10n.pageMalformed,
      _NoticeKind.missingAssets => l10n.pageMissingAssets(detail ?? ''),
    };

    return Container(
      width: double.infinity,
      color: theme.colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(
            switch (kind) {
              _NoticeKind.script => Icons.code_off_outlined,
              _NoticeKind.malformed => Icons.warning_amber_outlined,
              _NoticeKind.missingAssets => Icons.image_not_supported_outlined,
            },
            size: AppSpacing.md,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
