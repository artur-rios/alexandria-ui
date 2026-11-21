# Checking for updates at startup

**Date:** 2026-11-21
**Status:** approved

## Why

Alexandria is a desktop application installed from a release's packages. Nothing tells an owner that a newer release
exists: they find out only by visiting the release page. The owner wants the application to check for a new release
when it starts, say so when there is one, and update itself when they agree.

## Goals

- **The check.** On every start of a release build, the application asks for the latest release in the background.
  The answer must never delay or block startup.
- **The prompt.** When the latest release is newer than the running one, a dialog shows:
  - the new version and its release notes (the changelog section the release publishes);
  - **Update now**, **Later**, and **Skip this version**.
- **Updating, where the package can update itself.** **Update now** does the following:
  1. downloads the right installer, showing progress, with a way to cancel;
  2. verifies the download's SHA-256 against the checksums the release publishes;
  3. closes the application, asking first about unsaved edits and saying that a running scan will pause;
  4. installs over the current installation, keeping the owner's data. The new version is staged beside the old one
     and swapped in only when it has been copied completely, so a failed update leaves the old version working (the
     owner's decision);
  5. starts the updated application again.
- **Packages that cannot update themselves.** The dialog explains how to update and opens the release page.
- **The setting.** A Preferences toggle, "Check for updates at startup", is **on by default** (the owner's decision).
  Preferences also offers "Check now", which runs the same check and reports "You're up to date" when there is nothing
  newer. "Check now" offers a skipped version anyway: it is an explicit request, and the only way to undo a skip. The
  Flatpak never checks and hides the setting (§1).

## Non-goals

- No background or periodic checks while the application runs; only at start, and on "Check now".
- No downgrades, and no pre-releases. GitHub's `releases/latest` already leaves out pre-releases and drafts.
- No delta updates and no silent updates: every update is the owner's choice, made in the dialog.
- No updating of the `.deb`, Flatpak, portable zip or tarball, or MSIX. Those belong to the owner's package manager or
  to their own hands, and the dialog sends them to the download.
- The core is not updated separately. It ships inside every package, so a new package is a new core.

## Anti-goals

- **Nothing unverified runs.** A downloaded file whose SHA-256 does not match the checksum the release publishes is
  deleted and never run. A release that publishes no checksums cannot be installed by the application; for it, the
  dialog offers the download page instead.
- **Startup is never slowed or broken.** When the check fails — offline, rate-limited, a server error, an unreadable
  answer — it is logged and nothing is shown.
- **Nothing is sent but the request.** The request carries no identifying data beyond what any HTTPS request carries
  (the IP address). The User-Agent is `Alexandria/<version>`. There is still no telemetry.
- **Unsaved work is never lost.** Updating closes the application through the same "unsaved changes?" confirmation
  signing out uses. Ordinary window closing is unchanged: it does not start asking (my call — changing every close is
  a separate decision).
- **A failed update never leaves the owner without the application.** Both installers stage the new version and swap
  it in only after a complete copy (§3).

## Constraints

- **It reverses the documents' offline stance.** The Vision document's "no network call this application makes" and
  the operations document's "no telemetry" are updated: the application makes exactly one kind of call of its own,
  for updates, and it can be turned off.
- **Where releases live.** The source of truth is the public GitHub copy of the releases,
  `https://api.github.com/repos/artur-rios/alexandria-ui/releases/latest`. It is readable without a login, and
  unauthenticated reads are limited to 60 an hour per IP address, far more than one check per start needs. The URL is
  set by a `--dart-define` so that tests can point it elsewhere.
- **Version.** The running version is the pubspec version the release build stamps (`x.y.z`). The latest version is
  the tag without its `v`. Versions are compared as SemVer `major.minor.patch`; a tag that does not parse is ignored.
  Debug and profile builds (`!kReleaseMode`) never check, so a developer's `flutter run` reports nothing.
- **Unsigned packages.** The packages are unsigned, so integrity rests on HTTPS plus the published SHA-256. That
  checksum is what this design adds to the release.
- **Existing releases.** Releases up to and including 1.0.1 publish no checksums, and an installation of them has no
  updater anyway. The first release that carries this feature is updated to by hand, once.

## Approaches

Picked by the owner: **A**.

- **A. The application updates itself where its package allows it.** It checks GitHub's releases API, verifies the
  installer against a checksums file published with the release, and runs the existing installers. Packages that
  cannot update themselves get a link to the download. This builds on the installers the project already ships, which
  already replace an installation and keep the owner's data.
- **B. An updater library (`auto_updater`: Sparkle and WinSparkle).** Rejected: it covers Windows and macOS only, not
  Linux, and it needs an appcast feed and signing keys of its own.
- **C. Notify only.** Rejected: it does not update the application when the owner confirms.

## Design

### 1. How the application was installed

`InstallKind` is detected once at startup, each kind with the update it allows. "Current executable" means
`Platform.resolvedExecutable`.

| Kind | How it is recognised | What Update now does |
| --- | --- | --- |
| `windowsInstaller` | The Inno uninstall key `Software\Microsoft\Windows\CurrentVersion\Uninstall\{8F2A6C41-9B3E-4D77-A5C2-1E6D0B9F4A38}_is1` exists in HKCU or HKLM (64-bit or 32-bit view), its `InstallLocation` is the current executable's folder, and that folder is writable by the running user. A per-machine install the user cannot write to is `manual` (my call: no UAC prompts, matching Linux's root-owned `/opt`). | Run `alexandria-setup-<v>.exe` silently into that folder (§3). |
| `linuxInstaller` | A manifest exists at `$XDG_STATE_HOME/alexandria/install.manifest` (default `~/.local/state/alexandria/install.manifest`) or `/var/lib/alexandria/install.manifest`. Its recorded prefix contains the current executable, and that prefix is writable by the running user. | Run `alexandria-installer-<v>-linux-x64.sh --yes --prefix <prefix>` (§3). |
| `appImage` | `$APPIMAGE` is set, and its folder is writable. | Replace the file at `$APPIMAGE` with `alexandria-<v>-linux-x86_64.AppImage` (§3). |
| `flatpak` | `FLATPAK_ID` is set. | Nothing: the Flatpak has no network permission, and granting one would also open the network to saved pages (NFR-12). It never checks, and the Preferences switch and "Check now" are hidden (my call). |
| `manual` | Everything else: `.deb` (under `/usr`), the zip or tarball, MSIX (under `WindowsApps`), a root-owned `/opt` install run by an ordinary user, and anything not recognised. | Explain how this package updates, and open the release page. |

The kind is detected from facts on disk, not guessed. Anything uncertain is `manual`, which is always safe.

### 2. The check (`UpdateChecker`)

- **When it runs.** It starts once, when startup reaches ready (not per sign-in), unawaited, if the preference is on,
  the build is a release build, and the kind is not `flatpak`.
- **What it asks.** `GET <releasesUrl>` with `Accept: application/vnd.github+json`, `User-Agent: Alexandria/<version>`
  and a 10-second timeout. From the answer it reads:
  - `tag_name`, `body` (the notes) and `html_url` (the release page);
  - the `assets` list (`name`, `browser_download_url`, `size`).
- **What it answers.**
  - `UpToDate`;
  - `UpdateAvailable(version, notes, pageUrl, asset?, checksumsAsset?)`, where `asset` is the package for this
    `InstallKind` and `checksumsAsset` is §4's file;
  - `Skipped`, for a version the owner chose to skip — at startup only; "Check now" answers `UpdateAvailable` for it;
  - `CheckFailed`, for every failure. It is logged, and shown only for "Check now".
- **What it remembers.** The skipped version is stored in the settings store as `updates.skippedVersion`. A newer
  release than the skipped one is offered again.

### 3. Installing

All three self-updating kinds follow the same steps:

1. **Download.** The asset is downloaded to a fresh temporary folder, streaming, with progress (bytes against
   `size`). It can be cancelled, and a cancelled or failed download is deleted.
2. **Verify.** The checksums file is downloaded and the asset's line is found in it (`<sha256>  <name>`). The digest
   is computed with `package:crypto`. If they don't match, the file is deleted, the dialog says the download could
   not be verified, and nothing runs.
3. **Close.** The application closes through a new update path. It does not change ordinary window closing:
   - unsaved edits are confirmed exactly as signing out confirms them (`SignOutController.holdsUnsavedChanges` and its
     dialog);
   - when an index run is running, the dialog says the scan will pause and can be resumed after the update. The core
     records a run the application was closed on as paused;
   - session activities end, and the window geometry is recorded (`WindowGeometryController.record`);
   - the application writes a **pending-update marker**, `update-pending.json` in its support folder, holding
     `{from, to, at}`;
   - the updater is launched, detached so it outlives the application, and the application exits.
4. **Install, staged, and relaunch.** Both installers gain a staged mode. It is used by the updater, and by an
   interactive install that replaces an existing one:
   1. the new payload is written to a staging folder beside the install (`<install>.staging`);
   2. only after every file is written are the installer's **own paths** in the install swapped. Each recorded path of
      the old version is moved into a backup folder (`<install>.backup`), and each new path is moved in from staging;
   3. the backup is deleted after the swap.

   Paths, not the whole folder: the installers have always left files they did not write in the install folder alone,
   and the smoke tests pin that. A failure before the swap deletes the staging folder and leaves the old installation
   untouched. A failure during the swap moves the backed-up paths back. The manifest (Linux) and the uninstall key
   (Windows) are rewritten only after the swap, so they always describe what is on disk.
   - **Windows:** `installer.iss` installs into the staging folder and swaps in `[Code]`
     (`CurStepChanged(ssPostInstall)`), instead of running the old uninstaller before copying, as `NextButtonClick` on
     `wpSelectDir` does today.
     - The application runs the setup with `/SILENT /SUPPRESSMSGBOXES /NORESTART /DIR="<install folder>"` plus a new
       `/UPDATE` switch, then exits.
     - Under `/UPDATE`, the `MsgBox` prompts (ReplaceHere and RemoveElsewhere, which `/SUPPRESSMSGBOXES` does not
       silence) take their default answer: replace here, and leave other installs alone.
     - A `[Run]` entry with `Check: IsUpdate` and `Flags: runasoriginaluser nowait` starts the application again. The
       existing entry skips silent installs, so an updated application would not start otherwise.
     - Inno's `CloseApplications` already waits for it to close.
   - **Linux installer:** `install.sh` gains the same staging: extract into `<prefix>.staging`, swap path by path, then
     rewrite the manifest, instead of running `remove_recorded_install` before `extract_payload`.
   - **The Linux helper:** for the installer and the AppImage, the application writes a small `sh` helper beside the
     download and runs it detached (`setsid`). The helper:
     1. waits for the application's PID to exit;
     2. runs the installer with `--yes --prefix <prefix>`, or for an AppImage writes the new file beside `$APPIMAGE`,
        makes it executable and renames it over the old one, which is atomic on one filesystem;
     3. starts the application again, the old one when the install failed;
     4. deletes the temporary folder.
   - **CI:** `ci/release-build.sh`'s installer smoke tests gain a staged-replace case, and a failed one (a payload that
     cannot be extracted), asserting that the old installation still runs.
5. **After the restart.** At the next start, the application reads the pending-update marker. If it is running `to`,
   it deletes the marker. If it is still running `from`, the dialog's place shows a one-line notice, "The update to
   <to> did not complete", with **Open release page**, and the marker is deleted. This works on both platforms and
   replaces a log of the helper's.

### 4. Release pipeline: checksums

Each release publishes a checksums file next to its packages.

- **Linux:** `ci/release-build.sh` writes `dist/alexandria-<v>-linux-SHA256SUMS`, covering everything it puts in
  `dist/` except the checksums file itself.
- **Windows:** `release-windows.yml` writes `alexandria-ui-windows/alexandria-<v>-windows-SHA256SUMS`, covering the
  `.exe`, `.zip` and `.msix`.
- **Format:** `sha256sum` output, `<hex>  <file name>`, one line per file.
- **Publishing:** `yggdrasil.yml`'s `release.build.files` and `release.windows.files` list the new files.

This part changes `yggdrasil.yml` and a workflow, so it goes in **its own pull request, which the owner merges**. The
application side is merged separately, and does nothing harmful before then: without a checksums asset it falls back
to the download page.

### 5. Interface

```txt
┌ Alexandria 1.2.0 is available ─────────────────────────────┐
│ You have 1.1.0.                                            │
│ ┌ What's new ────────────────────────────────────────────┐ │
│ │ ### Added …  (the release notes, scrollable Markdown)  │ │
│ └────────────────────────────────────────────────────────┘ │
│ [Skip this version]                  [Later] [Update now]  │
└────────────────────────────────────────────────────────────┘
   while downloading:   Downloading… 84 MB of 190 MB  ━━━━─── [Cancel]
   manual kind:         "This copy was installed with <apt / Flatpak / by hand>.
                         Download the new version from the release page."  [Open release page]
```

- **When the dialog shows.** It shows over whatever screen is up — the login screen or the shell — as soon as the
  check answers, but never over another dialog. If one is open, it waits for that to close.
- **Rendering the notes.** The notes are rendered with the Markdown renderer the application already uses.
- **Later and Skip.** **Later** asks again at the next start. **Skip this version** stores the version.
- **A failed update.** At the next start, the pending-update marker (§3 step 5) shows a one-line notice in the
  dialog's place, with **Open release page**.
- **Preferences.** "Check for updates at startup" is a switch, on by default, beside the existing startup re-check
  switch. "Check now" runs the check, then either opens the same dialog or shows "You're up to date" / "Couldn't
  check for updates".
- **Strings** go in en and pt.

### 6. Layering

- **Domain** (`lib/features/updates/domain/`): `InstallKind`, `ReleaseInfo`, `UpdateCheckOutcome`, the version
  comparison, and the interfaces `ReleaseSource`, `InstallKindProbe`, `UpdateInstaller` and `Downloader`.
- **Data:**
  - `GitHubReleaseSource` over `dart:io` `HttpClient`, with no new HTTP package;
  - `PlatformInstallKindProbe`, reading the Windows registry through `win32_registry` and the files and environment
    on Linux;
  - `HttpDownloader`;
  - `WindowsSetupInstaller`, `LinuxHelperInstaller` and `AppImageInstaller`.
- **Application:** `UpdateController` (check, download, verify, install). The check is started once when startup
  reaches ready. An `UpdateSessionActivity` only cancels a download in flight when the owner signs out.
- **Presentation:** the update dialog and the Preferences rows.
- **New dependencies:** `crypto` (SHA-256) and `win32_registry`. Each is added at its latest stable version, per the
  Technology Stack Document's policy.

### 7. Tests

**Unit tests**, with fakes for the source, downloader, probe and installer:

- version comparison, including a non-SemVer tag;
- asset selection per kind;
- checksum parsing and mismatch;
- a skipped version, a newer one than the skipped, and the same one;
- every `CheckFailed` cause staying silent at startup and reported on "Check now";
- the preference off meaning no request;
- debug builds not checking;
- cancelling a download deleting the partial file;
- unsaved changes blocking the close until confirmed;
- a running scan named in the confirmation;
- "Check now" offering a skipped version;
- the pending-update marker: matched version → no notice; old version → notice.

**Install-kind detection**, from a fake filesystem, environment and registry:

- every row of §1, including a Windows install folder the user cannot write to, and Flatpak hiding the setting;
- a manifest whose prefix does not contain the executable;
- an `/opt` prefix that is not writable.

**Widget tests:** the dialog's three choices, progress, a verification failure, the manual kind's text and link,
Preferences' switch and "Check now", and the failed-update notice.

**Helper script:** a shell test of the generated helper against a fake installer, asserting the wait, install,
relaunch and cleanup, and that a failing install keeps the old file and relaunches it.

**Installers:** the staged replace and the failed staged replace, in `ci/release-build.sh`'s smoke tests (Linux) and
the Windows release workflow's installer step, which is the only place Inno Setup runs.

**Pipeline:** each release script's checksum step is checked by running it on fixture files in `ci/` tests, if the
repository has them, or with a step that verifies the sums file right after writing it.

## Left to the builder

- Exact widget structure and wording, within the strings above.
- Where the temporary download folder lives (the system temp folder is fine).
- How the Windows registry is read in tests (an interface seam is enough).
- Whether the Linux helper is a heredoc in Dart or an asset file.
