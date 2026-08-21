import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/video_metadata_editor.dart';
import '../domain/file_details.dart';
import '../domain/video_metadata.dart';
import 'file_details_view.dart';

/// The video metadata form (UC-16, FR-ME-02).
///
/// A dialog over the detail view it was opened from, as the music form is:
/// the owner is correcting one record and should land back on it.
class VideoMetadataForm extends ConsumerStatefulWidget {
  /// Creates the form.
  const VideoMetadataForm({super.key});

  /// Presents the form for [details] (main flow steps 1 and 2).
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    FileDetails details,
  ) {
    ref
        .read(videoMetadataEditorProvider.notifier)
        .open(details.file.uuid, VideoMetadata.fromDetails(details.metadata));

    return showDialog<void>(
      context: context,
      builder: (context) => const VideoMetadataForm(),
    );
  }

  @override
  ConsumerState<VideoMetadataForm> createState() => _VideoMetadataFormState();
}

class _VideoMetadataFormState extends ConsumerState<VideoMetadataForm> {
  /// The typed fields only: the marking is picked rather than typed, so it has
  /// no controller and is read straight from the draft.
  ///
  /// Created once from the values the form opened on. They hold the owner's
  /// text, so they are not rebuilt from state — doing that would move the
  /// cursor while they typed.
  late final Map<VideoField, TextEditingController> _controllers = {
    for (final field in VideoField.values)
      if (!field.isChoice)
        field: TextEditingController(
          text: ref.read(videoMetadataEditorProvider).draft[field],
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
    final theme = Theme.of(context);
    final state = ref.watch(videoMetadataEditorProvider);
    final editor = ref.read(videoMetadataEditorProvider.notifier);

    // Step 6 and AF-04: the form is finished, so it closes itself. The listing
    // behind it has already been told to read the core again.
    ref.listen(videoMetadataEditorProvider, (_, next) {
      switch (next.stage) {
        case VideoEditorStage.saved:
          Navigator.of(context).pop();
        case VideoEditorStage.gone:
          Navigator.of(context).pop();
          unawaited(showFileNotFound(context, ref));
        case VideoEditorStage.editing ||
            VideoEditorStage.saving ||
            VideoEditorStage.confirmingMarkingChange:
          break;
      }
    });

    final marking = MediaKind.fromWireName(state.draft[VideoField.mediaKind]);

    return AlertDialog(
      title: Text(l10n.videoMetadataTitle),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final field in VideoField.values)
                if (!field.isChoice) ...[
                  TextField(
                    controller: _controllers[field],
                    enabled: !state.isSaving,
                    // FR-UX-11: the form opens ready to be typed into, the
                    // same way the rename dialog and the bookmark form do.
                    autofocus: field == VideoField.values.first,
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
                    onChanged: (value) => editor.edit(field, value),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

              // FR-ME-02's own field. A pair of options rather than a text
              // field, because there are two answers and neither is spelled by
              // the owner.
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.videoMetadataFieldMediaKind,
                style: theme.textTheme.titleSmall,
              ),
              RadioGroup<String>(
                groupValue: marking?.wireName,
                // Guarded inside rather than by a null callback: the group
                // takes a non-nullable handler, and a disabled group would
                // also grey out what the marking currently is, which is the
                // one thing AF-03's question is about.
                onChanged: (wireName) {
                  if (state.isSaving) return;
                  final kind = MediaKind.fromWireName(wireName);
                  if (kind != null) editor.markAs(kind);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final kind in MediaKind.values)
                      RadioListTile<String>(
                        value: kind.wireName,
                        title: Text(_markingLabel(kind, l10n)),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),

              // AF-03: what the confirmation is about, in the form rather than
              // in a dialog over it — the owner is being asked about a field
              // they can see, and moving the question away from it would hide
              // what it is about.
              if (state.isConfirmingMarkingChange) ...[
                const SizedBox(height: AppSpacing.sm),
                _MarkingChangeWarning(
                  onConfirm: editor.confirmMarkingChange,
                  onCancel: editor.cancelMarkingChange,
                ),
              ],

              // AF-02: the core disagreed, and its reason is the final word.
              if (state.rejection case final rejection?) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  rejection.localizedMessage(l10n),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.videoMetadataCancel),
        ),
        FilledButton(
          // While the marking question is open, the save is the answer to it,
          // not this button: two ways to send the same call would let the
          // owner past the warning without answering it.
          onPressed: state.isSaving || state.isConfirmingMarkingChange
              ? null
              : editor.submit,
          child: state.isSaving
              ? const SizedBox(
                  width: AppSpacing.md,
                  height: AppSpacing.md,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.videoMetadataSave),
        ),
      ],
    );
  }

  String _label(VideoField field, AppLocalizations l10n) => switch (field) {
    VideoField.title => l10n.videoMetadataFieldTitle,
    VideoField.year => l10n.videoMetadataFieldYear,
    VideoField.resolution => l10n.videoMetadataFieldResolution,
    VideoField.mediaKind => l10n.videoMetadataFieldMediaKind,
  };

  String _markingLabel(MediaKind kind, AppLocalizations l10n) => switch (kind) {
    MediaKind.movie => l10n.videoMetadataMovie,
    MediaKind.series => l10n.videoMetadataSeries,
  };

  String _errorText(VideoFieldError error, AppLocalizations l10n) =>
      switch (error) {
        VideoFieldError.notANumber => l10n.videoMetadataErrorNotANumber,
        VideoFieldError.yearOutOfRange => l10n.videoMetadataErrorYear,
        VideoFieldError.tooLong => l10n.videoMetadataErrorTooLong(
          maxVideoFieldLength,
        ),
      };
}

/// What AF-03 asks: the progress recorded per episode becomes progress for the
/// item as a whole, and the core is not called until the owner says so.
class _MarkingChangeWarning extends StatelessWidget {
  const _MarkingChangeWarning({
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.videoMetadataMarkingWarning,
            style: TextStyle(color: theme.colorScheme.onErrorContainer),
          ),
          const SizedBox(height: AppSpacing.sm),
          // A Wrap rather than a Row: both actions name what they do rather
          // than saying "OK", and two named actions do not fit side by side
          // in the dialog at the narrower window sizes (FR-UX-02).
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              // Declining takes the focus, as it does in the application's
              // confirmation dialog: what is on the other side of the other
              // button cannot be undone.
              TextButton(
                autofocus: true,
                onPressed: onCancel,
                child: Text(l10n.videoMetadataMarkingCancel),
              ),
              FilledButton(
                onPressed: onConfirm,
                child: Text(l10n.videoMetadataMarkingConfirm),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
