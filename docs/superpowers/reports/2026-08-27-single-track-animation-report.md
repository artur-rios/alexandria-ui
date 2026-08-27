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

## Review round 2: six findings addressed

The coordinator's review found six issues. All six are fixed, verified,
and covered by tests below.

### Finding 1 (Important) — the sleeve jacket colour

`now_playing_screen.dart`'s `album:` argument to `AlbumStage` (feeds
`sleeveIndexFor`) now reads:

```dart
album: state.queue.label ?? musicEntryForFile(ref, current).album,
```

The queue's own label for an album/artist queue, unchanged; for a track
queue (where the label is always `null`), the current track's own raw
`album` tag from `MusicEntry` — never `musicAlbumForFile`'s localised
"Unknown album" fallback, which would have made the jacket hue depend on
the interface language and collapsed every untagged track onto the same
hue as a genuinely-named "Unknown album". `null` either way still reaches
`sleeveIndexFor`'s own "no name" case. `musicEntryForFile` was already in
scope via the existing `music_display_name.dart` import.

### Finding 2 (Important) — the two controllers' identities now share one function

`AlbumAnimationController`'s record resolution (`_recordOf`, private) is
now a top-level function `recordOf(PlaybackQueue queue, MusicLibrary?
library)` in `album_animation_controller.dart`, returning `({String
identity, int? year})`. `AlbumCoverController._identityOf` now calls it
directly (`(queue.kind, recordOf(queue, library).identity)`) instead of
carrying its own hand-copied `(queue.kind, queue.label ?? tracks.first.uuid)`.
Both controllers' doc comments were rewritten to say they share this
function rather than "mirror" or "duplicate" it. `AlbumCoverController.build()`
now watches `musicLibraryProvider` under the same condition
`AlbumAnimationController.build()` does.

**A real bug surfaced while wiring this up and fixing it took most of
this round's time.** My first pass watched `musicLibraryProvider` in
`AlbumCoverController.build()` whenever `queue.kind == QueueKind.track` —
but `PlaybackQueue.empty`'s own `kind` is `QueueKind.track` (it has to
pick something, and `track` is what `PlaybackQueue.empty`'s constructor
uses). `PlaybackSessionActivity.end()` reads
`albumCoverControllerProvider.notifier` — which triggers this
controller's very first `build()` — as part of `SessionController.establish()`'s
opening "wind down every activity" loop, which runs *before* the session
is set active. That first build watched `musicLibraryProvider` with
`credential == null`, permanently caching `MusicLibrary.empty`: nothing
ever re-triggers `MusicLibraryController.build()` afterward, since
nothing invalidates it once cached. Two of the `album_animation_controller_test.dart`
tests I had written in round 1 (`GivenATrackOfAnAlbumIsPlaying_...` and
`GivenATrackHasItsOwnYear_...`) started failing once `AlbumCoverController`
started reading the same provider — they had been silently relying on
being the *first* reader of `musicLibraryProvider` in their container.
Fixed by checking `!queue.isEmpty` before the library watch/read, in
*both* `AlbumCoverController.build()` and, defensively,
`AlbumAnimationController.insertionShown()` (which has the identical
"empty queue defaults to `QueueKind.track`" hazard, even though nothing
calls it with an empty queue today). `AlbumAnimationController.build()`
itself was already safe — `!queue.showsAlbumAnimation` (which is
`tracks.isEmpty`) returns early before the library watch.

Added a `group('a track queue (Finding 2)', ...)` to
`album_cover_controller_test.dart` with two tests reproducing the exact
scenario the finding describes: playing track 2 of an album via
`playTrack` (not `playAlbum`) does not re-fetch the cover, and playing a
track of a *different* album does swap it back to the designed jacket.
Both explicitly `await container.read(musicLibraryProvider.future)`
after each `playTrack` — matching the realistic case (the Songs list a
track was tapped from cannot be showing without the library already
loaded) and avoiding a related but separate race: since `playTrack`
never awaits the library itself, a `build()` running before it resolves
computes a uuid-fallback identity that would then change (and spuriously
re-trigger a fetch) the moment the library actually loads behind it.
That race is pre-existing to this design (it would equally affect
`AlbumAnimationController`'s `owedIdentity` for a track queue played
before the library has loaded even once this session) and is noted here
rather than fixed, since it requires the library to not already be
loaded, which cannot happen in practice for a track played from the
Songs list, search results, or a file's own details.

### Finding 3 (Important) — stale AF-02 reasoning in doc comments

`shell_screen.dart`'s `ref.listen` comment ("No separate AF-02 check
here...") rewritten to say the auto-open reads the same `owedIdentity`
edge for every queue kind, track included. `playback_bar.dart`'s comment
("AF-02 is about the animation, not about the player") rewritten to say
the full player shows the animation for a lone track exactly as it does
for an album or an artist.

### Finding 4 (Important) — renumbered alternative-flow ids

Fixed every UC-21-specific reference the finding named:
`album_stage.dart:141` and `album_visor.dart:59` (reduced motion, now
AF-03 not AF-04), `now_playing_screen.dart:20` (navigating away, now
AF-02 not AF-03), and `now_playing_screen_test.dart`'s file header and
its comments at (now-shifted) lines 34, 260, 529, 812, 883, plus
`album_stage_test.dart`'s `group('reduced motion (AF-03)', ...)`. Also
searched the rest of `lib/features/playback` and `lib/features/shell`
for any other `AF-0[3-5]` that might be UC-21's; every other hit belongs
to a different use case (UC-19, UC-20, UC-33, UC-38, UC-39) and was left
alone.

### Finding 5 (Minor) — the NUL byte separator

`recordOf`'s album/artist join is now `'$album ${entry.artist ?? ''}'`
— joined with a plain ASCII space character, not the NUL-byte escape it
used before. (Writing the replacement required going through Python
directly at one point: the Read tool renders a Dart NUL-byte source
escape visually as an ordinary space, and copying that rendering back
out via the Edit tool produced a literal NUL byte in the file rather
than the escape sequence itself — caught because `grep` started
reporting the file as binary. Worth knowing about if this comes up
again: never copy a `Read` result that renders as a plain space next to
a backtick-quoted separator verbatim into a new edit; retype the escape
by hand instead.)

### Finding 6 (Minor) — three consecutive tracks, not two

`libraryGateway()` in `album_animation_controller_test.dart` now adds a
third "Kind of Blue" track (`kob-3`, track 3). The renamed test
`GivenATrackOfAnAlbumIsPlaying_WhenTwoMoreTracksOfTheSameAlbumStartFromTheSongsList_ThenNoInsertionIsOwed`
plays `kob-1`, `kob-2`, `kob-3` via `playTrack` in sequence, asserting
`insertionOwed` is `false` after both the second and the third.

## Commands run for round 2 (final)

```
flutter analyze
  → No issues found!

dart format --set-exit-if-changed <every file this round touched>
  → 11 files, 0 changed (clean)

flutter test test/features/playback/application/album_animation_controller_test.dart
  → 16 tests, all pass

flutter test test/features/playback/application/album_cover_controller_test.dart
  → 10 tests, all pass (2 new, both for Finding 2)

flutter test test/features/playback test/features/shell
  → 440 tests, all pass

flutter test
  → 1879 tests, all pass
```

Files touched in round 2:
`lib/features/playback/application/album_animation_controller.dart`,
`lib/features/playback/application/album_cover_controller.dart`,
`lib/features/playback/presentation/album_stage.dart`,
`lib/features/playback/presentation/album_visor.dart`,
`lib/features/playback/presentation/now_playing_screen.dart`,
`lib/features/shell/presentation/playback_bar.dart`,
`lib/features/shell/presentation/shell_screen.dart`,
`test/features/playback/application/album_animation_controller_test.dart`,
`test/features/playback/application/album_cover_controller_test.dart`,
`test/features/playback/presentation/album_stage_test.dart`,
`test/features/playback/presentation/now_playing_screen_test.dart`.

Two files (`album_visor.dart`, `album_stage_test.dart`) show a larger
diff than the one-line change I made to each: this environment's
`dart format` reformats the whole file on any touch, and disagreed with
how those two files were previously formatted (unrelated to this
change — likely a `dart_style` version difference). One of those
reformats also turned a single-line `if` without braces into a
multi-line one, which `flutter analyze` then flagged
(`curly_braces_in_flow_control_structures`); fixed by adding braces
rather than fighting the formatter. Every other file's diff is exactly
the intended edit, verified with `git diff` per file before finalizing.
