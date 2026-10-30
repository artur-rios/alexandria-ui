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
import 'chromium_page.dart';
import 'page_widget_factory.dart';
import 'viewer_failure_view.dart';

/// The page viewer (UC-25, FR-VW-05, FR-VW-06).
///
/// A saved HTML page is drawn by the browser engine, sandboxed and held to
/// its own folder ([ChromiumPage]); a Markdown file, and a page the engine
/// cannot draw, are drawn as widgets, which run no script (NFR-12, Technology
/// Stack Document §3.4).
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
class _Page extends ConsumerStatefulWidget {
  const _Page();

  @override
  ConsumerState<_Page> createState() => _PageState();
}

class _PageState extends ConsumerState<_Page> {
  /// Why the engine did not draw this page, if it did not.
  ///
  /// Held here rather than asked again: once Chromium has failed on this
  /// machine it will keep failing, and a rebuild that tried it afresh would
  /// flicker between an empty frame and the markup.
  PageEngineFailure? _engineFailure;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pageViewerControllerProvider);
    final content = state.content;
    if (content == null) return const SizedBox.shrink();

    final path = state.target?.path;
    // Markdown is never handed to the engine: it was converted from text a
    // moment ago, carries no styling of its own, and reads better in this
    // application's own type than in a browser's defaults. The engine is for
    // pages somebody else wrote.
    final byEngine =
        ref.watch(pageEngineEnabledProvider) &&
        !content.isMarkdown &&
        _engineFailure == null &&
        path != null;

    return Column(
      children: [
        // AF-07, NFR-12: the engine is never started without Chromium's
        // sandbox, and an owner reading every page as widgets deserves to
        // know that it is the machine, not the page. Other failures are a
        // page's own and stay quiet, as AF-07 describes.
        if (_engineFailure == PageEngineFailure.sandboxUnavailable)
          const _Notice(kind: _NoticeKind.engineSandbox),

        // AF-03: said only when it is true. The markup renderer runs no
        // script and the owner is told rather than left to wonder why the
        // page's buttons do nothing; the engine runs it, so there is nothing
        // to say.
        if (content.hasScript && !byEngine)
          const _Notice(kind: _NoticeKind.script),

        // AF-04: what could be parsed is drawn, and the rest is admitted to.
        // The engine parses what no parser would call well-formed — recovering
        // from broken markup is most of what a browser does — so the notice
        // belongs to the renderer that really does drop what it cannot read.
        if (content.isMalformed && !byEngine)
          const _Notice(kind: _NoticeKind.malformed),

        // AF-02: the page renders without them, and says which. True of both
        // renderers: a picture that was never saved beside the page is not
        // there to draw either way.
        if (content.missingAssets.isNotEmpty)
          _Notice(
            kind: _NoticeKind.missingAssets,
            detail: content.missingAssets.join(', '),
          ),

        Expanded(
          child: byEngine
              // The file itself, not the markup this application read: the
              // engine opens it the way a browser would, and resolves its
              // stylesheets and pictures from the folder it sits in.
              ? ChromiumPage(
                  fileUrl: Uri.file(path).toString(),
                  onFailed: (failure) =>
                      setState(() => _engineFailure = failure),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: ConstrainedBox(
                      // A measure, as in the e-book viewer: a saved article
                      // running the width of a desktop display is unreadable.
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: HtmlWidget(
                        content.html,
                        // What the page's own relative references resolve
                        // against, which is what makes its pictures appear.
                        baseUrl: content.baseUrl,
                        factoryBuilder: PageWidgetFactory.new,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Which of the things the viewer has to say.
enum _NoticeKind { engineSandbox, script, malformed, missingAssets }

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
      _NoticeKind.engineSandbox => l10n.pageEngineSandboxUnavailable,
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
              _NoticeKind.engineSandbox => Icons.shield_outlined,
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
