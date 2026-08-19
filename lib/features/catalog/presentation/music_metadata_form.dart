import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/application/music_metadata_editor.dart';
import '../domain/file_details.dart';
import '../domain/music_metadata.dart';
import 'file_details_view.dart';

/// The music metadata form (UC-15, FR-ME-01).
///
/// A dialog over the detail view it was opened from, for the same reason the
/// detail view is a dialog over the listing: the owner is correcting one
/// record and should land back on it.
class MusicMetadataForm extends ConsumerStatefulWidget {
  /// Creates the form.
  const MusicMetadataForm({super.key});

  /// Presents the form for [details] (main flow steps 1 and 2).
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    FileDetails details,
  ) {
    ref
        .read(musicMetadataEditorProvider.notifier)
        .open(details.file.uuid, MusicMetadata.fromDetails(details.metadata));

    return showDialog<void>(
      context: context,
      builder: (context) => const MusicMetadataForm(),
    );
  }

  @override
  ConsumerState<MusicMetadataForm> createState() => _MusicMetadataFormState();
}

class _MusicMetadataFormState extends ConsumerState<MusicMetadataForm> {
  /// One controller per field, created once from the values the form opened
  /// on. They are the owner's text, so they are not rebuilt from state — doing
  /// that would move the cursor while they typed.
  late final Map<MusicField, TextEditingController> _controllers = {
    for (final field in MusicField.values)
      field: TextEditingController(
        text: ref.read(musicMetadataEditorProvider).draft[field],
      ),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(musicMetadataEditorProvider);

    // Steps 7 and AF-03/AF-04: the form is finished, so it closes itself. The
    // listing behind it has already been told to read the core again.
    ref.listen(musicMetadataEditorProvider, (_, next) {
      switch (next.stage) {
        case MusicEditorStage.saved:
          Navigator.of(context).pop();
        case MusicEditorStage.gone:
          Navigator.of(context).pop();
          unawaited(showFileNotFound(context, ref));
        case MusicEditorStage.editing || MusicEditorStage.saving:
          break;
      }
    });

    return AlertDialog(
      title: Text(l10n.musicMetadataTitle),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final field in MusicField.values) ...[
                TextField(
                  controller: _controllers[field],
                  enabled: !state.isSaving,
                  keyboardType: field.isNumeric
                      ? TextInputType.number
                      : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: _label(field, l10n),
                    // AF-01: the field is marked with what is wrong with it,
                    // and nothing was sent.
                    errorText: state.errors[field] == null
                        ? null
                        : _errorText(state.errors[field]!, l10n),
                  ),
                  onChanged: (value) => ref
                      .read(musicMetadataEditorProvider.notifier)
                      .edit(field, value),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // AF-02: the core disagreed, and its reason is the final word.
              if (state.rejection case final rejection?) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  rejection.localizedMessage(l10n),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isSaving
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(l10n.musicMetadataCancel),
        ),
        FilledButton(
          onPressed: state.isSaving
              ? null
              : () => ref.read(musicMetadataEditorProvider.notifier).submit(),
          child: state.isSaving
              ? const SizedBox(
                  width: AppSpacing.md,
                  height: AppSpacing.md,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.musicMetadataSave),
        ),
      ],
    );
  }

  String _label(MusicField field, AppLocalizations l10n) => switch (field) {
    MusicField.title => l10n.musicMetadataFieldTitle,
    MusicField.artist => l10n.musicMetadataFieldArtist,
    MusicField.album => l10n.musicMetadataFieldAlbum,
    MusicField.year => l10n.musicMetadataFieldYear,
    MusicField.genre => l10n.musicMetadataFieldGenre,
    MusicField.track => l10n.musicMetadataFieldTrack,
  };

  String _errorText(MusicFieldError error, AppLocalizations l10n) =>
      switch (error) {
        MusicFieldError.notANumber => l10n.musicMetadataErrorNotANumber,
        MusicFieldError.yearOutOfRange => l10n.musicMetadataErrorYear,
        MusicFieldError.trackNotPositive => l10n.musicMetadataErrorTrack,
        MusicFieldError.tooLong => l10n.musicMetadataErrorTooLong(
          maxMusicFieldLength,
        ),
      };
}
