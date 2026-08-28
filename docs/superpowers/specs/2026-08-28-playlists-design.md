# Playlists

**Date:** 2026-08-28
**Status:** approved

## Problem

The music area can play an album, an artist, or a single track. It cannot
play a set the owner assembled themselves, and there is nowhere to keep one.

The catalog already holds owner-curated collections — watchlists for video
(UC-29) and reading lists for books and comics (UC-31) — so audio is the
medium that has none.

## What a playlist is here

An ordered list of audio files, named by the owner, held in the core.

Ordered, because the running order is the thing being curated; a set would be
a tag. Audio only, because video has watchlists and books have reading lists,
and one collection type per medium keeps "which of these do I use" from being
a question. Duplicates are allowed, because a track can legitimately open and
close a set.

## Design

### 1. The core owns it, as it owns the other two

A `playlists` module beside `reading_lists`, with the same shape: commands
for create, rename, delete, add, remove and reorder, and a query for reading
one back. Both transports carry all of them at parity (FR-FC-24).

Not the application's to hold, for the reason BR-02 gives: what the catalog
contains is domain work, and a playlist is a fact about the catalog rather
than a preference about how it is displayed. It is also the difference
between a playlist that survives a reinstall and one that does not.

### 2. Two tables, and one constraint deliberately not copied

```
playlists        (id, uuid, name)
playlist_entries (id, playlist_id, file_id, position)
```

`reading_progress` carries `UNIQUE (reading_list_id, item_file_id)`, which is
what makes UC-31 AF-03 — "the item is already in that reading list" — a
refusal. **`playlist_entries` must not have it.** A playlist that refuses a
track it already holds cannot express a set that opens and closes with the
same song, and the refusal would arrive as a puzzle rather than a rule.

The consequence is that an entry's identity is its own row, not its file: to
remove *that* track is to remove that entry, and a playlist holding a track
three times has three entries that are removed independently.

`reading_progress` also has no foreign key, and its own comment says why —
SQLite cannot add one through `ALTER TABLE`, so nothing cascades and purging
a file has to delete the rows explicitly. `playlist_entries` inherits both the
absence and the obligation. A purge that forgets it leaves a playlist holding
an id that resolves to nothing, which is a worse failure than the missing
file it came from, because nothing on screen can explain it.

### 3. Positions are contiguous and mean what they show

`position` runs 0..n-1 within a playlist, renumbered across the affected span
on every move. A drag rewrites more rows than it strictly must; at the size a
personal playlist reaches, that is free, and what it buys is that the stored
position is always the position displayed.

The alternatives optimise the wrong thing. Sparse or fractional positions
rewrite one row per move but need renormalising when the gaps run out, and
their values stop matching what the owner sees. A linked list turns "read
this playlist in order" into a recursive query and lets one broken link
corrupt the whole list.

### 4. Reading a playlist is one batched query, not one per track

The entries join to their files and audio metadata through the batched
pattern `browse.rs` already uses — one query per subtype table, ids chunked
at `MAX_SQLITE_PARAMS`. A 500-track playlist costs a constant number of
queries. The listing carries the same `FileView` shape every other listing
does, so the application parses it with what it already has.

### 5. A missing file stays in the list and is passed over

An entry whose file the catalog has marked missing renders greyed and is
skipped during playback rather than removed or played into an error.

Removing it automatically would delete curation work silently, and an
unplugged drive would empty a playlist that is not actually broken. Playing
it into an error would stop the list dead partway through. Showing it and
stepping over it is the only option that keeps both the list and the
listening intact, and it matches how the catalog already reports missing
files rather than hiding them.

### 6. Playback reuses the queue that exists

Playing a playlist replaces the queue and plays in order — the same thing
pressing play on an album does, so there is no second notion of "what is
playing" to keep consistent.

The queue is a new `QueueKind.playlist`. It deliberately names **no record**
of its own, which means `recordOf` resolves the identity from the current
track exactly as it does for a lone track today — so crossing from one album
to the next inside a playlist inserts the new medium, and skipping within an
album does not. The behaviour the owner asked for falls out of the rule that
is already there rather than being a second rule beside it.

The player and the bar show the current track's cover, as they already do. A
playlist has no cover of its own, because every candidate for one is either
arbitrary (the first track's) or a new thing to build and keep correct (a
mosaic), and neither is more meaningful than the record actually playing.

### 7. Rename, which reading lists do not have

One `UPDATE`. Without it the only way out of a typo is to delete the list and
build it again, which loses the ordering work — a dead end far more expensive
than the mistake. That reading lists lack it is a gap there, not a precedent
worth matching.

## Components

| Component | Change |
| --- | --- |
| `alexandria-core/src/playlists/` (new) | Commands and queries, mirroring `reading_lists`. |
| `alexandria-core/migrations/` (new) | The two tables. |
| `catalog/commands/purge*.rs` | Delete a purged file's entries, as they already delete reading and watch progress. |
| `alexandria-ffi`, `alexandria-http` | Both surfaces, at parity. |
| `features/playlists/` (new, UI) | Domain, gateway, controllers, list and detail screens. |
| `playback/domain/playback_queue.dart` | `QueueKind.playlist`, naming no record. |
| Music lists, album and artist views, now playing | An "Add to playlist" action. |
| l10n | The new strings, in both locales. |

## Requirements impact

- A new use case for managing playlists — create, rename, delete, add,
  remove, reorder.
- A new use case for playing one.
- New functional requirements under the tracking group, beside
  FR-TR-08..FR-TR-11, for what the core holds and what it refuses.
- **FR-CT-13** applies unchanged: a playlist row names its track by metadata,
  never by file name.

## Testing

- A playlist holds the same track twice, and removing one entry leaves the
  other.
- Reorder puts the track where it was dropped, and the positions after it
  stay contiguous.
- Reading a playlist returns its tracks in position order.
- Reading a 500-entry playlist costs the same number of queries as a 5-entry
  one — pinned by a query counter, as `browse_batching.rs` pins the listing.
- Purging a file removes its playlist entries; no playlist is left holding an
  id that resolves to nothing.
- A missing file's entry is shown, is skipped on play, and the list continues.
- Playing a playlist replaces the queue and starts at position 0.
- Crossing an album boundary inside a playlist inserts the new medium;
  crossing tracks within one album does not.
- A blank name is refused before the core is called (as UC-31 AF-01).
- Both transports answer the same playlist identically (FR-FC-24).

## Risks

Reordering is the one interaction here that is hard to get right and easy to
get subtly wrong: a drag that lands between two rows, a drag onto the row it
started on, a drag while something else is renumbering. The core's contract
is the defence — a move is "put entry X at index N", computed and renumbered
in one transaction, rather than the application sending a list of positions
it believes are correct. A UI that sends its own arithmetic would be a second
implementation of the ordering rule, and the two would drift.

Statistics — most played songs, artists, albums and genres — were asked for
alongside this and are deliberately not in it. Nothing in the core records
that a play happened, so they need a collection mechanism before they can
show anything, and that is a separate design.
