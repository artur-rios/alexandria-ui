# Design: The indexing experience

**Date:** 2026-08-23
**Status:** Approved, ready for implementation planning
**Tracks:** Extends existing capability areas — Library Sources (LB) and
Shell/UX (UX). Consumes the core surface delivered by
`alexandria-api#114`.

## Context

The core can now do things the interface cannot show. `alexandria-api#114`
replaced full-file hashing with `(size_bytes, mtime)` change detection, so a
418 GB library costs 12,264 stat calls rather than 418 GB of reads; it added
live run progress, pause, resume, cancel, a `normal`/`low` run priority
choosable at start and on each resume, and a query for every outstanding run.
None of it is reachable from this application.

What the owner sees today, on the same library: a spinner. Adding a folder
does not index it — a second, separate click does. Leaving the library
sources screen hides the fact that a scan is still running. There is no way
to stop a scan and pick it up later, so closing the application means
starting over. And the window's title bar reads `alexandria_desktop`.

This design covers all of it. It is the front-end half of the work; the core
half is `alexandria-api`'s
`docs/superpowers/specs/2026-08-21-indexing-progress-and-scale-design.md`.

## Decisions

1. **The core answers "what is running?", not this application.**
   `IndexRunsController` records a `lastRunId` per registered source and reads
   each back at launch to reconstruct the picture. The core now answers that
   question directly, across every run at once, with
   `alexandria_index_runs_active_json`.

   A new `ActiveRunsController` owns the global view and becomes the
   launch-time source of truth; `IndexRunsController` keeps its per-folder job
   on the sources screen and stops guessing. Two components holding separate
   opinions about what is running is the bug class that consumed most of the
   core work, and it is not worth reproducing here.

2. **Progress appears in a strip above the playback bar, not inside it.**
   `PlaybackBar` is persistent and fixed at 64 pixels, and its documentation
   says why: it holds the bottom "from the first frame so the content area
   above it never changes height when a track starts."

   A new `BackgroundActivityStrip` sits between the content row and the
   playback bar, at zero height when nothing is running and animating to about
   40 when something is. This does reflow the content area — but only in
   response to a scan the owner just started, which is a moment they caused
   and expect feedback from. Folding indexing into the playback bar was
   considered and rejected: one bar doing two unrelated jobs is cramped at the
   640-pixel minimum window and puts track information in competition with
   progress.

3. **The strip tells the truth about the phase it is in.**
   A run in `discovering` has no `total`, so the strip shows an indeterminate
   bar and "Scanning folders…" — no percentage, no estimate. Only
   `processing` gets a determinate bar, counts, and a time remaining.

   Inventing a percentage during discovery would be the easiest way to make
   this feature feel dishonest.

4. **A time estimate is withheld until it is stable.**
   Rate is `Δprocessed / ΔactiveMillis` over a trailing window of poll
   samples; remaining is `(total − processed) / rate`. `activeMillis`
   excludes paused stretches, which is the reason the core reports it rather
   than leaving the client to subtract wall time.

   The strip shows no estimate at all until the window holds enough samples to
   be steady. A number that swings between "2 minutes" and "40 minutes" is
   worse than no number, and this is the single most likely way for the
   feature to read as broken.

5. **A paused run keeps the strip on screen, which is also the resume offer.**
   The core's startup reconciliation leaves an interrupted run `paused` rather
   than lost, and nothing resumes by itself. When `listActiveRuns` returns a
   paused run at launch, the strip simply appears in its paused state —
   "Paused — 8,412 of 12,264" with a resume button.

   No modal. The offer is impossible to miss and impossible to trigger by
   accident, and it costs no separate surface.

6. **Completion dismisses itself; failure does not.**
   A finished run shows its outcome for a few seconds and the strip slides
   away. A failed run stays until dismissed. A failure that vanishes unseen is
   worse than a strip that lingers.

7. **Several runs collapse to one aggregate row.**
   The strip shows one row. With more than one active run it reports the
   aggregate ("Indexing 3 folders — 12,004 of 31,200") and its controls
   collapse to a single action opening the library sources screen, where each
   run has its own controls. Stacking rows would reflow the content area
   proportionally to how much work is queued, which is the wrong thing to
   scale.

8. **Registering a folder indexes it.**
   `LibrarySourcesController.registerFolder` returns `void` today; it returns
   the registered `LibrarySource?` instead — null when the owner cancelled or
   the folder was refused. The screen chains registration to `startIndex`.

   The chain lives in the presentation layer so that neither controller
   acquires a dependency on the other: registration and runs stay separately
   testable, which is what they are.

9. **Three operations, three names.**
   Indexing a folder walks a root for new files. Refreshing re-checks every
   cataloged path for changes and disappearances. Rescanning is indexing a
   folder again. Today's labels blur them.

   The per-folder button becomes **Rescan** — its remaining job now that first
   add is automatic — and the catalog-wide action becomes **Re-check
   library**.

10. **The priority toggle works mid-run, and says what it costs.**
    The core cannot re-pace a running segment: priority is fixed while a
    segment walks, and changing it means pause, then resume with a new
    priority. Resume resets the segment — `processed` to zero, `total` to
    null, phase back to discovering — so the progress bar visibly returns to
    zero and re-climbs.

    The toggle stays available on a running scan, because the moment an owner
    wants low priority is precisely while a scan is hammering the disk. The
    strip states what happened ("Re-checking from the start at low speed") so
    the reset reads as expected rather than as lost work. The re-walk is fast:
    already-cataloged entries fall out in seconds.

11. **The rail's two actions are made to look like what they are.**
    The complaint is presentation, not location, so both stay in
    `NavigationRail.trailing`. A `_RailAction` widget renders each with the
    icon-and-label treatment destinations get, following the breakpoint rules
    the panel already computes: icon and tooltip at the minimum window, label
    beneath at medium, label beside once extended. A divider separates them
    from the destinations.

    The anonymous `Icons.widgets_outlined` becomes a labelled **Library**
    entry with a disclosure chevron — visibly a thing that opens rather than a
    place you go — and preferences becomes a labelled **Preferences** entry.

12. **The tools menu gains structure, not promotion.**
    Its six screens keep their existing order, which the code records as
    deliberate, running "from filling the library to reviewing what has left
    it". They gain section headings: **Library** (sources, collections),
    **Tracking** (watchlists, reading lists), **Review** (deleted items,
    missing files).

    They are not promoted into the rail. FR-UX-02 forbids dropping an entry at
    any breakpoint, and the panel is already nine destinations tall at the
    640-pixel minimum; six more would force it to scroll, which is the problem
    the menu was introduced to solve. The complaint is legibility, and labels
    with headings address it without reopening a settled constraint.

13. **`alexandria_desktop` is retired everywhere, in its own commits.**
    See the mapping below. The 754 mechanical import rewrites land separately
    from the feature work — in one diff they would make both unreviewable.

14. **Every folder row carries the controls its own state affords.**
    A row whose run is in flight shows pause, cancel, and its priority; a
    paused row shows resume and cancel; a row with no run shows **Rescan**.

    This duplicates the strip's controls when a single run is going, and that
    is the point: the strip collapses to an aggregate as soon as a second run
    exists (decision 7), and the sources screen is then the only place a
    specific run can be paused. The rows are also where the owner already
    goes to reason about folders one at a time.

15. **Polling follows work, not runs.**
    One poll at launch to discover anything outstanding, then roughly one per
    second while any run is actually *running*, stopping when none is.

    A paused run is outstanding but makes no progress, so polling it changes
    nothing — its state moves only when the owner acts, and the action's own
    response is what updates the strip. This application is what starts and
    resumes runs, so it always knows when to begin polling again; a permanent
    heartbeat would buy nothing.

## The rename

| Thing | From | To |
| --- | --- | --- |
| Dart package | `alexandria_desktop` | `alexandria_ui` |
| Win32 window title | `alexandria_desktop` | `Alexandria` |
| GTK header bar and window title | `alexandria_desktop` | `Alexandria` |
| Linux `BINARY_NAME` | `alexandria_desktop` | `alexandria` |
| Linux `APPLICATION_ID` | `com.arturrios.alexandria_desktop` | `io.github.artur_rios.Alexandria` |
| `Runner.rc` product and file metadata | `alexandria_desktop` | `Alexandria`, `alexandria.exe` |
| Packaging, installer, CI, documents | `alexandria_desktop` | by context, per the rule below |

The rule, from the owner: *Alexandria* for the whole product, *Alexandria UI*
for this application, *Alexandria API* for the core.

`appTitle` in both ARB files already reads "Alexandria" and
`MaterialApp.onGenerateTitle` already uses it. On desktop Flutter that does
not reach the operating system's title bar, which is why the window still
says `alexandria_desktop`: `windows/runner/main.cpp` creates it with that
literal.

**The application id change fixes a live defect.** `linux/CMakeLists.txt`
sets `com.arturrios.alexandria_desktop`, while the desktop entry and Flatpak
manifest are both `io.github.artur_rios.Alexandria`. GNOME matches windows to
launchers by application id, so the running window very likely does not
associate with its own icon today.

**Install paths change on Linux.** A new binary name and application id mean
an existing installation becomes a second entry rather than an upgrade. Inno
Setup keys upgrades off `AppId`, so Windows may upgrade in place despite the
new executable name — that is to be verified, not assumed.

## Components

| Unit | Responsibility | Depends on |
| --- | --- | --- |
| `ActiveRunsController` | The global picture: every outstanding run, polled while any is active | `IndexGateway` |
| `run_estimate.dart` | Pure rate and remaining-time calculation over a sample window | nothing |
| `BackgroundActivityStrip` | One row above the playback bar: progress, phase, controls | `ActiveRunsController` |
| `IndexRunsController` | Per-folder runs on the sources screen; no longer reconstructs the global picture | `IndexGateway` |
| `LibrarySourcesController` | Registration only; returns what it registered | `FolderPicker`, `FolderProbe`, `LibrarySourceStore` |
| `_RailAction` | One rail-shaped, non-selectable action | `Breakpoint` |

## Surfaces consumed

`IndexGateway` gains `pauseRun`, `resumeRun` (with an optional priority),
`cancelRun`, and `listActiveRuns`; `startIndex` and `startRefresh` gain a
priority argument. `CoreIndexGateway` implements them over `CoreClient`,
mapping the new `RUN_ERR_INVALID_STATE` through the existing
`CoreStatusFamily.run` mapper.

`IndexRun` gains `phase`, `total`, `processed`, `activeMillis`, `pausedAt`
and `alreadyCataloged`, parsed in `_runFrom`.

**`content_hash` is now null for most files.** Anything that displays it must
tolerate that; it is no longer a value the catalog generally holds.

`ffigen` regenerates the bindings from the rebuilt header; `tools/dev.ps1`
already performs the copy-and-regenerate step.

## Error handling

The existing conventions hold: an unauthorized failure returns the owner to
login through `SessionController.invalidate`; every other failure surfaces
through `failure_messages.dart`.

Two additions:

- A control call refused for state (`RUN_ERR_INVALID_STATE`) is not an error
  worth a dialog. The run moved on — a cancel arrived while the walk was
  finishing, or a resume raced a completion. The strip re-reads the run and
  shows its actual state.
- A failed poll does not clear the strip. Showing nothing because one read
  failed would report "no work running" on no evidence.

## Testing

Convention here is `GivenX_WhenY_ThenZ` in PascalCase — note this differs
from the core's snake_case.

- The estimate is a pure function, tested away from any widget: that it
  withholds a figure until the sample window is stable, and that paused
  stretches are excluded.
- `BackgroundActivityStrip` widget tests per state: hidden when idle,
  indeterminate with no estimate while discovering, counts and bar while
  processing, resume offered when paused, a failure that persists, a
  completion that dismisses itself, and the multi-run aggregate.
- The auto-index chain, both directions: registering a folder starts a run,
  and a refused folder does not. The negative is what catches a naive
  implementation.
- Rail goldens at all three breakpoints — the complaint was visual and
  goldens are already this repository's idiom.
- Gateway tests for the four new calls and the `RUN_ERR_INVALID_STATE`
  mapping.
- For the rename, a green suite plus `flutter analyze`.

## Risks

- **The estimate reading as wrong** is the likeliest way this feature
  disappoints. Withholding it until stable is the mitigation; it is a
  judgement call that may need tuning against a real 12,264-file run.
- **The priority toggle's progress reset** will look like a bug unless the
  strip explains it.
- **The Linux half of the rename is verified by inspection and CI**, not by a
  local build — this is a Windows machine. Saying so is better than implying
  both platforms were exercised.
