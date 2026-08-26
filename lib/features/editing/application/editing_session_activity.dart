import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../shell/domain/session_activity.dart';

/// The editor's share of signing out (UC-03 AF-01, FR-ME-09).
///
/// This is the activity UC-03 built its registry for: until now nothing in
/// the application held anything unsaved, so the warning before a sign-out
/// had no way to fire. An open editor with edits in it is exactly what it was
/// written for.
class EditingSessionActivity implements SessionActivity {
  /// Creates the activity over [_ref].
  const EditingSessionActivity(this._ref);

  final Ref _ref;

  @override
  bool get holdsUnsavedChanges =>
      _ref.read(textEditorControllerProvider).isDirty;

  /// Nothing here runs in the core: the write is one call, and it has either
  /// happened or it has not.
  @override
  bool get continuesInTheCore => false;

  @override
  Future<void> end() async => _ref.invalidate(textEditorControllerProvider);

  /// Nothing to start: this activity only has state to drop, not work to do.
  @override
  Future<void> begin() async {}
}
