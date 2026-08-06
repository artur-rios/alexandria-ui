import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'app.dart';
import 'core/di/providers.dart';
import 'core/logging/app_logger.dart';
import 'core/logging/rolling_file_log_sink.dart';
import 'core/startup/core_paths.dart';

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
    Logger('startup').warning('log file unavailable; logging to console', error);
  }
}

/// Whether the running platform is one this application targets (IR-01).
///
/// Referenced by the integration suite, which refuses to run anywhere else.
bool get isSupportedPlatform => Platform.isWindows || Platform.isLinux;
