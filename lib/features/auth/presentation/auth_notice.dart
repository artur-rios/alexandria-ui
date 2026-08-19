import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// What a notice is saying, which is what it is coloured by.
enum AuthNoticeTone {
  /// Something went wrong, or was refused.
  problem,

  /// Something the owner should know, where nothing went wrong — UC-03 AF-02
  /// is the first of these. Drawing it in the refusal colour would make a
  /// scan that is running normally read as a failure.
  information,
}

/// A bordered block carrying an icon and a message, used by both
/// authentication screens for anything the core refused.
///
/// Every color comes from the active scheme, so it reads in both themes and
/// meets the contrast floor in each (IR-10, NFR-08).
class AuthNotice extends StatelessWidget {
  /// Creates a notice showing [icon] beside [child].
  const AuthNotice({
    required this.icon,
    required this.child,
    this.tone = AuthNoticeTone.problem,
    super.key,
  });

  /// The icon shown beside the message.
  final IconData icon;

  /// The message, and any action that belongs with it.
  final Widget child;

  /// What the notice is saying. Defaults to a problem, which is what every
  /// notice on these screens was until UC-03.
  final AuthNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (background, foreground) = switch (tone) {
      AuthNoticeTone.problem => (
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
      ),
      AuthNoticeTone.information => (
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: foreground),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
