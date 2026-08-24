# Review — 2026-08-23

A full review of `alexandria-api`, `alexandria-ui`, and `alexandria-docs`:
implementation against documentation, bugs, inconsistent behavior, and
improvements. This file records what was found in **this** repository and what
was done about it. The other two repositories carry their own copy covering
theirs.

## Baseline

Every check was green before any change was made, and again after. That is the
important context for everything below: **not one finding was a failing test.**

| Check | Before | After |
| --- | --- | --- |
| `flutter test` | 1649 passed | 1652 passed (three regression tests added) |
| `flutter analyze --fatal-infos --fatal-warnings` | no issues | no issues |
| `cargo test --workspace` (alexandria-api) | 1201 passed, 0 failed | unchanged |
| `cargo clippy --workspace --all-targets` (alexandria-api) | clean | clean |

---

## Findings

### U-01 — The core was pinned one commit before the functions this application calls · **fixed**

`CORE_REF` named `88ffd3b`, the core's relicensing commit. The indexing
experience landed after it and calls four FFI functions that commit does not
export:

- `alexandria_index_pause`
- `alexandria_index_cancel`
- `alexandria_index_resume`
- `alexandria_index_runs_active_json`

and passes a second argument to `alexandria_index_refresh_start`, which takes one
at that commit.

Two consequences, neither visible locally, because a developer checkout builds
whatever core is sitting in the sibling directory:

- **CI could not pass.** The header-drift check compares the vendored
  `native/include/alexandria_ffi.h` against the core's generated one at
  `CORE_REF`. The vendored copy carries the new declarations; that commit's
  header does not.
- **A release would have shipped a broken application.** The release workflow
  builds the core from the same pin, so the packaged shared library would have
  been missing every symbol above. Dart FFI resolves a symbol on first use, so
  the failure would surface the first time anyone paused a scan — and the arity
  change on `refresh_start` is worse than a missing symbol, being an ABI
  mismatch rather than a clean lookup failure.

**Fixed** — both workflows moved to `80fe8ec`, the core's UC-42/UC-48 work, which
is where all five come from. The comment explaining the pin was rewritten; it
still recorded the relicensing commit as the reason.

The README also stated `CORE_REF` tracked the core's UC-46 (PR #107). It has not
for two moves. Corrected.

### U-02 — One run ending stopped the application following the others · **fixed**

Four places in `IndexRunsController` decided whether the poller still had work
to do. Three of them weighed only the per-folder scans and ignored the
catalog-wide refresh:

| Site | Was |
| --- | --- |
| `_poll`, run finished | `if (state.inFlightRoots.isEmpty) _stopPolling();` |
| `_poll`, read failed | `_stopPolling();` unconditionally |
| `_pollRefresh`, read failed | `_stopPolling();` unconditionally |
| `refresh` | correct — guarded on both |

The common case is the damaging one. A refresh is catalog-wide and can run for
hours; a folder scan beside it finishes in minutes. The folder scan finishing
cancelled the timer while the refresh was still going, and the refresh then
froze on its last reading — permanently, because polling only ever starts from a
start or a resume, so nothing would have restarted it. The owner would have been
left watching a progress bar that had stopped moving while the core carried on
working behind it.

The two error paths had the same shape in the other direction: one folder's
unreadable status stopped every other folder *and* the refresh.

**Fixed** — the rule now lives in one place, `_stopPollingIfIdle`, called from all
four sites. The poller iterates `pollableRoots` rather than `inFlightRoots`: a
folder whose read failed keeps its run in the state so the screen can still show
what it was doing, but drops out of the rotation rather than spinning on the same
error every interval — and, crucially, without taking the others with it.

Three regression tests added, each verified to fail against the previous
behavior before the fix was applied and to pass after.

### U-03 — The indexing experience shipped without being specified · **fixed**

This repository's Development Workflow Document is explicit that the project is
specified before it is built, one use case per issue per branch per pull request.
The indexing experience — roughly 2,500 lines across a new controller, a new
shell component, four new gateway operations, and per-folder run controls — has
an implementation plan and a design document under `docs/superpowers/`, and
nothing at all in the normative set.

Concretely, the following shipped with no requirement and no use case behind it:

- auto-indexing a folder the moment it is registered;
- live progress with counts, phase, and elapsed working time;
- a remaining-time estimate derived from observed rate;
- the background activity strip, so a scan started on one screen stays visible
  from every other;
- pause, resume, and cancel, from two places;
- run pacing, and the rule that a resume naming no pace keeps the current one;
- the resume offer at launch for a run left behind by a previous session.

The README compounded it: *"all forty-three issues are delivered"*, with a
backlog table of forty-three rows, none covering any of the above.

**Fixed** — the specification now describes what exists:

- **`FR-LB-12` … `FR-LB-20`** added to the System Requirements Document, with
  the three ranges that enumerate `FR-LB` updated to match.
- **`UC-43` Follow a scan while it runs**, **`UC-44` Pause, resume, or cancel a
  scan**, and **`UC-45` Pace a scan** added to the Use Case Specification, each
  with main flows and alternative flows, and each entered in the traceability
  table. `UC-05` now cites `FR-LB-12`, since registering a folder is what starts
  its first scan.
- README: status corrected to forty-six issues, an `M-11 — Indexing experience`
  milestone and backlog section added, and the summary of what the application
  does now mentions the capability at all.

`FR-LB-20` is the requirement that finding U-02 violated. It is stated
explicitly — *"shall continue to follow every other outstanding run when one of
them ends, fails to be read, or is abandoned"* — so the bug now has something to
be a bug against.

### U-04 — Requirement identifiers pointed at the wrong requirements · **fixed**

Run-control operations were annotated with the core's `FR-FC-28`, which is only
the *status query*, and with `UC-42`, likewise only the query. The correct
identifiers are `FR-FC-32` (pause), `FR-FC-33` (resume), `FR-FC-34` (cancel), and
`FR-FC-35` (the outstanding-runs listing), under `UC-48`.

The mistake originated in the core's own doc comments, which `cbindgen` copies
into the generated C header, which this repository vendors and runs through
`ffigen`. From there it was copied by hand into eight more files and into the
localization comments.

Two unrelated auth references were wrong in the same way: `authLocalAccount` cited
`FR-AU-14` (replace the password via a recovery code) where it meant `FR-AU-18`
(report how many codes remain), and both it and
`authLocalRegenerateRecoveryCodes` cited `UC-42`, which is a run query.

**Fixed** at the source. The core's annotations were corrected in its own branch;
the header was re-vendored from the core's regenerated one and the bindings
regenerated with `ffigen`, so `alexandria_bindings.dart` is a genuine generated
artefact rather than a hand-edit that the next regeneration would revert. The
diff is comments only — no signature changed.

Hand-written sources now cite **this repository's own** `FR-LB` identifiers for
its own behavior, with the core's requirement named alongside as `core FR-FC-nn`
where the behavior is really the core's. Cross-referencing another repository's
numbering as though it were local is what let the drift go unnoticed.

### U-05 — Fifty-three dead links in the README · **fixed**

Every milestone and issue URL still pointed at
`github.com/artur-rios/alexandria-desktop-front`. The repository was renamed to
`alexandria-ui`, and while the package, the module file, and the shipped metadata
were all updated, the README's link targets were not.

**Fixed** — all fifty-three rewritten.

### U-06 — The README said the product is two repositories · **fixed**

It is three. `alexandria-docs` exists and publishes the documentation site.

**Fixed**, while keeping the point the sentence was making: only two of them have
to be built to run the thing locally.

### U-07 — Two configuration knobs were spelled differently on each side · **fixed**

The product has two settings that both halves care about, and each was spelled
one way here and another in the core:

| Concept | This repository | The core |
| --- | --- | --- |
| Database path | `ALEXANDRIA_DB_PATH` | `ALEXANDRIA_DATABASE_PATH` |
| Log level | `ALEXANDRIA_LOG_LEVEL` | `ALEXANDRIA_LOG_LEVEL`, since renamed to `ALEXANDRIA_LOGGING_LEVEL` |

Neither collided, so nothing was broken — but two near-identical names for one
concept, in one program, is exactly the kind of thing that gets set wrong once
and then debugged for an hour.

**Fixed** — both renamed to match the core, in `app_logger.dart`,
`core_paths.dart`, `dev.ps1`, `dev.sh`, the README and a test. One name per
concept across the product.

The README now also records what the shared names do *not* imply, since the
mechanisms genuinely differ: the database path is read from the environment at
startup and handed to the core over FFI, so this side decides it; the log level
is a `--dart-define` here and a runtime variable in the core, so turning up both
halves means setting both.

---

## Reviewed and found correct

- **`ActiveRunsController`.** The counterpart to the controller in U-02, and it
  gets every one of the same decisions right — including reading *every* run
  that dropped off the active list rather than only the first, not letting a
  second run's outcome displace an unread failure, and reading a disappeared run
  directly because the outstanding-runs listing cannot carry a terminal status
  by construction.
- **The resume priority convention.** `null` means *keep the current pace*, not
  *normal*, and it is carried unchanged from the screen through the controller,
  the gateway, the client, the isolate, and into the C call. Getting this wrong
  anywhere along that chain would silently un-throttle a scan the owner
  deliberately slowed down, and it is right at every step.
- **The isolate argument reordering.** The Dart-level operation takes
  `(runId, priority, token)` and the C function takes `(run_id, token,
  priority)`; the nesting reorders correctly, and the comment says so. Getting
  it wrong would have passed a token as a priority.
- **Native string lifetimes.** Freed on the worker before returning, on the
  failure path too.
- **The layering rules.** Presentation and application never import data,
  domain imports nothing outward, and nothing above the data layer touches
  `dart:ffi` — enforced by analyzer rules in `tools/alexandria_lints` and proved
  against deliberately-violating fixtures by their own suite.

---

## Not done, and why

- **Issue numbers for `UC-43` … `UC-45` are recorded as `—`.** The work was done
  before the use cases existed, so there are no issues to point at. The core's
  README uses the same placeholder for its `UC-43` … `UC-45`, so the convention
  is at least consistent.
- **No new golden files.** The indexing experience's screens already have golden
  coverage; this review changed no rendering.
