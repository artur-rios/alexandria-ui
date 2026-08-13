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
import '../domain/login_validation.dart';

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

    final endedBecause = switch (ref.watch(sessionControllerProvider)) {
      SessionAbsent(:final endedBecause) => endedBecause,
      SessionActive() => null,
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
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.loginEmailLabel,
                    errorText: _fieldMessage(l10n, editing?.emailError, true),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                TextField(
                  controller: _password,
                  obscureText: true,
                  enabled: !submitting,
                  textInputAction: TextInputAction.done,
                  // Enter submits, so the primary action is reachable without
                  // tabbing to the button (FR-UX-11).
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: l10n.loginPasswordLabel,
                    errorText: _fieldMessage(
                      l10n,
                      editing?.passwordError,
                      false,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The message for a field-level verdict.
  ///
  /// [isEmail] picks between the two fields' wording for the same condition —
  /// the domain names the condition, and the screen is where it becomes
  /// language.
  String? _fieldMessage(
    AppLocalizations l10n,
    LoginFieldError? error,
    bool isEmail,
  ) => switch (error) {
    null => null,
    LoginFieldError.missing =>
      isEmail ? l10n.loginEmailMissing : l10n.loginPasswordMissing,
    LoginFieldError.malformed => l10n.loginEmailMalformed,
  };
}

/// The explanation shown when a session ended by rejection (AF-04, FR-AU-08).
class _SessionEndedNotice extends StatelessWidget {
  const _SessionEndedNotice({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return _Notice(
      icon: Icons.lock_clock_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.loginSessionEndedTitle,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(failure.localizedMessage(l10n)),
        ],
      ),
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

    return _Notice(
      icon: Icons.error_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
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

/// A bordered block carrying an icon and a message.
///
/// Every color comes from the active scheme, so it reads in both themes
/// (IR-10, NFR-08).
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.child});

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: theme.colorScheme.onErrorContainer),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
