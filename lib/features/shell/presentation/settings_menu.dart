import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../auth/presentation/change_credentials_dialog.dart';
import '../../auth/presentation/sign_out.dart';
import 'menu_entry.dart';
import 'preferences_dialog.dart';

/// Preferences and the account actions (UC-39 main flow step 1, FR-UX-01).
///
/// Preferences were behind a button at the bottom of the navigation rail, and
/// the account actions were inside the dialog that button opened — so leaving
/// the application took three levels of nesting through a screen that does not
/// announce it holds the exit. A named menu is one level, and it is where a
/// desktop owner looks first.
class SettingsMenu extends ConsumerWidget {
  /// Creates the menu.
  const SettingsMenu({required this.showsLabel, super.key});

  /// Whether the trigger carries its label beside its icon (FR-UX-02).
  final bool showsLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final button = SubmenuButton(
      leadingIcon: const Icon(Icons.settings_outlined),
      menuChildren: [
        MenuEntry(
          icon: Icons.tune_outlined,
          label: l10n.preferencesLabel,
          onSelected: () => PreferencesDialog.show(context),
        ),
        MenuEntry(
          icon: Icons.key_outlined,
          label: l10n.changeCredentialsOpen,
          onSelected: () => ChangeCredentialsDialog.show(context),
        ),
        // Last, and after a divider: it is the one action here that ends what
        // the others operate on.
        const Divider(),
        MenuEntry(
          icon: Icons.logout_outlined,
          label: l10n.signOut,
          onSelected: () => unawaited(confirmAndSignOut(context, ref)),
        ),
      ],
      child: showsLabel
          ? Text(l10n.settingsMenuLabel)
          : const SizedBox.shrink(),
    );

    if (showsLabel) return button;

    // The tooltip has to wrap the whole trigger, not sit on its shrunk
    // child: SubmenuButton lays `leadingIcon` and `child` side by side, so a
    // tooltip anchored to a zero-height child alone would cover a sliver
    // beside the icon that a pointer can never actually land on, and the
    // name it carries could never be revealed (FR-UX-02).
    return Tooltip(message: l10n.settingsMenuOpen, child: button);
  }
}
