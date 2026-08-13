import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';

/// What stands in place of the catalog while the account's e-mail is
/// unconfirmed (FR-AU-12, BR-25, UC-02 AF-06).
///
/// Deliberately minimal: the confirmation prompt itself — the code field, the
/// resend action, and their outcomes — is UC-40, which is blocked on core
/// support (System Requirements §5.4). This screen exists so that UC-02's
/// AF-06 has somewhere to land and the catalog is genuinely locked, rather
/// than the lock being deferred along with the prompt.
class CatalogLockedScreen extends StatelessWidget {
  /// Creates the locked state for the account at [email].
  const CatalogLockedScreen({required this.email, super.key});

  /// The address awaiting confirmation, named so the owner knows where to
  /// look.
  final String email;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: AppSpacing.xxl,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.catalogLockedTitle,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.catalogLockedBody(email),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
