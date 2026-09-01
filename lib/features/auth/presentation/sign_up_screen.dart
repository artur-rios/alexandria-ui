import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';
import '../application/sign_up_state.dart';
import '../../shell/presentation/preferences_dialog.dart';
import 'auth_field_messages.dart';
import 'auth_notice.dart';
import 'core_rejection_messages.dart';

/// The sign-up screen (UC-01).
///
/// Presented on first launch, when the core holds no account (FR-AU-01). It
/// issues no catalog call from here.
class SignUpScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  void _submit() {
    // The controller decides whether this is submittable; the screen does not
    // duplicate the validation, so the two can never disagree.
    ref
        .read(signUpControllerProvider.notifier)
        .submit(
          email: _email.text,
          password: _password.text,
          passwordConfirmation: _passwordConfirmation.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(signUpControllerProvider);
    final submitting = state is SignUpSubmitting;
    final editing = state is SignUpEditing ? state : null;

    // AF-03: both password fields are cleared after a refusal, so the owner
    // re-types a password rather than editing one already refused — and the
    // repeat cannot be left silently matching a value that changed.
    ref.listen(signUpControllerProvider, (previous, next) {
      if (next case SignUpEditing(problem: SignUpRejectedProblem())) {
        _password.clear();
        _passwordConfirmation.clear();
      }
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          // Scrollable so that at the minimum supported window height no
          // control becomes unreachable (NFR-07). This form is a field taller
          // than login, which is where that starts to matter.
          padding: EdgeInsets.all(
            Breakpoint.from(context) == Breakpoint.compact
                ? AppSpacing.lg
                : AppSpacing.xxl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.signUpTitle, style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                // The password cannot be recovered — the core owns no mail
                // transport — so the stakes are stated before the owner
                // chooses one, not after.
                Text(l10n.signUpIntro, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.lg),

                if (editing?.problem case final problem?) ...[
                  _SignUpProblemNotice(problem: problem),
                  const SizedBox(height: AppSpacing.md),
                ],

                TextField(
                  controller: _email,
                  autofocus: true,
                  enabled: !submitting,
                  keyboardType: TextInputType.emailAddress,
                  // Return submits, from here as from any field (FR-UX-11).
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  // AF-01: what the last attempt marked stops being true
                  // at the first keystroke.
                  onChanged: (_) => ref
                      .read(signUpControllerProvider.notifier)
                      .resetProblems(),
                  decoration: InputDecoration(
                    labelText: l10n.loginEmailLabel,
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
                  obscureText: true,
                  enabled: !submitting,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  // AF-01: what the last attempt marked stops being true
                  // at the first keystroke.
                  onChanged: (_) => ref
                      .read(signUpControllerProvider.notifier)
                      .resetProblems(),
                  decoration: InputDecoration(
                    labelText: l10n.loginPasswordLabel,
                    errorText: authFieldMessage(
                      l10n,
                      AuthField.password,
                      editing?.passwordError,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                TextField(
                  controller: _passwordConfirmation,
                  obscureText: true,
                  enabled: !submitting,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  // AF-01: what the last attempt marked stops being true
                  // at the first keystroke.
                  onChanged: (_) => ref
                      .read(signUpControllerProvider.notifier)
                      .resetProblems(),
                  decoration: InputDecoration(
                    labelText: l10n.signUpPasswordConfirmationLabel,
                    errorText: authFieldMessage(
                      l10n,
                      AuthField.passwordConfirmation,
                      editing?.passwordConfirmationError,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                FilledButton(
                  onPressed: submitting ? null : _submit,
                  child: submitting
                      ? const SizedBox.square(
                          dimension: AppSpacing.md,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.signUpSubmit),
                ),

                // UC-39 main flow step 1: preferences are reachable with or
                // without a session, and a first launch lands here before it
                // lands anywhere else — which makes this the first chance the
                // owner has to pick a language they can read.
                const SizedBox(height: AppSpacing.sm),
                const Align(
                  alignment: Alignment.centerRight,
                  child: PreferencesButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The explanation for a refused registration (AF-03, AF-04, AF-05).
class _SignUpProblemNotice extends ConsumerWidget {
  const _SignUpProblemNotice({required this.problem});

  final SignUpProblem problem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final message = switch (problem) {
      // The rule the core named, when it named one. This is the difference
      // between "try something else" and "use at least 12 characters".
      SignUpRejectedProblem(:final rejection?) => coreRejectionMessage(
        l10n,
        rejection,
      ),
      SignUpRejectedProblem() => l10n.signUpRejected,
      AccountExistsProblem() => l10n.signUpAccountExists,
      SignUpConfigurationProblem(:final failure) ||
      SignUpOtherProblem(:final failure) => failure.localizedMessage(l10n),
    };

    return AuthNotice(
      icon: Icons.error_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),

          // AF-04: the specification sends the owner to the login screen. It
          // is offered rather than done, because switching the screen out from
          // under someone mid-typing loses what they typed with no explanation.
          if (problem is AccountExistsProblem) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => ref.read(authEntryProvider.notifier).goToLogin(),
              icon: const Icon(Icons.login),
              label: Text(l10n.signUpGoToLogin),
            ),
          ],

          // AF-05: the core cannot create an account in its current state, so
          // the retry re-runs the startup sequence rather than the call.
          if (problem is SignUpConfigurationProblem) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(startupControllerProvider.notifier).retry(),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ],
      ),
    );
  }
}
