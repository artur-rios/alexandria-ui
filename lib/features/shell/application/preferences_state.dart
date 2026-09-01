import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/bindings/core_environment.dart';
import '../../playback/domain/album_medium.dart';

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
    @Default(AlbumAnimationMode.byYear) AlbumAnimationMode albumAnimation,
    @Default(true) bool rechecksAtStartup,
    @Default(true) bool musicLookupEnabled,
    @Default(defaultMusicLookupContact) String musicLookupContact,
    @Default(false) bool lastChangeUnsaved,
  }) = _PreferencesState;
}
