# Alexandria UI

The cross-platform desktop front-end for
[Alexandria](https://github.com/artur-rios/alexandria-api), a personal library
system that indexes, organizes, and surfaces a single person's on-disk media and
documents. This application is where the owner actually sees and uses that
library: it browses the catalog, plays audio and video, reads documents and
comics, edits Markdown and text in place, and organizes everything into
collections, watchlists, and reading lists. It links the Alexandria Rust core in
process over FFI rather than talking to a server, so the whole product runs as a
single local application with no network hop between the interface and its data.

> **Status:** all forty-six issues are delivered — the foundation and
> every use case in the backlog below.

> Windows and Ubuntu. Single-user. Metadata and content editing only — never
> re-encoding, never relocating, and never deleting a file from disk without an
> explicit confirmation.

## What it does

- Browses the catalog by file type — music, movies, series, HTML pages, Markdown
  and text notes, PDFs and e-books, comic books, images, and browser bookmarks —
  in list, detailed-list, and grid layouts.
- Registers one or more library folders and runs indexing and re-scans from the
  interface — indexing a folder as soon as it is added, showing live progress
  wherever the owner happens to be, and letting a scan be paused, resumed,
  cancelled, or paced down while it works.
- Plays video with full screen, seeking, subtitle tracks, and audio tracks.
- Plays audio in a persistent player, with the disc, vinyl, or tape animation
  turning for the duration of an album or artist and stopping on pause.
- Counts what is played and ranks it — most played tracks, artists, albums,
  and genres — where a track counts once half of it, or four minutes of it,
  has been heard.
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
- Signs the owner up, logs them in, and gets them back in with one of the ten
  single-use recovery codes the core mints at registration — shown once, and
  regenerated on request.
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
- No mail of any kind: the account's address is a login identifier and nothing
  else. Recovery is the core's single-use codes, not a message.
- No server, no cloud, no synchronization.
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

It asks where to install, defaulting to `~/.local/share/alexandria` — or
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

## Building from source

The product is three repositories: this one is the front end, the
[Alexandria core](https://github.com/artur-rios/alexandria-api) is a Rust
library it links in process over FFI, and
[alexandria-docs](https://github.com/artur-rios/alexandria-docs) is the
documentation site. Running the real thing locally means building the first
two.

Prerequisites, per the
[Technology Stack Document](docs/requirements/Technology%20Stack%20Document.md):

- The Flutter SDK, with the desktop target for your platform enabled.
- The Rust toolchain, to build the core.
- **Windows:** Windows 10 x64 or later, with the Visual Studio C++ desktop
  workload, LLVM, and `FFMPEG_DIR` pointing at a *shared* ffmpeg build — one
  with `include\`, `lib\` and `bin\` together, not one that only ships
  `ffmpeg.exe`. The core repository's README walks through installing one.
- **Linux:** Ubuntu LTS x64, with the GTK, ffmpeg, and libmpv development
  packages:

  ```bash
  sudo apt-get install ninja-build libgtk-3-dev libmpv-dev mpv \
    libavformat-dev libavcodec-dev libavutil-dev libavfilter-dev \
    libavdevice-dev libswscale-dev libswresample-dev pkg-config clang
  ```

```bash
git clone https://github.com/artur-rios/alexandria-ui.git
git clone https://github.com/artur-rios/alexandria-api.git
cd alexandria-ui
```

Cloning them side by side is what lets the tooling below find the core without
being told where it is.

### The development loop

One script builds the core, puts its shared library where the loader looks,
regenerates the FFI bindings if the core's header moved, and starts the
application against it.

```powershell
.\tools\dev.ps1
```

```bash
./tools/dev.sh
```

Once it is running, `r` hot-reloads Dart changes and `R` restarts. **Changing
the core needs the script again** — the shared library is loaded once, at
startup, so a rebuilt core is not picked up by a reload.

When only Dart changed, skip the core build entirely. This is the common case
and takes about two seconds:

```powershell
.\tools\dev.ps1 -SkipCore
```

```bash
./tools/dev.sh --skip-core
```

| What you want | PowerShell | sh |
| --- | --- | --- |
| A core checkout somewhere else | `-Core <path>` | `--core <path>` |
| Skip the core build | `-SkipCore` | `--skip-core` |
| Unoptimised core, faster to compile | `-DebugBuild` | `--debug` |
| Use the real catalog, not a scratch one | `-RealData` | `--real-data` |
| Start from nothing, as a first launch would | `-Clean` | `--clean` |
| Re-run build_runner and gen-l10n | `-Generate` | `--generate` |
| Build and wire up, but do not start | `-NoRun` | `--no-run` |

`ALEXANDRIA_CORE_REPO` sets the core's location without passing it each time.

The two knobs this application shares a concept with the core over are spelled
the same on both sides — `ALEXANDRIA_DATABASE_PATH` and
`ALEXANDRIA_LOGGING_LEVEL` — so there is one name per concept across the
product. They are not the same *mechanism*, though, and the difference matters
when one of them appears not to take:

- `ALEXANDRIA_DATABASE_PATH` is read from the environment at startup. The
  application resolves it and hands the path to the core over FFI, so this side
  is the one that decides.
- `ALEXANDRIA_LOGGING_LEVEL` sets **this** application's level at build time,
  through `--dart-define`, so changing it means rebuilding. The same name in the
  environment sets the core's own level at run time. Setting both is how you
  turn up both halves.

> **Runs use a scratch catalog.** The script points `ALEXANDRIA_DATABASE_PATH` at
> `.dev/catalog.db`, so indexing a folder, deleting an item, or testing a purge
> never touches a catalog you care about. `-RealData` / `--real-data` opts out.
> Settings and the log file are *not* redirected — they live in the
> application-support directory and are shared with an installed copy, which is
> worth knowing before blaming the scratch database for remembered state, and
> which is why starting over takes the clean script below rather than deleting
> one file.

### Starting from a clean environment

State outlives a run: the scratch catalog carries the previous index, the
preferences file carries the theme, the language and the window geometry, and
the core's thumbnail cache outlives the catalog that produced it. Seeing what an
owner sees the first time they open the application means removing all three.

```powershell
.\tools\clean.ps1
```

```bash
./tools/clean.sh
```

It removes the scratch catalog, the application-support folder holding the
preferences and the log, the thumbnail cache, and the folders left behind by
earlier versions of the application. Build output is left alone — this is a
fresh install, not a fresh clone — and no library source folder can be reached,
because not one of the paths it deletes is derived from the catalog.

The real catalog, the one `-RealData` runs against, survives unless you ask for
it by name with `-RealCatalog` / `--real-catalog`. `-WhatIf` / `--dry-run` lists
what would go and touches nothing.

`-Clean` / `--clean` on the development script does the same before building, so
one command starts the application from nothing.

### Doing it by hand

The script is a convenience, not a dependency. The same thing, step by step:

```bash
# 1. Build the core.
cd ../alexandria-api
cargo build -p alexandria-ffi --release

# 2. Put it where IR-04's resolver looks, relative to the working directory.
cd ../alexandria-ui
cp ../alexandria-api/target/release/libalexandria_ffi.so native/linux/
#  Windows: copy ..\alexandria-api\target\release\alexandria_ffi.dll native\windows\

# 3. If the core's API changed, re-vendor its header and regenerate bindings.
cp ../alexandria-api/crates/alexandria-ffi/src/header.h native/include/alexandria_ffi.h
dart run ffigen --config ffigen.yaml

# 4. Dart code generation, when models or translations changed.
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n

# 5. Run.
flutter run -d linux
```

`ALEXANDRIA_CORE_LIBRARY` overrides step 2 entirely, pointing the application
at a library wherever it happens to be.

The header in step 3 is generated by the core's build, so it exists only after
step 1. CI compares the vendored copy against the core's and fails on a
difference, which is the check the script performs locally — normalising line
endings first, since a Windows checkout stores the vendored copy with CRLF
while the generator writes LF.

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

The layering rules — Presentation and Application never importing Data, and
Domain importing nothing outward — are analyzer rules in `tools/alexandria_lints`
and run with the analyzer:

```bash
flutter analyze --fatal-infos --fatal-warnings
```

```bash
dart run custom_lint
```

They are proven against deliberately-violating fixtures by a third suite, which
shells out to the analyzer and so runs on its own rather than on every change:

```bash
flutter test analysis_test --timeout 5x
```

Golden files guard the theme and layout of the key screens. They live beside
the suites that use them, in `goldens/`, and are regenerated deliberately:

```bash
flutter test --update-goldens
```

**Look at the regenerated images in the pull request.** A golden updated without
being looked at is worse than no golden — it turns a visual regression into a
committed one. Note that `flutter test` loads no real font, so text and icons
render as boxes: these images capture colour, spacing, and layout, and what the
screens *say* is covered by the widget suites in both languages.

Tests are named with the Given-When-Then pattern
(`GivenSomeCondition_WhenSomeAction_ThenSomeOutcome`). Every use case ships with
its tests before its pull request is opened.

## Roadmap

Thirteen milestones covering fifty-one issues: one foundation issue plus one
issue per use case. Milestones are dependency-ordered — no milestone depends on
a later one, and every milestone after `M-01` depends on it.

| Milestone | Delivers | Depends on | Issues | Status |
| --- | --- | --- | --- | --- |
| [M-01 — Foundation](https://github.com/artur-rios/alexandria-ui/milestone/1) | The project scaffold, the core bindings, and the cross-cutting infrastructure every use case is built on | — | 1 | 1 / 1 closed |
| [M-02 — Shell and access](https://github.com/artur-rios/alexandria-ui/milestone/2) | A window the owner can open, navigate, theme, translate, sign up for, sign in to, and recover access to | M-01 | 9 | 9 / 9 closed |
| [M-03 — Library sources and indexing](https://github.com/artur-rios/alexandria-ui/milestone/3) | Folders can be registered, indexed, refreshed, and unregistered — the catalog gets its content | M-02 | 4 | 4 / 4 closed |
| [M-04 — Catalog browsing and search](https://github.com/artur-rios/alexandria-ui/milestone/4) | The library can be browsed by type, laid out three ways, searched, filtered, sorted, and summarized on a dashboard | M-03 | 6 | 6 / 6 closed |
| [M-05 — Metadata and content editing](https://github.com/artur-rios/alexandria-ui/milestone/5) | Music and video metadata, file names, and text content can be edited | M-04 | 4 | 4 / 4 closed |
| [M-06 — Media playback](https://github.com/artur-rios/alexandria-ui/milestone/6) | Video plays with subtitles and audio tracks; audio plays with a queue, a full player, and the sound of the track drawn from the recording | M-04 | 3 | 3 / 3 closed |
| [M-07 — Document and image viewing](https://github.com/artur-rios/alexandria-ui/milestone/7) | PDFs, e-books, comics, images, and saved pages can be read | M-04 | 4 | 4 / 4 closed |
| [M-08 — Collections and bookmarks](https://github.com/artur-rios/alexandria-ui/milestone/8) | Files and bookmarks can be grouped, and bookmarks managed and opened | M-04 | 3 | 3 / 3 closed |
| [M-09 — Watchlists and reading lists](https://github.com/artur-rios/alexandria-ui/milestone/9) | Movies, series, books, and comics can be tracked with per-episode and per-issue progress | M-08 | 4 | 4 / 4 closed |
| [M-10 — Deletion lifecycle](https://github.com/artur-rios/alexandria-ui/milestone/10) | Items can be deleted, restored, purged, purged on disk, and reviewed when missing | M-04 | 5 | 5 / 5 closed |
| [M-11 — Indexing experience](https://github.com/artur-rios/alexandria-ui/milestone/11) | A scan is visible from anywhere, controllable while it runs, and paceable; a newly registered folder indexes itself | M-03 | 3 | 3 / 3 closed |
| M-12 — Music library and playlists | The audio library browsed by album and artist with its own photographs, playlists curated and played, and what has been played most | M-06 | 4 | 4 / 4 closed |
| M-13 — Libraries | A folder browsed as its own tree, whose files are shown there rather than scattered across the type panels | M-04 | 1 | 1 / 1 closed |

GitHub's milestone pages are the live view of progress; the counts here are as
of the last update to this file. `M-12` and `M-13` carry no milestone links and
no issue numbers, and that is honest rather than an omission: they were built
from design documents in `docs/superpowers/specs/` rather than from the
issue-per-use-case backlog the first eleven follow. They are specified all the
same — `UC-46` … `UC-50` and their requirements are in the same two documents
as everything above them.

**The two repositories agree.** `CORE_REF` tracks the core that refuses to be
re-initialized while it is walking a disk, which the preferences dialog reads
to say that a lookup setting changed mid-scan takes effect when the scan
finishes. That core also carries the review fixes this application depends on
being there: a library that no longer claims folders differing only in case, a
re-encoded track that no longer keeps the old recording's envelope, and an
album ranking grouped by title *and* artist — which is what makes the
statistics screen agree with the music browsing beside it. Earlier divergences
are closed on both sides too:

- **Account recovery is recovery codes.** The core dropped e-mail confirmation
  and password reset and replaced them with ten single-use codes minted at
  registration. `UC-40`, `UC-41`, and `UC-42` are specified against those calls
  now — *Save the recovery codes*, *Recover access with a recovery code*, and
  *Regenerate the recovery codes* — and `FR-AU-12` … `FR-AU-19` with them. The
  catalog is no longer gated on a confirmation the core does not perform.
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

| Issue | Work | Spec |
| --- | --- | --- |
| [#39](https://github.com/artur-rios/alexandria-ui/issues/39) | UC-38 — Navigate the application shell — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#40](https://github.com/artur-rios/alexandria-ui/issues/40) | UC-39 — Manage application preferences — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#2](https://github.com/artur-rios/alexandria-ui/issues/2) | UC-01 — Sign up — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#3](https://github.com/artur-rios/alexandria-ui/issues/3) | UC-02 — Log in — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#4](https://github.com/artur-rios/alexandria-ui/issues/4) | UC-03 — Sign out — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#5](https://github.com/artur-rios/alexandria-ui/issues/5) | UC-04 — Change credentials — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#41](https://github.com/artur-rios/alexandria-ui/issues/41) | UC-40 — Save the recovery codes — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#42](https://github.com/artur-rios/alexandria-ui/issues/42) | UC-41 — Recover access with a recovery code — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#43](https://github.com/artur-rios/alexandria-ui/issues/43) | UC-42 — Regenerate the recovery codes — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-03 — Library sources and indexing

| Issue | Work | Spec |
| --- | --- | --- |
| [#6](https://github.com/artur-rios/alexandria-ui/issues/6) | UC-05 — Register a library folder — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#7](https://github.com/artur-rios/alexandria-ui/issues/7) | UC-06 — Index a library folder — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#8](https://github.com/artur-rios/alexandria-ui/issues/8) | UC-07 — Refresh the catalog — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#9](https://github.com/artur-rios/alexandria-ui/issues/9) | UC-08 — Unregister a library folder — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-04 — Catalog browsing and search

| Issue | Work | Spec |
| --- | --- | --- |
| [#10](https://github.com/artur-rios/alexandria-ui/issues/10) | UC-09 — Browse the library by type — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#11](https://github.com/artur-rios/alexandria-ui/issues/11) | UC-10 — Switch the view layout — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#12](https://github.com/artur-rios/alexandria-ui/issues/12) | UC-11 — Search the catalog — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#13](https://github.com/artur-rios/alexandria-ui/issues/13) | UC-12 — Filter and sort a listing — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#14](https://github.com/artur-rios/alexandria-ui/issues/14) | UC-13 — View a file's details — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#15](https://github.com/artur-rios/alexandria-ui/issues/15) | UC-14 — View the home dashboard — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-05 — Metadata and content editing

| Issue | Work | Spec |
| --- | --- | --- |
| [#16](https://github.com/artur-rios/alexandria-ui/issues/16) | UC-15 — Edit music metadata — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#17](https://github.com/artur-rios/alexandria-ui/issues/17) | UC-16 — Edit video metadata — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#18](https://github.com/artur-rios/alexandria-ui/issues/18) | UC-17 — Rename a file — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#19](https://github.com/artur-rios/alexandria-ui/issues/19) | UC-18 — Edit a Markdown or text file — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-06 — Media playback

| Issue | Work | Spec |
| --- | --- | --- |
| [#20](https://github.com/artur-rios/alexandria-ui/issues/20) | UC-19 — Play a video — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#21](https://github.com/artur-rios/alexandria-ui/issues/21) | UC-20 — Play audio — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| [#22](https://github.com/artur-rios/alexandria-ui/issues/22) | UC-21 — Show the album playback animation — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

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

The audio library as a library rather than a file listing: browsed by album and
artist, with the photograph the core holds for each; playlists curated and
played; and what has been played most, counted by the player and ranked by the
core.

| Issue | Work | Spec |
| --- | --- | --- |
| — | UC-46 — Browse the music library — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| — | UC-47 — Manage a playlist — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| — | UC-48 — Play a playlist — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |
| — | UC-50 — See what has been played most — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

### M-13 — Libraries

| Issue | Work | Spec |
| --- | --- | --- |
| — | UC-49 — Browse a library — done | [Use Case Specification](docs/requirements/Use%20Case%20Specification%20Document.md) |

## Contributing

One use case = one branch = one issue = one pull request. The full process —
branch naming, issue status lifecycle, the approval gates, the testing gate, and
the Definition of Done — is in the
[Development Workflow Document](docs/requirements/Development%20Workflow%20Document.md).

## Legal

Copyright © 2026 Artur Rios.

Alexandria UI is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version. The full text is in [LICENSE](LICENSE).

It is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

The same terms cover the [Alexandria core](https://github.com/artur-rios/alexandria-api),
which this application links in process. The two are one program in the sense
the licence means, so they are licensed alike.

### Why copyleft

The Linux packages are meant to be plug and play: unpack one on a machine with
a desktop and it runs, with no libraries to install first. Doing that means
carrying the libraries the program needs, and the ones a media library cannot
do without are copyleft — `libmpv`, which plays the video, and `libx264` and
`libx265`, which ffmpeg links whether or not anything ever encodes with them.
Distributing those alongside the application is what puts the whole of it under
the GPL. Every bundled library's licence travels in `lib/licenses`, and the
ones known to be copyleft are listed in `lib/licenses/COPYLEFT.tsv`.

The Windows packages carry an LGPL build of ffmpeg and no mpv, so they raise
none of this. They are covered by the same licence regardless, because the
program is the same program.
