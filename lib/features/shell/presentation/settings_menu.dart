import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../auth/presentation/change_credentials_dialog.dart';
import 'menu_entry.dart';
import 'preferences_dialog.dart';

/// Preferences and the account actions (UC-39 main flow step 1, FR-UX-01).
///
/// Preferences were behind a button at the bottom of the navigation rail, and
/// the account actions were inside the dialog that button opened — so leaving
/// the application took three levels of nesting through a screen that does not
/// announce it holds the exit. A named menu is one level, and it is where a
/// desktop owner looks first.
class SettingsMenu extends StatelessWidget {
  /// Creates the menu.
  const SettingsMenu({required this.showsLabel, super.key});

  /// Whether the trigger carries its label beside its icon (FR-UX-02).
  final bool showsLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SubmenuButton(
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
      ],
      child: showsLabel
          ? Text(l10n.settingsMenuLabel)
          : Tooltip(
              message: l10n.settingsMenuOpen,
              child: const SizedBox.shrink(),
            ),
    );
  }
}
