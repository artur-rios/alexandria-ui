import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/domain/catalog_file.dart';

/// Adds a book or comic to a reading list from its detail view (UC-31 main
/// flow step 3).
///
/// AF-02 needs nothing here: the detail view offers this for a document and a
/// comic and for nothing else, so a file that is neither never reaches it.
class AddToReadingListButton extends ConsumerWidget {
  /// Creates the button for [file].
  const AddToReadingListButton({required this.file, super.key});

  /// The book or comic to track.
  final CatalogFile file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lists = ref.watch(readingListsControllerProvider).value ?? const [];

    return PopupMenuButton<String>(
      tooltip: l10n.readingListAddTo,
      onSelected: (uuid) => unawaited(
        ref
            .read(readingListsFormProvider.notifier)
            .addItem(readingListUuid: uuid, itemUuid: file.uuid),
      ),
      itemBuilder: (context) => [
        if (lists.isEmpty)
          PopupMenuItem<String>(
            enabled: false,
            child: Text(l10n.readingListsNone),
          )
        else
          for (final list in lists)
            PopupMenuItem<String>(
              value: list.uuid,
              // AF-03: a list already tracking this item says so rather than
              // disappearing from the menu.
              child: Text(
                list.tracks(file.uuid)
                    ? l10n.readingListAlreadyIn(list.name)
                    : list.name,
              ),
            ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.library_add_outlined),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.readingListAddTo),
          ],
        ),
      ),
    );
  }
}
