import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../shell/application/window_geometry_controller.dart';
import '../../shell/presentation/confirmation_dialog.dart';
import '../domain/release_info.dart';

/// Closes the application to install [package] (update-check design §3
/// step 3), answering false when the owner stops it.
///
/// A path of its own, not ordinary window closing: it asks about unsaved
/// edits as signing out does, says a running scan will pause, ends the
/// session's activities, records the window, leaves the record the next
/// start checks, starts the installer, and exits.
Future<bool> closeForUpdate(
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
    if (!confirmed || !context.mounted) return false;
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
    if (!confirmed || !context.mounted) return false;
  }

  final installer = ref.read(updateInstallerProvider);
  final location = ref.read(installKindProbeProvider).installLocation();
  if (installer == null || location == null) return false;

  for (final activity in ref.read(sessionActivitiesProvider)) {
    await activity.end();
  }

  final settings = ref.read(startupControllerProvider.notifier).settings;
  if (settings != null) {
    await WindowGeometryController(
      placement: ref.read(windowPlacementProvider),
      settings: settings,
    ).record();
  }

  final from = ref.read(appVersionProvider);
  (await ref.read(
    pendingUpdateStoreProvider.future,
  )).write(from: from, to: release.version.toString());

  await installer.launch(
    package: package,
    installLocation: location,
    fromVersion: from,
  );
  ref.read(appExitProvider)(0);
  return true;
}
