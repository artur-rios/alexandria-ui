# Consuming the richer catalog

**Date:** 2026-08-26
**Status:** approved
**Depends on:** alexandria-api [#118](https://github.com/artur-rios/alexandria-api/pull/118) and [#119](https://github.com/artur-rios/alexandria-api/pull/119)

## Problem

Two features shipped on this application with a hole in the middle of each, and
both holes were the same thing: the catalog's listing answered file records and
no metadata.

**The music area pays one core call per track.** It lists the audio files, then
reads each one's details individually to learn its title and artist, because the
listing carries neither. A few thousand tracks is a few thousand sequential
calls across an FFI boundary served by a single worker isolate. The area was
built to fill in as they land — an incremental loader, a second provider
carrying "everything so far", a progress line counting up — and every line of
that machinery exists to make the wait bearable rather than to do anything an
owner asked for.

**Search cannot find a track by its name.** The results list labels an audio
match "Airbag — Radiohead" and refuses to show its file name, and yet typing
`Airbag` finds nothing while typing the ripper's `DISKNAME-01` finds it. The
interface contradicts itself in the one place an owner goes when they cannot
find something.

**And the case has no cover on it.** The now-playing animation draws an album's
sleeve facing the owner and puts a designed jacket there — the album and artist
typeset on a colour derived from the album's name — because the core had no
picture to give it.

The core now answers all three. `GET /v1/files` returns the same `FileView`
record the single-file call returns, and `alexandria_file_thumbnail` answers for
audio with the picture embedded in the file.

## Design

### 1. The listing answers what the detail answers

`CatalogListing.loaded` carries `List<FileDetails>` instead of
`List<CatalogFile>`.

`FileDetails` already models exactly the record the core now returns for each
row — the file, its metadata, and the extracted scalars — and the gateway
already parses one for the detail call. The listing reuses that parse rather
than growing a second one.

Callers that only ever wanted the file read `.file` off it. Nothing above the
gateway learns a new shape; what changes is that the ones who wanted more no
longer have to ask again.

### 2. The music library becomes one call

`MusicLibraryController` lists the audio files and builds its entries. That is
the whole of it.

Which means the machinery built to survive the N+1 goes with it:

- `musicLibraryProgressProvider` — the second provider carrying "everything so
  far" — is deleted. There is no "so far" any more.
- `MusicLibrary`'s `total` and `isComplete` go with it, and the type collapses
  to the list it always wanted to be.
- The progress line in the music area goes. It counted a wait that no longer
  happens.

This is the part of the change worth being careful about. That split existed
for a reason — a queue built from a partial library would silently lose tracks,
which is a bug this application already shipped once — and the reason is gone
rather than merely inconvenient. Deleting it is right precisely because
`musicLibraryProvider` now resolves in one call, so "the complete library" and
"everything so far" are the same thing and cannot drift apart.

The failure path stays exactly as it is: a listing that fails still surfaces the
failure view and its retry, and is still distinguishable from an empty library.

### 3. Search matches what a file is called

`matchesSearch` gains the file's metadata: for audio, its title, artist and
album; for the other types, whatever their metadata carries.

The rule stays the one FR-CT-06 states — the name and the metadata — and the
half that was "deliberately absent rather than faked" is now present. The
doc comment saying so is rewritten rather than left as a monument.

`audioMetadataProvider` is deleted. It existed to fetch one file's metadata for
a search result; the result now arrives carrying it.

### 4. The case carries the real cover

`AlbumStage` asks the core for the current album's thumbnail and hands the
decoded image to `CasePainter`, which draws it on the sleeve.

The designed jacket stays, and stays reachable: a file with no embedded picture
answers `InvalidInput`, which is common enough that the fallback is a normal
outcome rather than an error path. So the case shows, in order:

1. the album's embedded cover, when the file carries one;
2. the designed jacket — album and artist on a derived colour — when it does not.

The cover is fetched for the file the insertion is showing, once, and held for
as long as that album is what is playing. A cover that arrives after the
insertion has begun does not restart it: the sleeve swaps and the animation
carries on, because a case that flickered mid-flight would be worse than one
that started plain.

A thumbnail that fails for any other reason is the designed jacket too. The
animation is decoration with meaning; nothing about it is worth an error
message.

## Components

| Component | Change |
| --- | --- |
| `catalog/domain/catalog_gateway.dart` | `CatalogListing.loaded` carries `List<FileDetails>`. |
| `catalog/data/core_catalog_gateway.dart` | The listing parses each row as a `FileView`, reusing the detail call's parse. |
| `catalog/domain/catalog_search.dart` | `matchesSearch` matches metadata as well as the name. |
| `catalog/presentation/catalog_search_view.dart` | Reads the row's own metadata; no per-file provider. |
| `core/di/providers.dart` | `audioMetadataProvider` and `musicLibraryProgressProvider` are deleted. |
| `playback/application/music_library_controller.dart` | One call; `MusicLibrary` collapses to a list. |
| `playback/presentation/music_library_view.dart` | Loses the progress line. |
| `playback/domain/album_cover.dart` | **New.** What a sleeve shows: a fetched cover, or the designed jacket. |
| `playback/application/album_cover_controller.dart` | **New.** Fetches and holds the current album's cover. |
| `playback/presentation/media/case_painter.dart` | Draws a cover image when there is one. |
| `catalog/domain/catalog_gateway.dart` | Gains a thumbnail call. |

Every other consumer of a listing changes only where it reads `.file`.

## Requirements impact

- **FR-CT-06** describes search matching names and type-specific metadata. The
  requirement was always right; the implementation now meets it, so the
  requirement does not change — but UC-11's note about the metadata half being
  unavailable does.
- **FR-PL-07** describes the animation. The sleeve showing the album's own cover
  is new behaviour and belongs in it.

No new use case.

## Testing

- The listing carries metadata, and every existing caller still gets its files.
- A malformed row still surfaces as an unreadable listing rather than throwing.
- The music library loads in one gateway call — asserted by counting calls on
  the fake, because "one call" is the whole point and a regression to per-file
  reads would otherwise be invisible.
- The music area shows no progress line, and its empty and failed states are
  unchanged.
- Searching a track's title finds it; searching its file name does not surface
  it under that name; a non-audio file still matches by name.
- The case shows a fetched cover when the core answers with one, and the
  designed jacket when it answers `InvalidInput`, when the call fails, and
  while the cover has not arrived yet.
- A cover arriving mid-insertion does not restart the animation.

## Risks

The deletions are the risk. `musicLibraryProgressProvider`, the incremental
loader and `audioMetadataProvider` are load-bearing today, and each is removed
because the reason for it is gone rather than because it is unused. Anything
still reading them after this change is a caller that wanted "partial" and will
now get "complete" — which is correct in every case that exists, and worth
checking rather than assuming.

The second risk is the dependency. This cannot ship before the core changes it
consumes: the listing parse would break against a core that still answers bare
`File` records. Until those merge, this branch is built and tested against fakes
and against a core built from the two feature branches.
