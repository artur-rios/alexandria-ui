import '../../../core/l10n/generated/app_localizations.dart';
import '../domain/album_medium.dart';

/// What a screen reader is told a turning [medium] is (UC-21, FR-PL-07).
///
/// Shared between `AlbumStage` and `AlbumVisor` (Finding 10): both once kept
/// their own copy of this same switch, which is exactly the kind of two
/// copies that can quietly drift — the bar and the full player describing
/// the same record differently. One function is what keeps that impossible.
String albumMediumLabel(AlbumMedium medium, AppLocalizations l10n) => switch (medium) {
  AlbumMedium.vinyl => l10n.albumMediumVinyl,
  AlbumMedium.tape => l10n.albumMediumTape,
  AlbumMedium.disc => l10n.albumMediumDisc,
};
