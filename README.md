# Alexandria UI

The cross-platform desktop front-end for
[Alexandria](https://github.com/artur-rios/alexandria-api), a personal library
system that indexes, organizes, and surfaces a single person's on-disk media and
documents. This application is where the owner actually sees and uses that
library: it browses the catalog, plays video and music, reads documents and
comics, edits Markdown and text in place, and organizes everything into
collections, watchlists, and reading lists. It plays music files, but managing a
music collection — playlists, play history, browsing by artist and album — is
Orpheus's, a separate project. It links the Alexandria Rust
core in process over FFI rather than talking to a server, so the whole product
runs as a single local application with no network hop between the interface and
its data.

> **Status:** everything in the backlog below is delivered — the foundation
> and every use case that has not been removed.

> Windows and Ubuntu. Single-user. Metadata and content editing only — never
> re-encoding, never relocating, and never deleting a file from disk without an
> explicit confirmation.

## What it does

- Starts straight into the library: there is no account and no login. It runs
  on the owner's machine, over their own files.
- Lists the owner's libraries in the left menu, under Home and Bookmarks: the
  pinned ones first, A–Z, then the others, A–Z. Right-clicking one pins it,
  marks it as a favorite, or renames it.
- Opens a library in the main area as its folders, with breadcrumbs, and its
  files — movies and series, music, HTML pages, Markdown and text notes, PDFs
  and e-books, comic books, and images — in list, detailed-list, or grid
  layout, filtered to one type or not, and sorted by name, date, or album. Music
  is listed by its tags.
- Shows the favorite libraries on home, with the catalog's totals: how many
  libraries, and how many files of each type.
- Adds folders as libraries — the only way files get into the catalog — from
  the menu bar's Library menu, where Manage libraries lists them all. A library
  is indexed as soon as it is added, can be renamed at any time, scanned again,
  moved, or removed, and the whole catalog can be re-checked; live progress
  shows wherever the owner happens to be, and a scan can be paused, resumed,
  cancelled, or paced down while it works.
- Plays video with full screen, seeking, subtitle tracks, and audio tracks.
- Plays music in a player bar that stays while the owner browses, through the
  folder a track was started from.
- Views PDFs, e-books, comic books, images, saved HTML pages, and rendered
  Markdown.
- Edits Markdown and text files in place, with a live preview.
- Edits video metadata and music tags, and renames any file.
- Organizes files and bookmarks into collections, tracks movies and series in
  watchlists with per-episode progress, and tracks books and comics in reading
  lists with per-issue progress.
- Searches across every library at once.
- Carries out the core's two-phase deletion lifecycle — soft delete, restore,
  purge, and the separate explicit purge-on-disk.
- Adapts to window and screen size, in light and dark themes, in Brazilian
  Portuguese and English.
- Checks for a newer release at startup and offers it with its release notes.
  The Windows installer, the Linux installer, and the AppImage update
  themselves — the download verified against the release's SHA-256 checksums
  first — and every other package is pointed at the release page. The check
  can be turned off in Preferences; the Flatpak never makes it.

## What it doesn't do

- No music management. Tracks play, but there are no playlists, no play
  history or statistics, no browsing by artist or album, no lyrics or artist
  photographs, no shuffle or repeat, and a track does not remember where it
  stopped; that belongs to Orpheus, a separate project.
- No indexing outside a library: a folder's files reach the catalog only by
  adding the folder as a library.
- No media editing of any kind — no video re-encoding, no transcoding, no image
  manipulation.
- No domain logic of its own: validation, lifecycle, and every business rule
  belong to the Alexandria core.
- No file management — it never moves, copies, or duplicates a file, and removes
  one from disk only through the core's explicit purge-on-disk operation.
- No account, login, sharing, profiles, or roles — one owner, on their own
  machine.
- No mail of any kind.
- No server, no cloud, no synchronization, and no telemetry. The one network
  call the application makes of its own is the update check: a request for the
  latest release to GitHub's public API, carrying nothing but the running
  version.
- No mobile, web, or macOS build.

## Specifications

The project is specified before it is built. Start with the `initial/` documents
for context, then the `requirements/` documents for the normative detail.

| Document | What's in it |
| --- | --- |
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

## Installing

Every tag publishes a [release](https://github.com/artur-rios/alexandria-ui/releases)
carrying the application for both platforms. Each package bundles the
Alexandria core, so there is nothing else to install.

**Windows** — download `alexandria-setup-<version>.exe` and run it. It asks
where to install, and if it finds Alexandria already there — or in the place a
previous install recorded — it offers to remove that first. Only the program's
own files are removed: your library, catalog, and settings are never touched.

**Linux** — download `alexandria-installer-<version>-linux-x64.sh` and run it:

```bash
chmod +x alexandria-installer-<version>-linux-x64.sh
./alexandria-installer-<version>-linux-x64.sh
```

It asks where to install, defaulting to `~/.local/opt/alexandria` — or
`/opt/alexandria` when run as root — and replaces an existing installation the
same way the Windows installer does. `--prefix DIR` and `--yes` skip the
questions, and `--uninstall` removes what it installed and nothing else.

The Linux release also carries a `.deb`, an AppImage, and a Flatpak bundle for
anyone who would rather install through one of those. The `.deb` targets Ubuntu
24.04 LTS and pulls in ffmpeg, libmpv, and GTK through apt; the AppImage carries
everything it needs; the Flatpak gets its codecs from the
`org.freedesktop.Platform.ffmpeg-full` runtime extension.

### Without installing

`alexandria-<version>-windows-x64.zip` and
`alexandria-<version>-linux-x64.tar.gz` are the application itself, unpacked
and run wherever you put them. Nothing is registered, no menu entry is created,
and removing the directory removes the program.

```bash
tar xzf alexandria-<version>-linux-x64.tar.gz
./alexandria
```

Both archives are self-contained. The core links ffmpeg, and rather than
expecting it to be installed, the Linux archive carries it — along with
everything ffmpeg itself needs — in `lib/`, with the licences in `lib/licenses/`.
Only the graphics, sound, and C libraries any desktop application needs come
from your system. The Windows archive bundles the ffmpeg DLLs the same way.

## Roadmap

Thirteen milestones covering fifty issues: one foundation issue plus one
issue per use case. `M-12` was removed with music, and its four issues are not
counted. The sign-up, login and recovery issues of `M-02`, and `UC-09` of
`M-04`, were delivered and later removed, and are counted. Milestones are
dependency-ordered — no milestone depends on a later one, and every milestone
after `M-01` depends on it.

| Milestone | Delivers | Depends on | Issues | Status |
| --- | --- | --- | --- | --- |
| [M-01 — Foundation](https://github.com/artur-rios/alexandria-ui/milestone/1) | The project scaffold, the core bindings, and the cross-cutting infrastructure every use case is built on | — | 1 | 1 / 1 closed |
| [M-02 — Shell and access](https://github.com/artur-rios/alexandria-ui/milestone/2) | A window the owner can open, navigate, theme, and translate; its sign-up, sign-in, and recovery were removed with core 0.7 | M-01 | 9 | 9 / 9 closed |
| [M-03 — Libraries and indexing](https://github.com/artur-rios/alexandria-ui/milestone/3) | Folders can be added as libraries, indexed, refreshed, and removed — the catalog gets its content | M-02 | 4 | 4 / 4 closed |
| [M-04 — Catalog browsing and search](https://github.com/artur-rios/alexandria-ui/milestone/4) | The library can be laid out three ways, searched, filtered, sorted, and summarized on home; browsing by type was removed with library navigation | M-03 | 6 | 6 / 6 closed |
| [M-05 — Metadata and content editing](https://github.com/artur-rios/alexandria-ui/milestone/5) | Video metadata, music tags, file names, and text content can be edited | M-04 | 4 | 4 / 4 closed |
| [M-06 — Media playback](https://github.com/artur-rios/alexandria-ui/milestone/6) | Video plays with subtitles and audio tracks, and music plays in the player bar | M-04 | 3 | 3 / 3 closed |
| [M-07 — Document and image viewing](https://github.com/artur-rios/alexandria-ui/milestone/7) | PDFs, e-books, comics, images, and saved pages can be read | M-04 | 4 | 4 / 4 closed |
| [M-08 — Collections and bookmarks](https://github.com/artur-rios/alexandria-ui/milestone/8) | Files and bookmarks can be grouped, and bookmarks managed and opened | M-04 | 3 | 3 / 3 closed |
| [M-09 — Watchlists and reading lists](https://github.com/artur-rios/alexandria-ui/milestone/9) | Movies, series, books, and comics can be tracked with per-episode and per-issue progress | M-08 | 4 | 4 / 4 closed |
| [M-10 — Deletion lifecycle](https://github.com/artur-rios/alexandria-ui/milestone/10) | Items can be deleted, restored, purged, purged on disk, and reviewed when missing | M-04 | 5 | 5 / 5 closed |
| [M-11 — Indexing experience](https://github.com/artur-rios/alexandria-ui/milestone/11) | A scan is visible from anywhere, controllable while it runs, and paceable; a newly added library indexes itself | M-03 | 3 | 3 / 3 closed |
| M-12 — Music library and playlists | Removed (moved out of scope, see Orpheus) | M-06 | 4 | Removed |
| M-13 — Libraries | A folder browsed as its own tree | M-04 | 1 | 1 / 1 closed |
| M-14 — Library navigation | The left menu lists the libraries, pinned first; libraries are favorited for home and renamed at any time | M-13 | 3 | 3 / 3 closed |

GitHub's milestone pages are the live view of progress; the counts here are as
of the last update to this file. `M-13` and `M-14` carry no milestone link and
no issue number, and that is honest rather than an omission: they were built
from design documents in `docs/superpowers/specs/` rather than from the
issue-per-use-case backlog the first eleven follow. They are specified all the
same — `UC-49`, `UC-52`, `UC-53`, `UC-54` and their requirements are in the
same two documents as everything above them. `M-12` went
with music: `UC-46`, `UC-47`, `UC-48` and `UC-50` stay in those documents only
as Removed stubs, so their numbers are never reused. Core 0.6 brought audio back
as a file type, and with it `UC-15` and `UC-20`, narrowed to editing a track's
tags and playing tracks in the player bar; `UC-21` and `M-12` stay removed.

**The two repositories agree.** `CORE_REF` tracks core 0.7.0 — its develop
merge commit until this application's release pins the `v0.7.0` merge commit —
and this application accepts core `>=0.7.0 <0.8.0`. That core removed
authentication, the token on every call, and its HTTP server, and added a
library's pin, favorite, and rename, and the catalog's statistics. An older
core still expects a token on every call, so it is refused at startup. The
specifications follow it:

- **There is no login.** Sign-up, login, sign-out, the credentials change, and
  the recovery codes went with the core's authentication. `UC-01` … `UC-04` and
  `UC-40` … `UC-42` stay in the use case document only as Removed stubs, and
  `FR-AU-01` … `FR-AU-19` with them, so their numbers are never reused.
- **Libraries are navigated, not types.** The per-type pages are gone, and
  with them `UC-09` and `FR-CT-01` and `FR-CT-02`: a library's files are
  filtered by type inside it, and home counts each type.

Earlier divergences are closed on both sides too:

- **Collections can be listed.** `alexandria_collections_list` answers which
  collections exist, with the number of items in each. `UC-26` and `UC-27` are
  built on it, and `UC-28`'s optional filing of a bookmark into a bookmark
  collection — deferred when bookmarks shipped — is built with them.

`UC-27` step 2's breadcrumbs are not a problem: `FR-OG-07` fixes the present
depth of the hierarchy at one, so a flat `Collection` is the model it asks for,
and nesting stays a change of data rather than of interface.

## Backlog

### M-01 — Foundation

| Issue | Work | Spec |
|---|---|---|
| [#1](https://github.com/artur-rios/alexandria-ui/issues/1) | Project scaffold and initial infrastructure (IR-01 … IR-16) | [Operations & Infrastructure](docs/requirements/Operations%20%26%20Infrastructure%20Document.md) |

### M-02 — Shell and access

The sign-up, login and recovery use cases were delivered, then removed with
core 0.7, which has no authentication: Alexandria starts straight into the
shell. They keep their numbers so that nothing else is renumbered.

| Issue | Work | Spec |
| --- | --- | --- |
| [#39](https://github.com/artur-rios/alexandria-ui/issues/39) | UC-38 — Navigate the application shell — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#40](https://github.com/artur-rios/alexandria-ui/issues/40) | UC-39 — Manage application preferences — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#2](https://github.com/artur-rios/alexandria-ui/issues/2) | UC-01 — Sign up — Removed (0.7 core: no login) | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#3](https://github.com/artur-rios/alexandria-ui/issues/3) | UC-02 — Log in — Removed (0.7 core: no login) | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#4](https://github.com/artur-rios/alexandria-ui/issues/4) | UC-03 — Sign out — Removed (0.7 core: no login) | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#5](https://github.com/artur-rios/alexandria-ui/issues/5) | UC-04 — Change credentials — Removed (0.7 core: no login) | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#41](https://github.com/artur-rios/alexandria-ui/issues/41) | UC-40 — Save the recovery codes — Removed (0.7 core: no login) | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#42](https://github.com/artur-rios/alexandria-ui/issues/42) | UC-41 — Recover access with a recovery code — Removed (0.7 core: no login) | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#43](https://github.com/artur-rios/alexandria-ui/issues/43) | UC-42 — Regenerate the recovery codes — Removed (0.7 core: no login) | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-03 — Libraries and indexing

| Issue | Work | Spec |
| --- | --- | --- |
| [#6](https://github.com/artur-rios/alexandria-ui/issues/6) | UC-05 — Add a library — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#7](https://github.com/artur-rios/alexandria-ui/issues/7) | UC-06 — Scan a library — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#8](https://github.com/artur-rios/alexandria-ui/issues/8) | UC-07 — Refresh the catalog — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#9](https://github.com/artur-rios/alexandria-ui/issues/9) | UC-08 — Remove a library — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-04 — Catalog browsing and search

| Issue | Work | Spec |
| --- | --- | --- |
| [#10](https://github.com/artur-rios/alexandria-ui/issues/10) | UC-09 — Browse the library by type — Removed (navigation by library) | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#11](https://github.com/artur-rios/alexandria-ui/issues/11) | UC-10 — Switch the view layout — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#12](https://github.com/artur-rios/alexandria-ui/issues/12) | UC-11 — Search the catalog — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#13](https://github.com/artur-rios/alexandria-ui/issues/13) | UC-12 — Filter and sort a listing — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#14](https://github.com/artur-rios/alexandria-ui/issues/14) | UC-13 — View a file's details — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#15](https://github.com/artur-rios/alexandria-ui/issues/15) | UC-14 — View the home dashboard — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-05 — Metadata and content editing

| Issue | Work | Spec |
| --- | --- | --- |
| [#16](https://github.com/artur-rios/alexandria-ui/issues/16) | UC-15 — Edit a track's tags — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#17](https://github.com/artur-rios/alexandria-ui/issues/17) | UC-16 — Edit video metadata — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#18](https://github.com/artur-rios/alexandria-ui/issues/18) | UC-17 — Rename a file — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#19](https://github.com/artur-rios/alexandria-ui/issues/19) | UC-18 — Edit a Markdown or text file — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-06 — Media playback

| Issue | Work | Spec |
| --- | --- | --- |
| [#20](https://github.com/artur-rios/alexandria-ui/issues/20) | UC-19 — Play a video — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#21](https://github.com/artur-rios/alexandria-ui/issues/21) | UC-20 — Play audio — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#22](https://github.com/artur-rios/alexandria-ui/issues/22) | UC-21 — See what is playing — Removed (moved out of scope, see Orpheus) | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-07 — Document and image viewing

| Issue | Work | Spec |
| --- | --- | --- |
| [#23](https://github.com/artur-rios/alexandria-ui/issues/23) | UC-22 — View a document — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#24](https://github.com/artur-rios/alexandria-ui/issues/24) | UC-23 — Read a comic book — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#25](https://github.com/artur-rios/alexandria-ui/issues/25) | UC-24 — View an image — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#26](https://github.com/artur-rios/alexandria-ui/issues/26) | UC-25 — View a saved page — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-08 — Collections and bookmarks

| Issue | Work | Spec |
| --- | --- | --- |
| [#27](https://github.com/artur-rios/alexandria-ui/issues/27) | UC-26 — Manage collections — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#28](https://github.com/artur-rios/alexandria-ui/issues/28) | UC-27 — Organize items into collections — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#29](https://github.com/artur-rios/alexandria-ui/issues/29) | UC-28 — Manage bookmarks — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-09 — Watchlists and reading lists

| Issue | Work | Spec |
| --- | --- | --- |
| [#30](https://github.com/artur-rios/alexandria-ui/issues/30) | UC-29 — Manage watchlists — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#31](https://github.com/artur-rios/alexandria-ui/issues/31) | UC-30 — Track watch progress — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#32](https://github.com/artur-rios/alexandria-ui/issues/32) | UC-31 — Manage reading lists — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#33](https://github.com/artur-rios/alexandria-ui/issues/33) | UC-32 — Track reading progress — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-10 — Deletion lifecycle

| Issue | Work | Spec |
| --- | --- | --- |
| [#34](https://github.com/artur-rios/alexandria-ui/issues/34) | UC-33 — Delete an item — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#35](https://github.com/artur-rios/alexandria-ui/issues/35) | UC-34 — Browse and restore deleted items — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#36](https://github.com/artur-rios/alexandria-ui/issues/36) | UC-35 — Purge a record — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#37](https://github.com/artur-rios/alexandria-ui/issues/37) | UC-36 — Purge a file on disk — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#38](https://github.com/artur-rios/alexandria-ui/issues/38) | UC-37 — Review missing files — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-11 — Indexing experience

Built on the core's UC-42 and UC-48 — the run status query, the outstanding-runs
listing, and the pause, resume, and cancel controls.

| Issue | Work | Spec |
| --- | --- | --- |
| [#103](https://github.com/artur-rios/alexandria-ui/issues/103) | UC-43 — Follow a scan while it runs — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#104](https://github.com/artur-rios/alexandria-ui/issues/104) | UC-44 — Pause, resume, or cancel a scan — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#105](https://github.com/artur-rios/alexandria-ui/issues/105) | UC-45 — Pace a scan — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-12 — Music library and playlists

**Removed (moved out of scope, see Orpheus).** Music management left Alexandria;
it lives in Orpheus, the owner's separate project. Alexandria plays tracks
(`UC-20`) but browses no music library and keeps no playlists or play history.
The milestone and its use cases keep their numbers so that nothing else is
renumbered.

| Issue | Work | Spec |
| --- | --- | --- |
| — | UC-46 — Browse the music library — Removed (moved out of scope, see Orpheus) | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| — | UC-47 — Manage a playlist — Removed (moved out of scope, see Orpheus) | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| — | UC-48 — Play a playlist — Removed (moved out of scope, see Orpheus) | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| — | UC-50 — See what has been played most — Removed (moved out of scope, see Orpheus) | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-13 — Libraries

| Issue | Work | Spec |
| --- | --- | --- |
| — | UC-49 — Browse a library — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-14 — Library navigation

The left menu lists the libraries instead of file types, a library opens in the
main area, home shows the favorite libraries and the totals, and library
management moves to the menu bar. `UC-14`, `UC-38` and `UC-49` were rewritten
for it.

| Issue | Work | Spec |
| --- | --- | --- |
| — | UC-52 — Pin a library — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| — | UC-53 — Mark a favorite library — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| — | UC-54 — Rename a library — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

## Changelog

Notable changes in each release are recorded in [CHANGELOG.md](./CHANGELOG.md).

## Contributing

Building from source, the development loop, running the tests, the branching
model and the release process are described in [CONTRIBUTING.md](./CONTRIBUTING.md).

The GitHub repository is a read-only mirror for the real, open-source code of alexandria-ui. Its home is Forgejo, at
https://git.techcraftsmen.net/artur-rios/alexandria-ui. If you want to contribute, e-mail me at arturdev@duck.com.

## Legal

Copyright © 2026 Artur Rios.

This project is licensed under the [Artur Rios Attribution License](LICENSE).
It is free and open source: you may view, use, fork, modify, and extend it,
provided you credit the author, Artur Rios, with a link to
[artur-rios.tech](https://artur-rios.tech) or
[github.com/artur-rios](https://github.com/artur-rios).

The same licence covers the [Alexandria core](https://github.com/artur-rios/alexandria-api),
which this application links in process.

### Bundled libraries

The Attribution License covers this repository's source code. The third-party
libraries the release packages carry are not part of it: each keeps its own
licence.

The Linux packages are meant to be plug and play: unpack one on a machine with
a desktop and it runs, with no libraries to install first. Doing that means
carrying the libraries the program needs, and the ones a media library cannot
do without are copyleft — `libmpv`, which plays the video, and `libx264` and
`libx265`, which ffmpeg links whether or not anything ever encodes with them.
Every bundled library's licence travels in `lib/licenses`, and the ones known
to be copyleft are listed in `lib/licenses/COPYLEFT.tsv`. A Linux binary
package that bundles them is distributed as a combined work subject to those
libraries' terms, which means the GPL, version 3.

The Windows packages carry an LGPL build of ffmpeg and no mpv, so they raise
none of this.
