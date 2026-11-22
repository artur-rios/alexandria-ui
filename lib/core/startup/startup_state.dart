import 'package:freezed_annotation/freezed_annotation.dart';

import '../failures/failure.dart';

part 'startup_state.freezed.dart';

/// The steps of the startup sequence, in the order
/// Operations & Infrastructure Document §5.1 defines them.
///
/// Carried on [StartupState.running] so the progress the owner sees names what
/// is happening, and on [StartupState.failed] so a retry re-runs from step 1
/// while the log records which step actually failed.
enum StartupStep {
  /// Resolve and load the core's shared library.
  loadingCore,

  /// Resolve the application-support directory and the database path.
  resolvingPaths,

  /// Load the local settings and apply the theme and language.
  loadingPreferences,

  /// Read the core's version and health status.
  verifyingCore,

  /// Initialize the core against the database path.
  initializingCore,
}

/// Where the application is in its startup sequence (IR-06).
@freezed
sealed class StartupState with _$StartupState {
  /// Nothing has been attempted yet.
  const factory StartupState.idle() = StartupIdle;

  /// The sequence is running, currently at [step].
  const factory StartupState.running({required StartupStep step}) =
      StartupRunning;

  /// The core is loaded, healthy, supported, and initialized.
  ///
  /// This is where the shell takes over: there is nothing between a ready
  /// startup and the library (library navigation design §2).
  const factory StartupState.ready({
    required String coreVersion,
    required String databasePath,
    Failure? warning,
  }) = StartupReady;

  /// The sequence stopped at [step] with [failure].
  ///
  /// This is a first-class application state, not an error dialog over a broken
  /// window: no catalog call is attempted from here, and the retry re-runs the
  /// sequence from step 1 (§5.2).
  const factory StartupState.failed({
    required StartupStep step,
    required Failure failure,
  }) = StartupFailed;
}
