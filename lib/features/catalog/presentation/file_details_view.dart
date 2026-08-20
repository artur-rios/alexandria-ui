import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shell/presentation/async_state_view.dart';
import '../domain/file_details.dart';
import '../domain/library_type.dart';
import 'music_metadata_form.dart';
import '../../editing/presentation/text_editor_screen.dart';
import '../../playback/application/audio_playback_controller.dart';
import '../../viewers/domain/viewer_registry.dart';
import '../../viewers/presentation/comic_viewer_screen.dart';
import '../../viewers/presentation/document_viewer_screen.dart';
import '../../viewers/presentation/image_viewer_screen.dart';
import '../../viewers/presentation/page_viewer_screen.dart';
import '../domain/catalog_file.dart';
import '../../playback/presentation/video_player_screen.dart';
import '../../lifecycle/application/open_file_holds.dart';
import '../../lifecycle/presentation/delete_record_button.dart';
import '../../lifecycle/presentation/purge_on_disk_section.dart';
import '../../tracking/presentation/add_to_reading_list_button.dart';
import '../../tracking/presentation/add_to_watchlist_button.dart';
import 'rename_file_dialog.dart';
import 'video_metadata_form.dart';

/// One file's details (UC-13, FR-CT-05, FR-CT-12).
///
/// A dialog over the listing rather than a screen that replaces it: the owner
/// opened one row of something they were reading, and closing it should put
/// them back exactly where they were.
class FileDetailsView extends ConsumerWidget {
  /// Creates the view.
  const FileDetailsView({super.key});

  /// Presents the details for [uuid].
  static Future<void> show(BuildContext context, WidgetRef ref, String uuid) {
    ref.read(openFileProvider.notifier).open(uuid);

    return showDialog<void>(
      context: context,
      builder: (context) => const FileDetailsView(),
    ).whenComplete(() => ref.read(openFileProvider.notifier).close());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final details = ref.watch(fileDetailsControllerProvider);

    return AlertDialog(
      title: Text(l10n.detailsTitle),
      content: SizedBox(
        width: 520,
        child: AsyncStateView<FileDetails?>(
          value: details,
          onRetry: () =>
              ref.read(fileDetailsControllerProvider.notifier).reload(),
          builder: (context, loaded) => loaded == null
              ? const SizedBox.shrink()
              : _Details(details: loaded),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.preferencesClose),
        ),
      ],
    );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.details});

  final FileDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(details.file.name, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),

          _Section(l10n.detailsState),
          Text(
            switch ((details.isDeleted, details.isMissing)) {
              (true, _) => l10n.detailsStateDeleted,
              (_, true) => l10n.detailsStateMissing,
              _ => l10n.detailsStateActive,
            },
            style: theme.textTheme.bodyMedium?.copyWith(
              color: details.canReachTheFile ? null : theme.colorScheme.error,
            ),
          ),

          // AF-02: shown as deleted. Restoring it is UC-34's, so the state is
          // reported rather than an action offered that does not exist.
          if (details.isDeleted) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.detailsDeletedHint, style: theme.textTheme.bodySmall),
          ],

          // AF-03: shown as missing, with the re-scan that might bring it
          // back — which is UC-07's refresh, and does exist.
          if (details.isMissing && !details.isDeleted) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.detailsMissingHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(indexRunsControllerProvider.notifier).startRefresh(),
              icon: const Icon(Icons.autorenew),
              label: Text(l10n.detailsRescan),
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          _Section(l10n.detailsPath),
          SelectableText(details.file.path, style: theme.textTheme.bodySmall),

          const SizedBox(height: AppSpacing.md),
          _Section(l10n.detailsMetadata),
          _Metadata(details: details),

          // UC-15 and UC-16 main flow step 1. Offered for the two types there
          // is a form for, and not for a deleted record, which the core
          // refuses to edit until it is restored. The remaining editable
          // subtypes — document, comic, image — have no use case in the
          // backlog, so they are deliberately absent rather than pending.
          if (details.isDeleted ? null : _metadataFormFor(details.file.type)
              case final openForm?) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => openForm(context, ref, details),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.detailsEditMetadata),
            ),
          ],

          // UC-18 main flow step 1. Text and Markdown files are the ones the
          // core will read and write content for; every other type's content
          // is bytes this application does not edit (BR-06, BR-09).
          if (details.file.type == LibraryType.text && !details.isDeleted) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () =>
                  TextEditorScreen.show(context, ref, details.file),
              icon: const Icon(Icons.edit_note_outlined),
              label: Text(l10n.editorOpen),
            ),
          ],

          // UC-17 main flow step 1. Every type can be renamed, because the
          // name is the file's and not its subtype's — but not a deleted
          // record, which the core refuses to touch until it is restored.
          if (!details.isDeleted) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () =>
                  RenameFileDialog.show(context, ref, details.file),
              icon: const Icon(Icons.drive_file_rename_outline),
              label: Text(l10n.renameOpen),
            ),
          ],

          // UC-20 main flow step 1: a track, its album, or its artist. The
          // three are offered together because they are one decision — what
          // to put in the queue — and the owner is looking at the track that
          // answers it.
          if (details.file.type == LibraryType.audio && !details.isDeleted) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                FilledButton.icon(
                  onPressed: () => _startAudio(
                    context,
                    ref,
                    (player) => player.playTrack(details.file),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.audioPlay),
                ),
                OutlinedButton.icon(
                  onPressed: () => _startAudio(
                    context,
                    ref,
                    (player) => player.playAlbum(details.file),
                  ),
                  icon: const Icon(Icons.album_outlined),
                  label: Text(l10n.audioPlayAlbum),
                ),
                OutlinedButton.icon(
                  onPressed: () => _startAudio(
                    context,
                    ref,
                    (player) => player.playArtist(details.file),
                  ),
                  icon: const Icon(Icons.person_outline),
                  label: Text(l10n.audioPlayArtist),
                ),
              ],
            ),
          ],

          // UC-31 main flow step 3: a book or a comic can be tracked from
          // its own detail view. AF-02 needs nothing here -- this is offered
          // for those two types and for nothing else.
          if ((details.file.type == LibraryType.document ||
                  details.file.type == LibraryType.comic) &&
              !details.isDeleted) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: AddToReadingListButton(file: details.file),
            ),
          ],

          // UC-29 main flow step 3: a video can be tracked from its own
          // detail view. AF-02 needs nothing here — this is offered for a
          // video and for nothing else.
          if (details.file.type == LibraryType.video && !details.isDeleted) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: AddToWatchlistButton(file: details.file),
            ),
          ],

          // UC-19 main flow step 1. Offered for a video whose file the last
          // refresh could still find: AF-01 covers one that has gone since,
          // and offering nothing for a record already known to be missing
          // would be an action that cannot work.
          if (details.file.type == LibraryType.video && !details.isDeleted) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: () =>
                  VideoPlayerScreen.show(context, ref, details.file),
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.videoPlay),
            ),
          ],

          // UC-33 main flow step 1: a record already deleted has nothing to
          // delete, which is why this is offered for an active one only.
          if (!details.isDeleted) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: DeleteFileButton(file: details.file),
            ),
          ],
          const DeletionNoticeBar(),

          const SizedBox(height: AppSpacing.lg),
          // UC-22 main flow steps 1 and 2: the viewer is resolved from the
          // registry keyed by type (FR-VW-01), so a type gains an Open action
          // by being registered and nothing here changes for it.
          //
          // AF-04 / FR-VW-08: a type with no viewer says so and keeps every
          // other action, rather than offering an Open that would do nothing.
          if (ref.watch(viewerRegistryProvider).viewerFor(details.file.type)
              case final viewer?)
            FilledButton.icon(
              onPressed: () => openViewer(context, ref, viewer, details.file),
              icon: const Icon(Icons.open_in_full),
              label: Text(l10n.viewerOpen),
            )
          else
            Text(
              l10n.detailsNoViewer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

          // UC-36: last, folded away, and below everything else — FR-LC-06
          // asks for an action that is never the default and never one
          // interaction from a listing row.
          const SizedBox(height: AppSpacing.lg),
          PurgeOnDiskSection(file: details.file),
        ],
      ),
    );
  }
}

/// The type-specific metadata and the values the core extracted.
class _Metadata extends StatelessWidget {
  const _Metadata({required this.details});

  final FileDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final rows = <(String, String)>[
      for (final entry in details.metadata.entries) (entry.key, entry.value),
      if (details.width != null) (l10n.detailsWidth, '${details.width}'),
      if (details.height != null) (l10n.detailsHeight, '${details.height}'),
      if (details.pageCount != null)
        (l10n.detailsPages, '${details.pageCount}'),
      if (details.durationSeconds != null)
        (l10n.detailsDuration, _formatDuration(details.durationSeconds!)),
    ];

    if (rows.isEmpty) {
      return Text(
        l10n.detailsMetadataNone,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(label, style: theme.textTheme.bodySmall),
                ),
                Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }

  /// A duration as hours, minutes and seconds.
  ///
  /// Formatted here rather than localized: the separators are colons in both
  /// supported languages, and a duration is read the same way in each.
  String _formatDuration(double seconds) {
    final total = Duration(seconds: seconds.round());
    final minutes = total.inMinutes.remainder(60).toString().padLeft(2, '0');
    final remaining = total.inSeconds.remainder(60).toString().padLeft(2, '0');

    return total.inHours > 0
        ? '${total.inHours}:$minutes:$remaining'
        : '$minutes:$remaining';
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );
}

/// Opens the viewer registered for a file (UC-22 main flow steps 1 and 2).
///
/// The one place a [ViewerKind] becomes a screen. Everything above it works in
/// terms of the registry, which is what FR-VW-01 asks for: a new viewer is a
/// registration and one line here.
Future<void> openViewer(
  BuildContext context,
  WidgetRef ref,
  ViewerKind viewer,
  CatalogFile file,
) async {
  // UC-33 AF-04: while a viewer has the file open, a deletion knows about it
  // and can close it. Registered here rather than in each viewer, because this
  // is the one place a viewer is opened from.
  final navigator = Navigator.of(context);
  final forget = ref
      .read(openFileHoldsProvider.notifier)
      .register(
        OpenFileHold(
          uuid: file.uuid,
          close: () async {
            if (navigator.canPop()) navigator.pop();
          },
        ),
      );

  try {
    await _showViewer(context, ref, viewer, file);
  } finally {
    forget();
  }
}

Future<void> _showViewer(
  BuildContext context,
  WidgetRef ref,
  ViewerKind viewer,
  CatalogFile file,
) => switch (viewer) {
  ViewerKind.document => DocumentViewerScreen.show(context, ref, file),
  ViewerKind.comic => ComicViewerScreen.show(context, ref, file),
  // UC-24 moves between the images of the listing the owner opened this one
  // from, so the viewer is handed that listing rather than one file.
  ViewerKind.image => ImageViewerScreen.show(
    context,
    ref,
    file,
    ref.read(listingControllerProvider).value ?? [file],
  ),
  ViewerKind.page => PageViewerScreen.show(context, ref, file),
};

/// Starts audio playback and leaves the detail view (UC-20 main flow step 4).
///
/// The dialog closes because the player lives in the bar at the bottom of the
/// shell, and a modal over it would hide the transport — and, for AF-04, the
/// question the owner has to answer before anything plays.
void _startAudio(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function(AudioPlaybackController player) play,
) {
  Navigator.of(context).pop();
  unawaited(play(ref.read(audioPlaybackControllerProvider.notifier)));
}

/// How a metadata form is opened, whichever type's it is.
typedef OpenMetadataForm =
    Future<void> Function(
      BuildContext context,
      WidgetRef ref,
      FileDetails details,
    );

/// The form that edits [type]'s metadata, or `null` when there is none.
///
/// Resolved by lookup rather than by a chain of type conditionals in the
/// layout: a type either has a form or it does not, and the answer belongs in
/// one place (IR-02's registration rule).
OpenMetadataForm? _metadataFormFor(LibraryType type) => switch (type) {
  LibraryType.audio => MusicMetadataForm.show,
  LibraryType.video => VideoMetadataForm.show,
  LibraryType.document ||
  LibraryType.comic ||
  LibraryType.text ||
  LibraryType.html ||
  LibraryType.image => null,
};

/// What AF-01 shows: the record is gone, so the listing is refreshed and the
/// owner goes back to it.
///
/// A dialog of its own rather than a state inside the detail view, because
/// there are no details to show — the file is not there.
Future<void> showFileNotFound(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);

  // The listing is refreshed because the record it was showing is gone, and
  // the owner is going back to it.
  unawaited(ref.read(listingControllerProvider.notifier).reload());

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(l10n.detailsNotFound),
      actions: [
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.preferencesClose),
        ),
      ],
    ),
  );
}
