import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/synced_lyrics.dart';

/// Lyrics that follow the music (music enrichment design).
///
/// The line being sung is emphasised and kept in view; the rest are dimmed
/// but readable, because the point of lyrics on screen is as much to read
/// ahead as to follow along.
class SyncedLyricsView extends ConsumerStatefulWidget {
  /// Creates the view for [lyrics].
  const SyncedLyricsView({required this.lyrics, super.key});

  /// The timed lines.
  final SyncedLyrics lyrics;

  @override
  ConsumerState<SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends ConsumerState<SyncedLyricsView> {
  /// How long the view leaves the owner alone after they scroll it.
  ///
  /// Reading ahead is the obvious thing to do with lyrics on screen, and a
  /// view that dragged them back to the current line mid-sentence would make
  /// that impossible. Long enough to read a verse; short enough that they do
  /// not have to remember to hand control back.
  static const Duration _afterAScroll = Duration(seconds: 6);

  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _lineKeys = {};

  int? _shownFor;
  DateTime? _scrolledAt;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Whether the view may move itself right now.
  bool get _mayFollow {
    final scrolledAt = _scrolledAt;

    return scrolledAt == null ||
        DateTime.now().difference(scrolledAt) > _afterAScroll;
  }

  /// Brings [index] into view, if this is a line change and the owner is not
  /// reading elsewhere.
  void _follow(int? index) {
    if (index == null || index == _shownFor) return;
    _shownFor = index;
    if (!_mayFollow) return;

    // After the frame: the line may not be laid out yet on the build that
    // first makes it current, and there is nothing to scroll to until it is.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _lineKeys[index]?.currentContext;
      if (context == null || !mounted) return;

      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        // Kept off the very top: a line pinned to the edge gives no sight of
        // what is coming, which is half of what reading lyrics is for.
        alignment: 0.35,
      );
    });
  }

  /// One line, emphasised when it is the one being sung.
  Widget _line({
    required ThemeData theme,
    required SyncedLyricLine line,
    required bool isActive,
    required Key key,
  }) {
    // A timed gap has no words. It still occupies its moment — that is what
    // stops the previous line staying lit through a solo — but there is
    // nothing to draw for it.
    if (line.text.isEmpty) {
      return SizedBox(key: key, height: AppSpacing.md);
    }

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style:
            (isActive
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.bodyMedium) ??
                const TextStyle(),
        child: Text(
          line.text,
          textAlign: TextAlign.center,
          // Dimmed rather than hidden: the lines around the current one are
          // what let the owner read ahead and catch up.
          style: isActive
              ? null
              : TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The engine's own position, which is what the player bar and the video
    // player already read — so the highlight cannot disagree with the
    // elapsed time shown beside it.
    final position = ref.watch(
      audioPlaybackControllerProvider.select((state) => state.status.position),
    );
    final active = widget.lyrics.activeIndexAt(position);
    _follow(active);

    return NotificationListener<UserScrollNotification>(
      // A scroll the owner performed, not one this view performed: only
      // `UserScrollNotification` carries that distinction, and reacting to
      // every ScrollNotification would make the view stop following itself
      // the instant it started.
      onNotification: (notification) {
        _scrolledAt = DateTime.now();
        return false;
      },
      // A column in a scroll view, not a `ListView`.
      //
      // Both `ListView.builder` and `ListView(children:)` create elements
      // only for what is on screen, so a line scrolled out of view has no
      // context — and `ensureVisible` on a context that does not exist
      // silently does nothing. That made the auto-scroll work only for lines
      // already visible, which is exactly the case needing no scroll. A song
      // is tens of lines, so building all of them costs nothing and is what
      // makes following back to an off-screen line possible at all.
      child: SingleChildScrollView(
        controller: _scroll,
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          for (final (index, line) in widget.lyrics.lines.indexed)
            _line(
              theme: theme,
              line: line,
              isActive: index == active,
              key: _lineKeys.putIfAbsent(index, GlobalKey.new),
            ),
          ],
        ),
      ),
    );
  }
}
