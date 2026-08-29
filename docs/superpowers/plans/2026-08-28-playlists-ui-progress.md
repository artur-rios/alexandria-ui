# Playlists (UI) — progress and rulings

**Plan:** `docs/superpowers/plans/2026-08-28-playlists-ui.md`
**Design:** `docs/superpowers/specs/2026-08-28-playlists-design.md`
**Branch:** `feature/playlists-ui`, merged to `main` as `0601045` and deleted;
the review's fixes followed as `2a9b8e0`.
**Core half:** merged as alexandria-api #124 — the FFI, the header and the
generated bindings are already vendored here.

This file exists because the working ledger lives under `.superpowers/`,
which is git-ignored, and this work crossed between machines. It carries the
decisions that have no other home. Commit messages and `git log` carry the
rest.

## Where the work stands

| Task | State |
| --- | --- |
| 1 — the eight calls on `CoreClient` | complete (`feedaef`), reviewed |
| 2 — domain and gateway | complete (`743f987`), reviewed |
| 3 — the playlists screen | complete (`0eb141e`), reviewed |
| 4 — detail screen and reordering | complete (`29dd0bd`), reviewed, two fix rounds |
| 5 — adding tracks | complete (`f8eb29b`, `804357f`), reviewed |
| 6 — playing a playlist | complete (`c15c201`) |
| 7 — the real-core lifecycle test | complete (`2b7bb55`), run green on Linux |
| 8 — requirement documents | complete |

Every task in the plan is in, the final review is done, and both are merged
to `main` — the feature as `0601045`, the review's fixes as `2a9b8e0`. What
the review settled and what it deliberately left are below.

## Before doing anything on a new machine

The vendored core library is git-ignored (`.gitignore:49`). Rebuild it:

```bash
cd ../alexandria-api && cargo build -p alexandria-ffi --release
cp target/release/alexandria_ffi.dll ../alexandria-ui/native/windows/
# on Linux: cp target/release/libalexandria_ffi.so ../alexandria-ui/native/linux/
```

The header is committed, so `ffigen` does not need re-running. `flutter pub
get` first; `flutter analyze` and `flutter test` are the gates for every
commit, run in the foreground.

**On Linux**, the core needs FFmpeg's development packages and libclang to
build at all (`libavutil-dev`, `libavformat-dev`, `libavcodec-dev`,
`libswscale-dev`, `libavfilter-dev`, `libavdevice-dev`, `libclang-dev`), and
Task 7's integration test additionally needs the Flutter Linux desktop
toolchain and `libmpv-dev` for `media_kit`, with `xvfb-run` standing in for a
display:

```bash
xvfb-run -a bash -c 'flutter test integration_test/playlists/playlist_lifecycle_test.dart -d linux'
```

**Three golden tests fail on Linux and are not a regression.**
`case_painter_test.dart`'s three `Given…ThenItMatchesItsGolden` cases differ
by 1.2-1.9%, over the comparator's 0.5% tolerance. The goldens in the
repository were rendered on Windows, and `flutter_test_config.dart`'s own
comment names exactly this: the two platforms do not rasterize text
identically. They fail the same way on a clean checkout of `804357f`. Do not
regenerate them from Linux — that would move the goldens away from the
machine they were made on and hide a real regression later.

## Rulings that must not be quietly reversed

**Task 7 is load-bearing and cannot be dropped.** `core_isolate.dart`'s
switch cases map `arguments[n]` onto positional native parameters, and no
unit test can reach that mapping — it needs a loaded native library. Several
calls take three or four consecutive `String` parameters, so a transposition
inside a `case` compiles, passes every unit test, and fails only at runtime.
The integration test is the sole automated cover for that layer, which is
why the plan requires **all eight calls** to appear in its lifecycle. An
earlier draft omitted rename and delete, leaving those two covered by
nothing; the plan was amended.

**An entry is addressed by its own uuid**, never by an index and never by the
file it points at, because a playlist may hold the same track more than once.
The wire key is `entryUuid` — an early brief said `uuid` and was wrong.

**The core owns ordering (BR-02).** The UI sends "put entry X at index N" and
renders what comes back. It never computes positions. `ReorderableListView`
reports a `newIndex` offset by one for downward moves; that is converted in
one named place, `reorderDestinationIndex`, and both directions are tested.

**`onReorder` is deliberately used despite being deprecated.** The newer
`onReorderItem` pre-corrects the index (verified in Flutter 3.47.1's
`widgets/reorderable_list.dart`), so adopting it means *deleting*
`reorderDestinationIndex`, not stacking the two. Migrating is a removable
trade, not forbidden.

**Duplicates are never filtered client-side.** The core allows a track to
appear twice on purpose. Nothing in the UI may dedup a batch.

## What the final review fixed (`2a9b8e0`)

Three defects, none of them on the agenda this file carried, each now
covered by a test that fails without its fix.

- **Playlist writes died permanently after one rejection.** `PlaylistsForm._call`
  never cleared `isWriting` on the `UnauthorizedFailure` arm, and
  `playlistsFormProvider` is not auto-disposed, so the flag outlived the
  dialog, the session, and signing back in. `create` and `renameSubmitted`
  kept returning at their own `state.isWriting` guard: every later create,
  rename and delete silently did nothing for the rest of the run.
- **A playlist never refreshed after its first open.** `playlistDetailControllerProvider`
  is the only `.family` here, and `isAutoDispose` defaults to `false` in
  `AsyncNotifierProviderFamilyBuilder.call`. Its entry was cached for the life
  of the container, so a track added from the music area — where `addEntries`
  deliberately skips reloading it — never appeared, and a rename left the old
  title in the app bar. Now `isAutoDispose: true`.
- **`CatalogSessionActivity.end` had never been told about playlists**, where
  it drops every other core-backed collection (BR-05).

## Two things this file used to say that are wrong

Both were acted on as fact and both are false. They are kept here, corrected,
rather than deleted, so nobody re-derives them.

- **NFR-07 is not untested.** `shell_screen_test.dart` pins a
  `TheMinimumWindow` case at exactly 1024×640, `index_scope_dialog_test.dart`
  defaults to it, and `window_geometry_controller_test.dart` pins the minimum
  itself. What is true is narrower: the *playlists* screens have no test at
  that size. Both of them were checked by hand at 1024×640 during the review
  and render with no overflow and the play action intact, so this is a missing
  test rather than a latent defect.
- **`copyWithPrevious` would not fix the reload flash.** `AsyncStateView`
  matches `AsyncLoading()` *before* `AsyncData`, on purpose and with a comment
  saying why — a refresh that fails has to report the failure rather than sit
  on a spinner. So it renders the spinner whether or not a previous value is
  carried, and the flash is a property of that view, shared by every screen
  using it. Fixing it is a change to `AsyncStateView`, not to `reload()`.

## Still open

**Cross-cutting — a blank dialog over the login screen.** Reproduced during
the review, and **not a playlists defect**: `PlaylistsScreen` and
`PlaylistDetailScreen` are `showDialog` routes that survive `MaterialApp.home`
swapping to `LoginScreen`, but so are `ReadingListsScreen`,
`WatchlistsScreen`, `CollectionsScreen`, `DeletedItemsScreen`,
`MissingFilesScreen` and `LibrarySourcesScreen`, and nothing pops the
navigator when a session ends. `ReadingListsScreen` was checked and behaves
identically. It wants settling once for all of them — a listener on the
session that pops to the first route — not per screen.
`FileDetailsController` takes the other path, throwing on
`UnauthorizedFailure`, with a comment explaining why.

**Two the review raised outside playlists**, both real, neither a regression
from this work, each wanting its own change:

- `music_rows.dart:73` builds `inArtistOrder(group.entries)` eagerly inside
  `ListView.builder`'s `itemBuilder`, sorting an artist's entire track list
  and allocating a uuid list on every rebuild of every visible row, for a
  value only needed if the menu is opened.
- `AlbumAnimationController.insertionShown` recomputes `_shownFor` from the
  queue as it is when the animation *finishes*, rather than from the
  `owedIdentity` the insertion was shown for. `QueueKind.playlist` is the
  first kind whose record can change mid-animation, so a decode failure
  (AF-02) during an insertion can stamp the *next* album as already shown and
  cost it its own insertion.

## Deferred minors, still deferred

- **Codebase-wide:** the `Given{English,Portuguese}_…_ThenNoStringRendersAsItsKey`
  tests assert that no rendered text matches a feature-prefix regex, and
  nothing can make that fire. A key used in code but absent from the *template*
  is a compile error; a key missing from a *translation* is not — that was
  checked by deleting one and regenerating, which succeeds — but
  `test/core/l10n/arb_parity_test.dart` catches it and names the key, which
  was also checked. Neither gap can reach a rendered screen, so the regex has
  nothing left to catch. The pattern is copied across many features.
- A refused move is silent — the row snaps back with no message — while
  `PlaylistsForm` shows a notice for the same class of refusal. Deliberate.
- Every drop and every removal flashes the whole list, for the reason under
  "wrong" above.
- `addEntries` shows no in-widget feedback when the core refuses. Matches
  `AddToReadingListButton`. The review noted a sharper edge: the refusal is
  written to the shared `PlaylistsForm` state and cleared only by
  `acknowledge`, `editName`, or a later successful write — so it can surface
  later as an unexplained banner the next time the playlists screen opens.
- `AddToPlaylistButton` collapses a loading or failed browse into "no
  playlists yet" and offers to create one, where `AddToReadingListButton`
  disables the item instead.
- Adding a whole album is not reachable from *inside* an album screen, only
  from the Albums list and the artist drill-down. Satisfies the design as
  written.
- `PlaylistEntry` carries no `durationSeconds`, though the `FileView` it
  already parses supplies one. Adding it later means touching the domain type
  and the parser again.
- `ReorderableListView.builder` leaves `buildDefaultDragHandles` at `true`
  while `_EntryTile` supplies its own `ReorderableDragStartListener`, so on
  the desktop targets the whole row drags and the handle icon is not the
  affordance it advertises.

## Two things fixed along the way, worth knowing

`ffigen.yaml` never generated the `PLAYLIST_ERR_*` / `PLAYLIST_OK` macros, so
no real failure mapping was possible until Task 2 added them.

`CoreCatalogGateway`'s private `FileView` parsing was extracted into
`lib/features/catalog/data/file_view_parser.dart` so playlists could reuse it
rather than growing a second parser. The catalog's own tests still exercise
it through the same path.
