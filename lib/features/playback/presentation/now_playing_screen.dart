import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../enrichment/presentation/enrich_track_button.dart';
import '../../enrichment/presentation/lyrics_button.dart';
import '../../playlists/presentation/add_to_playlist_button.dart';
import '../../shell/presentation/playback_bar.dart';
import '../application/audio_playback_controller.dart';
import '../domain/album_cover.dart';
import 'album_stage.dart';
import 'media/device_artwork.dart';
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

  /// How wide the words are, when they are open.
  ///
  /// A column of a fixed comfortable measure, capped at a share of the
  /// window so a narrow one does not end up with two thin strips instead of
  /// a device and a page of lyrics. Lines of a song are short; past forty
  /// characters or so the extra width is margin, and it is width the device
  /// beside them can use.
  static const double _lyricsWidth = 420;

  /// The most of the window the words may take.
  static const double _lyricsShare = 0.42;

  /// Below this, the stage reads as a smudge, not a record: the animation
  /// stops being worth the room it would still have to fight the title and
  /// the transport for, so it is hidden rather than drawn this small.
  static const double _minimumStageSize = 160;

  /// The room left around the stage, top and bottom.
  ///
  /// The stage is the only thing on this screen now: the title, the album
  /// and the transport row moved onto the device itself, and what is left
  /// below it is nothing at all. So what used to be a 260-pixel allowance
  /// for that text is the page's own padding and no more — an allowance for
  /// what is no longer there was drawing the device at two thirds of the
  /// height it could have had.
  ///
  /// The text and the transport come back when there is no stage, and they
  /// have the whole window to themselves when they do.

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
  /// Whether the words to the track are open beside the device.
  ///
  /// Held here rather than in a provider: it is a state of *this screen*,
  /// closed again the moment the owner leaves it, and the only two things
  /// that read it — the button in the bar and the layout below — are both
  /// built from this widget.
  bool _showsLyrics = false;

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

  /// Does what a press on one of the device's own buttons asks.
  ///
  /// Straight onto [AudioPlaybackController], with no queue rules of its
  /// own: `next` and `previous` already decline at the ends of a queue, and
  /// a second opinion here about when a skip is allowed is exactly how the
  /// device and the bar would come to disagree.
  void _operate(AudioPlaybackController controller, DeviceControl control) {
    unawaited(switch (control) {
      DeviceControl.previous => controller.previous(),
      DeviceControl.playPause => controller.togglePlaying(),
      DeviceControl.stop => controller.stop(),
      DeviceControl.next => controller.next(),
    });
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

    // The machines themselves, read off the bundle once and held for the
    // life of the process. `null` for the frame or two before the decode
    // finishes, which the stage draws nothing at all for.
    final devices = ref.watch(deviceImagesProvider).value;

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
            // Task 5 entry point 2: the words of the track playing, fetched
            // on the press when nothing has been cached for it yet. Before
            // this button, lyrics could only appear beneath the player for a
            // track that had already been looked up — which no track has
            // been until somebody looks it up.
            LyricsButton(
              isOpen: _showsLyrics,
              onPressed: () => setState(() => _showsLyrics = !_showsLyrics),
            ),
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
          // The words take a column down one side, and the device moves over
          // to make the room rather than being covered by them.
          //
          // A sheet over the player was the first way this was built, and it
          // was the wrong shape for what lyrics are: timed lines are read
          // *while* the record turns, and a modal put the turning record
          // behind them. Nothing is stacked here — the two live side by
          // side, and the stage below is laid out in what is left.
          final showsLyrics = _showsLyrics && current != null;
          final lyricsWidth = showsLyrics
              ? math.min(
                  NowPlayingScreen._lyricsWidth,
                  viewport.maxWidth * NowPlayingScreen._lyricsShare,
                )
              : 0.0;

          final stageRoom = viewport.maxWidth - lyricsWidth - AppSpacing.lg * 2;
          final stageSize = math.min(
            stageRoom,
            viewport.maxHeight - AppSpacing.lg * 2,
          );
          final showsStage =
              showsAnimation && stageSize >= NowPlayingScreen._minimumStageSize;

          final device = SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewport.maxHeight - AppSpacing.lg * 2,
                // Wide as the window, and that is what centres the stage.
                //
                // A vertical `SingleChildScrollView` hands its child a
                // *loose* width and pins it to the left, so the column
                // shrank to the width of the widest thing in it — the stage
                // — and sat against the edge with the rest of the window
                // empty beside it. `mainAxisAlignment: center` was centring
                // it top to bottom all along, which is why only half of the
                // problem was visible.
                //
                // The room the device was left, not the width of the window:
                // with the words open the two differ, and centring the stage
                // in the window would put it half under them.
                minWidth: stageRoom,
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
                      // What the CD player's readout shows: which track of
                      // the queue is playing, and where it has got to. It
                      // read `01  03:47` on every album ever played until
                      // now — a fixed string, typeset into the painter,
                      // that said the same thing about a two-minute single
                      // and a twenty-minute side.
                      display: cdDisplayFor(state),
                      // The machine this medium plays on.
                      device: devices?[animation.medium!],
                      // What is playing, on the device itself — the track's
                      // own title, where the case beside it carries the
                      // record's. The page names it again below, in text
                      // that can be read at any size and selected; the plate
                      // is what makes the device know what is on it.
                      trackTitle: musicTitleForFile(ref, current, l10n),
                      size: stageSize,
                      // The device's own buttons, wired to the same
                      // controller the row below reaches (main flow step 6).
                      onControl: (control) => _operate(controller, control),
                      onInserted: ref
                          .read(albumAnimationControllerProvider.notifier)
                          .insertionShown,
                    ),
                  ],

                  // Named on the device, not under it.
                  //
                  // The nameplate on the machine says what is playing and
                  // the sleeve on the medium shows which record it is from,
                  // so a title and an album repeated in body text below were
                  // the same two facts a second time. What is left when the
                  // stage is hidden is the whole of what this screen can
                  // say, which is why the text below is kept for exactly
                  // that case.
                  if (!showsStage) ...[
                    Text(
                      // Never the file name (FR-CT-13): the metadata title,
                      // the same one the bar and the browsing area already
                      // agree a track is called.
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
                  ],

                  // Only when there is no device to press.
                  //
                  // The transport belongs on the machine: an owner looking
                  // at a tape deck reaches for the deck's own buttons, and a
                  // second row of the same three underneath it was the same
                  // controls twice. But this screen fills the window — the
                  // playback bar is behind it, not under it — so a stage
                  // that is hidden (the animation switched off, FR-PL-11, or
                  // a window too short to draw one in) would leave the
                  // player with no way to pause at all. This row is that
                  // floor, and nothing more.
                  if (!showsStage)
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
                          onPressed: () =>
                              unawaited(controller.togglePlaying()),
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
                ],
              ),
            ),
          );

          if (!showsLyrics) return device;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: device),
              SizedBox(
                width: lyricsWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: LyricsPanel(
                        fileUuid: current.uuid,
                        artistName: musicEntryForFile(ref, current).albumArtist,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// What the CD player's readout says: the track's place in the queue and
/// where playback has got to (FR-PL-09).
///
/// A top-level function rather than a method on the screen so the test that
/// cares about the *text* does not have to build a player to read it, and so
/// the same rule is available to any other device that grows a readout.
///
/// Written with [formatPlaybackPosition], the bar's own formatter, for the
/// reason every shared formatter exists: the elapsed time on the device and
/// the elapsed time in the bar are the same fact, and a readout that wrote
/// it its own way could show two different answers on one screen.
String cdDisplayFor(AudioPlaybackState state) {
  if (state.current == null) return '';

  // Two digits, as a disc player's track counter has always been — and the
  // queue's index, not the track's own tag: what a player counts is the
  // track it is playing, which is where in *this* queue it has got to.
  final track = (state.queue.index + 1).toString().padLeft(2, '0');

  return '$track  ${formatPlaybackPosition(state.status.position)}';
}
