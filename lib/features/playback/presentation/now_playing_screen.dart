import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../enrichment/presentation/enrich_track_button.dart';
import '../../enrichment/presentation/track_enrichment_panel.dart';
import '../../playlists/presentation/add_to_playlist_button.dart';
import '../domain/album_cover.dart';
import 'album_stage.dart';
import 'music_display_name.dart';

/// The full audio player (UC-21, FR-PL-07).
///
/// A route rather than a dialog: `AlbumPlayerScreen`, the widget this
/// replaces, drew the animation into a 360-pixel dialog because a dialog was
/// what UC-21 first asked for, but the insertion and the spin need real room
/// to read as a case, a medium, and a device rather than a cramped diagram.
/// Filling the window is what gives them it. Closing the route is how AF-02's
/// "navigates to another screen" happens — popping it leaves the queue and
/// the bar exactly where they were, because neither one lives in this widget.
class NowPlayingScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const NowPlayingScreen({super.key});

  /// Below this, the stage reads as a smudge, not a record: the animation
  /// stops being worth the room it would still have to fight the title and
  /// the transport for, so it is hidden rather than drawn this small.
  static const double _minimumStageSize = 160;

  /// A rough allowance for the title, the queue label, and the transport row
  /// beneath the stage, subtracted from the window's height to decide how
  /// much of it the stage may claim.
  ///
  /// An estimate, not a measurement: the real height of that text depends on
  /// the locale and the owner's text scale, neither known until *after* a
  /// stage size would have to be chosen to lay the rest out around it. The
  /// `SingleChildScrollView` in [build] is what keeps this estimate from
  /// being load-bearing — if it undershoots, the page scrolls instead of
  /// overflowing.
  static const double _reservedForTextAndControls = 260;

  /// Whether a [NowPlayingScreen] is currently mounted anywhere in the tree.
  ///
  /// What [show] checks before pushing another one (Finding 3): the shell's
  /// own auto-open and the playback bar's button are two independent paths
  /// to the same route, and either could otherwise stack a second copy on
  /// top of a first that is already open — the owner would then have to
  /// close it twice, and the buried stage would keep both its tickers
  /// running underneath. Tied to [_NowPlayingScreenState]'s own
  /// `initState`/`dispose` rather than to the push/pop that opened this
  /// particular route, so it stays correct however the screen leaves the
  /// tree — a pop, a replaced route, or (in a test) the widget tree being
  /// torn down between cases — every one of those already calls `dispose`.
  static bool _mounted = false;

  /// Pushes the full-window player over [context] (main flow step 2), unless
  /// one is already open.
  static Future<void> show(BuildContext context) {
    if (_mounted) return Future<void>.value();

    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
    );
  }

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  @override
  void initState() {
    super.initState();
    NowPlayingScreen._mounted = true;
  }

  @override
  void dispose() {
    NowPlayingScreen._mounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(audioPlaybackControllerProvider);
    final controller = ref.read(audioPlaybackControllerProvider.notifier);
    final animation = ref.watch(albumAnimationControllerProvider);
    final current = state.current;

    // The sleeve's own picture, when `AlbumCoverController` has one — never
    // read for anything but the image itself: `null` for the designed
    // jacket, whether that is because the file carries no picture, the call
    // failed, or the cover simply has not arrived yet, is one case to this
    // screen, exactly as design section 4 asks.
    final cover = switch (ref.watch(albumCoverControllerProvider)) {
      AlbumCoverFetched(:final image) => image,
      AlbumCoverDesigned() => null,
    };

    // `AlbumAnimationState.medium` is already `null` for an empty queue and
    // for the mode being off — `AlbumAnimationController` folds both rules
    // in itself, so there is no separate queue-kind check to make here.
    final showsAnimation = animation.medium != null && current != null;

    // Reduced motion means `AlbumStage` never calls `onInserted` — it has
    // nothing to report finishing when nothing played — so the insertion
    // this screen owes has to be acknowledged from here instead, or the
    // flag would stay stuck `true` forever for an owner who has turned
    // system motion off.
    //
    // `addPostFrameCallback`, not `ref.listen`: this screen is frequently
    // built *after* `insertionOwed` already turned `true` — the shell's own
    // auto-open (Task 7 step 4) is what got it on screen in the first
    // place — and `ref.listen` only calls back on a *change* it observes
    // after it starts listening, never for the value already current when
    // it was registered. A post-frame callback reads the current value on
    // every build instead, which is what catches that already-true case; it
    // is also unconditionally safe to write state from, for the same reason
    // the shell's listener callback is — it never runs during a build.
    if (animation.insertionOwed && MediaQuery.disableAnimationsOf(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(albumAnimationControllerProvider.notifier).insertionShown();
      });
    }

    // Never the file name (FR-CT-13), and never the queue's own label for a
    // single track — the generic title stands in for both an untagged queue
    // and a queue with no name of its own.
    final queueLabel = queueLabelOf(state.queue, l10n);

    return Scaffold(
      // No title here: the queue's own name is already the second line of
      // the body below, right under the track title it belongs beside, and
      // an `AppBar` title would only repeat it — this bar exists for the
      // close control alone.
      appBar: AppBar(
        actions: [
          // Task 5 entry point 3: whatever is currently playing — nothing
          // when the queue is empty, since there is then no track to add.
          if (current != null) ...[
            // Scoped to this track on purpose. A few seconds, where the
            // whole library is hours at MusicBrainz's one-request-per-second
            // limit — an action that long needs a screen to report progress
            // and be cancelled from, not a button on the player.
            EnrichTrackButton(
              fileUuid: current.uuid,
              artistName: musicEntryForFile(ref, current).albumArtist,
            ),
            AddToPlaylistButton(fileUuids: [current.uuid]),
          ],
          IconButton(
            tooltip: l10n.audioClosePlayer,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, viewport) {
          final stageSize = math.min(
            viewport.maxWidth - AppSpacing.lg * 2,
            viewport.maxHeight - NowPlayingScreen._reservedForTextAndControls,
          );
          final showsStage =
              showsAnimation && stageSize >= NowPlayingScreen._minimumStageSize;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewport.maxHeight - AppSpacing.lg * 2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showsStage) ...[
                    AlbumStage(
                      medium: animation.medium!,
                      // Step 3: it turns while audio plays; steps 4 and 5
                      // stop and continue it with the playback it belongs
                      // to.
                      isPlaying: state.isPlaying,
                      // Task 6's owed flag, played once and acknowledged
                      // above (or by `AlbumStage` itself, when motion is not
                      // reduced) so the next track of the same record does
                      // not replay it.
                      insert: animation.insertionOwed,
                      // The record's own name, typeset on the case — never
                      // the current track's title, which is a different
                      // tag naming a different thing.
                      title: musicAlbumForFile(ref, current, l10n),
                      // The record's artist, not the current track's
                      // performer: the case is the record's sleeve, and a
                      // guest appearance would otherwise re-typeset the case
                      // mid-album with the guest's name.
                      artist: musicAlbumArtistForFile(ref, current, l10n),
                      // The queue's own label when it has one (an album or
                      // an artist queue); otherwise the current track's own
                      // raw album tag, never the localised "Unknown album"
                      // `musicAlbumForFile` above answers — that word would
                      // make the jacket hue depend on the interface
                      // language, and would give every untagged track the
                      // same hue as an album genuinely named that word.
                      // `null` either way is `sleeveIndexFor`'s own "no name
                      // to derive a hue from" case (Finding 1).
                      album:
                          state.queue.label ??
                          musicEntryForFile(ref, current).album,
                      cover: cover,
                      size: stageSize,
                      onInserted: ref
                          .read(albumAnimationControllerProvider.notifier)
                          .insertionShown,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  Text(
                    // Never the file name (FR-CT-13): the metadata title,
                    // the same one the bar and the browsing area already
                    // agree a track is called — this screen does not get to
                    // disagree just because it names the track in its own
                    // body text.
                    current == null
                        ? l10n.playbackNothingPlaying
                        : musicTitleForFile(ref, current, l10n),
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  if (current != null && queueLabel != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      queueLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: l10n.audioPrevious,
                        iconSize: 48,
                        icon: const Icon(Icons.skip_previous),
                        onPressed: state.queue.hasPrevious
                            ? () => unawaited(controller.previous())
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      IconButton(
                        tooltip: state.isPlaying
                            ? l10n.audioPause
                            : l10n.audioPlay,
                        iconSize: 72,
                        icon: Icon(
                          state.isPlaying
                              ? Icons.pause_circle
                              : Icons.play_circle,
                        ),
                        onPressed: () => unawaited(controller.togglePlaying()),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      IconButton(
                        tooltip: l10n.audioNext,
                        iconSize: 48,
                        icon: const Icon(Icons.skip_next),
                        onPressed: state.queue.hasNext
                            ? () => unawaited(controller.next())
                            : null,
                      ),
                    ],
                  ),

                  // Below the transport, deliberately. Whatever the core
                  // cached about this track is worth reading while it plays,
                  // but it is not what this screen is for — the controls do
                  // not move down the page to make room for a photograph,
                  // and the panel renders nothing at all when there is
                  // nothing to show, which is most of a real library.
                  if (current != null)
                    TrackEnrichmentPanel(
                      fileUuid: current.uuid,
                      // The album artist, which is whose record this is and
                      // therefore whose photograph belongs against it —
                      // not the track's performer, which would put a guest's
                      // face on the host's album. The raw tag, never the
                      // localised "Unknown artist": that word is not
                      // anybody's name, and looking it up would ask the core
                      // for a photograph of a phrase.
                      artistName: musicEntryForFile(ref, current).albumArtist,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
