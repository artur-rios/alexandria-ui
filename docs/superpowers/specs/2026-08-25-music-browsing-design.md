# Browsing the music library

**Date:** 2026-08-25
**Status:** approved

## Problem

The music area is the generic catalog listing. It shows one row per audio
file, and what each row says is the file's name on disk — `04 - track.flac`,
`Unknown Artist - 03.mp3`, whatever the ripper wrote. The catalog holds the
title, the artist, the album, the year and the track number for every one of
those files, and the listing shows none of it.

That makes the one thing an owner does with a music library — find a record,
or an artist, or a song — a matter of reading file names in a flat
alphabetical list. There is no way to see which artists are in the library, no
way to see an album as an album, and no way to reach a single file's details
without opening a dialog that was designed for documents.

The grouping logic already exists: `albumOf` and `artistOf` build the queues
UC-20 plays. It is used for playing and never for browsing.

## Design

### 1. The music area

`ShellDestination.music` stops rendering `CatalogListing` and renders a new
`MusicLibraryView`. Three views, chosen by a segmented control across the top,
over one list at a time with a breadcrumb above it:

```txt
┌─ Music ─────────────────────────────────────┐
│ [ Artists | Albums | Songs ]                 │
│ Music › Radiohead › OK Computer              │
│                                              │
│  1  Airbag                                ⋮  │
│  2  Paranoid Android                      ⋮  │
│  3  Subterranean Homesick Alien           ⋮  │
└──────────────────────────────────────────────┘
```

| View    | Top level                        | Drills into            | Then                |
| ------- | -------------------------------- | ---------------------- | ------------------- |
| Artists | Every artist, alphabetically     | That artist's albums   | That album's tracks |
| Albums  | Every album, alphabetically      | That album's tracks    | —                   |
| Songs   | Every track, alphabetically      | —                      | —                   |

An album row reads *title — artist*. A track row reads *title — artist* in
Songs, where the list spans the whole library; inside an album it reads its
track number and title, because the artist is what the owner just navigated
through.

Drill-down rather than a three-column browser: the content area is already the
window less the navigation rail, the divider, and the padding, and three
columns of names inside that is unreadable at the minimum supported window
(NFR-07). One list at a time is the same bargain the listing layouts already
make.

Tracks are ordered by track number inside an album, exactly as `albumOf`
orders a queue — a record played in file-name order is not how anyone listens
to one. Every other list is ordered by its own name, case-insensitively.

### 2. Never a file name

A row's text comes from the file's tags. The file's name on disk appears in
one place in this design — the details dialog, under a label that says that is
what it is.

Where a tag is missing, the row says so:

| Missing        | Shown             |
| -------------- | ----------------- |
| Title          | "Unknown title"   |
| Artist         | "Unknown artist"  |
| Album          | "Unknown album"   |

All three are localized strings, and files with no artist or no album gather
under an "Unknown artist" or "Unknown album" group that sorts **last** in its
view. Grouped rather than scattered: those are the files that need tagging,
and putting them together is what makes tagging them a task rather than a
hunt. Sorting them last keeps them out of the way of a library that is mostly
tagged.

This rule follows the file type rather than the screen. The catalog-wide
search results (UC-11) show a row per matching file, and an audio file's row
there shows its metadata title with the same fallbacks — otherwise the file
names this design removes come back the moment anyone searches.

### 3. What a row does

A single click plays, and where the owner is decides what:

- A track inside an album plays **that album**, starting from the track
  (`playAlbum`).
- A track in Songs plays **that track alone** (`playTrack`).
- An artist or album row drills in rather than playing. Playing a whole artist
  or album is on the submenu, where it is a deliberate choice rather than
  something a mis-aimed click does.

### 4. The per-file submenu

Right-clicking a track row — or clicking the `⋮` at its end — opens a context
menu:

| Entry             | Does                                                    |
| ----------------- | ------------------------------------------------------- |
| Play              | `playTrack`                                             |
| Play album        | `playAlbum`                                             |
| Play artist       | `playArtist`                                            |
| Details…          | The file details dialog                                 |
| Edit metadata…    | The music metadata form                                 |

Both openings, not one: right-click is what a desktop owner reaches for, and
the `⋮` is what makes the same menu reachable from the keyboard and without a
right mouse button. Every action behind it exists already — this puts them one
gesture from the row instead of behind a dialog.

### 5. The details dialog gains the file's facts

`FileDetailsView` gains a section for what the file is, rather than what it
holds:

- The file name on disk.
- Its size, formatted (`4.7 MB`, not `4922880`).
- Its format, from the extension.
- When it was last modified.

Every one of these is already on the `CatalogFile` the core returns —
`name`, `sizeBytes`, `mtime` — so no gateway call and no core change is
involved. The dialog keeps its path, its state, its metadata, and its
actions.

### 6. Loading the metadata

The core's listing answers file records and carries no metadata, and it
publishes no "files by album" query. `MusicLibraryController` therefore lists
the audio files and then reads each one's details individually — one call per
file. Today that cost is paid only when an album or an artist is first played;
this design needs the same data to draw its first screen.

The library therefore loads **incrementally**:

1. The audio listing returns. The view can already show its count.
2. Metadata calls run and entries are added as they land. The views build from
   whatever has arrived, so artists appear and fill in rather than the area
   sitting blank.
3. A progress line names how far along it is, and disappears when it finishes.
4. The result is cached for the session. Every later visit to the area is
   immediate.

The first open of a large library will visibly take a while, and this design
does not pretend otherwise. The real remedy is core-side — the core's own
`FileView` already carries metadata, and only the list endpoint omits it — so
a listing that returns metadata with each file would collapse this to a single
call. That is an issue to raise against alexandria-api; it is deliberately not
a dependency of this work, and when it lands the gateway changes and the views
do not.

A file whose details fail to read joins the library with no metadata, which
puts it in the Unknown groups: a file the catalog cannot describe is still a
file the owner has, and hiding it would be worse than naming it unknown.

### 7. What the music area gives up

Two behaviours of the generic listing do not apply here, and the requirements
are amended rather than quietly broken:

- **The layout switcher (FR-CT-03).** Artists and Albums are groupings, not
  file listings, and a grid of tiles labelled with file names was never useful
  for music. The music area has one presentation per view.
- **The lifecycle filter (FR-CT-07).** The music views show active records.
  Deleted audio stays reachable exactly where every other deleted record is,
  through Library ▾ → Deleted items (UC-34).

### 8. What is not available

The core extracts `duration_seconds` for video only. An audio file's length is
not in the catalog, so no view here shows a track's duration — a column that
would be empty for every row is worse than no column. When the core extracts
it, the track row is where it goes.

## Components

| Component | Change |
| --- | --- |
| `playback/presentation/music_library_view.dart` | New. The segmented control, the breadcrumb, and which list is shown. |
| `playback/presentation/music_rows.dart` | New. The artist, album, and track rows, and the context menu. |
| `playback/domain/music_grouping.dart` | Gains the browsing groupings — artists, albums, and an album's tracks — beside the queue-building ones it already has. |
| `playback/domain/music_display_name.dart` | New. The metadata-first naming rule and its Unknown fallbacks, in one place so the views and the search results cannot disagree. |
| `playback/application/music_library_controller.dart` | Loads incrementally and publishes progress instead of one all-or-nothing future. |
| `playback/application/music_browse_controller.dart` | New. Which view is selected and how far the owner has drilled in. |
| `shell/presentation/shell_screen.dart` | Routes the music destination to the new view. |
| `catalog/presentation/file_details_view.dart` | Gains the file-facts section. |
| `catalog/presentation/catalog_search_view.dart` | An audio result shows its metadata title. |

## Requirements impact

- **FR-CT-13** (new): the system shall present audio files by artist, album, or
  title from their metadata, and shall not present an audio file by its file
  name.
- **FR-CT-14** (new): the system shall offer, per file, a context menu carrying
  the file's playback actions, its details, and its metadata editor.
- **FR-CT-03** is amended to exclude audio, whose area has its own
  presentation.
- **FR-CT-07** is amended the same way.
- **UC-46** (new): browse the music library. Main flow: open Music, pick a
  view, drill in, play. Alternative flows: an untagged file, a metadata read
  that fails, and an empty library.

## Testing

Widget and unit tests, mirroring the source tree:

- Each of the three views lists what it should, ordered as specified.
- Drilling in and back out through the breadcrumb, in Artists and in Albums.
- An album's tracks come back in track order, including when some tracks carry
  no number.
- Untagged files show the Unknown strings and their groups sort last.
- No file name renders anywhere in the music area — asserted directly, by
  putting a file whose name would be recognizable into the fixture and
  expecting it absent.
- An audio row in the search results shows its metadata title.
- The context menu opens on right-click and on the `⋮`, offers exactly its five
  entries, and each opens what it names.
- The details dialog shows the file name, a formatted size, the format, and the
  modified time.
- The incremental loader: entries visible while loading, the progress line
  present then gone, a failed details call landing the file in Unknown, and a
  failed listing showing the area's empty state.
- Clicking a track plays the album inside an album and the track alone in
  Songs.

## Risks

The first open of a large library costs one core call per audio file, run
sequentially. A library of a few thousand tracks will take long enough to
notice. The incremental view is what makes that bearable rather than broken,
and the core-side listing described in §6 is what would fix it. If the wait
proves worse than bearable in practice, the honest next step is to raise the
core issue and block on it — not to add a second cache in this repository.
