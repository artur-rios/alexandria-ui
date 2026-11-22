import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/catalog_file.dart';
import '../domain/file_type.dart';
import '../domain/view_layout.dart';
import 'file_details_view.dart';
import 'music_display_name.dart';

/// Files drawn in [layout], as a sliver of a scroll view (FR-CT-03,
/// FR-CT-10).
///
/// Built on demand, not as a column: FR-CT-10 asks that scrolling cost not
/// grow with the size of the folder, and one that built every row would spend
/// the whole folder's worth of work to show one screen of it.
class FileSlivers extends StatelessWidget {
  /// Creates the rows or tiles for [files].
  const FileSlivers({required this.files, required this.layout, super.key});

  /// The files, in the order they are drawn.
  final List<CatalogFile> files;

  /// The layout actually drawn, once a narrow window has had its say
  /// (`ViewLayout.resolvedFor`).
  final ViewLayout layout;

  @override
  Widget build(BuildContext context) => switch (layout) {
    ViewLayout.grid => SliverGrid.builder(
      gridDelegate: fileGridDelegate,
      itemCount: files.length,
      itemBuilder: (context, index) =>
          FileTile(file: files[index], shown: files),
    ),
    ViewLayout.list || ViewLayout.detailedList => SliverList.builder(
      itemCount: files.length,
      itemBuilder: (context, index) => FileRow(
        file: files[index],
        shown: files,
        detailed: layout == ViewLayout.detailedList,
      ),
    ),
  };
}

/// How the tiles are laid out: as many columns as fit, each at most 220 wide.
const SliverGridDelegate fileGridDelegate =
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 220,
      childAspectRatio: 4 / 3,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
    );

/// One file as a tile: it opens the file, and its details are the button in
/// the corner.
class FileTile extends ConsumerWidget {
  /// Creates the tile for [file], drawn among [shown].
  const FileTile({required this.file, required this.shown, super.key});

  /// The file.
  final CatalogFile file;

  /// The files drawn with it, in their order: a track plays through them.
  final List<CatalogFile> shown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Stack(
        children: [
          Positioned(top: 0, right: 0, child: FileDetailsButton(file: file)),
          Positioned.fill(
            child: InkWell(
              onTap: () => openFile(context, ref, file, shown: shown),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      file.isMissing
                          ? Icons.report_gmailerrorred_outlined
                          : Icons.insert_drive_file_outlined,
                      color: file.isMissing ? theme.colorScheme.error : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      displayName(file),
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One file as a row.
class FileRow extends ConsumerWidget {
  /// Creates the row for [file], drawn among [shown].
  const FileRow({
    required this.file,
    required this.shown,
    this.detailed = false,
    super.key,
  });

  /// The file.
  final CatalogFile file;

  /// The files drawn with it, in their order: a track plays through them.
  final List<CatalogFile> shown;

  /// Whether the row shows the file's path beside its name.
  final bool detailed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListTile(
      // UC-13 main flow step 1: a row opens its file. The details are the
      // button at the end of the row, and are still where a file that cannot
      // be opened ends up (`openFile`).
      onTap: () => openFile(context, ref, file, shown: shown),
      leading: Icon(
        // Deliberately not one of the navigation panel's icons: a row and a
        // destination that draw the same glyph are two different things
        // claiming to be one.
        file.isMissing
            ? Icons.report_gmailerrorred_outlined
            : file.type == FileType.audio
            ? Icons.music_note_outlined
            : Icons.insert_drive_file_outlined,
        color: file.isMissing ? theme.colorScheme.error : null,
      ),
      // The plain list is the name and nothing else; the detailed one adds
      // where the file actually is beside it, which is the detail that
      // distinguishes two files with the same name. Beside rather than
      // beneath: a second column is what "list with details" means in
      // FR-CT-03, and it is the column that needs the medium tier's width —
      // below the medium floor the layout is substituted rather than squeezed
      // (UC-10 AF-01).
      title: detailed
          ? Row(
              children: [
                Expanded(child: Text(displayName(file))),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    file.path,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : Text(displayName(file)),
      // A track is named by its tags, with who and from what beneath; the
      // path beside it in the detailed layout still tells two apart.
      subtitle: switch (musicByline(file)) {
        final String byline when file.type == FileType.audio => Text(byline),
        _ => null,
      },
      // A file the last refresh could not find is still an active record; it
      // is marked rather than hidden, and reviewing them is UC-37.
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (file.durationSeconds case final double seconds
              when file.type == FileType.audio)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Text(
                formatDuration(seconds),
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (file.isMissing)
            Text(
              l10n.catalogFileMissing,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          FileDetailsButton(file: file),
        ],
      ),
    );
  }
}
