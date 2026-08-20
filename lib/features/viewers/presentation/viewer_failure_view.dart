import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/file_viewer.dart';

/// What a viewer shows when it cannot present the file (FR-VW-08).
///
/// One view for every viewer, because the failures are the same set wherever
/// they happen: a file that is not there, bytes that are not what they claim,
/// a document nobody has the key to, a format nothing bundled decodes, and a
/// type with no viewer at all. Each says something different, and only the
/// first has an answer — a re-scan.
class ViewerFailureView extends ConsumerWidget {
  /// Creates the view.
  const ViewerFailureView({
    required this.failure,
    required this.name,
    super.key,
  });

  /// Why the file could not be presented.
  final ViewerFailure failure;

  /// The file's name, for a message that names it.
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: AppSpacing.xl, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              _message(l10n),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),

            // Only a file that has gone missing has an answer. A damaged
            // document, an encrypted one, and a format nothing decodes are
            // none of them fixed by indexing again.
            if (failure == ViewerFailure.missingOnDisk) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () => ref
                    .read(indexRunsControllerProvider.notifier)
                    .startRefresh(),
                icon: const Icon(Icons.autorenew),
                label: Text(l10n.detailsRescan),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (failure) {
    ViewerFailure.missingOnDisk => Icons.search_off,
    ViewerFailure.encrypted => Icons.lock_outline,
    ViewerFailure.unsupportedFormat => Icons.help_outline,
    ViewerFailure.noViewer => Icons.visibility_off_outlined,
    ViewerFailure.unreadable => Icons.broken_image_outlined,
  };

  String _message(AppLocalizations l10n) => switch (failure) {
    ViewerFailure.missingOnDisk => l10n.viewerFileMissing,
    ViewerFailure.unreadable => l10n.viewerUnreadable,
    ViewerFailure.encrypted => l10n.viewerEncrypted,
    ViewerFailure.unsupportedFormat => l10n.viewerUnsupportedFormat(name),
    ViewerFailure.noViewer => l10n.viewerNone,
  };
}
