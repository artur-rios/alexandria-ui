import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/di/providers.dart';
import 'core/logging/app_logger.dart';
import 'core/logging/rolling_file_log_sink.dart';
import 'core/settings/settings_store.dart';
import 'core/startup/core_paths.dart';
import 'core/theme/breakpoints.dart';
import 'features/shell/application/window_geometry_controller.dart';
import 'features/shell/data/window_close_recorder.dart';

/// The entry point and bootstrap.
///
/// It does the least it can: start logging, build the provider graph, put a
/// window on screen, and kick off the startup sequence. Everything the sequence
/// discovers — including that the core will not load — is a state inside the
/// application rather than a reason not to open a window
/// (Operations & Infrastructure Document §5.2).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _startLogging();

  final container = ProviderContainer();

  await _placeWindow(container);

  // Started after the first frame so a failure at step 1 lands on the
  // core-unavailable screen rather than on a blank window.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    container.read(startupControllerProvider.notifier).start();
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AlexandriaApp(),
    ),
  );
}

/// Enforces the minimum window size, restores the stored geometry, and shows
/// the window (UC-38 main flow steps 3 and 6, FR-UX-03).
///
/// This runs before `runApp` and therefore before the startup sequence loads
/// preferences at its step 5, so the settings store is loaded here in its own
/// right. Deferring it would mean showing the window at the default size and
/// then moving it once startup settled — a visible jump on every launch, to
/// save loading a preferences file twice.
///
/// Settings that will not load are not fatal, exactly as they are not fatal at
/// startup step 5: the window opens at the default size and the owner's next
/// choice is what gets recorded.
Future<void> _placeWindow(ProviderContainer container) async {
  await windowManager.ensureInitialized();

  SettingsStore? settings;
  try {
    settings = await container.read(settingsLoaderProvider)();
  } on Object catch (error) {
    Logger('shell').warning(
      'preferences could not be read; opening at the default size',
      error,
    );
  }

  final placement = container.read(windowPlacementProvider);
  if (settings == null) {
    await placement.applyMinimumSize(Breakpoint.minimumWindowSize);
    await placement.applyDefaultSize(defaultWindowSize);
    await placement.show();
    return;
  }

  final geometry = WindowGeometryController(
    placement: placement,
    settings: settings,
  );

  await geometry.restore(
    minimumSize: Breakpoint.minimumWindowSize,
    defaultSize: defaultWindowSize,
  );

  await WindowCloseRecorder(geometry).attach();
}

/// The size a first launch opens at, in logical pixels.
///
/// Comfortably inside [Breakpoint.medium] rather than at the minimum: the
/// minimum is the floor the application stays usable at, not the size it
/// should choose for an owner who has expressed no preference.
const Size defaultWindowSize = Size(1440, 900);

/// Routes logging to the console in development and to the rolling file in
/// release (IR-13).
Future<void> _startLogging() async {
  if (kDebugMode) {
    AppLogger.initialize();
    return;
  }

  try {
    final directory = await const CorePaths().resolveApplicationDirectory();
    AppLogger.initialize(
      fileSink: RollingFileLogSink(directory: p.join(directory.path, 'logs')),
    );
  } on Object catch (error) {
    // A log file that cannot be opened must not stop the application starting:
    // the owner came here to read their library, not to write a log.
    AppLogger.initialize();
    Logger(
      'startup',
    ).warning('log file unavailable; logging to console', error);
  }
}

/// Whether the running platform is one this application targets (IR-01).
///
/// Referenced by the integration suite, which refuses to run anywhere else.
bool get isSupportedPlatform => Platform.isWindows || Platform.isLinux;
