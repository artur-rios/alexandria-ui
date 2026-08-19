import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../shell/presentation/confirmation_dialog.dart';

/// Ends the session (UC-03 main flow step 1, FR-AU-09).
///
/// It sits in the preferences dialog beside the other account actions, which
/// is the one surface reachable from every area of the shell — signing out is
/// not a place in the library, so it is not a destination in the navigation
/// panel.
class SignOutButton extends ConsumerWidget {
  /// Creates the button.
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => _signOut(context, ref),
        icon: const Icon(Icons.logout_outlined),
        label: Text(l10n.signOut),
      ),
    );
  }

  /// Warns, then signs out (main flow steps 2 to 4, AF-01).
  ///
  /// The warning goes through the application's one confirmation dialog
  /// (FR-UX-10), which names what is about to be lost and defaults to
  /// cancelling — cancelling is how the owner goes back and saves first, which
  /// is the option AF-01 requires.
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(signOutControllerProvider);
    final navigator = Navigator.of(context);

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

    // The preferences dialog is closed explicitly rather than left to the
    // screen behind it changing: a route is not dismissed by what it is drawn
    // over, and the login screen would otherwise appear underneath it.
    if (navigator.mounted) navigator.pop();
  }
}
