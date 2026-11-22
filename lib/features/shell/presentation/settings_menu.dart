import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import 'menu_entry.dart';
import 'preferences_dialog.dart';

/// Preferences (UC-39 main flow step 1, FR-UX-01).
///
/// A named menu in the bar rather than a button at the bottom of the
/// navigation rail: it is where a desktop owner looks first.
class SettingsMenu extends StatelessWidget {
  /// Creates the menu.
  const SettingsMenu({required this.showsLabel, super.key});

  /// Whether the trigger carries its label beside its icon (FR-UX-02).
  final bool showsLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final button = SubmenuButton(
      leadingIcon: const Icon(Icons.settings_outlined),
      menuChildren: [
        MenuEntry(
          icon: Icons.tune_outlined,
          label: l10n.preferencesLabel,
          onSelected: () => PreferencesDialog.show(context),
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
