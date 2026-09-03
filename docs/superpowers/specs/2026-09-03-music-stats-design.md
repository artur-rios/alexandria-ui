# Music statistics

**Date:** 2026-09-03
**Status:** implemented

## Problem

The owner asked what they actually listen to. The playlists design turned the
question down and said why:

> Statistics — most played songs, artists, albums and genres — were asked for
> alongside this and are deliberately not in it. Nothing in the core records
> that a play happened, so they need a collection mechanism before they can
> show anything, and that is a separate design.

The core now has that mechanism (core, `2026-09-03-play-history-design.md`):
a `play_events` table, a write that records one play, and a read that answers
the four rankings. This design is the half that lives here — deciding when a
play has happened, telling the core, and showing what came back.

## Design

### 1. The player decides what "played" means

The core stamps and stores; it cannot see what the owner is hearing. So the
rule is here, in `countsAsPlayed`, and it is one function rather than a
condition spread through the player:

**half the track, or four minutes, whichever comes first.**

The convention scrobblers have used for twenty years, and it is the right
shape in both directions. A two-minute song abandoned after forty seconds was
not listened to. An hour-long live set does not stop counting because the
owner left before the encore. A track heard to its end counts however short
it is, which is the same rule reached from the other side.

A length the engine has not reported yet counts nothing: with nothing to take
half of, every rule reduces to guessing, and the next status carries the real
value a moment later.

### 2. Counted once per playthrough, and again for the next one

The status stream reports several times a second, and every report after the
first is also past the threshold. So the player carries one flag, cleared
when a track opens — not when it changes.

That distinction is the feature. Putting the same record on again is a second
playthrough and a second play, which is the listening the rankings exist to
count. Keying the flag to "the current track changed" would have silently
made a song on repeat worth one play a session.

### 3. Recording never interrupts anything

`PlayRecorder` swallows what it cannot write, and logs it. Nothing the owner
is doing depends on the row: stopping the music to report that a statistic
went unrecorded would be a worse failure than the missing statistic. The one
exception is a rejected session, which returns the owner to login as
everywhere else — the session is over regardless of what was being recorded
when it ended.

The call is fire-and-forget for the same reason, and the flag is set before
it rather than after, so the statuses arriving while the write is in flight
cannot each start one of their own.

### 4. One read, one screen

The core answers the summary and four rankings together, and the screen asks
once. Four reads could each see a different instant and put a total on screen
that disagrees with the lists under it.

The screen does not follow the music while it is open. A chart that reordered
itself under the reader would be harder to read than one a minute old, and
"Read again" is one button away.

Every ranking is drawn even when it is empty, because a heading with nothing
under it says the ranking exists and has nothing in it, where dropping it
says the application forgot about artists.

### 5. What an untagged library sees

A track nothing tagged is counted in the totals and listed among the tracks
under its filename. It appears in no other ranking — the core will not invent
an artist, and an "unknown artist" at the top of the owner's chart is a bug
wearing a fact's clothes.

That leaves a real reading problem: seven plays in the summary, three artists
under it, and nothing saying why. The note at the foot of the screen is what
says why, once, where an owner who noticed goes looking.

### 6. Where it is reached from

The Library tools menu, beside the playlists and the music lookup. What was
played belongs to no single file type, so it is not a destination of its own
(FR-CT-01) — the same reason every other library-wide screen is a menu entry.

## Components

| Component | Role |
| --- | --- |
| `stats/domain/play_threshold` | When a track counts as played. The whole rule. |
| `stats/domain/music_stats` | The rankings, as the screen reads them. |
| `stats/data/core_stats_gateway` | `alexandria_play_record` and `alexandria_music_stats`. |
| `stats/application/play_recorder` | Tells the core, and never throws. |
| `stats/application/music_stats_controller` | Reads once, and again on request. |
| `stats/presentation/music_stats_screen` | The summary and the four rankings. |
| `audio_playback_controller` | Applies the threshold, once per playthrough. |

## Testing

- The threshold itself: under half, half, four minutes into a long one,
  nothing heard, and a length the engine has not reported.
- The player applying it: a track skipped early counts nothing; half a track
  counts once; the rest of it does not count again; a track heard to the end
  counts; the same track played again counts twice.
- The gateway: what the record call sends (`fileUuid` and nothing else), the
  rankings parsed, an absent window kept absent, and a malformed ranking
  failing the whole read rather than losing a row quietly.
- The screen: reached from the menu, every ranking drawn, the untagged
  track listed by filename, the empty state saying what counts, a refusal
  showing the failure view with a retry, and "Read again" asking again.

## Risks

The rankings are only as good as the tags. A library tagged inconsistently —
the same artist spelled two ways — ranks as two artists, and nothing here
can tell that from two artists who really exist. The music lookup is the
existing answer to that, and it is worth saying that the two features help
each other: the tidier the tags, the truer this screen.

Time windows are absent, deliberately, and the omission is the core's as much
as this screen's. All-time is the answer worth looking at first; "this month"
is a control, a parameter, and a second set of numbers to explain, and none
of it is worth adding before anyone has read the first one.
