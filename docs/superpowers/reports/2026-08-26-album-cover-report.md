# Consuming the richer catalog — album cover report

**Date:** 2026-08-26
**Branch:** feat/consume-richer-catalog
**Scope:** design section 4 only — the case's real cover. Sections 1–3 were
already implemented and are covered by
`docs/superpowers/reports/2026-08-26-richer-catalog-listing-report.md`.

## Summary

The now-playing case now draws the album's own embedded picture when the
core has one, and falls back to the designed jacket — which is now
documented as the *normal* fallback, not a stand-in for cover art the core
"cannot give" — when it does not, when the fetch fails, and while the cover
has not arrived yet. A cover arriving mid-insertion swaps the sleeve without
touching the insertion's animation.

`flutter analyze` is clean and `flutter test` is fully green (1851 tests,
up from 1838 before this task; `integration_test` was not run, per
instructions).

## 1. Wiring `alexandria_file_thumbnail`

- `lib/core/bindings/core_isolate.dart` — new `'fileThumbnail'` case in the
  worker isolate's dispatch, calling `bindings.alexandria_file_thumbnail`,
  mirroring `'comicPage'`.
- `lib/core/bindings/core_client.dart` — `fileThumbnail(String uuid, String
  token)` added to the `CoreClient` interface and its isolate-backed
  implementation, documented with the JSON shape (`{uuid, mimeType,
  bytesBase64}`) taken from `alexandria-ffi/src/lib.rs`'s own doc comment on
  `alexandria_file_thumbnail` — note the field is `bytesBase64`, not
  `bytes`, matching `alexandria_comic_page`'s own convention, not the
  briefing's paraphrase.
- `test/support/fake_core_client.dart` — `fileThumbnail` added with a
  `thumbnailResponse` field, a `thumbnailRequests` log, `failOnFileThumbnail`,
  and a `holdFileThumbnail`/`releaseFileThumbnail` gate (mirroring
  `fake_auth_gateway.dart`'s existing hold/release pattern) for tests that
  need to observe a fetch in flight.

## 2. The gateway

- `lib/features/catalog/domain/catalog_gateway.dart` — new
  `FileThumbnailOutcome` union (`.read({bytes, mimeType})` /
  `.failed({failure})`) and a `fileThumbnail({uuid, credential})` method on
  `CatalogGateway`. The doc comments are explicit that `InvalidInput` (no
  embedded picture) is not distinguished from any other failure — the one
  caller (`AlbumCoverController`) treats the whole `.failed` variant as "show
  the designed jacket."
- `lib/features/catalog/data/core_catalog_gateway.dart` — `CoreCatalogGateway.
  fileThumbnail` implemented the same way `CoreComicGateway.readPage` reads
  `alexandria_comic_page`: `CoreStatusFamily.playback`, base64-decode
  `bytesBase64`, `_unreadableThumbnail()` for every parse/call failure.
- `test/support/fake_catalog_gateway.dart` — `thumbnails` map (keyed by
  uuid, absent = `InvalidInput`, matching the core's own behavior for a file
  with no picture), `thumbnailsRequested` log, and a
  `holdThumbnail`/`releaseThumbnail` gate for the same reason as the core
  client fake.
- Regenerated `catalog_gateway.freezed.dart` via `dart run build_runner
  build`.

## 3. Domain and controller

- `lib/features/playback/domain/album_cover.dart` (new) — `AlbumCover`
  sealed class: `AlbumCoverFetched({image})` and `AlbumCoverDesigned()`. Both
  variants are documented as normal outcomes. `AlbumCoverFetched` does not
  dispose its own image — ownership and lifecycle are the controller's job
  (see below); the domain type just carries the value.
- `lib/features/playback/application/album_cover_controller.dart` (new) —
  `AlbumCoverController extends Notifier<AlbumCover>`. Identifies "the same
  album" with the same `AlbumIdentity` tuple `AlbumAnimationController`
  already uses (imported via a `show` clause rather than duplicated as a
  type, though the identity *function* itself is duplicated — see the class
  doc comment for why). On an identity change, it disposes whatever cover
  was held, resets to the designed jacket, and kicks off one `fileThumbnail`
  fetch for the file the queue was showing at that moment. A `generation`
  counter guards every `await` in the fetch: if the counter has moved on by
  the time the gateway answers, or by the time the decode finishes, the
  answer is discarded (and its image disposed if it got that far) rather
  than clobbering whatever the *current* album's own fetch already decided.
  `lib/features/playback/application/playback_session_activity.dart` now
  also calls `AlbumCoverController.forgetSession()` alongside
  `AlbumAnimationController.forgetSession()`, so a later session's first
  play of the very same album fetches its cover again rather than reusing
  one held from before.
- `lib/core/di/providers.dart` — `albumCoverControllerProvider`.

## 4. The case draws it

- `lib/features/playback/presentation/media/case_painter.dart` —
  `CasePainter` gained an optional `ui.Image? cover`. `_paintFace` draws the
  cover, clipped to the case's `RRect` and fit with `BoxFit.cover` via
  `paintImage`, in place of the flat `sleeve` fill when `cover != null`; the
  lit-edge gradient, outline and typeset title/artist are unchanged either
  way. `shouldRepaint` compares `cover` by `identical`, not `==` (`ui.Image`
  has no value equality), which is also what makes "the same cover, held
  across an unrelated rebuild" a no-repaint rather than a random repaint.
  The class doc comment on `sleeve` was rewritten (the old one implied a
  designed jacket was purely a stand-in "because the core had no picture to
  give it" — now false); `sleeve_design.dart`'s `sleeveIndexFor` doc comment
  was rewritten the same way (it used to say the designed jacket would be
  "replaced wholesale" once the core could answer — also now false, since it
  stays the permanent fallback).
- `lib/features/playback/presentation/stage_layout.dart` — `StageLayout`
  gained an optional `cover` field, threaded straight into `CasePainter`.
- `lib/features/playback/presentation/album_stage.dart` — `AlbumStage`
  gained an optional `cover` field, threaded into `StageLayout`. `AlbumStage`
  does not watch any provider itself (it wasn't a `Consumer*` widget before
  this task, and every other piece of display data — `title`, `artist`,
  `album` — already arrives as a plain value from its caller); the cover
  follows the same pattern rather than converting the widget's whole
  lifecycle to Riverpod for one field.
- `lib/features/playback/presentation/now_playing_screen.dart` — watches
  `albumCoverControllerProvider`, reads the `ui.Image?` out of it (`null` for
  `AlbumCoverDesigned`), and passes it to `AlbumStage`.

## Image lifecycle

`ui.Image.dispose()` must run exactly once, after nothing can paint the
image any longer, and never while it might still be mid-paint. The design:

- **Ownership**: `AlbumCoverController` is the sole owner of every image it
  ever assigns to `_current`. `CasePainter`/`StageLayout`/`AlbumStage` only
  ever read the image; none of them dispose it.
- **Single source of truth for "what's current"**: a private `AlbumCover
  _current` field, updated everywhere the `Notifier`'s own `state` is, and
  read from inside `build()` (where the framework's own `state` getter is
  not yet reliably meaningful — see below).
- **`_disposeCurrent()` is idempotent**: it disposes `_current`'s image if
  it has one, and *always* resets `_current` to `AlbumCoverDesigned()`
  afterward — so a second call (from any of the several places that can
  legitimately call it) is a safe no-op instead of a double-`dispose()`,
  which throws.
- **A `generation` counter guards every `await` boundary** in `_fetch`: the
  gateway call, the decode, and the frame extraction. If the generation has
  moved on by the time any of those resolve, the image (if decoded) is
  disposed immediately and discarded — it was never assigned to `_current`
  and has no other owner.
- **`ref.mounted` guards, not `ref.onDispose`, for "has this been torn
  down"**: this is the one genuine surprise this task turned up. Riverpod 3
  replaces a `Notifier`'s `Ref` on every rebuild, and the *old* ref's
  `onDispose` hooks fire on that replacement — not only at final teardown.
  `AudioPlaybackController` and `VideoPlaybackController` already lean on
  this (their `ref.onDispose(() => unawaited(_statuses?.cancel()))` is safe
  to repeat every rebuild because cancelling an already-cancelled
  subscription is a no-op). Disposing the *held cover* on every rebuild is
  not safe in the same way: a track change within the same album rebuilds
  `AlbumCoverController` (because it watches
  `audioPlaybackControllerProvider`) without the album changing, and the
  whole point of the design is that this rebuild leaves the cover alone. A
  first attempt that registered `ref.onDispose(_disposeCurrent)` once (via a
  guard flag) reproduced exactly this bug in a test: `.next()` within the
  same album silently wiped the already-fetched cover back to the designed
  jacket, with zero extra gateway calls (confirmed by a debug trace —
  `ONDISPOSE firing current=Instance of 'AlbumCoverFetched'` printed
  *between* the two `BUILD` calls for the same identity). The fix was to
  stop using `ref.onDispose` for this purpose entirely: the image is now
  only ever released where the code can prove that's correct — a genuine
  identity change in `build()`, a fetch that lost the generation race in
  `_fetch`, or the session ending via a new `forgetSession()` method (called
  from `PlaybackSessionActivity.end`, exactly the way
  `AlbumAnimationController.forgetSession` already is). `ref.mounted` checks
  after each `await` in `_fetch` are what stop a fetch from touching `ref`
  or `state` after real disposal (container torn down, or a future Riverpod
  path that does dispose this ref) — that's the documented Riverpod 3
  pattern for exactly this ("check `ref.mounted` after async gaps").
- **`ref.keepAlive()`**, called on every `build()`, keeps the provider from
  being paused/disposed just because `NowPlayingScreen` (its only consumer)
  isn't currently mounted — which happens far more often than the album
  itself changes, since the persistent playback bar keeps audio running with
  the full player closed. Without it, closing and reopening the full player
  for a still-playing album would needlessly refetch (or, worse, risk the
  provider being disposed mid-fetch — this reproduced too, as `Cannot use
  the Ref of NotifierProvider<AlbumCoverController, AlbumCover> after it has
  been disposed` in an early test run, before `keepAlive()` was added).

## Testing

New/changed test files:

- `test/features/playback/presentation/media/case_painter_test.dart` — a new
  golden (`goldens/case-vinyl-cover.png`, described below), a `shouldRepaint`
  pair (`GivenACoverArrivesInPlaceOfNone_ThenItRepaints` /
  `GivenTheSameCoverInstanceIsRebuilt_ThenItDoesNotRepaint`).
- `test/features/playback/presentation/album_stage_test.dart` — `staged()`
  gained optional `cover`/`onInserted` parameters; a new group "a cover
  arriving mid-insertion" with
  `GivenAnInsertionUnderWay_WhenACoverArrives_ThenItDoesNotRestartTheInsertion`
  (samples the case's own painted opacity mid-insertion, rebuilds with a
  cover and *zero* elapsed time, and asserts the opacity is unchanged — a
  restarted insertion would read as `0`, not the sampled value — then lets
  the same insertion run to completion and checks `onInserted` still fires
  exactly once) and
  `GivenACoverArrives_WhenTheCaseIsRepainted_ThenItPaintsTheCover` (asserts
  the live `CasePainter`'s `cover` field is the same instance passed in).
- `test/features/playback/application/album_cover_controller_test.dart`
  (new) — 8 cases: fetched cover, `InvalidInput` (no fixture), an explicit
  gateway failure, "not arrived yet" (using the fake's hold/release gate),
  no refetch on the same album's next track (asserts both the gateway call
  count *and* `same()` identity of the returned `AlbumCover`), the designed
  jacket showing again immediately when a different album starts (before its
  own fetch could possibly have answered), a stale-fetch-discarded race
  (`GivenAnAlbumChangesWhileItsFetchIsStillPending_WhenTheStaleFetchAnswers_ThenItsAnswerIsDiscarded`
  — two albums' fetches held behind the same gate, released together;
  asserts the *later* album's answer wins regardless of resolution order),
  and a "forgetSession" case for the sign-out reset.
- `test/support/fake_core_client.dart`, `test/support/fake_catalog_gateway.dart`
  — see §1/§2 above.

A real fixture image (not a stand-in): `testPictureBytes()` in the
controller test and `_testCover()` in the widget tests render a small
`Picture` and convert it to a genuine PNG/raw image via `toImage()` — real
bytes `ui.instantiateImageCodec` can actually decode, rather than an
arbitrary byte string it would just as validly reject; the point of the
"fetched" tests is that decoding really happens.

**Golden**: `goldens/case-vinyl-cover.png` deliberately uses an
unmistakable green `sleeve` colour that the cover (an orange/blue split)
completely covers — the golden is what proves the image, not the flat
sleeve fill, is what actually painted. Looked at it directly: the
orange/blue rectangle fills the whole jacket, the lit top edge and outline
are still visible over it, and the title/artist text is legible on top,
unchanged from the no-cover goldens. The three existing goldens
(`case-vinyl.png`, `case-tape.png`, `case-disc.png`) are byte-identical to
before — confirmed via `git status`, since `cover: null` runs the exact same
draw calls as before this task.

## Design gaps closed by judgment call

- **Where the fetch call lives**: the design's Components table lists
  `catalog_gateway.dart` as gaining "a thumbnail call" without saying
  whether it belongs on `CatalogGateway` (alongside `fileDetails`,
  `renameFile`, etc.) or a new, narrower interface. Put it on
  `CatalogGateway`: it is a query about one file, exactly like
  `fileDetails`, and adding a second small gateway interface for one method
  seemed like unwarranted ceremony given `CoreComicGateway` already
  demonstrates the alternative (a dedicated gateway) exists in this codebase
  for cases where more than one method would cluster around it.
- **Where `AlbumStage` gets the cover from**: the design's prose says
  "`AlbumStage` asks the core for the current album's thumbnail," which
  reads as `AlbumStage` itself watching a provider. The Components table,
  however, lists no change to `album_stage.dart`, and every other piece of
  display data (`title`, `artist`, `album`) already arrives as a plain
  value from `NowPlayingScreen`. Kept `AlbumStage` a plain (non-`Consumer`)
  widget and had `NowPlayingScreen` do the watching, for consistency with
  its existing shape and to avoid widening `album_stage_test.dart`'s blast
  radius (converting it to `ConsumerStatefulWidget` would have required
  wrapping every existing test in a `ProviderScope`).
- **FR-PL-07 wording**: added one sentence to
  `docs/requirements/System Requirements Document.md`'s FR-PL-07 describing
  the cover/designed-jacket behavior, per the design's "Requirements impact"
  section. Left UC-21 itself untouched — its main/alternative flows don't
  mention the designed jacket at all today, so there was nothing there that
  had gone false.

## Concerns

- The `ref.onDispose`-fires-on-every-rebuild behavior (see "Image
  lifecycle" above) is a Riverpod 3 semantic that is easy to get wrong
  silently — it only failed a test, not `flutter analyze`, and the failure
  mode (a cover quietly reverting to the designed jacket on every track
  change) would have been very easy to miss without a test that plays a
  second track of the same album and checks `same()` identity rather than
  just "is it still `AlbumCoverFetched`". Worth flagging for review: this is
  the second controller-with-cleanup this codebase has (after
  `AudioPlaybackController`/`VideoPlaybackController`'s stream-cancel
  hooks), and the safe idiom here (own explicit `forgetSession`-style
  method, called from `SessionActivity`, rather than `ref.onDispose`) is
  worth keeping in mind for any future controller that holds a disposable
  resource tied to "the same X keeps being true," not to "this build
  happened."
- `AlbumCoverController._identityOf` duplicates
  `AlbumAnimationController._identityOf` rather than sharing it (documented
  in the class doc comment as a deliberate choice, given the two are
  independent `Notifier`s with no natural place to hold one shared copy).
  If a third controller ever needs the same "which album is this" concept,
  it would be worth extracting a shared free function at that point.

## Review follow-up (code review pass)

Six findings came back from review. All addressed:

- **Finding 1 (Important) — text was printed on top of the fetched cover.**
  `case_painter.dart`'s `paint()` now only calls `_paintText` when
  `cover == null` — the embedded cover and the designed jacket are
  alternatives, not a base plus an overlay. Regenerated
  `goldens/case-vinyl-cover.png` and looked at it: the orange/blue split
  fills the whole jacket with no text on it; the lit edge and outline are
  still drawn over it (see below for the command output confirming only
  this one golden changed).
- **Finding 2 (Important) — `CoreCatalogGateway.fileThumbnail` had no
  test.** Added four cases to `test/features/catalog/data/core_catalog_gateway_test.dart`:
  a good read (asserts the decoded bytes), `PLAYBACK_ERR_INVALID_INPUT`
  (asserts `InvalidInputFailure`, not merely "failed"), malformed JSON
  (`bytesBase64` missing), and the call throwing `CoreCallException`.
  Re-verified the wire key directly against
  `D:\Repositories\alexandria-api\crates\alexandria-ffi\src\lib.rs`
  (`alexandria_file_thumbnail`, around line 903): the core serializes
  `{"uuid":…, "mimeType":…, "bytesBase64":…}` — **`bytesBase64`**, matching
  what the shipped code already used and what the doc comment on
  `alexandria_file_thumbnail` in `alexandria_bindings.dart` says, not the
  `bytes` the original task brief paraphrased it as.
- **Finding 3 (Important) — the "it paints the cover" test couldn't fail
  for that reason.** Rewrote
  `GivenACoverArrives_WhenTheCaseIsRepainted_ThenTheCanvasDrawsTheCoverImage`
  in `album_stage_test.dart` to use flutter_test's `paints` recording-canvas
  matcher (`paints..drawImageRect(image: cover)`) instead of reading
  `painter.cover` — it now fails against a `_paintFace` that ignores
  `cover`, proving actual painted output rather than field-passing, and
  runs unconditionally (not gated behind `goldensAreComparable`).
- **Finding 4 (Minor) — nothing releases the image at real teardown.**
  Left the behavior as is (Riverpod 3 has no once-only "provider is truly
  gone" hook for a `Notifier` compatible with also holding state across
  ordinary rebuilds — see the class doc's own explanation of why
  `Ref.onDispose` can't be used here) and added a "Known gap" paragraph to
  `AlbumCoverController`'s class doc naming it explicitly: the whole
  container going away (app shutdown, or a test's `container.dispose()`)
  leaks whatever cover was last held. Harmless at real shutdown; a real,
  bounded (one image) leak in a long-lived test container that never signs
  out.
- **Finding 5 (Minor) — `mimeType` was required and never read.** Dropped
  the field from `FileThumbnailOutcome.read` entirely and from the JSON
  parse in `core_catalog_gateway.dart`; a picture with no `mimeType` (or any
  `mimeType`) no longer fails to decode on that account alone —
  `ui.instantiateImageCodec` sniffs the format from the bytes regardless.
  Regenerated `catalog_gateway.freezed.dart`.
- **Finding 6 (Minor) — unused `FakeCoreClient.fileThumbnail` scaffolding.**
  `thumbnailRequests`, `holdFileThumbnail`/`releaseFileThumbnail` had no
  callers even after Finding 2's tests (those exercise the gateway
  directly over a plain response, not a race) — deleted all three, along
  with the now-unused `dart:async` import. `thumbnailResponse` and
  `failOnFileThumbnail` stayed, since Finding 2's tests use both.

### Verification

```
$ flutter analyze
Analyzing alexandria-ui...
No issues found! (ran in 95.7s)

$ flutter test
...
01:15 +1855: All tests passed!
```

1855 tests (up from 1851 before this follow-up — the four new
`fileThumbnail` gateway cases from Finding 2), 0 failing.
`integration_test` was not run, per instructions.

```
$ git status --porcelain test/features/playback/presentation/media/goldens/
 M test/features/playback/presentation/media/goldens/case-vinyl-cover.png
```

Only the cover golden changed; `case-vinyl.png`/`case-tape.png`/`case-disc.png`
(the no-cover path) are untouched, confirming Finding 1's fix only affects
the cover-present branch.
