# Libraries only, and audio back, in the desktop app

**Date:** 2026-11-20
**Status:** draft
**Core:** alexandria-api 0.6.0 (`v0.6.0`, merge commit `0e4500bf08039e92a63e48f7d51d351529dad85b`)

## Why

Alexandria is a library manager: the owner adds folders as libraries, then browses them and opens, plays, or reads
what is in them. Core 0.6.0 made that the only way the catalog fills. It removed free-form indexing
(`alexandria_index_start` and its type scope), so a file is in the catalog only because it is inside a library, and
every file belongs to exactly one library. It also brought audio back as a file type.

The app still works the 0.5 way, and so it has two ways in:

- "Library sources": folders kept in the app's own settings, indexed through `alexandria_index_start`, with a dialog
  for which types to index.
- Libraries: some of those folders, marked as libraries, whose files the type panels hide.

The app also refuses any core outside `0.5.x`, so a 0.6.0 core does not start it at all. This change brings the app in
line with the core, so that the owner adds a library and everything else follows from it.

## Goals

- The Libraries screen is the only way to add a folder. Adding a library starts its indexing, and the app follows that
  run.
- A library can be scanned again on its own. A refresh still re-checks the whole catalog.
- The type panels, dashboard, search, deleted items, missing files and collection candidates list files from every
  library. Nothing is hidden for being in a library any more.
- Audio plays. A **Music** panel lists tracks by their tags. A player bar keeps playing while the owner browses, with
  play, pause, seek, and next and previous within the list the track was started from. The tags are editable the way
  video metadata is.
- The app accepts core `0.6.x` and builds against the `v0.6.0` core: a new pin, the vendored header and regenerated
  bindings.
- The docs (README, CHANGELOG, `docs/requirements`, `docs/initial`) describe the app as a library manager.

## Non-goals

- No playlists, play history or statistics. No browsing by artist or album, no lyrics, no artist pictures, no
  sound-bar animation. Music management belongs to Orpheus (the owner chose this option, "A", over bringing back the
  0.4 music browser).
- No shuffle or repeat, and the app doesn't remember where a track stopped (video keeps its resume positions).
- No carrying over of the 0.5 source folders. The core already deleted their records on upgrade ("start clean", the
  owner's decision for the core), and the app drops the stored list too. The owner adds those folders again as
  libraries.

## Anti-goals

- The app must not make up rules the core owns: which folder may be a library, whether a run may start, or what a
  type is. It shows the core's refusal instead.
- Removing a library deletes catalog records, so the confirmation must say so plainly. Wording that implies the files
  go somewhere else is a failure.

## Approaches

**Audio** (the owner picked A):

- **A. Audio as one more type.** A Music panel, a player bar and tag editing. It is small and stays out of Orpheus's
  territory.
- **B. The 0.4 music browser.** Artists, albums and songs, a queue and animations, without playlists or statistics.
  It is far larger, and it rebuilds part of a music manager.

**Library sources** (my call; there is one sensible way):

- **Delete the source-folder concept** and move what indexing still needs out of it. This is what this design does.
- Keeping the sources screen as a front for libraries was rejected. It would keep a second list of folders in
  settings that the core no longer reads, and two places to add a folder.

## Design

### 1. Core pin, bindings and version range

- `ci/pins.sh`: `CORE_REF=0e4500bf08039e92a63e48f7d51d351529dad85b` (the `v0.6.0` merge commit, which is on the
  GitHub mirror). Rewrite the comment above it for 0.6.
- Vendor `native/include/alexandria_ffi.h` from that core's generated header. Regenerate
  `lib/core/bindings/alexandria_bindings.dart` with ffigen.
- `CoreVersionRange`: `minimum = '0.6.0'`, `exclusiveMaximum = '0.7.0'`. Its doc comment says why: 0.6 removed
  free-form indexing and changed what removing a library does, so a 0.5 core is refused by name and version.
- `core_status_mapper.dart` `_mapIndex` handles the new codes:
  - `INDEX_ERR_NOT_FOUND` (6) maps to `Failure.notFound` (or the nearest existing variant).
  - `INDEX_ERR_CONFLICT` (7) maps to `Failure.conflict`, keeping the core's message, which names the unfinished run.
  - `INDEX_ERR_BUSY` (5) maps to its existing meaning, if it has one; it is unmapped today.
- `CoreClient`:
  - Remove `indexStart`.
  - Add `libraryIndexStart(uuid, token, priority)`, a `CoreRunStart` like the refresh call.
  - `libraryRegister` takes an optional priority, sends `priority` only when it is low, and returns the JSON body so
    the caller can read `runId`.
  - Add `fileThumbnail(uuid, token)` over `alexandria_file_thumbnail` (the player's cover). The core extracts audio
    covers, even though the header's comment lists only video, image and comic.
  - Change the isolate cases to match.

### 2. Indexing without sources

Rename `lib/features/library_sources` to `lib/features/indexing` and keep only what is not about source folders:

- the run model, priority and estimate;
- `IndexGateway` without `startIndex`;
- active runs, run failures and the startup re-check;
- the folder picker.

These go:

- `LibrarySource` and its store;
- the folder registration verdicts;
- the disk folder probe;
- `LibrarySourcesController` and its state;
- `IndexScopeDialog`;
- `LibrarySourcesScreen`;
- the audio scope cleanup and its session activity.

The l10n keys used only by these go too.

- `IndexRun` gains `libraryUuid` (nullable: a refresh has none), read from the run JSON.
- `IndexGateway` gains `startLibraryIndex({uuid, priority, credential})` over `libraryIndexStart`.
- `IndexRunsController` keys the runs it follows by **library uuid** instead of root path. The refresh run stays its
  own slot.
  - `startLibraryIndex(uuid)` starts a run and follows it.
  - `follow(uuid, runId)` follows a run started by adding a library.
  - `startRefresh` is unchanged.
  - Pause, cancel and resume by uuid stay.
  - `resumeRecordedRuns`, which read `LibrarySource.lastRunId`, goes. Paused runs from an earlier session are found
    through the active-runs listing, as the strip already does.
- A start refused as a conflict (the library has an unfinished run) shows the core's sentence beside the library. It
  does not start a second run, and the owner can pause, resume or cancel the run from the strip.
- The background activity strip names a run by its library's name (looked up by `libraryUuid` in the libraries list).
  It falls back to the root folder's name, and a refresh still reads "catalog". Its "View all" opens the Libraries
  destination instead of the sources screen.
- The run failures screen opens from the strip's finished-run report and from the library's row. Its only opener
  today is the sources screen.

### 3. The Libraries screen

The Libraries destination becomes the place where everything about libraries happens.

```txt
┌─ Libraries ─────────────────────────── [ Refresh all ] [ + Add library ] ┐
│  Movies      /media/movies          Indexing… 1,204 of ~3,000   [⏸] [✕] │
│  Books       /media/books           Indexed 14:02 · 3 failed (view)  ⋮  │
│  Music       /media/music                                            ⋮  │
└──────────────────────────────────────────────────────────────────────────┘
                     ⋮ = Open · Scan again · Moved… · Remove
```

- **Add library:**
  1. Pick a folder.
  2. Give it a name (`askForLibraryName`, which defaults to the folder's name).
  3. `register` returns the library and its `runId`.
  4. The controller follows that run.

  The core's refusal shows in the same way as today's register refusals:
  - invalid input: not a folder, missing, or outside the core's root;
  - conflict: it overlaps another library.

  Adding uses normal priority. The run can be throttled from the strip, as now. (My call: a priority question on
  every add is friction for a choice that can be changed afterwards.)
- **Scan again** calls `startLibraryIndex`. It replaces today's `_scan`, which registered a source first.
- **Refresh all** moves here from the sources screen and is unchanged. The startup re-check is unchanged too.
- **Moved…** works as now. A conflict (an unfinished run, or the folder overlapping another library) shows the core's
  sentence. `followLibraryMove` goes, because there is no source to follow.
- **Remove:**
  - The confirmation says that removing the library deletes it from the catalog with its files, reading and watching
    positions, and collection membership, and that nothing on disk is touched. This replaces "its files go back to
    the type panels".
  - When the library has a paused run (known from the active-runs listing), the confirmation adds that its paused
    scan is discarded too. The core deletes a paused run with its library and refuses only a running one. (My call:
    the anti-goal asks for plain wording about what goes.)
  - A refusal while a run is running shows the core's sentence.
  - After removal:
    - the libraries list, type counts, listings and collections are invalidated;
    - the controller stops following the library's run;
    - active runs are reloaded, so the strip doesn't show a deleted run.
    - If the removed library's track is in the player queue, that track is dropped from the queue. If it is
      playing, playback stops.
- **Row status:**
  - A row shows the run this session is following, or a running or paused run from the active-runs listing.
  - Otherwise, it shows the outcome of the last run this session followed.
  - A library with no run seen this session shows no status. (My call: the core does not list finished runs per
    library, and a status kept in settings would bring back the store this design removes.)
- `librariesExplanation` and `librariesNone` are rewritten: a library is a folder Alexandria indexes and keeps the
  structure of, and adding one is how anything gets into the catalog.
- The Library menu's "Library sources…" entry becomes "Libraries" (it opens the destination) and "Add library…".
- The empty-state "Add a folder" buttons (dashboard, listing, search) open the Libraries destination and start the
  add flow.

### 4. Every library, everywhere

- Remove `includeLibraries` from `CatalogGateway` and `CoreCatalogGateway`, and from its callers: search, deleted
  items, missing files, collection candidates, the type listing and type counts.
- `DashboardController` stops dropping recent files that have a `libraryUuid`.
- The missing-files screen takes its roots from the libraries list instead of the sources. Its rescan is unchanged.
- Search keeps the hit's library tag, because every hit now has one. That is still the useful "where is it".
- The `fake_catalog_gateway` library-reach logic and `library_reach_test` go. A test now says that a library's files
  appear in their type panel.

### 5. Clean start for the stored sources

At startup, the app deletes the `librarySources` settings key once, silently. A 0.6 core already deleted those
folders' records, and keeping the list would hold paths no screen shows.

### 6. Audio

- `FileType.audio` (wire name `audio`) and `ShellDestination.music`, placed after `videos`. It gets an icon, a label
  ("Music" / "Música") and a `fileTypeFor` case. Everything that iterates `FileType.values` picks it up.
- **Metadata.** Restore the domain, editor and form from `7697589^`:
  - `music_metadata.dart`, `music_metadata_editor.dart`, `music_metadata_form.dart`;
  - their gateway call and provider;
  - the fields title, artist, album, album artist, year, genre and track.

  Adapt them to the current video editor's shape, which they were written alongside. The file details view shows the
  tags and duration, and offers Edit and Play.
- **Listing rows.** A Music row shows the title (or the file name when untagged), then artist · album, and the
  duration. Rows have no cover. (My call: one thumbnail call per row is more than a list needs, and the player shows
  the cover.)
- **Track order** (my call: next and previous have to follow an album, not file names). The Music panel gains an
  **Album** sort, which is its default:
  - album artist (falling back to artist), then album, then track number, then title, all case-insensitive;
  - untagged values sort last.

  The existing name and indexed sorts stay. The sort is Music-only and is saved with the type's other listing
  settings. That needs `ListingView`/`SortField`, the sort menu, and the tags on whatever the listing rows are built
  from.
- **Names from tags everywhere** (my call: a track should have one name wherever it appears). Restore
  `music_display_name.dart` from `7697589^`: the title, or the file name when untagged, with the artist beside it. Use
  it wherever `7697589` stopped using it:
  - search hits;
  - the dashboard's recent files;
  - the delete confirmation;
  - the missing-files review;
  - library tree rows (with `LibraryFile` carrying the tags again);
  - the player bar.
- **Player.**
  - `AudioPlaybackController` uses its own `MediaPlayer` instance, separate from the video player. It opens the
    path `filePlaybackSource` gives.
  - Its state is: the queue (`List<CatalogFile>`), the index in it, playing or paused, position and duration, and
    the cover bytes.
  - `play(file, queue)` starts a track, and the queue is the list it was started from:
    - from the Music panel, the listing as it is sorted and filtered;
    - from a library folder, that folder's audio files in tree order;
    - from search or details, just that file.
  - The queue holds active files only: deleted records are left out, even when the listing shows them.
  - At the end of a track, the next one plays. Playback stops after the last.
  - Opening a video pauses the music.
  - A track that fails to open (missing on disk, unreadable) is skipped. The bar briefly says which one was skipped,
    and the next track plays. Playback stops with an error in the bar, offering to rescan the way the video player
    does, only when nothing left in the queue opens. (My call: one missing file shouldn't end an album.)
  - A `PlaybackSessionActivity`-style hold keeps the file from being deleted mid-play, if the current video hold
    generalises cheaply. If not, it's left to the builder.
- **Player bar.** It is docked at the bottom of the shell while a track is loaded:

  ```txt
  [cover] Title — Artist      ⏮  ⏯  ⏭   01:12 ━━━━━●──────── 04:05   ✕
  ```

  Clicking the title opens the track's details. ✕ stops and hides the bar.
- **Opening a file.** `openFile` gains an audio case, which starts the player instead of opening a viewer. Library
  tree rows and listing rows go through it, as video does.
- `media_kit_libs_video` already decodes audio, so no new package is needed.

### 7. Tests

- Unit and widget tests follow the existing patterns. Write each failing test first, and name it Given-When-Then.
  They cover:
  - the version range;
  - the new status codes;
  - the run model's `libraryUuid`;
  - the controller keyed by uuid;
  - adding a library following its run;
  - a scan-again conflict;
  - the remove confirmation wording;
  - files in a library appearing in their type panel;
  - the settings key being cleared;
  - the Music panel rows;
  - the audio editor;
  - the player: queue, next and previous, the end of the queue, a video pausing it, and a failure.
- The source-specific tests (`test/features/library_sources/**`, the fake library sources) go, along with
  `integration_test/catalog/index_scope_test.dart`.
- The integration tests that call `indexStart` register a library instead, and follow its `runId`.
  `library_boundary_test` turns from "hidden from the type panels" into "listed in its type panel and removed with
  its library". One integration test indexes a tagged audio file and reads its tags.
- Golden images change for the navigation panel (the new Music entry). Regenerate them in CI's image.
- Verification: `flutter analyze` here, then `ci-check test` and the integration check. Their native dependencies
  need GTK, which this machine doesn't have.

### 8. Docs

- README: "What it does" and "What it doesn't do" (music is back as playable files, but there is still no music
  management), the roadmap and backlog rows for sources, music and libraries, and "the two repositories agree"
  (`>=0.6.0 <0.7.0`).
- CHANGELOG `[Unreleased]`:
  - Changed: libraries are the only way in, and the core is 0.6.
  - Added: audio playback and tag editing.
  - Removed: library sources and the index scope.
- `docs/requirements`:
  - System Requirements §3.2 becomes libraries: FR-LB requirements for sources are replaced, and FR-CT-16 (the
    exclusion) is removed.
  - Audio requirements are added under catalog and playback.
  - Use cases UC-05 to UC-08, UC-49 and others are rewritten to libraries.
  - Vision §1.2 and F-02/F-03, and IR-06.
- `docs/initial`: Project Overview and Business Rules BR-11.

## Left to the builder

- Exact widget structure, and the names of new private widgets.
- Whether the renamed `indexing` feature's files keep their current names.
- How the player bar animates in and out.
- Portuguese wording, following the existing Portuguese strings.
- Whether `PlaybackSessionActivity` generalises to audio, or audio gets its own small one.
