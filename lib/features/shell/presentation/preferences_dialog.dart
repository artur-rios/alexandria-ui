import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/application/session_state.dart';
import '../../auth/presentation/change_credentials_dialog.dart';
import '../../auth/presentation/sign_out_button.dart';
import '../../library_sources/presentation/library_sources_screen.dart';

/// The preferences dialog (UC-39, FR-UX-04, FR-UX-05, FR-UX-12).
///
/// A dialog rather than a screen, because main flow step 1 requires it
/// reachable "with or without a session" — it opens over the login screen and
/// over the shell alike, which a routed screen could not do without inventing
/// navigation no use case has asked for.
///
/// Nothing here has an apply or a cancel. Each choice takes effect the moment
/// it is made (steps 3 and 5), so [preferencesClose] closes a dialog whose
/// work is already done.
class PreferencesDialog extends ConsumerWidget {
  /// Creates the dialog.
  const PreferencesDialog({super.key});

  /// Presents the dialog over [context].
  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => const PreferencesDialog(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final preferences = ref.watch(preferencesControllerProvider);
    final controller = ref.read(preferencesControllerProvider.notifier);
    // UC-04 main flow step 1 puts the credential change here. It is offered
    // only with a session, because the core requires one to authorize the call
    // — and preferences themselves are reachable without one (UC-39).
    final signedIn = ref.watch(sessionControllerProvider) is SessionActive;

    return AlertDialog(
      title: Text(l10n.preferencesTitle),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          // Bounded so the dialog does not stretch across a wide display, and
          // scrollable so it stays usable at the minimum window height
          // (NFR-07).
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (preferences.lastChangeUnsaved) ...[
                _UnsavedNotice(message: l10n.preferencesUnsaved),
                const SizedBox(height: AppSpacing.md),
              ],

              _GroupLabel(l10n.preferencesThemeLabel),
              RadioGroup<ThemeMode>(
                groupValue: preferences.themeMode,
                onChanged: (mode) =>
                    mode == null ? null : controller.setThemeMode(mode),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final option in _ThemeOption.values)
                      RadioListTile<ThemeMode>(
                        value: option.mode,
                        title: Text(option.label(l10n)),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              _GroupLabel(l10n.preferencesLanguageLabel),
              // Keyed by a tag rather than by the nullable locale itself:
              // "follow the system" is `null`, and a null group value would
              // make every option read as unselected.
              RadioGroup<String>(
                groupValue: _LanguageOption.tagOf(preferences.locale),
                onChanged: (tag) => tag == null
                    ? null
                    : controller.setLocale(_LanguageOption.byTag(tag).locale),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final option in _LanguageOption.values)
                      RadioListTile<String>(
                        value: option.tag,
                        title: Text(option.label(l10n)),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),

              if (signedIn) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => LibrarySourcesScreen.show(context),
                    icon: const Icon(Icons.folder_outlined),
                    label: Text(l10n.librarySourcesOpen),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => ChangeCredentialsDialog.show(context),
                    icon: const Icon(Icons.key_outlined),
                    label: Text(l10n.changeCredentialsOpen),
                  ),
                ),
                // UC-03 main flow step 1. Last in the group, because it is the
                // one action here that ends what the others operate on.
                const SignOutButton(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          // The dialog's primary action, and the only one: focused so it is
          // reachable from the keyboard (FR-UX-11). Closing applies nothing,
          // so a stray return key costs the owner nothing.
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.preferencesClose),
        ),
      ],
    );
  }
}

/// The heading above a group of options.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

/// What AF-02 tells the owner: applied, but not remembered.
class _UnsavedNotice extends StatelessWidget {
  const _UnsavedNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The theme choices, in the order they are offered.
enum _ThemeOption {
  system(ThemeMode.system),
  light(ThemeMode.light),
  dark(ThemeMode.dark);

  const _ThemeOption(this.mode);

  final ThemeMode mode;

  String label(AppLocalizations l10n) => switch (this) {
    _ThemeOption.system => l10n.preferencesThemeSystem,
    _ThemeOption.light => l10n.preferencesThemeLight,
    _ThemeOption.dark => l10n.preferencesThemeDark,
  };
}

/// The language choices, in the order they are offered.
///
/// The two languages name themselves rather than being translated: an owner
/// who has landed in the language they cannot read finds their own by looking
/// for the word they recognize, which only works if it is written the way they
/// would write it.
enum _LanguageOption {
  system('system', null),
  english('en', Locale('en')),
  portuguese('pt-BR', Locale('pt', 'BR'));

  const _LanguageOption(this.tag, this.locale);

  /// The value the radio group compares on, standing in for the nullable
  /// [locale].
  final String tag;

  /// The locale this option selects, or `null` to follow the system.
  final Locale? locale;

  /// The option [tag] names.
  static _LanguageOption byTag(String tag) =>
      _LanguageOption.values.firstWhere((option) => option.tag == tag);

  /// The tag standing for [locale].
  static String tagOf(Locale? locale) => switch (locale) {
    null => _LanguageOption.system.tag,
    Locale(languageCode: 'pt') => _LanguageOption.portuguese.tag,
    _ => _LanguageOption.english.tag,
  };

  /// The option's label.
  ///
  /// The two languages are deliberately not localized — they are the same
  /// words in either catalog, so translating them would only make the list
  /// harder to escape from.
  String label(AppLocalizations l10n) => switch (this) {
    _LanguageOption.system => l10n.preferencesLanguageSystem,
    _LanguageOption.english => 'English',
    _LanguageOption.portuguese => 'Português (Brasil)',
  };
}

/// The control that opens [PreferencesDialog].
///
/// One widget rather than a button on each screen, because UC-39 requires the
/// same entry point with and without a session, and two of them would drift.
class PreferencesButton extends StatelessWidget {
  /// Creates the button.
  const PreferencesButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: l10n.preferencesOpen,
      onPressed: () => PreferencesDialog.show(context),
    );
  }
}
