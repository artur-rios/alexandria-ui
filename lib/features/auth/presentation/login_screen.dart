import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';
import '../application/login_state.dart';
import '../application/session_state.dart';
import '../../shell/presentation/preferences_dialog.dart';
import 'auth_field_messages.dart';
import 'recovery_screen.dart';
import 'auth_notice.dart';

/// The login screen (UC-02).
///
/// Presented whenever there is no active session, and it issues no catalog
/// call from here (FR-AU-07).
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    // The controller decides whether this is submittable; the screen does not
    // duplicate the validation, so the two can never disagree.
    ref
        .read(loginControllerProvider.notifier)
        .submit(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(loginControllerProvider);
    final submitting = state is LoginSubmitting;
    final editing = state is LoginEditing ? state : null;

    // AF-02: the password is cleared after a refusal, so a second attempt
    // starts from an empty field rather than from a value already refused.
    ref.listen(loginControllerProvider, (previous, next) {
      if (next case LoginEditing(problem: RejectedProblem())) {
        _password.clear();
      }
    });

    final session = ref.watch(sessionControllerProvider);
    final endedBecause = switch (session) {
      SessionAbsent(:final endedBecause) => endedBecause,
      SessionActive() => null,
    };
    // UC-03 AF-02: the owner signed out while the core was still scanning.
    final indexRunContinues = switch (session) {
      SessionAbsent(:final indexRunContinues) => indexRunContinues,
      SessionActive() => false,
    };

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          // Scrollable so that at the minimum supported window height no
          // control becomes unreachable (NFR-07).
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
                Text(l10n.loginTitle, style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.lg),

                if (endedBecause != null) ...[
                  _SessionEndedNotice(failure: endedBecause),
                  const SizedBox(height: AppSpacing.md),
                ],

                if (indexRunContinues) ...[
                  const _IndexRunContinuesNotice(),
                  const SizedBox(height: AppSpacing.md),
                ],

                if (editing?.problem case final problem?) ...[
                  _ProblemNotice(problem: problem),
                  const SizedBox(height: AppSpacing.md),
                ],

                TextField(
                  controller: _email,
                  // The form's first field takes focus, so the screen is
                  // usable from the keyboard alone (FR-UX-11).
                  autofocus: true,
                  enabled: !submitting,
                  keyboardType: TextInputType.emailAddress,
                  // Enter submits from here too, rather than doing Tab's job.
                  //
                  // `TextInputAction.next` is what a soft keyboard's corner
                  // key should say on a field with another one after it, and
                  // this application has no soft keyboard: it runs on two
                  // desktops (IR-01), where the key that carries the action
                  // is Return and moving between fields is what Tab is for.
                  // Configured `next`, Return moved the focus and the form
                  // could only be submitted from the last field or the
                  // button — an owner who typed their password and pressed
                  // Return got their focus moved and their credentials left
                  // sitting there.
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  // AF-01: what the last attempt marked stops being true at
                  // the first keystroke.
                  onChanged: (_) =>
                      ref.read(loginControllerProvider.notifier).resetProblems(),
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
                  // Enter submits, so the primary action is reachable without
                  // tabbing to the button (FR-UX-11) — the same from either
                  // field, since a form is submitted from wherever the owner
                  // happens to be in it.
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) =>
                      ref.read(loginControllerProvider.notifier).resetProblems(),
                  decoration: InputDecoration(
                    labelText: l10n.loginPasswordLabel,
                    errorText: authFieldMessage(
                      l10n,
                      AuthField.password,
                      editing?.passwordError,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                FilledButton(
                  onPressed: submitting ? null : _submit,
                  child: submitting
                      // Sized to the text it replaces so the button does not
                      // resize when an attempt starts.
                      ? const SizedBox.square(
                          dimension: AppSpacing.md,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.loginSubmit),
                ),

                // UC-41 main flow step 1 / UC-02 AF-06: the way back in for
                // an owner who cannot remember their password. Here because
                // this is where they find out, and unauthenticated because
                // that is the whole situation it addresses (UC-41 AF-05).
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => unawaited(RecoveryScreen.show(context)),
                    child: Text(l10n.recoveryOpen),
                  ),
                ),

                // UC-39 main flow step 1: preferences are reachable with or
                // without a session, so the entry point is here as well as in
                // the shell. Below the primary action, because the owner came
                // here to sign in.
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

/// The explanation shown when a session ended by rejection (AF-04, FR-AU-08).
class _SessionEndedNotice extends StatelessWidget {
  const _SessionEndedNotice({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AuthNotice(
      icon: Icons.lock_clock_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.loginSessionEndedTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(failure.localizedMessage(l10n)),
        ],
      ),
    );
  }
}

/// What UC-03 AF-02 tells the owner: the scan they signed out on is the
/// core's, it did not stop, and they will see how it ended once they are back.
class _IndexRunContinuesNotice extends StatelessWidget {
  const _IndexRunContinuesNotice();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AuthNotice(
      tone: AuthNoticeTone.information,
      icon: Icons.sync_outlined,
      child: Text(l10n.signOutIndexRunContinues),
    );
  }
}

/// The explanation for a refused attempt (AF-02, AF-03, AF-05).
class _ProblemNotice extends ConsumerWidget {
  const _ProblemNotice({required this.problem});

  final LoginProblem problem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final message = switch (problem) {
      RejectedProblem() => l10n.loginRejected,
      NoAccountProblem() => l10n.loginNoAccount,
      CoreNotReadyProblem(:final failure) ||
      OtherProblem(:final failure) => failure.localizedMessage(l10n),
    };

    return AuthNotice(
      icon: Icons.error_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),

          // AF-03: the specification sends the owner to sign-up. UC-02 could
          // only state the condition, because the sign-up screen did not exist
          // and the core could not create an account. Both do now.
          if (problem is NoAccountProblem) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(authEntryProvider.notifier).goToSignUp(),
              icon: const Icon(Icons.person_add_outlined),
              label: Text(l10n.loginGoToSignUp),
            ),
          ],

          // AF-05: the core-unavailable message comes with a retry, and the
          // retry re-runs the startup sequence from step 1 rather than only
          // re-attempting the login that has no core to reach.
          if (problem is CoreNotReadyProblem) ...[
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
