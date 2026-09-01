import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/recovery_controller.dart';
import 'core_rejection_messages.dart';

/// Spending a recovery code on a new password (UC-41).
///
/// Reached from the login screen, and only from there: it is the screen for an
/// owner who cannot sign in, so it exists on the unauthenticated side of the
/// application (AF-05). Nothing here judges the code or the password — both
/// are the core's (`FR-AU-19`); this collects them, checks the two things it
/// can check without a call, and reads back what the core said.
class RecoveryScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const RecoveryScreen({super.key});

  /// Presents it over [context] (main flow step 1).
  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => const Dialog.fullscreen(child: RecoveryScreen()),
  );

  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen> {
  final TextEditingController _code = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmation = TextEditingController();

  @override
  void dispose() {
    // FR-AU-11: the plaintext password and the code are both credentials, and
    // neither outlives the screen that collected them.
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(recoveryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recoveryTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: switch (state) {
              // Step 6: the core spent the code and invalidated every session,
              // so there is nothing to sign the owner in with — they use the
              // password they just set.
              RecoveryDone() => _Done(onClose: () => _close(context)),
              _ => _Form(
                code: _code,
                password: _password,
                confirmation: _confirmation,
                state: state,
                l10n: l10n,
                theme: theme,
                onSubmit: () => unawaited(_submit()),
                // AF-01: what the last attempt marked stops being true at
                // the first keystroke.
                onEditing: ref.read(recoveryControllerProvider.notifier).reset,
              ),
            },
          ),
        ),
      ),
    );
  }

  Future<void> _submit() => ref
      .read(recoveryControllerProvider.notifier)
      .submit(
        code: _code.text,
        newPassword: _password.text,
        passwordConfirmation: _confirmation.text,
      );

  void _close(BuildContext context) {
    ref.read(recoveryControllerProvider.notifier).reset();
    Navigator.of(context).pop();
  }
}

/// What the owner fills in (main flow step 2).
class _Form extends StatelessWidget {
  const _Form({
    required this.code,
    required this.password,
    required this.confirmation,
    required this.state,
    required this.l10n,
    required this.theme,
    required this.onSubmit,
    required this.onEditing,
  });

  final TextEditingController code;
  final TextEditingController password;
  final TextEditingController confirmation;
  final RecoveryState state;
  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onSubmit;

  /// Clears what the last attempt marked, as the owner types.
  final VoidCallback onEditing;

  @override
  Widget build(BuildContext context) {
    final submitting = state is RecoverySubmitting;
    final problem = state is RecoveryEditing
        ? (state as RecoveryEditing).problem
        : null;
    final invalid = problem is RecoveryInvalidInput ? problem : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.recoveryExplanation, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),

        TextField(
          controller: code,
          enabled: !submitting,
          autofocus: true,
          // Return submits, from here as from any field (FR-UX-11).
          onSubmitted: (_) => onSubmit(),
          onChanged: (_) => onEditing(),
          decoration: InputDecoration(
            labelText: l10n.recoveryCodeLabel,
            errorText: invalid?.codeError == null
                ? null
                : l10n.recoveryCodeMissing,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        TextField(
          controller: password,
          enabled: !submitting,
          obscureText: true,
          onSubmitted: (_) => onSubmit(),
          onChanged: (_) => onEditing(),
          decoration: InputDecoration(labelText: l10n.recoveryNewPassword),
        ),
        const SizedBox(height: AppSpacing.md),

        TextField(
          controller: confirmation,
          enabled: !submitting,
          obscureText: true,
          decoration: InputDecoration(
            labelText: l10n.recoveryConfirmPassword,
            errorText: switch (invalid?.passwordError) {
              RecoveryFieldError.passwordMissing =>
                l10n.recoveryPasswordMissing,
              RecoveryFieldError.passwordMismatch =>
                l10n.signUpPasswordMismatch,
              _ => null,
            },
          ),
          onSubmitted: (_) => onSubmit(),
          onChanged: (_) => onEditing(),
        ),

        if (_refusal(problem) case final message?) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: submitting ? null : onSubmit,
          child: Text(l10n.recoverySubmit),
        ),
      ],
    );
  }

  /// AF-02, AF-03, and AF-04, in the owner's language.
  String? _refusal(RecoveryProblem? problem) => switch (problem) {
    // AF-02 and AF-03 are told apart here, and only here, by the code the
    // core named. An owner working down a printed list needs to know whether
    // they mistyped or already spent it (FR-AU-16).
    RecoveryRefused(rejection: final rejection?) => switch (rejection.code) {
      'recovery_code_unknown' => l10n.recoveryCodeUnknown,
      'recovery_code_used' => l10n.recoveryCodeUsed,
      // AF-04, and anything else the core refuses: its own reason, already
      // translatable.
      _ => coreRejectionMessage(l10n, rejection),
    },
    RecoveryRefused() => l10n.recoveryRefused,
    RecoveryUnavailable(:final failure) => failure.localizedMessage(l10n),
    _ => null,
  };
}

/// Step 6: the password was replaced and every session is gone.
class _Done extends StatelessWidget {
  const _Done({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: AppSpacing.xxl,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.recoveryDone,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.recoveryDoneExplanation,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(onPressed: onClose, child: Text(l10n.recoveryBackToLogin)),
      ],
    );
  }
}
