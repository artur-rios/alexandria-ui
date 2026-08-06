# Alexandria Desktop

The cross-platform desktop front-end for
[Alexandria](https://github.com/artur-rios/alexandria-api), a personal library
system that indexes, organizes, and surfaces a single person's on-disk media and
documents. This application is where the owner actually sees and uses that
library: it browses the catalog, plays audio and video, reads documents and
comics, edits Markdown and text in place, and organizes everything into
collections, watchlists, and reading lists. It links the Alexandria Rust core in
process over FFI rather than talking to a server, so the whole product runs as a
single local application with no network hop between the interface and its data.

> **Status:** specification complete, implementation not started.

> Windows and Ubuntu. Single-user. Metadata and content editing only — never
> re-encoding, never relocating, and never deleting a file from disk without an
> explicit confirmation.

## What it does

- Browses the catalog by file type — music, movies, series, HTML pages, Markdown
  and text notes, PDFs and e-books, comic books, images, and browser bookmarks —
  in list, detailed-list, and grid layouts.
- Registers one or more library folders and runs indexing and re-scans from the
  interface.
- Plays video with full screen, seeking, subtitle tracks, and audio tracks.
- Plays audio in a persistent player, with the disc, vinyl, or tape animation
  turning for the duration of an album or artist and stopping on pause.
- Views PDFs, e-books, comic books, images, saved HTML pages, and rendered
  Markdown.
- Edits Markdown and text files in place, with a live preview.
- Edits music and video metadata, and renames any file.
- Organizes files and bookmarks into collections, tracks movies and series in
  watchlists with per-episode progress, and tracks books and comics in reading
  lists with per-issue progress.
- Searches, filters, and sorts across the whole catalog.
- Carries out the core's two-phase deletion lifecycle — soft delete, restore,
  purge, and the separate explicit purge-on-disk.
- Signs the owner up, confirms their e-mail, logs them in, and recovers their
  password, keeping the library locked until the account is confirmed.
- Adapts to window and screen size, in light and dark themes, in Brazilian
  Portuguese and English.

## What it doesn't do

- No media editing of any kind — no audio or video re-encoding, no transcoding,
  no image manipulation.
- No domain logic of its own: validation, lifecycle, and every business rule
  belong to the Alexandria core.
- No file management — it never moves, copies, or duplicates a file, and removes
  one from disk only through the core's explicit purge-on-disk operation.
- No second account, sharing, profiles, or roles — one owner, one account.
- No mail transport of its own: the core sends the confirmation and recovery
  messages and owns their tokens.
- No server, no cloud, no synchronization.
- No mobile, web, or macOS build.

## Specifications

The project is specified before it is built. Start with the `initial/` documents
for context, then the `requirements/` documents for the normative detail.

| Document | What's in it |
|---|---|
| [Brainstorm](docs/initial/Brainstorm.md) | The original free-form notes this project grew from. |
| [Project Overview](docs/initial/Project%20Overview.md) | What the project is, who it's for, and how success is measured. |
| [Technology Stack](docs/initial/Technology%20Stack.md) | The informal stack decisions. |
| [Workflow](docs/initial/Workflow.md) | How one use case is delivered, step by step. |
| [Business Rules](docs/initial/Business%20Rules.md) | Domain entities, relationships, and the `BR-xx` rules. |
| [Vision Document](docs/requirements/Vision%20Document.md) | Stakeholders, positioning, and the `F-xx` features. |
| [System Requirements Document](docs/requirements/System%20Requirements%20Document.md) | The `FR-<AREA>-xx` and `NFR-xx` requirements, data model, and traceability. |
| [Use Case Specification Document](docs/requirements/Use%20Case%20Specification%20Document.md) | The `UC-xx` use cases, their flows, and their `AF-xx` alternatives. |
| [Development Workflow Document](docs/requirements/Development%20Workflow%20Document.md) | The normative branch pattern, issue lifecycle, and Definition of Done. |
| [Testing Specification Document](docs/requirements/Testing%20Specification%20Document.md) | How tests are written, named, and run. |
| [Technology Stack Document](docs/requirements/Technology%20Stack%20Document.md) | The single source of truth for every technology and version. |
| [Operations & Infrastructure Document](docs/requirements/Operations%20%26%20Infrastructure%20Document.md) | Layout, configuration, logging, startup checks, and the `IR-xx` platform requirements. |

## Installation

Prerequisites, per the
[Technology Stack Document](docs/requirements/Technology%20Stack%20Document.md):

- The Flutter SDK, with the desktop target for your platform enabled.
- **Windows:** Windows 10 x64 or later, with the Visual Studio C++ desktop
  workload.
- **Linux:** Ubuntu LTS x64, with the GTK development packages.
- A build of the [Alexandria core](https://github.com/artur-rios/alexandria-api)'s
  `alexandria-ffi` shared library, placed in `native/` for your platform. Release
  packages bundle it; a development checkout needs it built.

```bash
git clone https://github.com/artur-rios/alexandria-desktop-front.git
cd alexandria-desktop-front
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Run it with the desktop target for your platform:

```bash
flutter run -d windows
```

```bash
flutter run -d linux
```

## Testing

`flutter test` runs the suite described in the
[Testing Specification Document](docs/requirements/Testing%20Specification%20Document.md):

```bash
flutter test
```

That is the unit and widget suite, which runs without the native library. The
integration suite drives the real Alexandria core over FFI and needs a desktop
device:

```bash
flutter test integration_test -d windows
```

```bash
flutter test integration_test -d linux
```

Tests are named with the Given-When-Then pattern
(`GivenSomeCondition_WhenSomeAction_ThenSomeOutcome`). Every use case ships with
its tests before its pull request is opened.

## Roadmap

Ten milestones covering forty-three issues: one foundation issue plus one issue
per use case. Milestones are dependency-ordered — no milestone depends on a later
one, and every milestone after `M-01` depends on it.

| Milestone | Delivers | Depends on | Issues | Status |
|---|---|---|---|---|
| [M-01 — Foundation](https://github.com/artur-rios/alexandria-desktop-front/milestone/1) | The project scaffold, the core bindings, and the cross-cutting infrastructure every use case is built on | — | 1 | 0 / 1 closed |
| [M-02 — Shell and access](https://github.com/artur-rios/alexandria-desktop-front/milestone/2) | A window the owner can open, navigate, theme, translate, sign up for, confirm, and sign in to | M-01 | 9 | 0 / 9 closed |
| [M-03 — Library sources and indexing](https://github.com/artur-rios/alexandria-desktop-front/milestone/3) | Folders can be registered, indexed, refreshed, and unregistered — the catalog gets its content | M-02 | 4 | 0 / 4 closed |
| [M-04 — Catalog browsing and search](https://github.com/artur-rios/alexandria-desktop-front/milestone/4) | The library can be browsed by type, laid out three ways, searched, filtered, sorted, and summarized on a dashboard | M-03 | 6 | 0 / 6 closed |
| [M-05 — Metadata and content editing](https://github.com/artur-rios/alexandria-desktop-front/milestone/5) | Music and video metadata, file names, and text content can be edited | M-04 | 4 | 0 / 4 closed |
| [M-06 — Media playback](https://github.com/artur-rios/alexandria-desktop-front/milestone/6) | Video plays with subtitles and audio tracks; audio plays with a queue and the album animation | M-04 | 3 | 0 / 3 closed |
| [M-07 — Document and image viewing](https://github.com/artur-rios/alexandria-desktop-front/milestone/7) | PDFs, e-books, comics, images, and saved pages can be read | M-04 | 4 | 0 / 4 closed |
| [M-08 — Collections and bookmarks](https://github.com/artur-rios/alexandria-desktop-front/milestone/8) | Files and bookmarks can be grouped, and bookmarks managed and opened | M-04 | 3 | 0 / 3 closed |
| [M-09 — Watchlists and reading lists](https://github.com/artur-rios/alexandria-desktop-front/milestone/9) | Movies, series, books, and comics can be tracked with per-episode and per-issue progress | M-08 | 4 | 0 / 4 closed |
| [M-10 — Deletion lifecycle](https://github.com/artur-rios/alexandria-desktop-front/milestone/10) | Items can be deleted, restored, purged, purged on disk, and reviewed when missing | M-04 | 5 | 0 / 5 closed |

Once the issues exist, GitHub's milestone pages are the live view of progress;
the counts here are as of creation time.

**Blocked on the core.** `UC-01`, `UC-40`, `UC-41`, and `UC-42` need account
creation, e-mail confirmation, confirmation resend, and password-reset operations
that the Alexandria core's FFI surface does not publish yet. They are specified
and tracked, and each is implemented when its call lands — never by working around
the missing call. The capabilities and what the front-end needs from each are in
[System Requirements §5.4](docs/requirements/System%20Requirements%20Document.md).

## Backlog

### M-01 — Foundation

| Issue | Work | Spec |
|---|---|---|
| [#1](https://github.com/artur-rios/alexandria-desktop-front/issues/1) | Project scaffold and initial infrastructure (IR-01 … IR-16) | [Operations & Infrastructure](docs/requirements/Operations%20%26%20Infrastructure%20Document.md) |

### M-02 — Shell and access

| Issue | Work | Spec |
|---|---|---|
| [#39](https://github.com/artur-rios/alexandria-desktop-front/issues/39) | UC-38 — Navigate the application shell | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#40](https://github.com/artur-rios/alexandria-desktop-front/issues/40) | UC-39 — Manage application preferences | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#2](https://github.com/artur-rios/alexandria-desktop-front/issues/2) | UC-01 — Sign up | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#3](https://github.com/artur-rios/alexandria-desktop-front/issues/3) | UC-02 — Log in | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#4](https://github.com/artur-rios/alexandria-desktop-front/issues/4) | UC-03 — Sign out | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#5](https://github.com/artur-rios/alexandria-desktop-front/issues/5) | UC-04 — Change credentials | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#41](https://github.com/artur-rios/alexandria-desktop-front/issues/41) | UC-40 — Confirm the e-mail address | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#42](https://github.com/artur-rios/alexandria-desktop-front/issues/42) | UC-41 — Request a password reset | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#43](https://github.com/artur-rios/alexandria-desktop-front/issues/43) | UC-42 — Complete a password reset | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-03 — Library sources and indexing

| Issue | Work | Spec |
|---|---|---|
| [#6](https://github.com/artur-rios/alexandria-desktop-front/issues/6) | UC-05 — Register a library folder | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#7](https://github.com/artur-rios/alexandria-desktop-front/issues/7) | UC-06 — Index a library folder | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#8](https://github.com/artur-rios/alexandria-desktop-front/issues/8) | UC-07 — Refresh the catalog | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#9](https://github.com/artur-rios/alexandria-desktop-front/issues/9) | UC-08 — Unregister a library folder | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-04 — Catalog browsing and search

| Issue | Work | Spec |
|---|---|---|
| [#10](https://github.com/artur-rios/alexandria-desktop-front/issues/10) | UC-09 — Browse the library by type | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#11](https://github.com/artur-rios/alexandria-desktop-front/issues/11) | UC-10 — Switch the view layout | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#12](https://github.com/artur-rios/alexandria-desktop-front/issues/12) | UC-11 — Search the catalog | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#13](https://github.com/artur-rios/alexandria-desktop-front/issues/13) | UC-12 — Filter and sort a listing | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#14](https://github.com/artur-rios/alexandria-desktop-front/issues/14) | UC-13 — View a file's details | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#15](https://github.com/artur-rios/alexandria-desktop-front/issues/15) | UC-14 — View the home dashboard | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-05 — Metadata and content editing

| Issue | Work | Spec |
|---|---|---|
| [#16](https://github.com/artur-rios/alexandria-desktop-front/issues/16) | UC-15 — Edit music metadata | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#17](https://github.com/artur-rios/alexandria-desktop-front/issues/17) | UC-16 — Edit video metadata | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#18](https://github.com/artur-rios/alexandria-desktop-front/issues/18) | UC-17 — Rename a file | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#19](https://github.com/artur-rios/alexandria-desktop-front/issues/19) | UC-18 — Edit a Markdown or text file | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-06 — Media playback

| Issue | Work | Spec |
|---|---|---|
| [#20](https://github.com/artur-rios/alexandria-desktop-front/issues/20) | UC-19 — Play a video | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#21](https://github.com/artur-rios/alexandria-desktop-front/issues/21) | UC-20 — Play audio | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#22](https://github.com/artur-rios/alexandria-desktop-front/issues/22) | UC-21 — Show the album playback animation | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-07 — Document and image viewing

| Issue | Work | Spec |
|---|---|---|
| [#23](https://github.com/artur-rios/alexandria-desktop-front/issues/23) | UC-22 — View a document | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#24](https://github.com/artur-rios/alexandria-desktop-front/issues/24) | UC-23 — Read a comic book | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#25](https://github.com/artur-rios/alexandria-desktop-front/issues/25) | UC-24 — View an image | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#26](https://github.com/artur-rios/alexandria-desktop-front/issues/26) | UC-25 — View a saved page | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-08 — Collections and bookmarks

| Issue | Work | Spec |
|---|---|---|
| [#27](https://github.com/artur-rios/alexandria-desktop-front/issues/27) | UC-26 — Manage collections | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#28](https://github.com/artur-rios/alexandria-desktop-front/issues/28) | UC-27 — Organize items into collections | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#29](https://github.com/artur-rios/alexandria-desktop-front/issues/29) | UC-28 — Manage bookmarks | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-09 — Watchlists and reading lists

| Issue | Work | Spec |
|---|---|---|
| [#30](https://github.com/artur-rios/alexandria-desktop-front/issues/30) | UC-29 — Manage watchlists | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#31](https://github.com/artur-rios/alexandria-desktop-front/issues/31) | UC-30 — Track watch progress | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#32](https://github.com/artur-rios/alexandria-desktop-front/issues/32) | UC-31 — Manage reading lists | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#33](https://github.com/artur-rios/alexandria-desktop-front/issues/33) | UC-32 — Track reading progress | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-10 — Deletion lifecycle

| Issue | Work | Spec |
|---|---|---|
| [#34](https://github.com/artur-rios/alexandria-desktop-front/issues/34) | UC-33 — Delete an item | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#35](https://github.com/artur-rios/alexandria-desktop-front/issues/35) | UC-34 — Browse and restore deleted items | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#36](https://github.com/artur-rios/alexandria-desktop-front/issues/36) | UC-35 — Purge a record | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#37](https://github.com/artur-rios/alexandria-desktop-front/issues/37) | UC-36 — Purge a file on disk | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#38](https://github.com/artur-rios/alexandria-desktop-front/issues/38) | UC-37 — Review missing files | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

## Contributing

One use case = one branch = one issue = one pull request. The full process —
branch naming, issue status lifecycle, the approval gates, the testing gate, and
the Definition of Done — is in the
[Development Workflow Document](docs/requirements/Development%20Workflow%20Document.md).
