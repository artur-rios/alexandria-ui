import 'package:flutter/material.dart';

import 'album_palette.dart';
import 'app_spacing.dart';
import 'playback_colors.dart';

/// The light and dark themes, and the single source of colors, spacing, and
/// typography for every screen (IR-10, FR-UX-04, FR-UX-07).
///
/// Nothing outside this file declares a color. Widgets read
/// `Theme.of(context).colorScheme`, and the guard test in
/// `test/core/theme/no_color_literal_test.dart` is what keeps that true — BR-18
/// prohibits a literal in a component, and a prohibition nobody checks is a
/// comment.
abstract final class AppTheme {
  /// The seed the two schemes are derived from.
  ///
  /// A single seed rather than a hand-built palette: Material 3 generates the
  /// tonal range for both brightnesses from it, which is what keeps the light
  /// and dark screens recognisably the same product.
  static const Color _seed = Color(0xFF4A6FA5);

  /// The light theme.
  static ThemeData get light => _build(Brightness.light);

  /// The dark theme.
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      // The players' surround, which is black in both brightnesses and so is
      // not something the scheme can answer (UC-19, UC-20), and the palette
      // the now-playing artwork paints its device from (BR-18, FR-UX-07).
      extensions: const [PlaybackColors.standard, AlbumPalette.standard],
      visualDensity: VisualDensity.comfortable,

      // A desktop application is read at arm's length on a large display; the
      // phone defaults are too tight for a catalog listing.
      cardTheme: CardThemeData(
        margin: const EdgeInsets.all(AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }
}
