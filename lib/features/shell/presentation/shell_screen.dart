import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/domain/catalog_search.dart';
import '../../catalog/presentation/catalog_listing.dart';
import '../../catalog/presentation/catalog_search_view.dart';
import '../../catalog/presentation/home_dashboard.dart';
import '../../libraries/presentation/library_tree_screen.dart';
import '../../organization/presentation/bookmarks_view.dart';
import '../../playback/presentation/music_library_view.dart';
import '../../playback/presentation/now_playing_screen.dart';
import '../domain/shell_destination.dart';
import 'background_activity_strip.dart';
import 'playback_bar.dart';
import 'shell_menu_bar.dart';
import 'shell_navigation_panel.dart';

/// The application shell (UC-38, FR-UX-01, FR-UX-02).
///
/// Four regions and nothing else: the menu bar across the top, the navigation
/// panel down the left, the content area beside it, and the playback bar
/// across the bottom. Everything the owner does happens inside the content
/// area, which is why this widget stays this small — it is a frame, and a
/// frame that grew feature logic would be the thing every later use case has
/// to edit.
class ShellScreen extends ConsumerWidget {
  /// Creates the shell.
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destination = ref.watch(shellControllerProvider);

    // FR-PL-15: the pass that gives every artist a face, kept alive from
    // here for the whole of the session.
    //
    // Listened to rather than watched: this widget has no use for the pass's
    // progress and would otherwise rebuild the entire shell once per artist
    // fetched. What the listen actually does is hold the provider — a
    // background job with nobody reading it is a background job that is
    // disposed — and the shell is the right holder because the pass belongs
    // to the session, not to whoever happens to have the artists list open.
    ref.listen(artistPortraitBackfillProvider, (_, _) {});

    // UC-21 main flow step 2: the player opens itself when a track starts,
    // from wherever it was started — the shell is where every path into
    // playback converges, so a listener here is the one place that covers
    // all of them without any call site having to remember to open it.
    //
    // Keyed on the track playing rather than on the record: the owner asked
    // for the player on every track, and the album animation this listener
    // used to edge-trigger on — which owed an insertion once per record and
    // had a whole controller to say when — is gone. What is left is the fact
    // that decides it, which the queue has always carried.
    //
    // `ref.listen` rather than reading the queue in `build` and pushing from
    // inside it: a route push is a side effect, and Riverpod only calls a
    // widget's `listen` callback once the state change has been committed —
    // after this build, not during it — which is what lets
    // `Navigator.of(context).push` run here safely. `NowPlayingScreen.show`
    // declines to stack a second player on one already open, so there is
    // nothing left to guard here.
    ref.listen(audioPlaybackControllerProvider, (previous, next) {
      final started = next.current?.uuid;
      if (started == null || started == previous?.current?.uuid) return;
      // The owner's own switch: off means a track starts where they left the
      // player, rather than in front of it.
      if (!ref.read(preferencesControllerProvider).opensPlayerOnPlay) return;

      unawaited(NowPlayingScreen.show(context));
    });

    return Scaffold(
      body: Column(
        children: [
          // FR-UX-01: the library-wide menus, above everything the destination
          // owns.
          const ShellMenuBar(),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: Row(
              children: [
                ShellNavigationPanel(
                  selected: destination,
                  onSelected: ref.read(shellControllerProvider.notifier).go,
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: ShellContentArea(destination: destination)),
              ],
            ),
          ),
          // FR-LB-15: whatever the core is indexing, above the playback bar
          // and below everything else. It takes no height when nothing is
          // running, so the shell is unchanged for anyone not indexing.
          const BackgroundActivityStrip(),
          const Divider(height: 1, thickness: 1),
          const PlaybackBar(),
        ],
      ),
    );
  }
}

/// The content area (FR-UX-01).
///
/// A file type shows its listing (UC-09); home is the dashboard (UC-14) and
/// bookmarks are the bookmark manager (UC-28). Neither of the last two is a
/// file listing, which is why the switch below is on the type rather than on
/// the destination alone.
class ShellContentArea extends ConsumerWidget {
  /// Creates the content area for [destination].
  const ShellContentArea({required this.destination, super.key});

  /// Which area is shown.
  final ShellDestination destination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // UC-11: the search is across every type at once, so it belongs to the
    // shell rather than to any one listing — and while a term is present, the
    // results are what the content area shows.
    final searching = isSearchable(ref.watch(searchTermProvider));

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(destination.label(l10n), style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: switch (destination) {
              // AF-02 needs nothing of its own: an empty term is not a search,
              // and the listing is already what an absent search shows.
              // FR-CT-06 matches file names and file metadata, and bookmarks
              // are not files: the field is withheld there (see
              // `ShellMenuBar`), so a term left over from another area must
              // not replace the bookmarks with matching files either.
              _ when searching && destination != ShellDestination.bookmarks =>
                const CatalogSearchResults(),
              // The two areas that are not file listings: home is the
              // dashboard (UC-14) and bookmarks are the bookmark manager
              // (UC-28). Every other destination is a type, and its listing
              // reads which one from the shell.
              ShellDestination.home => const HomeDashboard(),
              ShellDestination.bookmarks => const BookmarksView(),
              // Folders browsed as trees, of every type at once (libraries
              // design) — a listing of one type is exactly what it is not.
              ShellDestination.libraries => const LibrariesView(),
              // UC-46: audio has its own area. A listing of file names is the
              // one thing a music library should never be.
              ShellDestination.music => const MusicLibraryView(),
              _ => const CatalogListing(),
            },
          ),
        ],
      ),
    );
  }
}
