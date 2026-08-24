# A clean environment for the development loop

**Date:** 2026-08-24
**Status:** approved

## Problem

`tools/dev.ps1` and `tools/dev.sh` build the core, wire it into the checkout,
and run the application. What they cannot do is start it from nothing.

State survives every run. The scratch catalog in `.dev/` carries the previous
run's index. `shared_preferences.json` carries the theme, the language and the
window geometry. The core's thumbnail cache carries thumbnails keyed by uuid
and mtime, so they outlive the catalog that produced them. Testing first-launch
behaviour — the startup sequence, an empty library, the onboarding an owner
sees once — means finding and deleting each of those by hand, and the comment
in both scripts saying settings and logs live elsewhere is the only record of
where to look.

Two things follow: the dev loop needs an option that starts from nothing, and
the wipe itself needs to be runnable on its own, because wanting a clean
environment and wanting to build the core are separate wants.

## Design

### 1. Shape

Two new scripts, `tools/clean.ps1` and `tools/clean.sh`, own the wipe. They
take no core checkout and run no toolchain preflight — they delete, report what
they deleted, and exit. Nothing else in the repository knows the list of paths.

`dev.ps1` gains `-Clean` and `dev.sh` gains `--clean`, each invoking its
platform's clean script as the first step, before the toolchain preflight. The
delegation is what keeps one definition of "everything from previous runs";
the standalone script is the real script rather than a wrapper around a copy
that will drift.

Flags on the clean scripts:

- `-RealCatalog` / `--real-catalog` — also delete the real catalog. Off by
  default, for the reason `-RealData` is off by default in the dev scripts.
- `-WhatIf` / `--dry-run` — list what would be removed and touch nothing.
  `-WhatIf` on Windows comes from `SupportsShouldProcess` rather than a
  hand-rolled parameter of the same name.
- `-Help` / `--help` on the shell script, matching `dev.sh`.

`-Clean` on the dev scripts never passes `-RealCatalog`. `-Clean` together with
`-RealData` is not an error — it cleans everything else and prints a note that
the real catalog was left alone and that `tools/clean.ps1 -RealCatalog` is how
to ask for it.

### 2. What is removed

Runtime state only. Build output — `build/`, `.dart_tool/`, `native/*.dll`, the
core's `target/` — is left alone: this is a fresh install, not a fresh clone,
and a clean run should not cost a full rebuild.

Four paths, in this order:

1. **The scratch catalog.** `.dev/`, whole. Both dev scripts already put
   `catalog.db` there and the directory is already git-ignored.

2. **The application-support folder.** On Windows
   `%APPDATA%\com.arturrios\Alexandria\`; on Linux
   `${XDG_DATA_HOME:-~/.local/share}/io.github.artur_rios.Alexandria/`. It
   holds `shared_preferences.json` — theme, locale, window geometry (IR-12) —
   and the `Alexandria\` subfolder `CorePaths.resolveApplicationDirectory`
   creates, which is where `catalog.db` and `logs\` live (IR-05, IR-13).

   The Windows name is `CompanyName\ProductName` from the executable's
   VERSIONINFO, which `windows/runner/Runner.rc` sets to `com.arturrios` and
   `Alexandria`. The Linux name is the GTK application id, which
   `linux/CMakeLists.txt` sets to `io.github.artur_rios.Alexandria`. Both are
   written as constants in the clean scripts with a comment naming the file
   they must agree with; deriving them at run time would trade one fragility
   for a worse one.

3. **The thumbnail cache.** `thumbnails/` at the repository root — the core's
   `playback.thumbnail_cache_dir` defaults to a path relative to the working
   directory, and a checkout run has the repository root as its working
   directory.

4. **Folders left by earlier versions.** On Windows
   `%APPDATA%\com.arturrios\alexandria_desktop\`, from before commit d86b493
   renamed the application. On Linux the same
   `com.arturrios.alexandria_desktop` folder, plus
   `${XDG_DATA_HOME:-~/.local/share}/alexandria/` —
   `path_provider_linux` reads an executable-name folder in preference to the
   application-id one when it exists, so a stale one is not merely clutter but
   state the application would still load.

Nothing else. In particular:

- **No library source folder is ever named.** The scripts delete the four paths
  above and nothing derived from the catalog, so no indexed folder — music,
  video, images — can be reached by them. This is the property the whole
  feature has to hold.
- **The real catalog is preserved without `-RealCatalog`.** The
  application-support folder is still emptied around it: `shared_preferences.json`
  and `logs/` go, `Alexandria/catalog.db` stays, and a note says so. With
  `-RealCatalog` the folder is removed whole.
- `config.toml` at the repository root, if one exists, is authored rather than
  generated, and is left alone.

### 3. Containing what future runs write

The thumbnail cache is the one piece of state whose location is not fixed: it
follows the working directory, so a run started from somewhere else leaves a
cache the clean script will not find.

Both dev scripts therefore export `ALEXANDRIA_PLAYBACK_THUMBNAIL_CACHE_DIR`
pointing at `.dev/thumbnails`, beside the existing `ALEXANDRIA_DATABASE_PATH`
redirect, so that everything a dev run writes outside the application-support
folder is inside one already-ignored directory. It is set for scratch runs and
for `-RealData` alike: a real catalog is a reason not to touch the index, not a
reason to scatter cache files.

The clean script still removes a repository-root `thumbnails/`, for runs made
before this change.

### 4. Output and failure

The existing `Write-Step` / `Write-Note` and `step` / `note` helpers, so a
clean run reads like the dev run it precedes. One line per path: removed
(with what it was), absent, or preserved. A dry run prints the same lines
under a heading saying nothing was touched.

A path that cannot be deleted fails the script, naming the path and saying the
likely reason is that Alexandria is still running — on Windows a locked
`catalog.db` or a loaded `alexandria_ffi.dll` otherwise surfaces as a bare
access-denied that reads like a permissions problem.

### 5. Documentation

The scripts are self-documenting in the style the repository already uses: a
comment-based help block in `clean.ps1` with `.SYNOPSIS`, `.DESCRIPTION`, a
`.PARAMETER` per flag and worked `.EXAMPLE`s; a header comment and a `usage`
function in `clean.sh`. `dev.ps1`'s help gains a `.PARAMETER Clean`, and
`dev.sh`'s `usage` gains a `--clean` line.

`README.md`'s development section mentions the clean scripts where it describes
the dev loop.

## Testing

These are shell scripts around file deletion, and the repository has no harness
for them, so verification is by running them:

1. `tools/clean.ps1 -WhatIf` on a machine with state present — every path is
   listed, and every one of them still exists afterwards.
2. `tools/clean.ps1` — the listed paths are gone, `Alexandria/catalog.db` is
   preserved with a note if it existed, and the legacy `alexandria_desktop`
   folder on this machine is removed.
3. `tools/clean.ps1` again — every path reports absent and the exit code is
   zero, because a clean environment cleaned twice is still a clean
   environment.
4. `tools/dev.ps1 -Clean -SkipCore` — the wipe runs first, the application
   starts, and it starts as a first launch: default theme, default window size,
   an empty library.
5. `tools/dev.ps1 -Clean -RealData -NoRun` — the note about the real catalog
   is printed and `Alexandria/catalog.db` still exists.
6. A library source folder indexed before step 2 still holds every file it
   held, which is the property that matters most and the one no amount of
   reading the script proves.

Linux verification of the same steps is left to the next run on Linux, as the
existing scripts' Linux paths are.
