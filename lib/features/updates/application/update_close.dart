import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../shell/application/window_geometry_controller.dart';
import '../../shell/presentation/confirmation_dialog.dart';
import '../domain/release_info.dart';
import 'update_session_activity.dart';

final _log = Logger('updates');

/// How closing for an update ended.
enum CloseForUpdate {
  /// The owner kept their unsaved edits or their scan; nothing changed.
  declined,

  /// The installer is running and the application is exiting.
  launched,

  /// The installer could not be started. The session's activities were begun
  /// again and the pending-update record cleared, so the application goes on
  /// as it was.
  failed,
}

/// Closes the application to install [package] (update-check design §3
/// step 3), answering how that ended.
///
/// A path of its own, not ordinary window closing: it asks about unsaved
/// edits as signing out does, says a running scan will pause, ends the
/// session's activities, records the window, leaves the record the next
/// start checks, starts the installer, and exits.
Future<CloseForUpdate> closeForUpdate(
  BuildContext context,
  WidgetRef ref, {
  required ReleaseInfo release,
  required File package,
}) async {
  final l10n = AppLocalizations.of(context);

  if (ref.read(signOutControllerProvider).holdsUnsavedChanges) {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: l10n.updateUnsavedTitle,
      message: l10n.updateUnsavedMessage,
      confirmLabel: l10n.updateUnsavedConfirm,
    );
    if (!confirmed || !context.mounted) return CloseForUpdate.declined;
  }

  // The core records a run the application was closed on as paused, and it
  // can be resumed after the update.
  if (ref.read(activeRunsControllerProvider).anyRunning) {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: l10n.updateScanTitle,
      message: l10n.updateScanMessage,
      confirmLabel: l10n.updateScanConfirm,
    );
    if (!confirmed || !context.mounted) return CloseForUpdate.declined;
  }

  final installer = ref.read(updateInstallerProvider);
  final location = ref.read(installKindProbeProvider).installLocation();
  if (installer == null || location == null) return CloseForUpdate.failed;

  // Every activity but the update's own: ending that one cancels this very
  // update and deletes the package about to be run.
  final activities = [
    for (final activity in ref.read(sessionActivitiesProvider))
      if (activity is! UpdateSessionActivity) activity,
  ];
  final store = await ref.read(pendingUpdateStoreProvider.future);
  var ended = 0;
  try {
    for (final activity in activities) {
      await activity.end();
      ended++;
    }

    final settings = ref.read(startupControllerProvider.notifier).settings;
    if (settings != null) {
      await WindowGeometryController(
        placement: ref.read(windowPlacementProvider),
        settings: settings,
      ).record();
    }

    final from = ref.read(appVersionProvider);
    store.write(from: from, to: release.version.toString());

    await installer.launch(
      package: package,
      installLocation: location,
      fromVersion: from,
    );
  } on Object catch (error, stack) {
    // Quarantined by an antivirus, a missing setsid, a full disk: the
    // application stays, as it was before the owner chose Update now.
    _log.warning('the update could not be started', error, stack);
    try {
      store.clear();
    } on Object catch (clearError) {
      _log.warning('the pending-update record stays: $clearError');
    }
    for (final activity in activities.take(ended)) {
      try {
        await activity.begin();
      } on Object catch (beginError) {
        _log.warning('an activity did not begin again: $beginError');
      }
    }
    return CloseForUpdate.failed;
  }
  ref.read(appExitProvider)(0);
  return CloseForUpdate.launched;
}
