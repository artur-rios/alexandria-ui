# Refresh the catalog's projections after a run finishes

Branch: `fix/refresh-catalog-after-a-run`

## The report

"I tried to index a folder full of music, it looked like it indexed, but I
see no files listed on the Music tab."

## Reproducing it

The root cause handed to me was already correct, and I verified it by reading
rather than re-deriving it:

- `ActiveRunsController._applyRead` (`lib/features/library_sources/application/active_runs_controller.dart`)
  detects a run leaving the active list, reads back how it ended, and records
  it as `state.justFinished` — and invalidates nothing.
- `MusicLibraryController.build` (`lib/features/playback/application/music_library_controller.dart`)
  watches nothing that changes when the catalog changes. It reads the catalog
  once per session and `musicLibraryProvider` then just sits on that answer
  forever, unlike `ListingController`, which rebuilds on `shellControllerProvider`
  every time a tab is navigated to.

I reproduced it as a widget test in
`test/features/playback/presentation/music_library_view_test.dart` (new group,
"a run finishes while the area is open"): the music area is opened over an
empty catalog, the empty message shows correctly, an index run is started and
then finishes (via `ActiveRunsController.refresh()`, the same call the poller
makes), the catalog gateway is given a track the way a real scan would have
left one, and the test asserts the track appears. Before the fix, this failed
with:

```
Expected: no matching candidates
  Actual: _TextWidgetFinder:<Found 1 widget with text "No audio files are
  catalogued yet.": [...]>
  Which: means one was found but none were expected
```

— i.e. the empty-library message was still showing after the run reported
done, which is exactly the bug reported. I ran this test against the
unmodified `active_runs_controller.dart` before writing the fix to confirm the
failure, then re-ran it after the fix to confirm it passes (both runs are the
`flutter test` output further down).

One implementation note on the test: driving a running run through
`pumpAndSettle` timed out, because the shell's activity strip shows an
indeterminate progress indicator for a running run, and that animation never
idles (the existing `index_run_test.dart` has the same caveat documented).
The test starts with no run outstanding (so sign-in's own `pumpAndSettle`
still settles), then drives the run's start and finish with bounded `pump()`
calls instead of `pumpAndSettle`.

## The fix

`ActiveRunsController._applyRead` now calls a new private method,
`_invalidateCatalogProjections()`, once per read when at least one run left
the active list on that read (an edge, tracked with a local `anyEnded` flag
set only when `_endOf` returns a non-null outcome — see "failed runs" below).
It does not fire on every poll of a still-running run, only on the poll where
a run's status transition is first observed.

```dart
void _invalidateCatalogProjections() {
  ref.invalidate(listingControllerProvider);
  ref.invalidate(typeCountsControllerProvider);
  ref.invalidate(recentFilesProvider);
  ref.invalidate(catalogSearchProvider);
  ref.invalidate(fileDetailsControllerProvider);
  ref.invalidate(musicLibraryProvider);
}
```

## Where I drew the projection line, and why

`catalog_session_activity.dart`'s `end()` is the full inventory of everything
that is either a catalog projection or session state, but it conflates both
because signing out has to clear both. I split it in two, and the split
follows the same line `deletion_controller.dart`'s `onDone` already draws for
a single deleted file — a run finishing is the same kind of event ("the
catalog changed"), just wider in scope:

**Invalidated (reads *from* the catalog, is stale the instant the catalog
changes underneath it):**
- `listingControllerProvider` — the type-scoped file listing.
- `typeCountsControllerProvider` — the navigation panel's per-type counts.
- `recentFilesProvider` — the dashboard's "recently added" list.
- `catalogSearchProvider` — the search index built from the catalog.
- `fileDetailsControllerProvider` — the currently-open file's *details*. This
  one is in `deletion_controller.dart`'s set for the same reason it belongs
  here: a run can also touch a file that's already open (e.g. clear a
  "missing" flag, add a newly-extracted thumbnail), and the owner looking at
  it should see the current record.
- `musicLibraryProvider` — the projection this bug is actually about. It
  belongs in this cluster by the same logic `catalog_session_activity.dart`
  already states for it: "Read from the catalog, so it goes when the catalog
  does."

**Left alone (is the owner's own state, not the catalog's):**
- `openFileProvider` — *which* file is open. This is the one the task
  description calls out explicitly: invalidating this would close whatever
  the owner navigated into, out from under them, the moment a background scan
  happens to finish. `fileDetailsControllerProvider` refetches the content of
  that same file without touching which file is selected.
- `searchTermProvider` — what the owner typed. Refetching
  `catalogSearchProvider` re-indexes against the current catalog; the term
  itself is unrelated to the catalog and must survive.
- `musicMetadataEditorProvider`, `videoMetadataEditorProvider`,
  `fileRenameControllerProvider` — open, in-progress edits. None of these are
  catalog projections at all; they're forms with local state the owner is
  mid-way through.
- Everything else `end()` touches — bookmarks, collections, watchlists,
  reading lists, deletion/restore/purge controllers, missing-files review —
  is genuinely session-scoped (BR-05: nothing survives past sign-out) but has
  no dependency on an index run's outcome, and invalidating it here would be
  scope creep past what the bug report and root cause actually implicate.

## What I decided about failed runs, and why

`ended != null` is true whenever `_endOf` got back *any* terminal read
(`complete`, `failed`, or a cancellation) — it is not narrowed to
`IndexRunStatus.complete`. A run that failed partway through has usually
still written some files into the catalog before it stopped, so the same
listings, counts, and music library can be stale after a failure exactly as
after a success; treating only success as catalog-changing would leave this
bug half-fixed. The one case that does *not* set `anyEnded` is `ended == null`
— the terminal read itself failed (the run's outcome is unknowable), which is
not evidence the catalog changed one way or the other, so nothing is
invalidated for it. This matches the existing doc comment on `_endOf` about
why a read that fails is reported as nothing rather than guessed at.

## Verification

```
$ flutter analyze
Analyzing alexandria-ui...
No issues found! (ran in 41.8s)

$ flutter test
...
+1856: All tests passed!
```

Targeted run, showing the reproduction failing before the fix and passing
after (see `test/features/playback/presentation/music_library_view_test.dart`,
group "a run finishes while the area is open (bug: catalog never
refreshes)"):

```
$ flutter test test/features/playback/presentation/music_library_view_test.dart \
    test/features/library_sources/application/active_runs_controller_test.dart \
    test/features/playback/application/music_library_controller_test.dart
...
+32: All tests passed!
```

## Concerns

- The invalidation is per-`_applyRead` call (once per poll where something
  ended), not per-run — two runs ending on the same poll trigger one
  invalidation batch, not two. This is deliberate (stated in the code
  comment) and matches the task's efficiency note, but is worth flagging as a
  design choice rather than an oversight.
- I did not add a unit test at the `ActiveRunsController` level asserting the
  exact provider set invalidated (e.g. via a Riverpod listener/dirty check) —
  the widget test proves the observable behavior (`musicLibraryProvider`
  actually refetches and the UI updates), which is the owner-visible contract
  the bug report is about. A more surgical unit test could be added if the
  team wants a assertion at the controller layer independent of widget
  rendering.
- `inProgressProvider` (the dashboard's "in progress" list) and the
  bookmarks/collections/watchlists/reading-lists controllers are not
  invalidated by this change. If any of those turn out to read fields an
  index run can change (e.g. `inProgressProvider` reading file metadata that
  a re-index could update), that would be a separate, narrower bug to
  investigate — it wasn't in the reported symptom or the given root cause.
