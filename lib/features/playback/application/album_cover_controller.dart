import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../catalog/domain/catalog_gateway.dart';
import '../domain/album_cover.dart';
import '../domain/playback_queue.dart';
import 'album_animation_controller.dart' show AlbumIdentity;

/// Fetches and holds the current album's cover (design section 4, UC-21,
/// FR-PL-07).
///
/// Identifies "the same record" the same way `AlbumAnimationController`
/// does — [AlbumIdentity], the queue's kind paired with its label or its
/// first track's uuid — because the two controllers have to agree on when a
/// track change is still the same album and when it is a new one; if they
/// disagreed, a cover could swap under a case that never re-inserted, or an
/// insertion could play under a cover left over from the record before it.
///
/// The cover is fetched once per album, for the file the queue was showing
/// when that album became current, and held — never refetched — for as
/// long as the same album keeps playing (design section 4). A cover that
/// arrives after the insertion has already begun does not restart it: this
/// controller only ever swaps [state] from the designed jacket to the
/// fetched image, one `Notifier` state change like any other, and nothing
/// downstream treats that swap as a reason to replay an animation.
///
/// Kept alive with [Ref.keepAlive] (called on every [build]): the only
/// consumer today is `NowPlayingScreen`, which is closed far more often than
/// the album it opened over stops playing — the persistent bar keeps audio
/// running with the full player unmounted. Without [Ref.keepAlive], Riverpod
/// would treat a provider with no active listener as eligible to pause and
/// dispose, throwing away a cover already held for an album still playing.
///
/// Deliberately *not* using [Ref.onDispose] to release the held image: a
/// `Notifier`'s `ref` is replaced on every rebuild (Riverpod 3), and its old
/// ref's [Ref.onDispose] hooks fire on that replacement too, not only at
/// final teardown — `AudioPlaybackController`'s own `ref.onDispose` embraces
/// this by cancelling a stream subscription, which is harmless to repeat on
/// every rebuild. Disposing the *current cover* on every rebuild is not
/// harmless: a track change within the same album rebuilds this controller
/// (`audioPlaybackControllerProvider` changed) without the album itself
/// changing, and the whole point is that rebuild leaves the held cover
/// alone. The image is released only where this class can tell that is
/// actually correct — a genuine album change ([build]), a fetch that lost
/// the race to one ([_fetch]) — and at the one point neither of those
/// reaches: the session ending, via [forgetSession], called by
/// `PlaybackSessionActivity.end` exactly as `AlbumAnimationController`'s own
/// session reset is.
class AlbumCoverController extends Notifier<AlbumCover> {
  AlbumIdentity? _identity;

  /// Counts every album the queue has shown, including the empty one.
  ///
  /// A fetch captures the count current when it starts. If the count has
  /// moved on by the time the fetch — or the decode after it — finishes, a
  /// different album is what is playing now, and the answer belongs to
  /// nobody: it is discarded, and its image (if it got that far) is disposed
  /// rather than left to leak.
  int _generation = 0;

  /// What [state] currently holds, tracked independently of the `Notifier`'s
  /// own [state] getter so the disposal decisions in [build] — which run
  /// before this controller's first state is ever assigned — have something
  /// safe to read.
  AlbumCover _current = const AlbumCoverDesigned();

  @override
  AlbumCover build() {
    ref.keepAlive();

    final queue = ref.watch(audioPlaybackControllerProvider).queue;
    final identity = queue.isEmpty ? null : _identityOf(queue);

    // Rebuilt for a reason that is not a new album — a track change within
    // the same record, or anything else `audioPlaybackControllerProvider`
    // changed about — leaves whatever this controller already holds alone.
    // This is the rule that matters most: a cover fetch in flight keeps
    // flying, and a cover already shown keeps being shown.
    if (identity == _identity) return _current;

    _identity = identity;
    final generation = ++_generation;
    _disposeCurrent();

    if (identity != null) {
      final uuid = queue.current?.uuid ?? queue.tracks.first.uuid;
      unawaited(_fetch(uuid: uuid, generation: generation));
    }

    return _current;
  }

  /// Reads the file [uuid]'s embedded picture and, if [generation] is still
  /// current when each step finishes, shows it.
  ///
  /// Every early return here leaves the designed jacket standing — a file
  /// with no embedded picture, the call failing, undecodable bytes, and a
  /// generation that has moved on are all the same outcome to this method:
  /// nothing worth telling the owner about (design section 4). [Ref.mounted]
  /// is checked after every `await`: [Ref.keepAlive] keeps this provider
  /// alive through an ordinary loss of listeners, but the session ending
  /// (via [forgetSession]'s own `state =`, or the container going away for
  /// real) can still invalidate it mid-fetch, and a `ref.read`/`state=`
  /// after that throws rather than quietly doing nothing.
  Future<void> _fetch({required String uuid, required int generation}) async {
    if (!ref.mounted) return;
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return;

    final outcome = await ref
        .read(catalogGatewayProvider)
        .fileThumbnail(uuid: uuid, credential: credential);
    if (!ref.mounted || outcome is! FileThumbnailRead) return;

    final image = await _decode(outcome.bytes);
    if (image == null) return;
    if (!ref.mounted) {
      image.dispose();
      return;
    }

    if (generation != _generation) {
      // A different album has taken over since this fetch started. Its own
      // fetch (or the designed jacket, if it has none) is what is shown now;
      // this image was never assigned to [_current] and has no other owner,
      // so disposing it here is the only chance it gets.
      image.dispose();
      return;
    }

    _disposeCurrent();
    _current = AlbumCoverFetched(image: image);
    state = _current;
  }

  /// Decodes [bytes] into a paintable image, or `null` for bytes the
  /// platform's codecs cannot make sense of — which is exactly as ordinary
  /// as the core answering no picture at all.
  Future<ui.Image?> _decode(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } on Object {
      return null;
    }
  }

  /// Releases [_current]'s image, if it has one, and leaves [_current]
  /// holding the designed jacket either way.
  ///
  /// Idempotent on purpose: a stale fetch's own discard, a fresh album's
  /// [build], and [forgetSession] can all reach an already-designed
  /// [_current] — resetting it here (not only disposing) is what keeps a
  /// second call from ever disposing the same [ui.Image] twice, which
  /// throws.
  void _disposeCurrent() {
    final current = _current;
    if (current is AlbumCoverFetched) current.image.dispose();
    _current = const AlbumCoverDesigned();
  }

  /// Forgets which album's cover is held, and releases it (Finding 4's
  /// counterpart for the cover, called by `PlaybackSessionActivity.end`).
  ///
  /// A later session's first play of the very same album fetches its cover
  /// again rather than finding this controller still holding — and still
  /// showing — the previous session's image, the same way
  /// `AlbumAnimationController.forgetSession` makes that play owe an
  /// insertion again rather than finding `_shownFor` still remembering it.
  void forgetSession() {
    _identity = null;
    _generation++;
    _disposeCurrent();
    state = _current;
  }

  /// What identifies "which record is playing" — kept in step with
  /// `AlbumAnimationController._identityOf`, which this deliberately mirrors
  /// rather than shares: the two controllers are independent `Notifier`s
  /// with no common ancestor to hold one copy on, and the identity rule
  /// itself is small enough that duplicating it here is less risk than
  /// threading a dependency between two otherwise-unrelated controllers.
  AlbumIdentity _identityOf(PlaybackQueue queue) =>
      (queue.kind, queue.label ?? queue.tracks.first.uuid);
}
