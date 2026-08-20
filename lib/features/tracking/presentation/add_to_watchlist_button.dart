import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../catalog/domain/catalog_file.dart';

/// Adds a video to a watchlist from its detail view (UC-29 main flow step 3).
///
/// AF-02 needs nothing here: the detail view offers this for a video and for
/// nothing else, and a file that is not one never reaches it.
class AddToWatchlistButton extends ConsumerWidget {
  /// Creates the button for [file].
  const AddToWatchlistButton({required this.file, super.key});

  /// The video to track.
  final CatalogFile file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final watchlists =
        ref.watch(watchlistsControllerProvider).value ?? const [];

    return PopupMenuButton<String>(
      tooltip: l10n.watchlistAddTo,
      onSelected: (uuid) => unawaited(
        ref
            .read(watchlistsFormProvider.notifier)
            .addVideo(watchlistUuid: uuid, videoUuid: file.uuid),
      ),
      itemBuilder: (context) => [
        if (watchlists.isEmpty)
          PopupMenuItem<String>(
            enabled: false,
            child: Text(l10n.watchlistsNone),
          )
        else
          for (final watchlist in watchlists)
            PopupMenuItem<String>(
              value: watchlist.uuid,
              // A list already tracking this video says so rather than
              // disappearing: AF-03 is an answer, and a menu that quietly
              // dropped the entry would leave the owner wondering where it
              // went.
              child: Text(
                watchlist.tracks(file.uuid)
                    ? l10n.watchlistAlreadyIn(watchlist.name)
                    : watchlist.name,
              ),
            ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.playlist_add),
            const SizedBox(width: 8),
            Text(l10n.watchlistAddTo),
          ],
        ),
      ),
    );
  }
}
