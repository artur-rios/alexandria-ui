import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../shell/domain/session_activity.dart';

/// Stops an update in flight when the session ends (update-check design §6).
///
/// Signing out — or the core rejecting the session — closes every route, the
/// update prompt included. A download left running would finish with no
/// prompt to show it and a package sitting in the temporary folder, so it is
/// cancelled and its folder removed.
class UpdateSessionActivity implements SessionActivity {
  /// Creates the activity over [_ref].
  const UpdateSessionActivity(this._ref);

  final Ref _ref;

  @override
  bool get holdsUnsavedChanges => false;

  @override
  bool get continuesInTheCore => false;

  @override
  Future<void> begin() async {}

  @override
  Future<void> end() async =>
      _ref.read(updateControllerProvider.notifier).endSession();
}
