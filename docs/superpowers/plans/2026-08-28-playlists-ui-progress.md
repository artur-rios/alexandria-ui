# Playlists (UI) — progress and rulings

**Plan:** `docs/superpowers/plans/2026-08-28-playlists-ui.md`
**Design:** `docs/superpowers/specs/2026-08-28-playlists-design.md`
**Branch:** `feature/playlists-ui`
**Core half:** merged as alexandria-api #124 — the FFI, the header and the
generated bindings are already vendored here.

This file exists because the working ledger lives under `.superpowers/`,
which is git-ignored, and this work is being handed to another machine. It
carries the decisions that have no other home. Commit messages and `git log`
carry the rest.

## Where the work stands

| Task | State |
| --- | --- |
| 1 — the eight calls on `CoreClient` | complete (`feedaef`), reviewed |
| 2 — domain and gateway | complete (`743f987`), reviewed |
| 3 — the playlists screen | complete (`0eb141e`), reviewed |
| 4 — detail screen and reordering | complete (`29dd0bd`), reviewed, two fix rounds |
| 5 — adding tracks | implementation and fix round 1 in (`f8eb29b`); round 2 adds one test for the untagged artist group |
| 6 — playing a playlist | not started |
| 7 — the real-core lifecycle test | not started |
| 8 — requirement documents | not started |

## Before doing anything on a new machine

The vendored core library is git-ignored (`.gitignore:49`). Rebuild it:

```bash
cd ../alexandria-api && cargo build -p alexandria-ffi --release
cp target/release/alexandria_ffi.dll ../alexandria-ui/native/windows/
```

The header is committed, so `ffigen` does not need re-running. `flutter pub
get` first; `flutter analyze` and `flutter test` are the gates for every
commit, run in the foreground.

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

## Open items for the final review

**Cross-cutting — a blank dialog over the login screen.** `PlaylistsScreen`
and `PlaylistDetailScreen` are `showDialog` routes, so they survive
`MaterialApp.home` swapping to `LoginScreen`. On a rejected session the owner
is left looking at a fullscreen dialog with an empty title and an empty body,
floating above login. Both screens are affected identically, so it should be
settled once, for both, rather than diverging one from the other.
`FileDetailsController` takes the other path — it throws on
`UnauthorizedFailure`, with a comment explaining why.

## Deferred minors, to triage before merge

- **Codebase-wide:** the `Given{English,Portuguese}_…_ThenNoStringRendersAsItsKey`
  tests assert that no rendered text matches a feature-prefix regex, but
  `gen_l10n` makes a missing key a *compile* error, so the condition cannot
  occur. The pattern is copied across many features and proves nothing.
- **Codebase-wide:** NFR-07 (usable at 1024×640) is exercised by no test
  anywhere; screen tests run at 1440×1000.
- A refused move is silent — the row snaps back with no message — while
  `PlaylistsForm` shows a notice for the same class of refusal. Deliberate.
- `reload()` sets a bare `AsyncValue.loading()` with no `copyWithPrevious`,
  so every drop and every removal flashes the whole list. House style, shared
  with `PlaylistsController` and `FileDetailsController`.
- `addEntries` shows no in-widget feedback when the core refuses. Matches
  `AddToReadingListButton`.
- Adding a whole album is not reachable from *inside* an album screen, only
  from the Albums list and the artist drill-down. Satisfies the design as
  written.
- `PlaylistEntry` carries no `durationSeconds`, though the `FileView` it
  already parses supplies one. Adding it later means touching the domain type
  and the parser again.

## Two things fixed along the way, worth knowing

`ffigen.yaml` never generated the `PLAYLIST_ERR_*` / `PLAYLIST_OK` macros, so
no real failure mapping was possible until Task 2 added them.

`CoreCatalogGateway`'s private `FileView` parsing was extracted into
`lib/features/catalog/data/file_view_parser.dart` so playlists could reuse it
rather than growing a second parser. The catalog's own tests still exercise
it through the same path.
