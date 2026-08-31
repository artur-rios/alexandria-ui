import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../application/session_state.dart';

/// Closes everything the owner had open when their session ends (BR-05,
/// FR-AU-09).
///
/// The application swaps `MaterialApp.home` between the shell and the login
/// screen, and that reads as though it replaced the screen — but `home` is
/// only the first route's content. Every dialog reached through `showDialog`
/// is a route of its own, pushed *above* that one, and rebuilding what is
/// underneath does not take it away. Eighteen of them are full-screen.
///
/// So a session ending — the owner signing out, or the core rejecting the
/// session mid-call — left whatever was open sitting over the login screen:
/// a comic still on its page, a document mid-read, a library tree, the list
/// of deleted records. All of it the previous session's, all of it still
/// legible, and none of it something BR-05 allows to outlive the session that
/// fetched it.
///
/// One listener rather than a rule for each screen. There is no version of
/// this that eighteen dialogs each remember to do, and the two that noticed
/// the problem before could only write it down (see the comment in
/// `playlist_detail_controller.dart`, which asks for exactly this and defers
/// it). The evidence that routes really do persist is already in the tree:
/// `recovery_codes_section.dart` pops the preferences dialog by hand, because
/// otherwise the new codes appear behind it.
///
/// Wrapped around `home` rather than passed to `MaterialApp.builder`: the
/// builder's context sits above the navigator, and this needs one below it.
class SessionRouteGuard extends ConsumerWidget {
  /// Wraps [child], which is whatever `home` resolves to.
  const SessionRouteGuard({required this.child, super.key});

  /// The screen underneath.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sessionControllerProvider, (previous, next) {
      // Only the ending. Signing in pushes nothing to clear, and running this
      // on every session change would pop a dialog the owner opened on the
      // way in.
      if (previous is! SessionActive || next is! SessionAbsent) return;

      // After this frame, not during it. The same session change is already
      // rebuilding what `home` resolves to, and a route operation part-way
      // through that rebuild is the one way this could be worse than the
      // problem it fixes. One frame later the login screen is laid out and
      // the pop is an ordinary one.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;

        // The root navigator, and back to the first route: `pop` alone would
        // uncover the next dialog down rather than the login screen, and the
        // owner can have several stacked — a file's details over a library
        // tree, an editor over that.
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.popUntil((route) => route.isFirst);
        }
      });
    });

    return child;
  }
}
