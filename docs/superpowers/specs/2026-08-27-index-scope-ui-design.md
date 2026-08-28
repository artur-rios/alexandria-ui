# Choosing what a folder is for

**Date:** 2026-08-27
**Status:** approved

## Problem

Registering a folder indexes every supported file under it, so a music
folder's `cover.jpg` becomes an image library. The core can now be told which
types a run records (alexandria-api #122); nothing in this application tells
it.

## Design

### 1. The scope belongs to the folder, not to the run

The core takes a scope per run, because a run is what walks. But the owner is
not describing a run — they are describing what a folder is *for*, and that
does not change between one index and the next.

Library sources are this application's to remember (`LibrarySourceStore`), so
`LibrarySource` gains the scope and every later index of that folder uses it.
The alternative, asking each time, would make the answer a thing the owner
has to keep re-supplying and keep consistent by hand.

### 2. Seven types, not three buckets

The picker offers **all supported files**, selected by default, or any
combination of the seven `LibraryType` values.

The request described "music, video and other supported files". Collapsing
the remaining five into one bucket would be smaller, but it cannot express
"books but not images" — and images-beside-the-thing-you-wanted is exactly
the problem this feature exists to solve. A folder of ebooks has covers in it
too.

Seven also means the picker is the core's own `FileType` and not a second
vocabulary that has to be mapped onto it (BR-02).

### 3. Where the question is asked

In `registerFolder`, after the verdict accepts the folder and after any
overlap confirmation, immediately before `_record`.

Asking later would mean registering a folder and then interrupting; asking
earlier would mean asking about a folder that is then refused for not
existing. It follows the shape `onOverlapConfirmed` already established: a
callback the presentation supplies, returning `null` when the owner
cancels — and a cancel here abandons the registration entirely, because a
folder registered with a scope nobody chose is not what was asked for.

### 4. Absent means all, exactly as the core reads it

An empty scope is stored as absent and sent as absent, which the core reads
as every type. One meaning, held the same way on both sides, so a folder
registered before this existed keeps behaving as it did with no migration.

### 5. Refresh is not scoped

A re-check walks the catalog rather than the disk (FR-LB-06), so it revisits
what is already recorded and cannot pull in an excluded type. It passes no
scope, matching the core.

## Components

| Component | Change |
| --- | --- |
| `library_sources/domain/library_source.dart` | The scope, persisted by wire name. |
| `library_sources/application/library_sources_controller.dart` | `registerFolder` asks for the scope and records it. |
| `library_sources/presentation/` | The picker dialog; the sources list shows each folder's scope. |
| `library_sources/application/index_runs_controller.dart` | An index run sends the source's scope. |
| `core/bindings/core_client.dart`, `core_isolate.dart` | `indexStart` carries `types`. |
| l10n | The dialog's strings, and a name per type, in both locales. |

## Requirements impact

- **UC-05** (registering a folder) gains the choice.
- **FR-LB-03** gains what is recorded about a source.
- **FR-FC-25** is unaffected: this narrows what a run walks, not when
  extraction happens.

## Testing

- Registering a folder with the default indexes every type.
- Registering it scoped to music indexes the FLACs and not the cover art —
  the owner's actual symptom.
- Cancelling the picker registers nothing.
- The scope survives a restart and a later index of the same folder uses it,
  without asking again.
- A source stored before this existed indexes every type.
- The picker is not offered for a folder that is refused.
- A re-check sends no scope.
- The sources list shows what each folder covers.

## Risks

The scope cannot be changed after registration; correcting a mistake means
unregistering and registering again, which is a heavier action than the
mistake deserves. Editing is deliberately not in this change — it needs its
own answer for what happens to files already catalogued under the old scope,
and inventing one here would be guessing.
