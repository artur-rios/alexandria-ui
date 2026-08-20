import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';

/// The recovery codes a new account was given, shown once (UC-40).
///
/// In place of the catalog, and the only way past it is the acknowledgement
/// (AF-01): there is no skip, no dismissal, and no route around it, because
/// this is the single moment the codes exist anywhere (FR-AU-12).
///
/// Nothing here writes them down. They are read from the session state, put on
/// the clipboard if the owner asks, and dropped when the owner says they have
/// them (FR-AU-13) — a file would be a stored value, which is exactly what
/// this must not create.
class RecoveryCodesScreen extends ConsumerWidget {
  /// Creates the screen for [codes].
  const RecoveryCodesScreen({required this.codes, super.key});

  /// The codes the core minted. Empty is AF-03: an account created without a
  /// set, which is worth saying rather than showing as an empty list.
  final List<String> codes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.key_outlined,
                  size: AppSpacing.xxl,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.recoveryCodesTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),

                if (codes.isEmpty)
                  // AF-03: the account exists and the session is open; there
                  // is simply no set to show. Said plainly, with the way to
                  // get one (UC-42).
                  Text(
                    l10n.recoveryCodesNone,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  )
                else ...[
                  Text(
                    l10n.recoveryCodesExplanation,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _CodeList(codes: codes),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: () => unawaited(_copy(context, l10n)),
                      icon: const Icon(Icons.copy_outlined),
                      label: Text(l10n.recoveryCodesCopy),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  // Step 4, and the only way out of this screen (AF-01).
                  onPressed: ref
                      .read(sessionControllerProvider.notifier)
                      .acknowledgeRecoveryCodes,
                  child: Text(l10n.recoveryCodesAcknowledge),
                ),
                const SizedBox(height: AppSpacing.sm),
                // AF-04: leaving without storing them is allowed, and costs
                // the codes — which is what UC-42 exists to repair.
                TextButton(
                  onPressed: () =>
                      unawaited(ref.read(signOutControllerProvider).signOut()),
                  child: Text(l10n.signOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// AF-02: onto the clipboard, and nowhere else.
  Future<void> _copy(BuildContext context, AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);

    await Clipboard.setData(ClipboardData(text: codes.join('\n')));

    messenger.showSnackBar(SnackBar(content: Text(l10n.recoveryCodesCopied)));
  }
}

/// The codes themselves, monospaced so a transcribed character is unambiguous.
class _CodeList extends StatelessWidget {
  const _CodeList({required this.codes});

  final List<String> codes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final code in codes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: SelectableText(
                code,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
