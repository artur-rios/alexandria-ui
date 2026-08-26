import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/domain/catalog_file.dart';
import '../../catalog/domain/library_type.dart';
import '../../catalog/domain/music_metadata.dart';
import '../../organization/domain/bookmark.dart';
import '../../playback/domain/music_grouping.dart';
import '../../playback/presentation/music_display_name.dart' show tagOr;
import '../../shell/presentation/confirmation_dialog.dart';
import '../application/deletion_controller.dart';

/// Deletes a file from its detail view (UC-33 main flow step 1).
class DeleteFileButton extends ConsumerWidget {
  /// Creates the button for [file].
  const DeleteFileButton({required this.file, super.key});

  /// The file to hide.
  final CatalogFile file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return TextButton.icon(
      onPressed: () => _confirm(context, ref),
      icon: const Icon(Icons.delete_outline),
      label: Text(l10n.deleteFile),
    );
  }

  /// Step 2: the confirmation states that the record is hidden, that it stays
  /// restorable, and that the file on disk is untouched (FR-LC-01, BR-07).
  ///
  /// AF-01 is declining it. AF-04 is a player, viewer, or editor having the
  /// file open — said here, and let go of on the way through.
  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final deletion = ref.read(deletionControllerProvider.notifier);
    final isOpen = deletion.holdsOn(file.uuid).isNotEmpty;

    // FR-CT-13: the confirmation names an audio file by its metadata, read
    // off the same `musicLibraryProvider` the music area and playback read —
    // read rather than watched, because this runs from a button press, not a
    // build.
    String? title;
    if (file.type == LibraryType.audio) {
      final library = await ref.read(musicLibraryProvider.future);
      title = library.entries
          .firstWhere(
            (candidate) => candidate.file.uuid == file.uuid,
            orElse: () =>
                MusicEntry(file: file, metadata: const MusicMetadata()),
          )
          .title;
    }
    final name = file.type == LibraryType.audio
        ? tagOr(title, l10n.musicUnknownTitle)
        : file.name;
    if (!context.mounted) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: l10n.deleteFile,
      message: isOpen
          ? '${l10n.deleteFileMessage(name)} ${l10n.deleteFileInUse}'
          : l10n.deleteFileMessage(name),
      confirmLabel: l10n.deleteFile,
      fileOnDiskNotice: l10n.deleteFileOnDisk,
    );
    if (!confirmed) return;

    await deletion.deleteFile(file.uuid);
  }
}

/// Deletes a bookmark from its row (UC-33 main flow step 1).
class DeleteBookmarkButton extends ConsumerWidget {
  /// Creates the button for [bookmark].
  const DeleteBookmarkButton({required this.bookmark, super.key});

  /// The bookmark to hide.
  final Bookmark bookmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return IconButton(
      tooltip: l10n.deleteBookmark,
      icon: const Icon(Icons.delete_outline),
      onPressed: () => _confirm(context, ref),
    );
  }

  /// Step 2, without the disk notice: a bookmark is a record and nothing else,
  /// so a dialog that mentioned a file on disk would be describing something
  /// that is not there.
  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await ConfirmationDialog.show(
      context,
      title: l10n.deleteBookmark,
      message: l10n.deleteBookmarkMessage(bookmark.title),
      confirmLabel: l10n.deleteBookmark,
    );
    if (!confirmed) return;

    await ref
        .read(deletionControllerProvider.notifier)
        .deleteBookmark(bookmark.uuid);
  }
}

/// AF-02, AF-03, and anything else the core refused (UC-33).
class DeletionNoticeBar extends ConsumerWidget {
  /// Creates the bar.
  const DeletionNoticeBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(deletionControllerProvider);
    if (state.notice == DeletionNotice.none) return const SizedBox.shrink();

    final message = switch (state.notice) {
      DeletionNotice.alreadyDeleted => l10n.deleteAlreadyDeleted,
      DeletionNotice.notFound => l10n.deleteNotFound,
      DeletionNotice.refused =>
        state.refusal?.localizedMessage(l10n) ?? l10n.deleteNotFound,
      DeletionNotice.none => '',
    };

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: ref
                .read(deletionControllerProvider.notifier)
                .acknowledge,
            child: Text(l10n.editorDismiss),
          ),
        ],
      ),
    );
  }
}
