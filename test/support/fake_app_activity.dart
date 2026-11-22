import 'package:alexandria_ui/features/shell/domain/app_activity.dart';

/// An [AppActivity] a test drives directly (Testing Specification §2.3).
///
/// It stands in for the player and the editor the features register, so the
/// application's start and its close for an update are exercised against the
/// mechanism rather than against whichever features happen to exist.
class FakeAppActivity implements AppActivity {
  /// Creates an activity that holds nothing.
  FakeAppActivity({
    this.holdsUnsavedChanges = false,
    this.onEnd,
    this.beginThrows = false,
  });

  @override
  bool holdsUnsavedChanges;

  /// Called from [end], so a test can observe what was still true when the
  /// activity was wound down.
  final void Function()? onEnd;

  /// Whether [begin] should throw rather than complete — a stand-in for an
  /// activity whose `begin()` reads a gateway or calls a core that is not
  /// ready, so a test can prove that failure stays this activity's own
  /// problem rather than an unhandled error at startup.
  final bool beginThrows;

  /// How many times [end] was called.
  int endCount = 0;

  /// How many times [begin] was called, whether or not it threw.
  int beginCount = 0;

  @override
  Future<void> end() async {
    endCount++;
    onEnd?.call();
  }

  @override
  Future<void> begin() async {
    beginCount++;
    if (beginThrows) throw StateError('begin failed');
  }
}
