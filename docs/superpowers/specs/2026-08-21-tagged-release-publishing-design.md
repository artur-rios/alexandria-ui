# Tagged release publishing, install programs, and portable archives

**Date:** 2026-08-21
**Status:** approved

## Problem

`.github/workflows/release.yml` already builds every package the project ships
— an MSIX, an Inno Setup installer executable, a `.deb`, an AppImage, and a
Flatpak — on a `v*` tag. It then stops at `actions/upload-artifact`. Nothing
creates a GitHub Release, so the packages are reachable only from a workflow
run page, expire with the artifact retention window, and cannot be linked to.

Three gaps follow from that, and one more sits beside it:

1. A tag produces no release.
2. There is no way to run the application without going through a package
   manager or an installer.
3. The Windows installer overwrites whatever is in the chosen directory. A
   stale DLL from an older version survives an upgrade and is loaded in
   preference to the new one — the failure mode is an unrelated-looking "core
   could not be loaded".
4. Linux has three packages and no plain install program, so a user who wants
   neither dpkg, nor AppImage, nor Flatpak has nothing to run.

## Design

### 1. The release job

`release.yml` gains a third job, `release`, with `needs: [windows, linux]` and
`if: startsWith(github.ref, 'refs/tags/')` — `workflow_dispatch` keeps
producing artifacts and nothing else, because a manual run has no tag to
release against.

It holds `permissions: contents: write`, downloads both package artifacts, and
publishes with `softprops/action-gh-release@v2`:

- `generate_release_notes: true`, so the notes come from the commits since the
  previous tag rather than from a file nobody remembers to write.
- `prerelease` is true when the version starts with `0.`. `v0.0.1` therefore
  lands as a prerelease.

Assets: the Windows setup `.exe`, the `.msix`, the Windows portable `.zip`,
the Linux installer `.sh`, the `.deb`, the `.AppImage`, the `.flatpak`, and the
Linux portable `.tar.gz`.

### 2. Portable archives

For the user who wants to run the program without an install step.

- **Windows** — `alexandria-<version>-windows-x64.zip`, the whole
  `build/windows/x64/runner/Release` directory. Produced *after* the step that
  verifies every linked library is present, so the archive cannot ship without
  `alexandria_ffi.dll` and the seven ffmpeg DLLs.
- **Linux** — `alexandria-<version>-linux-x64.tar.gz`, the whole
  `build/linux/x64/release/bundle` directory, carrying `libalexandria_ffi.so`
  in `lib/`. The known ffmpeg gap documented in the workflow header applies
  here exactly as it applies to the three Linux packages.

### 3. Replacing an existing installation

Both installers follow the same policy, decided deliberately: **run the
previous uninstaller if there is one, otherwise remove only what this payload
writes.** Neither blind-deletes the chosen directory. A user who points the
installer at a folder holding unrelated files must not lose them.

Both also look for an installation at a *different* location than the one
being chosen, and offer to remove it, so that changing the install path does
not silently leave two copies on the machine.

#### Windows — `packaging/windows/installer.iss`

`[Setup]` gains:

- `CloseApplications=yes` / `RestartApplications=no` — the Restart Manager
  closes a running Alexandria, so replacing a file cannot fail on a lock.
- `PrivilegesRequiredOverridesAllowed=dialog` — `DefaultDirName` is
  `{autopf}`, so the user chooses per-machine or per-user.

A `[Code]` section adds:

- `InitializeSetup` reads `InstallLocation` and `UninstallString` from
  `Uninstall\{AppId}_is1` under HKLM and then HKCU.
- `NextButtonClick(wpSelectDir)` inspects the directory the user actually
  chose. An existing install is `alexandria_desktop.exe` or `unins000.exe`
  present in it. If found, it asks to replace; on refusal it stays on the
  page. On acceptance it runs that directory's `unins000.exe` with
  `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART` and waits, and if there is no
  uninstaller it deletes only the payload's own paths.
- If the registry named a directory other than the one chosen, that
  installation is offered for removal separately.

#### Linux — `packaging/linux/install.sh`

POSIX `sh`. The release workflow concatenates it with the portable tarball
below a `__PAYLOAD__` marker to produce a single self-extracting
`alexandria-installer-<version>-linux-x64.sh`. The script finds the payload
offset with `awk` and pipes the remainder through `tar`.

- Flags: `--prefix DIR`, `--yes`, `--uninstall`, `--help`.
- Default prefix: `/opt/alexandria` as root, `$HOME/.local/share/alexandria`
  otherwise. Prompted interactively with that default unless `--yes`.
- An install manifest at `$XDG_STATE_HOME/alexandria/install.manifest`
  (`/var/lib/alexandria/install.manifest` as root) records the prefix, the
  launcher, the desktop entry, and every installed file. It is what makes
  "remove exactly what the last install wrote" possible, and it is the Linux
  counterpart to the Windows uninstall registry key.
- Installs the bundle into the prefix, writes the `.desktop` entry into
  `applications/`, symlinks a launcher onto `PATH` (`~/.local/bin` or
  `/usr/local/bin`), and runs `update-desktop-database` when it exists.

### 4. The tag

`v0.0.1`, matching the workflow's existing `v*` trigger. The workflow strips
the leading `v`, so the version carried by the packages is `0.0.1`.

## Known gaps, carried deliberately

- **The core is not pinned here.** `release.yml` sets `CORE_REF: main` where
  `ci.yml` pins a commit. What a tag links against is whatever the core's
  `main` was at build time, so a tag is not reproducible. Changing it is a
  separate decision from this one.
- **No icon exists.** `io.github.artur_rios.Alexandria.desktop` declares
  `Icon=io.github.artur_rios.Alexandria` and the repository contains no icon
  file, so the desktop entry falls back to a generic icon. Pre-existing; the
  Flatpak has the same hole.
- **The Linux packaging steps are unproven.** `flutter_distributor` and
  `flatpak-builder` have never run on a tag. The first tag may fail on them.
- **ffmpeg on Linux.** Unchanged by this work, and documented at length in the
  workflow header.
