# Report: the animation for a single track

**Date:** 2026-08-27
**Branch:** fix/single-track-animation
**Design:** `docs/superpowers/specs/2026-08-27-single-track-animation-design.md`

## Summary

Playing a single track from the Songs list (or a track's context menu)
now shows the album animation and opens the full player, exactly like
playing an album or an artist. Three tracks of one album played back to
back — even via `playTrack`, one at a time — insert the record once; a
track from a different album, or a second untagged track, inserts again.
A track's own year picks its medium instead of always falling back to a
compact disc, and the fallback (a disc with the designed jacket) still
applies when the music library has not loaded or does not hold the
track.

## TDD: the first test and its failure

The first test written was the owner's exact symptom, in
`test/features/playback/presentation/now_playing_screen_test.dart`:

```
GivenOneTrackPlays_WhenItStarts_ThenTheAnimationShowsAndThePlayerOpens
```

Run before any implementation change:

```
flutter test test/features/playback/presentation/now_playing_screen_test.dart \
  --plain-name "GivenOneTrackPlays_WhenItStarts_ThenTheAnimationShowsAndThePlayerOpens"
```

Failed as expected:

```
Expected: exactly one matching candidate
  Actual: _TypeWidgetFinder:<Found 0 widgets with type "NowPlayingScreen": []>
   Which: means none were found but one was expected
```

confirming the exact bug reported: nothing opened the player for a lone
track. After the fix (below), the same test passes, along with the rest
of the suite (1877 tests).

## Changes, by file

### `lib/features/playback/domain/playback_queue.dart`

`showsAlbumAnimation` no longer excludes `QueueKind.track`:

```dart
bool get showsAlbumAnimation => tracks.isNotEmpty;
```

Doc comments on `kind` and `showsAlbumAnimation` rewritten — they used to
assert "one track is not a record" (UC-21 AF-02), which is now false.

### `lib/features/playback/application/music_library_controller.dart`

Added `MusicLibrary.entryFor(CatalogFile file)` — the uuid lookup that
used to live only in `music_display_name.dart`'s `musicEntryForFile`,
lifted here so both the presentation layer and the application-layer
`AlbumAnimationController` share one lookup instead of two copies:

```dart
MusicEntry entryFor(CatalogFile file) => entries.firstWhere(
  (candidate) => candidate.file.uuid == file.uuid,
  orElse: () => MusicEntry(file: file, metadata: const MusicMetadata()),
);
```

### `lib/features/playback/presentation/music_display_name.dart`

`musicEntryForFile` now delegates to `MusicLibrary.entryFor` instead of
duplicating the `firstWhere`/fallback logic.

### `lib/features/playback/application/album_animation_controller.dart` (the core fix)

`build()` and `insertionShown()` now resolve a `_recordOf(queue, library)`
record — `({String identity, int? year})` — instead of reading the
queue's own `label`/`year` unconditionally:

- For an album or artist queue: unchanged — `queue.label ?? tracks.first.uuid`
  for identity, `queue.year` for the year.
- For a track queue: the current track's entry, read via
  `MusicLibrary.entryFor`, watched through `musicLibraryProvider` (`ref.watch`
  in `build()`, `ref.read` in `insertionShown()` — only `build()` may
  `ref.watch`). The identity is the track's own uuid when it carries no
  album tag (the untagged rule `music_grouping.dart`'s `albumOf` already
  states), or `'$album<sep>$artist'` when it does — the separator joins them
  because no tag can carry it, so no album/artist pair can collide with a
  different one once joined. The year is `entry.metadata.year`.

`musicLibraryProvider` is watched conditionally — only when
`queue.kind == QueueKind.track` — so an album or artist queue's own
reactivity is untouched, matching the design's "an album or artist queue
keeps using the queue's own label and year exactly as it does now."

`playTrack` itself (`audio_playback_controller.dart`) was **not**
touched — it still builds a bare `PlaybackQueue(tracks: [file], kind:
QueueKind.track)` with no library read, so a track stays playable when
the library listing has failed. All the new resolution happens in
`AlbumAnimationController`.

### `lib/features/playback/presentation/now_playing_screen.dart`

Doc-only change: the comment claiming `AlbumAnimationState.medium` is
`null` "for a single track (AF-02)" was rewritten to say "for an empty
queue" — the AF-02 exclusion it described no longer exists. No logic in
this file changed; `title`/`artist` passed to `AlbumStage` were already
`musicAlbumForFile`/`musicArtistForFile` (resolved from the current
track regardless of queue kind), so they needed no change. `album:
state.queue.label` (which feeds the case's jacket-colour hash) stays as
is per the design's component table ("Nothing else"): for a track queue
it stays `null`, so every untagged/track case gets the same "untitled"
jacket hue — a cosmetic detail, not covered by the design's testing list,
and out of the stated scope.

## Requirements updated

- **UC-21** (`docs/requirements/Use Case Specification Document.md`):
  Description, Preconditions and main flow step 1 changed from "album or
  artist" to "audio playback"/"a track, an album, or an artist." AF-02
  ("A single track is played... compact player used") removed; the old
  AF-03/AF-04/AF-05 renumbered to AF-02/AF-03/AF-04.
- **FR-PL-07** (`docs/requirements/System Requirements Document.md`):
  "on the session's first album or artist play and whenever the album or
  the artist changes" → "on the session's first audio play and whenever
  the record playing changes."
- `lib/core/l10n/app_en.arb`: the `audioClosePlayer` description cited
  "UC-21 AF-03" (the pre-renumbering id for "owner navigates away");
  updated to "UC-21 AF-02" and regenerated
  `lib/core/l10n/generated/app_localizations.dart` via `flutter gen-l10n`
  (one-line diff, the doc comment only — no ARB value changed, so no
  translatable string was touched).

## Tests: what encoded the old rule, and what happened to it

`test/features/playback/presentation/now_playing_screen_test.dart`:

- Group **"a single track"** (was "AF-02: a single track is not a
  record"): the two tests asserting `find.byType(AlbumStage), findsNothing`
  for a played track were replaced. First test is now the owner's exact
  symptom (see above); second confirms the transport still works when
  the animation is off (manual open, no auto-open race).
- **`GivenALoneTrackStarts_WhenItPlays_ThenThePlayerDoesNotOpenItself`**
  (in the "opening itself for an owed insertion" group): its premise —
  "Finding 4: ... a lone track owes no insertion at all" — is now false.
  Rewritten to `GivenALoneTrackStarts_WhenItPlays_ThenThePlayerOpensItself`,
  asserting the opposite.
- **`GivenALoneTrackPlayedFirst_WhenAnAlbumIsStarted_ThenThePlayerOpensItself`**:
  its premise — "nothing shows a stage for a lone track, so
  `AlbumStage.onInserted` never fires, so the flag stuck true" — is also
  false now (a lone track draws a stage like anything else). Renamed to
  `...WhenAnAlbumStarts_ThenThePlayerOpensItselfAgain` and rewritten to
  acknowledge the track's own insertion and close the player before
  playing the album, so the album's insertion is a fresh edge rather than
  a leftover stuck flag — preserving the original scenario's shape while
  matching the new rule.
- Doc comments referencing AF-02/the old exclusion (file header,
  `playSomething`'s doc comment) rewritten to stop asserting it.

`test/features/playback/application/album_animation_controller_test.dart`:
Added a new `group('a track queue', ...)` with six tests covering the
design's testing checklist for track queues specifically (these didn't
exist before, since a track queue never reached this code path under the
old rule):

- `GivenNothingHasPlayed_WhenALoneTrackStarts_ThenAnInsertionIsOwedAndThereIsAMedium`
- `GivenATrackOfAnAlbumIsPlaying_WhenAnotherTrackOfTheSameAlbumStartsFromTheSongsList_ThenNoInsertionIsOwed`
- `GivenATrackIsPlaying_WhenATrackFromADifferentAlbumStartsFromTheSongsList_ThenAnInsertionIsOwed`
- `GivenAnUntaggedTrackIsPlaying_WhenADifferentUntaggedTrackStartsFromTheSongsList_ThenAnInsertionIsOwed`
- `GivenATrackHasItsOwnYear_WhenItStartsFromTheSongsList_ThenItsOwnYearPicksTheMedium`
  (uses "Kind of Blue", 1959 — asserts `AlbumMedium.vinyl`, which only
  happens if the track's own year was read; `queue.year` is `null` for a
  track queue, which `mediumFor` would otherwise answer `disc` for)
- `GivenTheLibraryHasNotLoaded_...` / `GivenTheLibraryDoesNotHoldTheTrack_...`
  (both assert the disc fallback — the former by never awaiting
  `musicLibraryProvider.future`, the latter by awaiting it over a uuid
  the gateway never listed)

One thing worth flagging while writing these: `playAlbum`/`playArtist`
internally `await ref.read(musicLibraryProvider.future)`, so pre-existing
tests never needed to await it themselves. `playTrack` does not, so the
two tests whose assertions depend on the library being loaded
(same-album continuity, own-year medium) needed an explicit
`await container.read(musicLibraryProvider.future);` after `playTrack` —
without it they read the library mid-load and got the null-library
fallback instead, which is exactly what surfaced as two initially-red
tests before I added the await (a useful confirmation that the identity
really was library-driven, not accidentally always matching).

## Commands run and results

```
flutter test test/features/playback/presentation/now_playing_screen_test.dart
  → 27 tests, all pass (was 1 red before the fix, as shown above)

flutter test test/features/playback/application/album_animation_controller_test.dart
  → 16 tests, all pass

flutter test test/features/playback
  → 241 tests, all pass

flutter test
  → 1877 tests, all pass

flutter analyze
  → No issues found!

dart format --set-exit-if-changed <every file this change touched>
  → 7 files, 0 changed (clean)
```

## Concerns

- **Jacket colour for a track queue stays "untitled."** `now_playing_screen.dart`
  passes `album: state.queue.label` to `AlbumStage` for the case's
  jacket-colour hash (`sleeveIndexFor`), which stays `null` for every
  track queue since `playTrack` never sets a label. The design's
  Components table restricts changes to `playback_queue.dart` and
  `album_animation_controller.dart` ("Nothing else"), and its own testing
  list only asks that "the case shows the track's album and artist" —
  which it already does, since `title`/`artist` were already resolved
  per-track before this change and needed no fix. I left this alone per
  that explicit scope, but it means two different tracks played from the
  Songs list will show the same "untitled" jacket hue rather than
  colours derived from their own albums, even though the animation's
  *identity* (which record it is) is now correctly per-track. Worth a
  follow-up if that visual distinction turns out to matter.
- **Separator choice for the track identity** (`'$album<sep>$artist'`)
  is a private implementation detail with no test asserting the exact
  string — only the resulting equality/inequality is tested, which is
  the right level, but flagging the choice in case a reviewer wants a
  different join strategy.
