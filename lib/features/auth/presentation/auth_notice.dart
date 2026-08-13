import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// A bordered block carrying an icon and a message, used by both
/// authentication screens for anything the core refused.
///
/// Every color comes from the active scheme, so it reads in both themes and
/// meets the contrast floor in each (IR-10, NFR-08).
class AuthNotice extends StatelessWidget {
  /// Creates a notice showing [icon] beside [child].
  const AuthNotice({required this.icon, required this.child, super.key});

  /// The icon shown beside the message.
  final IconData icon;

  /// The message, and any action that belongs with it.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: theme.colorScheme.onErrorContainer),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
