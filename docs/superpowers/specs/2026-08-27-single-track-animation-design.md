# The animation for a single track

**Date:** 2026-08-27
**Status:** approved

## Problem

Playing a track from the Songs list, or **Play** from a track's context menu,
shows no animation and opens no player. Only an album or an artist does.

That is UC-21 AF-02 working as written — *"the animation is a record being
played, and one track is not a record"* — but it predates what was actually
asked for: the animation on the first music of a session, and whenever the
album or artist changes. Nothing in that excludes a lone track, and the Songs
list is one of the three ways the music area invites an owner to start playing.

Two things underneath the rule would also be wrong if it were simply flipped.

**A single-track queue carries no album and no year.** `playTrack` builds
`PlaybackQueue(tracks: [file], kind: QueueKind.track)` and nothing else, so
`mediumFor(mode, queue.year)` sees a null year and answers a compact disc for
every track whatever its era, and the case has no album name to typeset or to
derive its jacket colour from.

**The insertion identity for a track queue is the track's uuid.** So playing
three tracks of one album in a row from the Songs list would put a disc in
three times — the exact thing "no need to replay it for a music change of the
same album" rules out.

## Design

### 1. A track is a record too

`PlaybackQueue.showsAlbumAnimation` stops excluding `QueueKind.track`. A queue
with tracks in it shows the animation; an empty one does not.

The rule it replaces was a reasonable reading of "album playback" when the
animation only existed for albums. It is not what the owner asked for, and the
Songs list makes it the common case rather than an edge one.

### 2. What the animation is *about* is the record, not the queue

The insertion is owed when the **record** changes, and a record is its album and
its artist — however the queue that plays it was built.

So the identity `AlbumAnimationController` compares becomes, in order:

1. the queue's own label and kind, when it has one — an album queue is that
   album, an artist queue is that artist, and skipping within either changes
   nothing;
2. for a track queue, the **current track's album and artist**, resolved from
   the music library the way every other surface resolves a track's metadata.

Three consecutive tracks from one album therefore insert once. A track from a
different album inserts again. A track with no album tags falls back to its
uuid, so two untagged tracks are still two records — the rule
`music_grouping.dart` already states.

### 3. The medium and the sleeve come from the track

`mediumFor` needs a year and the case needs an album and an artist. For an
album or artist queue those are on the queue. For a track queue they are on the
track, and are read from the music library — the same cached, single-call
source the playback bar and the search results already read a track's title
from.

`playTrack` is deliberately left alone. It is the one playback path that works
without the music library, which is what makes a track playable when the
library listing has failed; giving it a library read would trade that away for
something the presentation layer can resolve on its own. When the library has
not loaded or does not hold the track, the animation falls back exactly as it
does today: a compact disc with the designed jacket, which is a reasonable
picture of an unknown record rather than an error.

## Components

| Component | Change |
| --- | --- |
| `playback/domain/playback_queue.dart` | `showsAlbumAnimation` no longer excludes a track queue. |
| `playback/application/album_animation_controller.dart` | The identity, the medium and the sleeve resolve from the current track when the queue names no record. |

Nothing else. The stage, the visor, the preference, the auto-open and the
strip all read what this controller publishes and are unchanged.

## Requirements impact

- **UC-21 AF-02** currently says a single track shows no animation. It is
  removed, and the main flow says the animation belongs to whatever is playing.
- **FR-PL-07** describes the animation for "album or artist playback" and
  becomes audio playback.

## Testing

- Playing a single track shows the animation and opens the player.
- Three tracks of one album, played one after another, insert once.
- A track from a different album inserts again.
- Two untagged tracks are two records.
- A track's own year picks its medium — a 1971 track arrives on vinyl, not on
  the compact disc a null year would have given it.
- The case shows the track's album and artist.
- With the library unloaded or missing the track, the animation still shows,
  with the fallback medium and the designed jacket.
- Album and artist queues behave exactly as before.

## Risks

The identity now depends on the music library for track queues, and that
library can be empty or stale at the moment a track starts. The consequence is
bounded — a wrong-looking medium, or an insertion that replays once — and
never a failure to play, because nothing on the playback path waits for it.
