import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/change_credentials_state.dart';
import 'auth_field_messages.dart';
import 'auth_notice.dart';
import 'core_rejection_messages.dart';
import 'recovery_codes_section.dart';

/// The credential-change form (UC-04, FR-AU-10).
///
/// A dialog opened from the Settings menu, where main flow step 1 puts it,
/// beside [RecoveryCodesSection] (UC-42): both are things an owner does to an
/// account they still have access to, not a preference. It is offered only
/// inside an active session: the core requires one to authorize the call, and
/// the operation exists to change credentials that already exist.
class ChangeCredentialsDialog extends ConsumerStatefulWidget {
  /// Creates the dialog.
  const ChangeCredentialsDialog({super.key});

  /// Presents the dialog over [context].
  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => const ChangeCredentialsDialog(),
  );

  @override
  ConsumerState<ChangeCredentialsDialog> createState() =>
      _ChangeCredentialsDialogState();
}

class _ChangeCredentialsDialogState
    extends ConsumerState<ChangeCredentialsDialog> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    // The two password fields hold plaintext for as long as the form is open
    // and no longer (FR-AU-11).
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() => ref
      .read(changeCredentialsControllerProvider.notifier)
      .submit(
        email: _email.text,
        password: _password.text,
        passwordConfirmation: _confirmation.text,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(changeCredentialsControllerProvider);
    final editing = state is ChangeCredentialsEditing ? state : null;
    final submitting = state is ChangeCredentialsSubmitting;

    // Clearing the plaintext the moment the core accepts it, rather than
    // leaving it in three controllers until the dialog closes (FR-AU-11).
    ref.listen(changeCredentialsControllerProvider, (previous, next) {
      if (next is ChangeCredentialsChanged) {
        _email.clear();
        _password.clear();
        _confirmation.clear();
      }
    });

    return AlertDialog(
      title: Text(l10n.changeCredentialsTitle),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state is ChangeCredentialsChanged) ...[
                AuthNotice(
                  icon: Icons.check_circle_outline,
                  child: Text(l10n.changeCredentialsDone),
                ),
              ] else ...[
                Text(
                  l10n.changeCredentialsIntro,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),

                if (editing?.problem case final problem?) ...[
                  _RefusalNotice(failure: problem),
                  const SizedBox(height: AppSpacing.md),
                ],

                TextField(
                  controller: _email,
                  // The form's first field takes focus, so the dialog is
                  // usable from the keyboard alone (FR-UX-11).
                  autofocus: true,
                  enabled: !submitting,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => ref
                      .read(changeCredentialsControllerProvider.notifier)
                      .resetProblems(),
                  decoration: InputDecoration(
                    labelText: l10n.changeCredentialsEmailLabel,
                    errorText: authFieldMessage(
                      l10n,
                      AuthField.email,
                      editing?.emailError,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                TextField(
                  controller: _password,
                  enabled: !submitting,
                  obscureText: true,
                  onChanged: (_) => ref
                      .read(changeCredentialsControllerProvider.notifier)
                      .resetProblems(),
                  decoration: InputDecoration(
                    labelText: l10n.changeCredentialsPasswordLabel,
                    errorText: authFieldMessage(
                      l10n,
                      AuthField.password,
                      editing?.passwordError,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                TextField(
                  controller: _confirmation,
                  enabled: !submitting,
                  obscureText: true,
                  onChanged: (_) => ref
                      .read(changeCredentialsControllerProvider.notifier)
                      .resetProblems(),
                  onSubmitted: (_) => submitting ? null : _submit(),
                  decoration: InputDecoration(
                    labelText: l10n.changeCredentialsConfirmationLabel,
                    errorText: authFieldMessage(
                      l10n,
                      AuthField.passwordConfirmation,
                      editing?.passwordConfirmationError,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              // UC-42 beside UC-04: regenerating the recovery codes and
              // changing the password are both things an owner does to an
              // account they still have access to, and the preferences dialog
              // they used to share was neither of those things.
              const RecoveryCodesSection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            state is ChangeCredentialsChanged
                ? l10n.preferencesClose
                : l10n.cancel,
          ),
        ),
        if (state is! ChangeCredentialsChanged)
          FilledButton(
            onPressed: submitting ? null : _submit,
            child: submitting
                // Sized to the text it replaces so the button does not resize
                // when an attempt starts.
                ? const SizedBox.square(
                    dimension: AppSpacing.md,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.changeCredentialsSubmit),
          ),
      ],
    );
  }
}

/// What the core refused on (AF-03).
///
/// The stored credentials are untouched when this shows, which is the part the
/// owner needs to know: nothing half-changed.
class _RefusalNotice extends ConsumerWidget {
  const _RefusalNotice({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return AuthNotice(
      icon: Icons.error_outline,
      child: Text(
        // A named rejection reads as the rule it broke — too short, too
        // common, contains the address — which is what lets the owner fix it.
        // Anything else falls back to the sentence that says the stored
        // credentials are unchanged.
        switch (failure) {
          RejectedFailure(:final rejection) => coreRejectionMessage(
            l10n,
            rejection,
          ),
          _ => l10n.changeCredentialsRejected,
        },
      ),
    );
  }
}
