import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../shell/domain/app_activity.dart';

/// The editor's share of the application's activities (FR-ME-09).
///
/// The one activity that can hold something the owner has not saved: an open
/// editor with edits in it is what the warning before closing for an update
/// asks about.
class EditingAppActivity implements AppActivity {
  /// Creates the activity over [_ref].
  const EditingAppActivity(this._ref);

  final Ref _ref;

  @override
  bool get holdsUnsavedChanges =>
      _ref.read(textEditorControllerProvider).isDirty;

  @override
  Future<void> end() async => _ref.invalidate(textEditorControllerProvider);

  /// Nothing to start: this activity only has state to drop, not work to do.
  @override
  Future<void> begin() async {}
}
