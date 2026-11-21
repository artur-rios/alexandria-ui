import 'dart:io';

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/domain/file_size.dart';
import '../application/update_close.dart';
import '../application/update_state.dart';
import '../domain/release_info.dart';

/// The update prompt, following the update as it moves along
/// (update-check design §5).
class UpdateDialog extends ConsumerWidget {
  /// Creates the dialog.
  const UpdateDialog({super.key});

  /// Shows the prompt over [context] and waits until it closes. An offer the
  /// owner dismissed some other way counts as "later".
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final presence = ref.read(updatePromptPresenceProvider.notifier);
    if (ref.read(updatePromptPresenceProvider)) return;
    presence.mark(open: true);
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const UpdateDialog(),
      );
    } finally {
      if (ref.context.mounted) presence.mark(open: false);
    }
    if (ref.read(updateControllerProvider) is UpdateAvailable) {
      ref.read(updateControllerProvider.notifier).later();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);

    void close() => Navigator.of(context).pop();
    Future<void> openPage(ReleaseInfo release) =>
        ref.read(browserLauncherProvider).open(release.pageUrl);

    return switch (state) {
      UpdateAvailable(:final release, :final canInstall) => AlertDialog(
        title: Text(l10n.updateAvailableTitle(release.version.toString())),
        content: _Offer(
          release: release,
          running: ref.read(appVersionProvider),
          manual: !canInstall,
        ),
        actions: [
          if (canInstall) ...[
            TextButton(
              onPressed: () async {
                await controller.skip();
                if (context.mounted) close();
              },
              child: Text(l10n.updateSkip),
            ),
            TextButton(
              onPressed: () {
                controller.later();
                close();
              },
              child: Text(l10n.updateLater),
            ),
            FilledButton(
              autofocus: true,
              onPressed: controller.download,
              child: Text(l10n.updateNow),
            ),
          ] else ...[
            TextButton(
              onPressed: () {
                controller.later();
                close();
              },
              child: Text(l10n.updateClose),
            ),
            FilledButton(
              autofocus: true,
              onPressed: () => openPage(release),
              child: Text(l10n.updateOpenPage),
            ),
          ],
        ],
      ),
      UpdateDownloading(:final release, :final received, :final total) =>
        AlertDialog(
          title: Text(l10n.updateAvailableTitle(release.version.toString())),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.updateDownloading(
                  formatFileSize(received),
                  formatFileSize(total),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: total > 0 ? received / total : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: controller.cancelDownload,
              child: Text(l10n.updateCancel),
            ),
          ],
        ),
      UpdateDownloadFailed(:final release) => _notice(
        l10n,
        message: l10n.updateDownloadFailed,
        onClose: () {
          controller.dismiss();
          close();
        },
        onOpenPage: () => openPage(release),
      ),
      UpdateVerifyFailed(:final release) => _notice(
        l10n,
        message: l10n.updateVerifyFailed,
        onClose: () {
          controller.dismiss();
          close();
        },
        onOpenPage: () => openPage(release),
      ),
      UpdatePreviousFailed(:final to) => _notice(
        l10n,
        message: l10n.updatePreviousFailed(to),
        onClose: () {
          controller.dismiss();
          close();
        },
        onOpenPage: () => ref
            .read(browserLauncherProvider)
            .open('https://github.com/artur-rios/alexandria-ui/releases'),
      ),
      UpdateReadyToInstall(:final release, :final package) => _Installing(
        release: release,
        package: package,
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _notice(
    AppLocalizations l10n, {
    required String message,
    required VoidCallback onClose,
    required VoidCallback onOpenPage,
  }) => AlertDialog(
    content: Text(message),
    actions: [
      TextButton(onPressed: onClose, child: Text(l10n.updateClose)),
      FilledButton(
        autofocus: true,
        onPressed: onOpenPage,
        child: Text(l10n.updateOpenPage),
      ),
    ],
  );
}

/// The release on offer: the running version, the notes, and — for a copy
/// that cannot update itself — where to get it.
class _Offer extends StatelessWidget {
  const _Offer({
    required this.release,
    required this.running,
    required this.manual,
  });

  final ReleaseInfo release;
  final String running;
  final bool manual;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.updateYouHave(running)),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.updateWhatsNew, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: MarkdownBody(data: release.notes),
            ),
          ),
          if (manual) ...[
            const SizedBox(height: AppSpacing.md),
            Text(l10n.updateManual),
          ],
        ],
      ),
    );
  }
}

/// Closes the application to install the verified package, once it is shown.
class _Installing extends ConsumerStatefulWidget {
  const _Installing({required this.release, required this.package});

  final ReleaseInfo release;
  final File package;

  @override
  ConsumerState<_Installing> createState() => _InstallingState();
}

class _InstallingState extends ConsumerState<_Installing> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _install());
  }

  Future<void> _install() async {
    if (!mounted) return;
    final closed = await closeForUpdate(
      context,
      ref,
      release: widget.release,
      package: widget.package,
    );
    // The owner kept unsaved work or a scan: the offer stands, and the
    // downloaded package goes.
    if (!closed && mounted) {
      ref.read(updateControllerProvider.notifier).abandonInstall();
    }
  }

  @override
  Widget build(BuildContext context) =>
      AlertDialog(content: Text(AppLocalizations.of(context).updateInstalling));
}
