import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shell/presentation/async_state_view.dart';
import '../domain/index_run.dart';

/// The files a run could not record (UC-06 AF-08 / core FR-FC-42).
///
/// The other half of the count on the folder's row. "3 files could not be
/// read" is a fact the owner can do nothing with on its own: those files are
/// on disk, in no listing, in no search, and until this screen they were
/// named nowhere outside a log file.
///
/// The path is what the screen is for, so the path is what it shows, whole
/// and selectable — the owner is going to go and look at these files, and a
/// truncated path sends them to the wrong folder. The reason sits under it in
/// the core's own words.
class RunFailuresScreen extends ConsumerWidget {
  /// Creates the screen.
  const RunFailuresScreen({required this.runId, super.key});

  /// The run whose failures are shown.
  final String runId;

  /// Presents the failures of [runId] over [context].
  static Future<void> show(BuildContext context, String runId) =>
      showDialog<void>(
        context: context,
        builder: (context) =>
            Dialog.fullscreen(child: RunFailuresScreen(runId: runId)),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final failures = ref.watch(runFailuresProvider(runId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.runFailuresTitle),
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
            // Said before the list: these files are not damaged and nothing
            // was deleted — they were not read, and another run is what
            // tries again.
            Text(l10n.runFailuresExplanation, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: AsyncStateView<List<RunFailure>>(
                value: failures,
                onRetry: () => ref.invalidate(runFailuresProvider(runId)),
                isEmpty: (rows) => rows.isEmpty,
                // A run whose failures are all gone — read after the record
                // was pruned, or a count that came from a different run.
                emptyBuilder: (context) =>
                    Center(child: Text(l10n.runFailuresNone)),
                builder: (context, rows) => ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final failure = rows[index];

                    return ListTile(
                      leading: Icon(
                        Icons.description_outlined,
                        color: theme.colorScheme.error,
                      ),
                      // Selectable, because the next thing the owner does
                      // with a path is paste it somewhere.
                      title: SelectableText(
                        failure.path,
                        style: theme.textTheme.bodyMedium,
                      ),
                      subtitle: failure.reason.isEmpty
                          ? null
                          : Text(
                              failure.reason,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
