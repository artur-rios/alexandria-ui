import 'package:alexandria_ui/features/shell/domain/session_activity.dart';

/// A [SessionActivity] a test drives directly (Testing Specification §2.3).
///
/// It stands in for the player and the editor that later use cases register,
/// so UC-03's flows are exercised against the mechanism rather than against
/// whichever features happen to exist.
class FakeSessionActivity implements SessionActivity {
  /// Creates an activity that holds nothing and continues nowhere.
  FakeSessionActivity({
    this.holdsUnsavedChanges = false,
    this.continuesInTheCore = false,
    this.onEnd,
  });

  @override
  bool holdsUnsavedChanges;

  @override
  bool continuesInTheCore;

  /// Called from [end], so a test can observe what was still true when the
  /// activity was wound down.
  final void Function()? onEnd;

  /// How many times [end] was called.
  int endCount = 0;

  @override
  Future<void> end() async {
    endCount++;
    onEnd?.call();
  }
}
