# Re-checking the library at startup

**Date:** 2026-08-26
**Status:** approved

## Problem

Nothing in this application notices that a library folder changed. That is
deliberate — the core has no filesystem watcher, and indexing is explicit,
observable and cancellable rather than something that happens behind the
owner's back.

But the only way to act on a change is to remember to. An owner who adds an
album while the application is closed opens it to a library that does not have
the album in it, with nothing on screen suggesting anything is stale. There is
a **Re-check** in Library ▾ → Sources and another in a file's details, and both
require knowing to press them.

The moment a re-check is most likely to be worth running is the moment the
application opens, because that is exactly when the catalog has had the longest
opportunity to fall behind the disk.

## Design

### 1. When it runs

The re-check starts when a **session is established**, which in this
application is once per launch: signing in is how an owner reaches the shell.

`SessionActivity` already has an `end()` that every feature implements to wind
its own session-scoped state down when the session closes. This adds the
symmetric `begin()`, and `IndexSessionActivity` — the activity that already
owns indexing's session state — is what implements it.

The trigger belongs there rather than in `SessionController`. Establishing a
session is authentication's business; starting a scan is not, and a session
controller that reached into indexing to start one would be the wrong thing
knowing about the other.

### 2. When it deliberately does nothing

Three silences, each a decision rather than a failure:

| Condition | Why |
| --- | --- |
| The preference is off | The owner said not to. |
| The catalog holds no files | A refresh walks the paths the catalog already knows (FR-LB-06), so an empty catalog gives it nothing to walk. The test is the file count, not whether a folder has been registered: a source added but never scanned leaves the catalog empty too, and a refresh would still find nothing to compare. |
| A run is already outstanding | The core's runs outlive the application (`continuesInTheCore`), so a scan started before the last close may still be going — running or paused. A pause is the owner holding it where it is, not abandoning it, and the strip already shows it; starting a second run alongside it would be stranger than waiting. It is neither interrupted nor duplicated. |

Each is silent. None of them is a state an owner needs to be told about, and a
notice saying "no re-check was needed" is worse than the absence of one.

**Signing out and back in without closing the application starts another
re-check.** That is a new session, and it is the honest reading of a rule
expressed in terms of sessions. The alternative — remembering whether this
process has already done it — is a rule that has to be maintained for a case
nobody meets by accident.

### 3. The preference

A third group in the preferences dialog, beside theme and language:
**Re-check the library at startup**, on by default.

It reads and writes through the same settings store as the other two, applies
immediately, and raises the same unsaved notice when the store refuses the
write (UC-39 AF-02). Nothing about it is special except what it controls.

Default on because the case for it is the common one: a library that has fallen
behind is the normal state after the application has been closed for a while,
and a re-check reads no file contents — it compares the recorded size and
modification time against the directory entry (FR-FC-10), so its cost is a walk
rather than a read. The preference exists for the owner whose library is large
enough, or whose disk slow enough, that even a walk on every launch is not
worth it.

### 4. The indication

Nothing new is built.

The startup re-check is a run like any other, so `BackgroundActivityStrip`
already reports it exactly as it reports one the owner started: the strip grows
from nothing, shows an indeterminate bar while the walk is still discovering
what it has to do, switches to a determinate bar with its processed-of-total
count once there is a total to divide by, and shows the finished outcome before
clearing itself (FR-LB-15, FR-FC-28).

One place in the application reports background work, whoever started it. That
also means the catalog's projections refresh when it completes, because a run
leaving the active list already invalidates them — the listings, the counts,
the search index and the music library all pick the changes up without the
owner navigating anywhere.

## Components

| Component | Change |
| --- | --- |
| `shell/domain/session_activity.dart` | Gains `begin()`, alongside `end()`. |
| `library_sources/application/index_session_activity.dart` | Implements `begin()`: starts the re-check unless one of §2's three silences applies. |
| `auth/application/session_controller.dart` | Runs each activity's `begin()` on establish, as it already runs `end()`. |
| Every other `SessionActivity` implementer | A no-op `begin()`. |
| `core/settings/settings_store.dart` and its implementations | Read and write the preference. |
| `shell/application/preferences_state.dart`, `preferences_controller.dart` | Carry and set it. |
| `shell/presentation/preferences_dialog.dart` | Offers it. |
| `library_sources/application/index_runs_controller.dart` | `startRefresh` gains `reportRefusals`, suppressing both AF-01's own refusal and a failure the core returns for the start, so a re-check nobody asked for never reaches the screen. |
| `library_sources/application/index_session_activity.dart` | `begin()` also consults `ActiveRunsController` for a run outstanding from a previous session (FR-LB-19) before ever asking `startRefresh` to start one — `IndexRunsController` is built fresh at sign-in and cannot see that on its own. |

No change to the strip or to the gateway.

## Requirements impact

- **FR-LB-06** covers the catalog-wide refresh and gains the startup trigger.
- **FR-LB-21** (new): the system shall re-check the catalog when a session is
  established, unless the owner has turned that off, the catalog is empty, or
  a run is already outstanding.

No new use case: UC-07 already covers re-checking the catalog, and this adds
when one starts.

## Testing

- Establishing a session starts a re-check.
- It does not, when the preference is off; when the catalog is empty; and when
  a run is already outstanding — three separate tests, because they are three
  separate reasons and a single one would not say which rule failed.
- The strip shows a startup re-check exactly as it shows a manual one.
- The preference persists, applies immediately, and raises the unsaved notice
  when the store refuses the write.
- The owner's actual symptom, end to end: a catalog that has fallen behind the
  disk shows its changes after a launch, with nobody pressing anything.

## Risks

The re-check competes with everything else the application does on its way in.
The core serves its calls from a single worker isolate, so a scan starting the
moment a session is established is queued ahead of the first listing the shell
asks for. A large library could therefore make the first screen slower to fill
than it is today — the opposite of what an owner expects from something they
did not ask for.

The honest mitigation is the preference, which is why it exists rather than
being deferred as YAGNI. If the competition proves worse than that covers, the
next step is to let the re-check yield — the core already takes a `priority`
argument on a refresh, and `"low"` is what it is for — rather than to move the
trigger somewhere less predictable.
