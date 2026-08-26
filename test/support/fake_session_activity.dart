import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/auth/application/session_state.dart';
import 'package:alexandria_ui/features/shell/domain/session_activity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Future<void> begin() async {}
}

/// A [SessionActivity] that records whether the session was already active
/// when [begin] ran (Testing Specification §2.3).
///
/// The ordering is the thing worth proving, not the call: an activity that
/// reads the credential — as the library re-check does — would find none if
/// `begin` ran before the session was recorded, and a fake that only counted
/// calls would not catch that.
class RecordingSessionActivity implements SessionActivity {
  RecordingSessionActivity(this._ref);

  final Ref _ref;

  @override
  bool holdsUnsavedChanges = false;

  @override
  bool continuesInTheCore = false;

  /// Whether `sessionControllerProvider`'s state was already active when
  /// [begin] was called.
  bool begunWithSessionActive = false;

  @override
  Future<void> end() async {}

  @override
  Future<void> begin() async {
    begunWithSessionActive = _ref.read(sessionControllerProvider) is SessionActive;
  }
}
