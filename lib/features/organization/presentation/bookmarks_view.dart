import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../lifecycle/presentation/delete_record_button.dart';
import '../../shell/presentation/async_state_view.dart';
import '../domain/bookmark.dart';

/// The bookmarks area of the shell (UC-28, FR-OG-08 … FR-OG-12).
///
/// The navigation panel has always had an entry for it; this is what the entry
/// now shows.
class BookmarksView extends ConsumerWidget {
  /// Creates the view.
  const BookmarksView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final bookmarks = ref.watch(bookmarksControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: ref.read(bookmarkFormProvider.notifier).create,
            icon: const Icon(Icons.add),
            label: Text(l10n.bookmarkAdd),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // The form is inline rather than a dialog: creating one bookmark after
        // another is what an owner filing a session's reading does, and a
        // modal makes that a sequence of interruptions.
        if (ref.watch(bookmarkFormProvider).isOpen) ...[
          const _BookmarkForm(),
          const SizedBox(height: AppSpacing.md),
        ],
        const DeletionNoticeBar(),

        Expanded(
          child: AsyncStateView(
            value: bookmarks,
            onRetry: ref.read(bookmarksControllerProvider.notifier).reload,
            isEmpty: (bookmarks) => bookmarks.isEmpty,
            emptyBuilder: (context) => Center(child: Text(l10n.bookmarksNone)),
            builder: (context, bookmarks) => ListView.builder(
              itemCount: bookmarks.length,
              itemBuilder: (context, index) =>
                  _BookmarkTile(bookmark: bookmarks[index]),
            ),
          ),
        ),
      ],
    );
  }
}

/// One bookmark, with what can be done to it.
class _BookmarkTile extends ConsumerWidget {
  const _BookmarkTile({required this.bookmark});

  final Bookmark bookmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return ListTile(
      leading: const Icon(Icons.bookmark_outline),
      title: Text(bookmark.title),
      subtitle: Text(bookmark.url, overflow: TextOverflow.ellipsis),
      // Step 6: opening it is the ordinary thing to do with a bookmark, so it
      // is the tile's own tap rather than an action beside it.
      onTap: () => unawaited(_open(context, ref, bookmark)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.bookmarkEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                ref.read(bookmarkFormProvider.notifier).edit(bookmark),
          ),
          // UC-33 main flow step 1.
          DeleteBookmarkButton(bookmark: bookmark),
        ],
      ),
    );
  }

  /// Step 6: the URL goes to the platform's default browser (FR-OG-11).
  ///
  /// AF-04: where none can be launched, the owner is told and offered the
  /// address to copy — which is the only useful thing left when the platform
  /// will not open it.
  static Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    Bookmark bookmark,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (await ref.read(browserLauncherProvider).open(bookmark.url)) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.bookmarkNoBrowser),
        action: SnackBarAction(
          label: l10n.bookmarkCopyUrl,
          onPressed: () =>
              unawaited(Clipboard.setData(ClipboardData(text: bookmark.url))),
        ),
      ),
    );
  }
}

/// The create-and-update form (main flow steps 3 to 5).
class _BookmarkForm extends ConsumerStatefulWidget {
  const _BookmarkForm();

  @override
  ConsumerState<_BookmarkForm> createState() => _BookmarkFormState();
}

class _BookmarkFormState extends ConsumerState<_BookmarkForm> {
  late final TextEditingController _url = TextEditingController(
    text: ref.read(bookmarkFormProvider).url,
  );
  late final TextEditingController _title = TextEditingController(
    text: ref.read(bookmarkFormProvider).title,
  );

  /// Which bookmark the fields were filled from, so opening the form on
  /// another one refills them and typing in it does not.
  String? _filledFrom;

  @override
  void dispose() {
    _url.dispose();
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(bookmarkFormProvider);
    final form = ref.read(bookmarkFormProvider.notifier);

    if (_filledFrom != state.uuid) {
      _filledFrom = state.uuid;
      _url.text = state.url;
      _title.text = state.title;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _title,
              enabled: !state.isSaving,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.bookmarkTitleLabel,
                errorText: _messageFor(state.titleError, l10n),
              ),
              onChanged: form.editTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _url,
              enabled: !state.isSaving,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: l10n.bookmarkUrlLabel,
                errorText: _messageFor(state.urlError, l10n),
              ),
              onChanged: form.editUrl,
              onSubmitted: (_) => unawaited(form.submit()),
            ),

            // AF-02 and AF-05: the core's reason, with what the owner wrote
            // still in front of them.
            if (state.rejection case final rejection?) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                rejection.localizedMessage(l10n),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: state.isSaving ? null : form.close,
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: state.isSaving
                      ? null
                      : () => unawaited(form.submit()),
                  child: Text(
                    state.isEditing ? l10n.bookmarkSave : l10n.bookmarkCreate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _messageFor(BookmarkFieldError? error, AppLocalizations l10n) =>
      switch (error) {
        null => null,
        BookmarkFieldError.empty => l10n.bookmarkFieldEmpty,
        BookmarkFieldError.malformedUrl => l10n.bookmarkUrlMalformed,
        BookmarkFieldError.unopenableUrl => l10n.bookmarkUrlUnopenable,
      };
}
