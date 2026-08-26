# Consuming the richer catalog — listing report

**Date:** 2026-08-26
**Branch:** feat/consume-richer-catalog
**Scope:** design sections 1–3 only (section 4, the album cover, is a later task and was not touched)

## Summary

`CatalogListing.loaded` now carries `List<FileDetails>` instead of
`List<CatalogFile>`, reusing the detail call's own JSON parse. Every caller
that only wanted the file was updated to read `.file`. The music library
(`MusicLibraryController`) is now one gateway call; `musicLibraryProgressProvider`
and the incremental-loading machinery it existed to support are deleted.
Search (`matchesSearch`) now matches a row's metadata as well as its name and
path, and `audioMetadataProvider` is deleted in favor of reading a row's own
metadata (or, for a handful of single-file callers outside search, the now-
cheap `musicLibraryProvider`).

`flutter analyze` is clean and `flutter test test` is fully green (1837
tests). `integration_test` was not run, per instructions.

## 1. The listing answers what the detail answers

- `lib/features/catalog/domain/catalog_gateway.dart` — `CatalogListing.loaded`
  now carries `List<FileDetails>`. Doc comment rewritten to say so and to
  explain each row is the same `FileView` record the detail call answers.
- `lib/features/catalog/data/core_catalog_gateway.dart` — factored the detail
  call's parse into a private `_detailsFrom(Map<String, dynamic> body)` that
  builds a `FileDetails` from one `FileView` body (or `null` for an unknown
  file type). `fileDetails` and `listFiles` both call it now, so there is one
  parse rather than two. A malformed row (or a wrongly-typed field) still
  throws inside the `try`/`on Object` in `listFiles` and surfaces as
  `CatalogListing.failed` — verified directly by a new test,
  `test/features/catalog/data/core_catalog_gateway_test.dart`, which also
  proves a per-row unknown file type is dropped rather than failing the whole
  listing (mirroring `_fileFrom`'s existing behavior for the single-file
  call).

Callers updated to read `.file` off each row:
- `lib/features/catalog/application/listing_controller.dart` —
  `ListingController` maps `files` to `[for (final row in files) row.file]`
  before sorting; its public state stays `List<CatalogFile>`, so
  `catalog_listing.dart` (the presentation layer) needed no change.
  `TypeCountsController` only reads `.length`, unaffected.
- `lib/features/catalog/application/search_controller.dart` — `CatalogSearchIndex.files`
  is now `List<FileDetails>` (search needs the metadata, see §3 below).
- `lib/features/catalog/application/dashboard_controller.dart` —
  `RecentFilesController` maps `index.files` (now `FileDetails`) to `.file`
  before calling `sortFiles`; its own state stays `List<CatalogFile>`.
- `lib/features/lifecycle/application/deleted_items_controller.dart` —
  `files.map((row) => DeletedRecord.ofFile(row.file))`.
- `lib/features/lifecycle/application/missing_files_controller.dart` —
  `files.map((row) => row.file).where((file) => file.isMissing)`.
- `lib/features/organization/application/collection_candidates_controller.dart` —
  reads `row.file.uuid` / `row.file.name`.
- `lib/features/playback/application/music_library_controller.dart` — see §2.

Screens that never touched `CatalogListing` directly (`catalog_listing.dart`,
`image_viewer_controller.dart`/`image_viewer_screen.dart`, the collections and
lists screens) needed no change, exactly as the design predicted — they
consume the application-layer `List<CatalogFile>` these controllers still
publish.

## 2. The music library becomes one call

`lib/features/playback/application/music_library_controller.dart` was
rewritten: `build()` now calls `gateway.listFiles(type: LibraryType.audio, …)`
once and builds every `MusicEntry` straight from each row's `file` and
`metadata`. No `fileDetails` call remains in this file.

**Pinning the one call:** `FakeCatalogGateway` gained a `listCalls` getter
(`requested.length`). The rewritten
`test/features/playback/application/music_library_controller_test.dart` has
a dedicated test —
`GivenAudioFiles_WhenTheLibraryLoads_ThenTheGatewayIsCalledExactlyOnce` —
asserting `gateway.listCalls == 1` and `gateway.detailsRequested.isEmpty`
after loading a 3-track library. This is the assertion the design calls out
as necessary: without it, a regression back to per-file reads would be
invisible to every other assertion about the resulting `MusicLibrary`.

**Deleted, and why it's safe:**
- `musicLibraryProgressProvider` / `MusicLibraryProgress` — deleted from
  `lib/core/di/providers.dart`. Its only reason to exist was to publish
  "everything read so far" while the old N+1 scan ran; `musicLibraryProvider`
  now resolves in one gateway call, so there is no "so far" distinct from
  "complete" — both providers would have carried identical state at every
  observable instant, making the second one pure overhead, not a narrower
  correctness net. I confirmed this by checking every remaining reader:
  `music_library_view.dart` now watches only `musicLibraryProvider`;
  `music_display_name.dart`'s `musicEntryForFile` now reads
  `ref.watch(musicLibraryProvider).value` (falling back to an untitled
  `MusicEntry` while loading/failed, same as before); three presentation
  callers outside search (`home_dashboard.dart`, `delete_record_button.dart`,
  `missing_files_screen.dart`) previously bypassed the whole-library
  provider specifically to avoid triggering the (then-expensive) N+1 scan —
  their doc comments said so explicitly. That reason is gone now that the
  scan is one call, so I moved them onto `musicLibraryProvider` too (via
  `musicTitleForFile`, or a direct one-shot `ref.read(musicLibraryProvider.future)`
  for the async button-press case in `delete_record_button.dart`).
- `MusicLibrary.total` / `.isComplete` — the type collapsed to
  `{required List<MusicEntry> entries}` with a `static const empty`. Nothing
  outside this file and its provider registration referenced either field
  once the progress provider was gone.
- The progress line in `music_library_view.dart` (`_Progress` widget) —
  deleted along with the `musicLoading` ARB entry (`app_en.arb`, `app_pt.arb`)
  and its regenerated `generated/app_localizations*.dart` output.

**Failure path unchanged:** `MusicLibraryController` still throws on a failed
listing (`UnauthorizedFailure` invalidates the session; any other failure is
rethrown), which `AsyncStateView` in `music_library_view.dart` still renders
as `ShellFailureView` with retry — same as before, just with `onRetry`
invalidating only `musicLibraryProvider` now (there is no second provider to
invalidate alongside it). The existing failure test
(`GivenTheListingFails_WhenTheAreaIsShown_ThenAMessageAndRetryAppear`) and the
rewritten empty-library test both still pass and still mean what their names
say — I re-verified this is a *different* code path from the empty case by
keeping both as distinct tests in `music_library_controller_test.dart`
(`GivenAListingThatFails…ThenTheFailureIsThrown` vs.
`GivenNoAudioFiles…ThenItIsEmptyRatherThanFailed`).

I also deleted the tests that existed purely to cover the N+1 machinery
(checkpointed publishing, the orphan-scan-stops-on-invalidate race, "metadata
still arriving") since that code no longer exists; kept/added tests for what
still applies (metadata present per entry, a row with no metadata joining
untagged, the one-call assertion, empty vs. failed).

## 3. Search matches metadata

- `lib/features/catalog/domain/catalog_search.dart` — `matchesSearch` now
  takes a `FileDetails` and matches `file.name`, `file.path`, and every value
  in `metadata`. Doc comment rewritten: the paragraph explaining the metadata
  half was "deliberately absent rather than faked" now says each row carries
  its metadata already, reused from the same parse as the detail call.
  `searchResults`/`isSearchable`/`highlightRange` updated to the new
  parameter type where needed.
- `lib/core/di/providers.dart` — `audioMetadataProvider` deleted.
- `lib/features/catalog/presentation/catalog_search_view.dart` — `_ResultRow`
  now takes the row's own `FileDetails` and reads
  `MusicMetadata.fromDetails(details.metadata)` directly instead of watching
  a per-file provider; it no longer needs `WidgetRef` at all, so it became a
  plain `StatelessWidget`.
- `test/features/catalog/domain/catalog_search_test.dart` — rewritten for the
  `FileDetails` signature, plus new cases: a term matching only metadata
  matches; a term matching an unrelated tag (no file-name overlap) still
  matches; no metadata value matching means no match.

## Other callers of the deleted `audioMetadataProvider`

Three presentation files outside search also called the per-file provider,
which the design's component table didn't call out explicitly (it only lists
`catalog_search_view.dart`). Each explained in its own doc comment that it
was deliberately avoiding `musicLibraryProvider` to dodge the (then-real) cost
of the full N+1 scan:

- `lib/features/catalog/presentation/home_dashboard.dart` (`_RecentSection`)
- `lib/features/lifecycle/presentation/delete_record_button.dart` (`DeleteFileButton._confirm`)
- `lib/features/lifecycle/presentation/missing_files_screen.dart` (`_MissingTile`)

Since `musicLibraryProvider` is now one gateway call, that reasoning no
longer holds, so all three now read through it (two via
`musicTitleForFile`/`ref.watch`, one via a one-shot
`ref.read(musicLibraryProvider.future)` since it runs from a button press).
Their doc comments were rewritten to say why. This was not spelled out in the
design; I judged it the correct consequence of §2's premise rather than an
open question, since leaving them on a since-deleted provider wasn't an
option and reintroducing a per-file `fileDetails` provider just for these
three call sites would have kept exactly the "second call per file" shape the
whole task exists to remove.

## Test fixture changes

- `test/support/fake_catalog_gateway.dart` — `listings`/`deleted` now hold
  `CatalogListing` over `List<FileDetails>`; `addAudio` builds one
  `FileDetails` row carrying metadata and reuses it for both the listing and
  `details[uuid]`; `addFile` wraps its `CatalogFile` in a metadata-less
  `FileDetails`. Added `loadedDetails(List<CatalogFile>)` — a listing of rows
  with no metadata, for the many fixtures that only care about the file half —
  and `listCalls` (see §2). `aFile` itself is unchanged.
- `test/support/fake_core_client.dart` — `filesListResult`'s default JSON
  fixture was still the *old* bare-`File`-array shape used by every widget
  test that exercises the real `CoreCatalogGateway` wiring without a
  `FakeCatalogGateway` override (e.g. `shell_screen_test.dart`). Updated it to
  the `FileView`-array shape. This was the one bug that only showed up under
  the full suite, not under any single catalog-focused test file: with the
  old fixture, every type's listing failed to parse (a bare file object has
  no `"file"` key), so `TypeCountsController`'s map ended up empty, which made
  `HomeDashboard`'s `catalogEmpty` check vacuously true (`{}.every(...)` is
  `true`), which made the dashboard render its "Add Folder" button — which
  happens to share its English string ("Library folders") with the library
  menu's own item, producing a duplicate-widget failure in
  `shell_screen_test.dart` and `shell_menu_bar_test.dart` that had nothing to
  do with either file's own subject matter.
- Fixed several test files that built an audio listing from a bare
  `.file`/`aFile()` (losing metadata) while separately stubbing
  `gateway.details[uuid]` for the old per-file path: `music_metadata_form_test.dart`,
  `rename_file_test.dart`, `delete_record_test.dart`, `audio_player_test.dart`.
  Since naming now comes from the listing row itself, the listing has to
  carry the same `FileDetails` (with metadata) that used to live only in
  `details`.

## Commands run (summary)

- `flutter pub get`
- `dart run build_runner build` — regenerated `catalog_gateway.freezed.dart`
  for the `FileDetails` type change.
- `flutter gen-l10n` — regenerated the localization output after removing
  `musicLoading` from both ARB catalogs.
- `flutter analyze` — clean, no issues, on the final diff (ran repeatedly
  during the work; last run confirmed clean).
- `flutter test test` — 1837 passed, 0 failed, on the final diff.
- `dart format lib test` was run once broadly and reformatted 62 files well
  outside this change's scope (pre-existing formatting drift elsewhere in the
  tree); all of those were reverted with `git checkout --` so the diff stays
  scoped to the files this task actually touches.

## Open items / concerns

- The design's component table didn't mention `home_dashboard.dart`,
  `delete_record_button.dart`, or `missing_files_screen.dart` as callers of
  `audioMetadataProvider`; I updated all three as described above and believe
  that's the intended consequence of §2, but it's worth a second look since
  it wasn't explicitly scoped.
- `test/features/catalog/data/core_catalog_gateway_test.dart` is new — there
  was no existing test file for `CoreCatalogGateway`'s parsing at all before
  this change (its behavior was only exercised indirectly through
  `FakeCoreClient`'s default fixture in unrelated widget tests). I added it
  to give the reused parse — and the "malformed row is unreadable, not
  thrown" and "unknown type is dropped, not failed" behaviors — direct,
  fast, non-widget coverage.
- Section 4 (album cover on the case) is untouched, as instructed.

## Code review response (same day)

Review confirmed the deletions were sound (one-call resolution, no partial
publish, empty distinguishable from failed, FR-CT-13 held end to end,
localization clean) and raised seven findings, all addressed:

- **Finding 1 (Critical)** — `DeleteFileButton` (`lib/features/lifecycle/presentation/delete_record_button.dart`)
  awaited `musicLibraryProvider.future`, which throws on a failed audio
  listing or a rejected session; fired unawaited from `onPressed`, that
  exception escaped and the confirmation dialog never opened. Fixed by
  changing the button to take the `FileDetails` its caller already has
  (`lib/features/catalog/presentation/file_details_view.dart:277`, now
  `DeleteFileButton(details: details)`) and reading
  `MusicMetadata.fromDetails(details.metadata).title` directly — no
  provider, no await, no failure path. Added
  `GivenTheAudioListingHasFailed_WhenADeleteIsAsked_ThenTheConfirmationStillOpens`
  to `test/features/lifecycle/presentation/delete_record_test.dart`, which
  fails the audio listing and asserts the dialog still opens and still names
  the track correctly.
- **Finding 2 (Important)** — `RecentFilesController` and
  `MissingFilesController` mapped their rows to `.file`, discarding the
  metadata already on hand, then `home_dashboard.dart` and
  `missing_files_screen.dart` watched `musicLibraryProvider` to get it back —
  a second whole-audio-library listing for data the first listing already
  had, with "Unknown title" shown until (or if) that second read resolved.
  Both controllers now publish `List<FileDetails>` and both screens read each
  row's own metadata directly, the way `catalog_search_view.dart` already
  did. Neither screen touches `musicLibraryProvider` any more.
- **Finding 3 (Important)** — `TypeCountsController` leaves a failed type out
  of its map rather than counting it as zero, and `byType.values.every(...)`
  on a resulting short (or empty) map is vacuously true — so a core outage
  that fails every listing made the dashboard (and the listing's own empty
  state in `catalog_listing.dart`, which had the identical bug) tell the
  owner their library was empty and offer to register a folder. Both sites
  now additionally require `byType.length == LibraryType.values.length`
  before treating the catalog as empty, so an unread type keeps the ordinary
  (non-first-run) view rather than asserting emptiness it cannot back up.
- **Finding 4 (Minor)** — deleted `_holdDetailsAfter`, `_heldDetails`,
  `holdDetailsAfter`, `holdDetailsFor`, and `releaseDetails` from
  `test/support/fake_catalog_gateway.dart`; none had callers left after the
  N+1 tests they existed for were removed.
- **Finding 5 (Minor)** — rewrote UC-46 main flow step 1 in
  `docs/requirements/Use Case Specification Document.md` from "reads each
  audio file's metadata, showing what it has while the rest arrives" to "reads
  the audio library in one call, metadata included."
- **Finding 6 (Minor)** — `musicEntryForFile` in `music_display_name.dart`
  built the same fallback `MusicEntry` twice (once in `orElse:`, once after
  `??`); now built once and reused.
- **Finding 7 (Minor)** — added a caveat to `FakeCatalogGateway.listCalls`'s
  doc comment: it counts every type requested, not just audio, so it is only
  meaningful for a single-type fixture, and the paired
  `expect(gateway.detailsRequested, isEmpty)` is what actually catches a
  regression to per-file reads.

### Commands run and output (review-fix pass)

```
$ flutter analyze
Analyzing alexandria-ui...
No issues found! (ran in 11.8s)

$ flutter test test
...
01:04 +1838: All tests passed!
```

1838 tests passed (1837 from the first pass, plus the new failed-listing
regression test for Finding 1), 0 failed. `integration_test` was not run,
per instructions.
