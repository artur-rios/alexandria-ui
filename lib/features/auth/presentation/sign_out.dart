import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../shell/presentation/confirmation_dialog.dart';

/// Warns, then signs out (UC-03 main flow steps 2 to 4, AF-01).
///
/// The warning goes through the application's one confirmation dialog
/// (FR-UX-10), which names what is about to be lost and defaults to
/// cancelling — cancelling is how the owner goes back and saves first, which
/// is the option AF-01 requires.
///
/// Nothing is popped afterwards. Signing out replaces the shell with the login
/// screen at the root, and a pop here would be dismissing a route that the
/// session change has already taken away.
Future<void> confirmAndSignOut(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final controller = ref.read(signOutControllerProvider);

  if (controller.holdsUnsavedChanges) {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: l10n.signOutUnsavedTitle,
      message: l10n.signOutUnsavedMessage,
      confirmLabel: l10n.signOutUnsavedConfirm,
    );
    if (!confirmed) return;
  }

  await controller.signOut();
}
