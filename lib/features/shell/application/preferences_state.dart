import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/bindings/core_environment.dart';

part 'preferences_state.freezed.dart';

/// The owner's theme and language, and whether the last change reached the
/// settings store (UC-39, FR-UX-04, FR-UX-05, FR-UX-12).
///
/// A single state rather than two providers because AF-02 couples them: a
/// change that applied but was not saved has to be reported, and the report
/// belongs to whichever choice the owner just made.
@freezed
sealed class PreferencesState with _$PreferencesState {
  /// Creates a state.
  ///
  /// The defaults are AF-03's: no preference has ever been set, so the theme
  /// follows the system and the language is left to Flutter's own resolution,
  /// which picks the system language when it is one of the two supported and
  /// English otherwise.
  const factory PreferencesState({
    @Default(ThemeMode.system) ThemeMode themeMode,
    Locale? locale,
    @Default(true) bool opensPlayerOnPlay,
    @Default(true) bool rechecksAtStartup,
    @Default(true) bool musicLookupEnabled,
    @Default(defaultMusicLookupContact) String musicLookupContact,
    @Default(false) bool lastChangeUnsaved,

    /// Whether a music-lookup change is saved but not yet running.
    ///
    /// The core will not be reconfigured while it is walking a disk — a run
    /// already executing would be left behind by the replacement — so a
    /// switch moved during a scan is stored and applied when the scan
    /// settles. Reported rather than left silent: the alternative is a
    /// preference that appears to do nothing for as long as the scan lasts,
    /// which is the reading an owner would take as a bug.
    @Default(false) bool musicLookupDeferred,
  }) = _PreferencesState;
}
