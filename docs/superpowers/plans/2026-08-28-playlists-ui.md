# Playlists (UI) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the owner build, arrange and play named lists of their own music.

**Architecture:** A new `features/playlists/` area following the shape `features/tracking/` already uses for reading lists and watchlists — a domain gateway, a `data/` implementation over `CoreClient`, Riverpod controllers, and screens. Playback reuses the existing queue with a new `QueueKind.playlist`. Reached from `Library ▾`, as reading lists are, not through `ShellDestination`.

**Tech Stack:** Flutter, Riverpod 3.4 (`Notifier`, `AsyncNotifier`, `FutureProvider.family`), freezed, gen_l10n, `dart:ffi` through the generated bindings.

**Design:** `docs/superpowers/specs/2026-08-28-playlists-design.md`. The core half is merged (alexandria-api #124) and the bindings are already vendored — `alexandria_playlist_*` is callable today.

## Global Constraints

- **BR-02:** the core owns domain decisions. Ordering arithmetic, validation and identity all live there. This application sends "put entry X at index N" and renders what comes back — it never computes positions.
- **FR-CT-13:** audio is named by its metadata, never by its file name. A playlist row shows the track's title; a file with no title tag has no name here.
- **BR-18 / FR-UX-07:** no colour literals outside `lib/core/theme/`.
- **NFR-07:** usable at 1024×640.
- **IR-11:** every string in both `.arb` files (`lib/core/l10n/app_en.arb`, `app_pt.arb`); a missing translation is a build failure. Regenerate with `flutter gen-l10n`.
- **Test naming:** `Given<State>_When<Action>_Then<Outcome>`, and the test tree mirrors `lib/`.
- **Doc comments explain *why*, not *what*.** Match the surrounding density.
- **Verification gates, both read for their exit code, before every commit:** `flutter analyze`, `flutter test`. Run them in the FOREGROUND with a generous timeout; never in the background.
- Freezed models need `dart run build_runner build --delete-conflicting-outputs`.

## An entry is addressed by its uuid

The core's wire contract, already shipped: a playlist is addressed by `uuid`, and **an entry by its own `uuid`** — not by an index and not by the file it points at. A playlist may hold the same track more than once, so the file uuid does not identify a row. Every remove and every move sends the entry's uuid.

## File Structure

| File | Responsibility |
| --- | --- |
| `features/playlists/domain/playlist.dart` | `Playlist`, `PlaylistEntry`, `PlaylistView`. |
| `features/playlists/domain/playlist_gateway.dart` | The port + its result types. |
| `features/playlists/data/core_playlist_gateway.dart` | The port over `CoreClient`. |
| `features/playlists/application/playlists_controller.dart` | The owner's playlists. |
| `features/playlists/application/playlist_detail_controller.dart` | One playlist and its tracks. |
| `features/playlists/presentation/playlists_screen.dart` | The list of playlists. |
| `features/playlists/presentation/playlist_detail_screen.dart` | One playlist, reorderable. |
| `features/playlists/presentation/add_to_playlist_button.dart` | The add action, reused from three places. |
| `core/bindings/core_client.dart`, `core_isolate.dart` | The eight calls. |
| `playback/domain/playback_queue.dart` | `QueueKind.playlist`. |

---

### Task 1: The eight calls on `CoreClient`

**Files:**
- Modify: `lib/core/bindings/core_client.dart`, `lib/core/bindings/core_isolate.dart`
- Modify: `test/support/fake_core_client.dart`
- Test: `test/core/bindings/core_isolate_test.dart` (follow whatever the existing file does; create it only if the repository has one)

**Interfaces:**
- Produces, on `CoreClient`: `playlistCreate(String jsonBody, String token)`, `playlistRename(String uuid, String jsonBody, String token)`, `playlistDelete(String uuid, String token)`, `playlistsList(String token)`, `playlistRead(String uuid, String token)`, `playlistAddEntries(String uuid, String jsonBody, String token)`, `playlistRemoveEntry(String uuid, String entryUuid, String token)`, `playlistMoveEntry(String uuid, String entryUuid, String jsonBody, String token)`. Each answers the same `CoreJsonResponse` shape the reading-list calls use.

The generated binding is already in place — read `alexandria_playlist_*` in `lib/core/bindings/alexandria_bindings.dart` for the exact signatures. Follow the reading-list calls in `core_client.dart` and their `core_isolate.dart` cases exactly, including `withNativeString` nesting.

- [ ] **Step 1: Write the failing tests**

Follow whatever the repository already does for the reading-list calls. At minimum, one test per call asserting the isolate case dispatches to the right binding with its arguments in the right order — the failure this catches is two `String` parameters transposed, which compiles and misbehaves silently.

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/bindings/`
Expected: FAIL — the methods do not exist.

- [ ] **Step 3: Implement the eight calls**

- [ ] **Step 4: Run to verify they pass**

- [ ] **Step 5: Run `flutter analyze` and `flutter test`, then commit**

```bash
git add lib/core/bindings test
git commit -m "feat: reach the core's playlist calls"
```

---

### Task 2: The domain and the gateway

**Files:**
- Create: `lib/features/playlists/domain/playlist.dart`, `playlist_gateway.dart`
- Create: `lib/features/playlists/data/core_playlist_gateway.dart`
- Modify: `lib/core/di/providers.dart` (a `playlistGatewayProvider`, beside `readingListGatewayProvider`)
- Test: `test/features/playlists/data/core_playlist_gateway_test.dart`

**Interfaces:**
- Produces: `Playlist { String uuid, String name }`; `PlaylistEntry { String uuid, CatalogFile file, MusicMetadata? metadata, int position, bool missing }`; `PlaylistView { Playlist playlist, List<PlaylistEntry> entries }`; a sealed `PlaylistBrowse`/`PlaylistRead`/`PlaylistWrite` result trio mirroring `ReadingListBrowse`/`ReadingListWrite`; and `PlaylistGateway` with `browse`, `read`, `create`, `rename`, `delete`, `addEntries`, `removeEntry`, `moveEntry`.

Read `lib/features/tracking/domain/reading_list_gateway.dart` and `data/core_reading_list_gateway.dart` first and mirror them — the sealed-result shape, the failure mapping, and the `UnauthorizedFailure` path all already exist.

The entry's file and metadata parse from the same `FileView` shape every other listing answers, so reuse whatever `core_catalog_gateway.dart` already uses rather than writing a second parser.

- [ ] **Step 1: Write the failing tests**

Cover, at minimum:
- A read parses entries in the order the core sent them, and does **not** re-sort by anything.
- An entry whose `missing` is true parses as missing rather than being dropped.
- The same track twice parses as two entries with different uuids.
- A malformed payload answers a failure rather than throwing.
- An unauthorized answer maps to `UnauthorizedFailure`.

For the ordering test, make the fixture's payload order differ from any order the parser might accidentally impose — put position 0 second in the JSON array, so a parser that sorts by array index fails.

- [ ] **Step 2: Run to verify they fail; Step 3: implement; Step 4: run to verify they pass**

- [ ] **Step 5: Run both gates, then commit**

```bash
git add lib/features/playlists lib/core/di test
git commit -m "feat: read and write playlists through the core"
```

---

### Task 3: The playlists screen

**Files:**
- Create: `lib/features/playlists/application/playlists_controller.dart`
- Create: `lib/features/playlists/presentation/playlists_screen.dart`
- Modify: `lib/features/shell/presentation/library_menu.dart` (an entry opening it, beside the reading-lists one)
- Modify: `lib/core/l10n/app_en.arb`, `app_pt.arb`
- Test: `test/features/playlists/application/playlists_controller_test.dart`, `test/features/playlists/presentation/playlists_screen_test.dart`

**Interfaces:**
- Consumes: `PlaylistGateway` from Task 2.
- Produces: `playlistsControllerProvider` (an `AsyncNotifier<List<Playlist>>` mirroring `ReadingListsController`, including its no-session and `UnauthorizedFailure` handling); `PlaylistsScreen.show(BuildContext)`.

- [ ] **Step 1: Write the failing tests**

- Creating a playlist with a blank name does not call the core and marks the field (the same rule reading lists apply).
- Creating one adds it to the list without a manual refresh.
- Renaming shows the new name.
- Deleting asks first, and the confirmation says the tracks themselves are untouched.
- An empty state invites the owner to make one rather than showing a bare empty list.
- Both locales render with no string showing as its key.

- [ ] **Step 2: Run to verify they fail; Step 3: implement; Step 4: run to verify they pass**

- [ ] **Step 5: Run both gates, then commit**

```bash
git add lib test
git commit -m "feat: manage playlists from the library menu"
```

---

### Task 4: The playlist detail screen, with reordering

**Files:**
- Create: `lib/features/playlists/application/playlist_detail_controller.dart`
- Create: `lib/features/playlists/presentation/playlist_detail_screen.dart`
- Modify: l10n
- Test: `test/features/playlists/application/playlist_detail_controller_test.dart`, `test/features/playlists/presentation/playlist_detail_screen_test.dart`

**Interfaces:**
- Consumes: `PlaylistGateway.read`, `.removeEntry`, `.moveEntry`.
- Produces: `playlistDetailControllerProvider` — a `FutureProvider.family`-shaped controller keyed by playlist uuid.

**The reordering contract is the thing to get right.** `ReorderableListView` gives a `newIndex` that is offset by one when an item moves **down** — Flutter's documented behaviour, and the single most common bug in this widget. The core expects a plain destination index. Convert once, in one named place, with a comment saying why, and test both directions.

The core answers the full new order; render that rather than the optimistic local list, so the displayed order is always the stored order (design §3).

- [ ] **Step 1: Write the failing tests**

- Tracks render in position order, by title from metadata, never by file name (FR-CT-13).
- Dragging a track **down** puts it where it was dropped — the case Flutter's off-by-one breaks.
- Dragging a track **up** puts it where it was dropped.
- A missing entry renders greyed and is still listed.
- Removing an entry removes that entry, when the same track appears twice — assert the *other* one survives.
- The screen shows the core's returned order after a move, not a locally computed one.

- [ ] **Step 2: Run to verify they fail; Step 3: implement; Step 4: run to verify they pass**

- [ ] **Step 5: Run both gates, then commit**

```bash
git add lib test
git commit -m "feat: arrange a playlist"
```

---

### Task 5: Adding tracks

**Files:**
- Create: `lib/features/playlists/presentation/add_to_playlist_button.dart`
- Modify: `lib/features/playback/presentation/music_rows.dart` (the track context menu), the album and artist views, `lib/features/playback/presentation/now_playing_screen.dart`
- Modify: l10n
- Test: `test/features/playlists/presentation/add_to_playlist_button_test.dart`, plus cases in the touched screens' tests

**Interfaces:**
- Consumes: `PlaylistGateway.addEntries`, `playlistsControllerProvider`.

Follow `lib/features/tracking/presentation/add_to_reading_list_button.dart` — the `PopupMenuButton` listing the owner's lists is the established shape.

Three entry points, per the approved design: a track's context menu, a whole album or artist at once, and the now-playing screen. **Search results were deliberately excluded** — do not add it there.

- [ ] **Step 1: Write the failing tests**

- Adding from a track's menu sends that one file uuid.
- Adding a whole album sends every track's uuid **in the order the album lists them**, in one call — not one call per track.
- Adding from now playing sends the current track.
- Adding a track already in the playlist adds a second entry rather than refusing (the core allows duplicates; the UI must not invent a refusal the core does not have).
- With no playlists yet, the action offers to create one rather than showing an empty menu.

- [ ] **Step 2: Run to verify they fail; Step 3: implement; Step 4: run to verify they pass**

- [ ] **Step 5: Run both gates, then commit**

```bash
git add lib test
git commit -m "feat: add tracks to a playlist"
```

---

### Task 6: Playing a playlist

**Files:**
- Modify: `lib/features/playback/domain/playback_queue.dart` (`QueueKind.playlist`)
- Modify: `lib/features/playback/application/audio_playback_controller.dart` (a `playPlaylist`)
- Modify: `lib/features/playlists/presentation/playlist_detail_screen.dart` (the play action)
- Test: cases in `test/features/playback/` and the detail screen's test

**Interfaces:**
- Consumes: `PlaybackQueue`, `AudioPlaybackController`.

**Two rules from the design, both of which fall out of code that already exists rather than needing new logic:**

1. A playlist queue **names no record of its own**. `recordOf` then resolves the animation's identity from the current track, exactly as it does for a lone track today — so crossing from one album to the next inside a playlist inserts the new medium, and skipping within an album does not. Do not add a second rule beside the one that is already there.
2. **Missing entries are skipped, not played into an error.** The design's §5: the list continues.

- [ ] **Step 1: Write the failing tests**

- Playing a playlist replaces the queue and starts at position 0.
- A missing entry is stepped over and the next track plays.
- Crossing an album boundary inside a playlist owes an insertion; two tracks of the same album do not.
- A playlist of entirely missing files reports that nothing could be played rather than appearing to play silence.

- [ ] **Step 2: Run to verify they fail; Step 3: implement; Step 4: run to verify they pass**

- [ ] **Step 5: Run both gates, then commit**

```bash
git add lib test
git commit -m "feat: play a playlist"
```

---

### Task 7: The end-to-end proof against the real core

**Files:**
- Create: `integration_test/playlists/playlist_lifecycle_test.dart`

Every test above runs against a fake this application also wrote, so none of them can tell whether the core agrees. The two existing integration tests — `integration_test/catalog/listing_shape_test.dart` and `index_scope_test.dart` — exist for exactly that reason and are the pattern to follow.

**Note:** `flutter test integration_test -d windows` does not work in this repository (the Windows harness cannot relaunch the app between files). Run the single file: `flutter test integration_test/playlists/playlist_lifecycle_test.dart -d windows`.

- [ ] **Step 1: Write the test**

One lifecycle, against a real core over the real FFI: create a playlist; add four tracks; move the last to the front; remove what is then the second; read it back and assert the exact remaining order and that positions are `0,1,2`. Then add the same track twice and assert two entries come back with different uuids.

This is the one test that would catch a wire-name disagreement, an argument in the wrong position, or an entry-uuid contract drift — each of which succeeds silently against a fake.

- [ ] **Step 2: Verify it fails for the right reason**

Before trusting it, break it deliberately: send the move's destination index off by one, confirm the assertion fails naming the wrong order, then restore. Report the observed failure.

- [ ] **Step 3: Run it, then commit**

```bash
git add integration_test
git commit -m "test: prove a playlist round-trips through the real core"
```

---

### Task 8: Requirement documents

**Files:**
- Modify: `docs/requirements/Use Case Specification Document.md`, and whichever requirement document holds the UI's functional requirements

- [ ] **Step 1: Add the use cases**

Managing a playlist and playing one, in this repository's own format — the application's half, not the core's. The core's use cases live in the sibling repository and should not be duplicated here; cite them.

- [ ] **Step 2: Record the rules a future reader could undo**

That a playlist row is named by metadata (FR-CT-13); that a playlist queue names no record, so the animation resolves per track; that missing entries are shown and skipped; and that the destination index sent to the core is a plain index, with `ReorderableListView`'s downward off-by-one converted in one place.

- [ ] **Step 3: Commit**

```bash
git add docs
git commit -m "docs: specify the playlists area"
```

---

## Self-Review

**Spec coverage.** Design §1 (core owns it) → Tasks 1-2. §2 (duplicates, entry identity) → Task 2's parse test, Task 4's remove test, Task 5's duplicate-add test, Task 7's round trip. §3 (contiguous positions, displayed order is stored order) → Task 4. §4 (batched read) → core-side, already shipped; Task 2 only parses it. §5 (missing kept and skipped) → Task 4 renders, Task 6 skips. §6 (playback, queue kind, no record named, current track's cover) → Task 6. §7 (rename) → Task 3. Requirements impact → Task 8.

**Placeholders.** None. Task 1's test file is conditional on what the repository already has, which is a real instruction rather than a deferral.

**Type consistency.** `PlaylistEntry.uuid` is the entry's own uuid throughout, distinct from `file.uuid`; Tasks 4 and 5 both address by it. `PlaylistView` is produced in Task 2 and consumed unchanged in Tasks 4 and 6. `QueueKind.playlist` is added in Task 6 and referenced nowhere earlier.

**Known risk carried into Task 4:** `ReorderableListView`'s `newIndex` is offset by one for downward moves. The plan names it, requires the conversion in one place, and tests both directions — because a test written only for upward drags passes with the bug present.
