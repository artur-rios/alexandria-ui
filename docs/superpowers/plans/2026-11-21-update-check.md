# Startup Update Check Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:**
- **The app** checks GitHub's releases at startup and offers a newer release. On confirmation it installs the release
  itself, where the package allows, and otherwise points to the download.
- **The installers** stage a replacement, so a failed update keeps the old version.
- **Each release** publishes SHA-256 checksums.

**Architecture:**
- **Code layout.** A new `lib/features/updates` feature: domain types and interfaces; data adapters (HTTP, platform
  probe, installers); an `UpdateController`; and a prompt host wrapped around `MaterialApp.home`.
- **Packaging.** It lands on a separate branch, which the owner merges because it touches `yggdrasil.yml`. The
  installers gain path-level staging and an `/UPDATE` mode, and the release scripts publish checksums.

**Tech Stack:** Flutter 3.50.0, Riverpod 3, freezed, `dart:io` `HttpClient`, `crypto`, `win32_registry`,
`flutter_markdown_plus` (already present), and `url_launcher` through the existing `BrowserLauncher`. Packaging uses
Inno Setup 6 and POSIX `sh`.

**Spec:** `docs/superpowers/specs/2026-11-21-update-check-design.md` (§n below are its sections).

## Global Constraints

- **Releases URL:** `https://api.github.com/repos/artur-rios/alexandria-ui/releases/latest`. It can be overridden with
  `--dart-define=ALEXANDRIA_RELEASES_URL=…`.
- **Request headers:** `Accept: application/vnd.github+json` and `User-Agent: Alexandria/<version>`. The timeout is
  10 seconds, and nothing else is sent.
- **When the check runs:** only when `kReleaseMode` is true, the preference "Check for updates at startup" is on, and
  the install kind is not `flatpak`. It runs once, when startup reaches `StartupReady`.
- **Default:** the preference is **on**.
- **Settings keys:** `settings.checksForUpdates` (`'false'` means off) and `updates.skippedVersion`.
- **Pending-update marker:** `update-pending.json` in the application support folder, holding
  `{"from": "x.y.z", "to": "x.y.z", "at": "<ISO-8601>"}`.
- **Asset names:**

  | Use | Name |
  | --- | --- |
  | Windows setup | `alexandria-setup-<v>.exe` |
  | Linux installer | `alexandria-installer-<v>-linux-x64.sh` |
  | AppImage | `alexandria-<v>-linux-x86_64.AppImage` |
  | Checksums | `alexandria-<v>-windows-SHA256SUMS`, `alexandria-<v>-linux-SHA256SUMS` |

  The checksums are in `sha256sum` format, `<hex>  <name>`.
- **Windows setup command line:**
  `/SILENT /SUPPRESSMSGBOXES /NORESTART /UPDATE /DIR="<install folder>"`.
- **Inno uninstall key:** `Software\Microsoft\Windows\CurrentVersion\Uninstall\{8F2A6C41-9B3E-4D77-A5C2-1E6D0B9F4A38}_is1`,
  with value `InstallLocation`.
- **Linux manifests:** `$XDG_STATE_HOME/alexandria/install.manifest` (default `~/.local/state/alexandria/…`) and
  `/var/lib/alexandria/install.manifest`. The `prefix=` line holds the prefix.
- **Staging folders:** `<install>.staging` and `<install>.backup`. The swap moves only the installer's own paths;
  files the installer did not write survive.
- **Strings:** every string is in en and pt, with descriptions.
- **Tests:** Given-When-Then names, failing test first.
- **Commits:** lowercase Conventional Commits, a subject of at most 50 characters, no attribution.
- **Dependencies:** `crypto` and `win32_registry` are added at their latest stable versions (Technology Stack §1.1),
  each with the pubspec comment the file's style uses.
- **Memory:** one heavy suite at a time.

## Review Focus

1. **A release whose checksums file lacks the asset's line, or a checksum in upper case.** The update is refused as
   unverifiable, and the comparison is case-insensitive. Test in Task 2.
2. **A download cut off mid-stream (connection reset, short body).** The partial file is deleted, an error is shown,
   and nothing runs. Test in Task 2.
3. **A tag such as `v1.2.0-rc.1`, or one that isn't SemVer, from a misconfigured release.** It is ignored and the app
   is treated as up to date. A version with a build suffix compares by `x.y.z`. Test in Task 1.
4. **The check answering after the owner has already opened another dialog, or signed out.** The prompt waits for the
   dialog to close, and is not lost on sign-out. Test in Task 6.
5. **An install folder path with spaces or non-ASCII letters (`C:\Programs\Ålexandria`, `/home/me/My Apps`).** The
   setup's `/DIR=` and the Linux helper's quoting carry it intact. Test in Task 7.

---

## Part 1 — the application (branch `feature/update-check`)

### Task 0: Dev loop (no commit)

Recreate the `aui-dev` container from the previous plan:
- `ubuntu:24.04@sha256:fe81560990fae86dc4743202b2cb4d3df98d0bcf949173cecef15ce1127ef852`;
- mounting the repository, `~/.pub-cache` and `~/sdk/flutter` at the same paths, with `PUB_CACHE` and `HOME` set;
- with `clang g++ pkg-config libgtk-3-dev libx11-dev libxi-dev cmake ninja-build libclang-dev` installed.

`TEST <paths>` means `docker exec aui-dev bash -c 'export PATH=/home/dev/sdk/flutter/bin:$PATH; flutter test <paths>'`.
After any `ci-check` run, restore the host's package configs with `flutter pub get` at the root and `dart pub get` in
`tools/alexandria_lints`.

### Task 1: Domain — versions, releases, asset choice, checksums

**Files:**
- Create in `lib/features/updates/domain/`: `app_version.dart`, `release_info.dart`, `install_kind.dart`,
  `checksums.dart`, `update_ports.dart`
- Test in `test/features/updates/domain/`: `app_version_test.dart`, `release_info_test.dart`, `checksums_test.dart`

**Interfaces:**
- Produces:
  - **`AppVersion`** (`major`, `minor`, `patch`, comparable):
    - `static AppVersion? parse(String raw)` accepts `x.y.z`, `vx.y.z` and `x.y.z+build`;
    - it rejects a pre-release (`-…`) and anything else, answering null.
  - **`enum InstallKind { windowsInstaller, linuxInstaller, appImage, flatpak, manual }`.**
  - **`ReleaseAsset({name, url, size})`.**
  - **`ReleaseInfo({version, notes, pageUrl, assets})`:**
    - `static ReleaseInfo? fromGitHubJson(Map<String, dynamic>)` reads `tag_name`, `body`, `html_url` and
      `assets[].name/browser_download_url/size`, and answers null when the tag doesn't parse;
    - `ReleaseAsset? packageFor(InstallKind kind)` answers by the Global Constraints names, and null for `flatpak` and
      `manual`;
    - `ReleaseAsset? checksumsFor(InstallKind kind)` answers the windows file for `windowsInstaller` and the linux one
      for the two Linux kinds.
  - **`String? checksumFor(String sumsFileText, String assetName)`** returns the lower-case hex, or null when there is
    no line.
  - **Ports in `update_ports.dart`:**
    - `abstract interface class ReleaseSource { Future<ReleaseInfo> latest(); }` throws `UpdateCheckException`;
    - `abstract interface class InstallKindProbe { InstallKind detect(); String? installLocation(); }`;
    - `abstract interface class Downloader { Future<File> download(Uri url, File to, {void Function(int received, int total)? onProgress, CancelToken? cancel}); Future<String> sha256Of(File file); }`;
    - `abstract interface class UpdateInstaller { Future<void> launch({required File package, required String installLocation, required String fromVersion}); }`;
    - `class CancelToken { void cancel(); bool get isCancelled; }`;
    - `class UpdateCheckException implements Exception`.

- [ ] **Step 1: Write the failing tests.**

  **`app_version_test.dart`:**
  - `GivenVPrefixedTag_WhenParsed_ThenNumbersAreRead`: `v1.2.3`;
  - `GivenBuildSuffix_WhenParsed_ThenItIsIgnored`: `1.2.3+7`;
  - `GivenPreRelease_WhenParsed_ThenNull`: `1.2.0-rc.1`;
  - `GivenGarbage_WhenParsed_ThenNull`: `latest`, `1.2` and empty;
  - `GivenTwoVersions_WhenCompared_ThenNumericNotLexical`: `1.10.0 > 1.9.9`.

  **`release_info_test.dart`:**
  - `GivenGitHubLatestJson_WhenRead_ThenVersionNotesPageAndAssets`, using the 1.0.1 shape seen live;
  - `GivenAnUnparseableTag_WhenRead_ThenNull`;
  - `GivenEachKind_WhenThePackageIsChosen_ThenTheMatchingAssetName`, one case per kind, with flatpak and manual null;
  - `GivenNoChecksumsAsset_WhenAsked_ThenNull`.

  **`checksums_test.dart`:**
  - `GivenSumsText_WhenAsked_ThenTheNamedLinesHex`;
  - `GivenUpperCaseHex_WhenAsked_ThenLowerCase` (Review Focus 1);
  - `GivenNoLineForTheName_WhenAsked_ThenNull` (Review Focus 1);
  - `GivenASimilarName_WhenAsked_ThenOnlyTheExactName`, with `a.exe` against `a.exe.sig`.

- [ ] **Step 2: Run them.** Run `TEST test/features/updates/domain`. Expected: FAIL to compile.
- [ ] **Step 3: Implement** the types above. They are pure Dart, with no Flutter imports.
- [ ] **Step 4: Run them again.** Expected: PASS.
- [ ] **Step 5: Commit.** `feat: read releases and compare versions`.

### Task 2: Data — GitHub source and downloader

**Files:**
- Create in `lib/features/updates/data/`: `github_release_source.dart`, `http_downloader.dart`
- Modify: `pubspec.yaml` (add `crypto`)
- Test in `test/features/updates/data/`: `github_release_source_test.dart`, `http_downloader_test.dart`

**Interfaces:**
- Consumes: Task 1.
- Produces:
  - `GitHubReleaseSource({required Uri url, required String appVersion, HttpClient Function()? client})`, which
    implements `ReleaseSource`;
  - `HttpDownloader({HttpClient Function()? client})`, which implements `Downloader`.

- [ ] **Step 1: Write the failing tests** against a real `HttpServer.bind(loopback, 0)` serving fixtures.

  **Source tests:**
  - `GivenTheLatestRelease_WhenAsked_ThenItIsParsedAndHeadersSent`: asserts `Accept` and
    `User-Agent: Alexandria/1.1.0`;
  - `GivenA403RateLimit_WhenAsked_ThenUpdateCheckException`;
  - `GivenNonJson_WhenAsked_ThenUpdateCheckException`;
  - `GivenNoAnswerIn10Seconds_WhenAsked_ThenUpdateCheckException`. Construct the source with a `timeout` parameter
    that defaults to 10 seconds and is set short in the test.

  **Downloader tests:**
  - `GivenABody_WhenDownloaded_ThenTheFileHoldsItAndProgressReachesTotal`;
  - `GivenACutOffBody_WhenDownloaded_ThenThePartialFileIsDeletedAndItThrows` (Review Focus 2): the server sends a
    `Content-Length` larger than the body, then closes;
  - `GivenACancel_WhenMidDownload_ThenThePartialFileIsDeleted`;
  - `GivenAFile_WhenHashed_ThenItsSha256`, with a known vector: `"abc"` →
    `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad`.

- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.**
  - Stream into `to` with `IOSink`, counting bytes against `contentLength`.
  - A short body, or any error, deletes the file and rethrows.
  - `sha256Of` uses `sha256.bind(file.openRead())`.
  - Add `crypto` to `pubspec.yaml`, then `flutter pub get` in `aui-dev`.
- [ ] **Step 4: Run them again.** Expected: PASS.
- [ ] **Step 5: Commit.** `feat: fetch releases and download packages`.

### Task 3: Install-kind probe

**Files:**
- Create: `lib/features/updates/data/platform_install_kind_probe.dart`
- Modify: `pubspec.yaml` (add `win32_registry`)
- Test: `test/features/updates/data/platform_install_kind_probe_test.dart`

**Interfaces:**
- Produces: `PlatformInstallKindProbe` with seams:
  ```dart
  PlatformInstallKindProbe({
    required bool isWindows,
    required String executable,
    required Map<String, String> environment,
    required bool Function(String path) exists,
    required bool Function(String directory) isWritable,
    required String? Function(String path) readFile,
    required String? Function() registryInstallLocation,
  })
  ```
  Also `factory PlatformInstallKindProbe.system()`.
  - `registryInstallLocation` reads `InstallLocation` from HKCU, then HKLM, in the 64-bit and 32-bit views, through
    `win32_registry`. The import is used only behind `isWindows`, so Linux never calls it.
  - `isWritable` creates and deletes a probe file in that folder.

- [ ] **Step 1: Write the failing tests**, one per §1 row:
  - `GivenTheUninstallKeyMatchingAWritableExecutableFolder_WhenDetected_ThenWindowsInstaller`;
  - `GivenTheKeyButAFolderTheUserCannotWrite_WhenDetected_ThenManual`;
  - `GivenTheKeyForAnotherFolder_WhenDetected_ThenManual`, for the zip run elsewhere;
  - `GivenAWindowsAppsPath_WhenDetected_ThenManual`;
  - `GivenAUserManifestWhosePrefixHoldsTheExecutable_WhenDetected_ThenLinuxInstaller`;
  - `GivenARootManifestAndAnUnwritablePrefix_WhenDetected_ThenManual`;
  - `GivenAManifestForAnotherPrefix_WhenDetected_ThenManual`;
  - `GivenAppImageSetAndAWritableFolder_WhenDetected_ThenAppImage`;
  - `GivenFlatpakId_WhenDetected_ThenFlatpak`;
  - `GivenUsrExecutable_WhenDetected_ThenManual`.

  Also assert `installLocation()` for each self-updating kind: the folder, the prefix, or `$APPIMAGE`.

- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.** The checks run in this order: flatpak, AppImage, Windows key, Linux manifest, manual.
  Path comparisons normalise separators, and are case-insensitive on Windows.
- [ ] **Step 4: Run them again.** Expected: PASS.
- [ ] **Step 5: Commit.** `feat: tell how the app was installed`.

### Task 4: Settings, skip and pending marker

**Files:**
- Modify:
  - `lib/core/settings/settings_store.dart`, `shared_preferences_settings_store.dart`
  - `test/support/in_memory_settings_store.dart`, `failing_settings_store.dart`
  - `lib/features/shell/application/preferences_state.dart`, `preferences_controller.dart`
- Create: `lib/features/updates/data/pending_update_store.dart`
- Test: `test/core/settings/settings_store_test.dart`,
  `test/features/shell/application/preferences_controller_test.dart` (create or extend),
  `test/features/updates/data/pending_update_store_test.dart`

**Interfaces:**
- Produces:
  - `SettingsStore`: `bool get checksForUpdates` (default true) and `Future<void> setChecksForUpdates(bool)`. The
    skipped version uses `getString/setString('updates.skippedVersion')`.
  - `PreferencesState.checksForUpdates` and `PreferencesController.setChecksForUpdates(bool)`, mirroring
    `rechecksAtStartup`.
  - `PendingUpdateStore(Directory supportDir)`, with `Future<void> write({from, to})`,
    `Future<({String from, String to})?> read()` and `Future<void> clear()`. An unreadable file reads as null and is
    deleted.

- [ ] **Step 1: Write the failing tests.**
  - `GivenNoStoredChoice_WhenRead_ThenChecksForUpdatesIsOn`;
  - `GivenOff_WhenStoredAndRead_ThenOff`;
  - `GivenThePreference_WhenToggled_ThenPersisted`;
  - `GivenAWrittenMarker_WhenRead_ThenFromAndTo`;
  - `GivenAGarbledMarker_WhenRead_ThenNullAndDeleted`.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run them again.** Expected: PASS.
- [ ] **Step 5: Commit.** `feat: remember the update preferences`.

### Task 5: UpdateController

**Files:**
- Create in `lib/features/updates/application/`: `update_controller.dart`, `update_state.dart`
- Modify: `lib/core/di/providers.dart`
- Test: `test/features/updates/application/update_controller_test.dart`, and `test/support/fake_updates.dart`
  (`FakeReleaseSource`, `FakeDownloader`, `FakeInstallKindProbe`, `FakeUpdateInstaller`)

**Interfaces:**
- Consumes: Tasks 1–4.
- Produces:
  - **Providers:** `releaseSourceProvider`, `downloaderProvider`, `installKindProbeProvider`,
    `updateInstallerProvider` (null for kinds that cannot install), `pendingUpdateStoreProvider`,
    `appVersionProvider` (`String`, from `package_info`-free `const String.fromEnvironment('FLUTTER_BUILD_NAME')`,
    falling back to the pubspec version), `isReleaseBuildProvider` (`kReleaseMode`; overridable) and
    `updateControllerProvider` (`NotifierProvider<UpdateController, UpdateState>`).
  - **`UpdateState`** (freezed):
    - `idle`
    - `checking`
    - `upToDate`
    - `available(ReleaseInfo release, InstallKind kind)`
    - `downloading(ReleaseInfo release, int received, int total)`
    - `verifyFailed(ReleaseInfo release)`
    - `failed(Failure? failure)`
    - `previousUpdateFailed(String to)`
    - `readyToInstall(ReleaseInfo release, File package)`
  - **`UpdateController` methods:**
    - `Future<void> checkAtStartup()`: honours the preference, release mode, flatpak and the skipped version. Every
      failure becomes `idle`, logged.
    - `Future<void> checkNow()`: ignores the skip. A failure becomes `failed`, and nothing newer becomes `upToDate`.
    - `Future<void> skip()`
    - `void later()`
    - `Future<void> download()`: downloads, verifies, then becomes `readyToInstall`. A sums mismatch or missing line
      becomes `verifyFailed`. Cancel goes back to `available`.
    - `void cancelDownload()`
    - `Future<void> evaluatePendingMarker()`: runs before the check, so a failed update's notice wins over a new
      prompt.
  - **Version.** Before relying on it, confirm whether `FLUTTER_BUILD_NAME` is defined for a release build on this
    Flutter version. If it isn't, read the version from a `--dart-define=ALEXANDRIA_VERSION` that both release scripts
    pass. Rule on this in the ledger: adding the define is part of Part 2.

- [ ] **Step 1: Write the failing tests.**
  - `GivenANewerRelease_WhenCheckedAtStartup_ThenAvailable`;
  - `GivenTheSameRelease_WhenChecked_ThenIdleAtStartupAndUpToDateOnCheckNow`;
  - `GivenTheSkippedVersion_WhenCheckedAtStartup_ThenIdle`;
  - `GivenTheSkippedVersion_WhenCheckNow_ThenAvailable`;
  - `GivenANewerThanSkipped_WhenCheckedAtStartup_ThenAvailable`;
  - `GivenThePreferenceOff_WhenCheckedAtStartup_ThenNoRequest`;
  - `GivenADebugBuild_WhenCheckedAtStartup_ThenNoRequest`;
  - `GivenFlatpak_WhenCheckedAtStartup_ThenNoRequest`;
  - `GivenTheSourceThrows_WhenCheckedAtStartup_ThenIdleAndOnCheckNowFailed`;
  - `GivenMatchingChecksums_WhenDownloaded_ThenReadyToInstall`;
  - `GivenAMismatch_WhenDownloaded_ThenVerifyFailedAndTheFileDeleted`;
  - `GivenNoChecksumsAsset_WhenAvailable_ThenTheKindIsTreatedAsManual`: the dialog offers the page;
  - `GivenAMarkerToTheRunningVersion_WhenEvaluated_ThenClearedAndNoNotice`;
  - `GivenAMarkerFromTheRunningVersion_WhenEvaluated_ThenPreviousUpdateFailedAndCleared`.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.**
  - The check starts from `StartupController` reaching ready. A `ref.listen` on `startupControllerProvider` in a
    provider that `app.dart` watches calls `evaluatePendingMarker()`, then `checkAtStartup()`, once per process.
  - An `UpdateSessionActivity` in `sessionActivitiesProvider` cancels a download on sign-out.
  - Run `GEN`.
- [ ] **Step 4: Run them again.** Expected: PASS.
- [ ] **Step 5: Commit.** `feat: check for a newer release at startup`.

### Task 6: The prompt and Preferences

**Files:**
- Create: `lib/features/updates/presentation/update_prompt_host.dart`, `update_dialog.dart`
- Modify:
  - `lib/app.dart` (wrap `home`'s content in `UpdatePromptHost`, inside `SessionRouteGuard`)
  - `lib/features/shell/presentation/preferences_dialog.dart`
  - the arb files
- Test: `test/features/updates/presentation/update_dialog_test.dart`,
  `test/features/shell/presentation/preferences_dialog_test.dart`

**Interfaces:**
- Consumes: Task 5's states and methods, and `browserLauncherProvider.open(url)`.
- Produces:
  - **`UpdatePromptHost(child)`.** It listens to `updateControllerProvider`, and shows `UpdateDialog` when the state
    becomes `available` or `previousUpdateFailed`. If another route is above `home`
    (`ModalRoute.of(context)?.isCurrent == false`), it waits until that route is popped, re-checking on each
    `didPopNext` (`RouteAware`, with a `RouteObserver` added to `MaterialApp`).
  - **`UpdateDialog`.**
    - **Title and notes:** "Alexandria <v> is available". The body reads "You have <current>." followed by the notes
      in `MarkdownBody` inside a scrollable box with a max height.
    - **Buttons:** Skip this version, Later, and Update now.
    - **The manual kind, and a release without checksums:** the body names how the copy was installed (strings per
      kind), and the button is **Open release page**.
    - **Downloading:** a progress row, "Downloading… <a> of <b>", with Cancel.
    - **`verifyFailed`:** "The download could not be verified, so it was not installed.", with Open release page and
      Close.
    - **`previousUpdateFailed`:** "The update to <to> did not complete.", with Open release page and Close.
  - **Preferences:** a `SwitchListTile` "Check for updates at startup", and a "Check now" button that shows
    `upToDate`/`failed` as a snackbar or opens the dialog. Both are hidden when the kind is `flatpak`.

- [ ] **Step 1: Write the failing tests.**
  - `GivenAnAvailableRelease_WhenTheShellShows_ThenTheDialogShowsVersionAndNotes`;
  - `GivenAnotherDialogOpen_WhenTheCheckAnswers_ThenThePromptWaitsUntilItCloses` (Review Focus 4);
  - `GivenTheLoginScreen_WhenTheCheckAnswers_ThenThePromptShowsThere`;
  - `GivenLater_WhenTapped_ThenTheDialogClosesAndNothingIsStored`;
  - `GivenSkip_WhenTapped_ThenTheVersionIsStored`;
  - `GivenUpdateNow_WhenDownloading_ThenProgressAndCancel`;
  - `GivenVerifyFailed_ThenTheSentenceAndTheReleasePage`;
  - `GivenTheManualKind_ThenOpenReleasePageOnly`;
  - `GivenAPreviousFailure_ThenTheNotice`;
  - `GivenPreferences_WhenTheSwitchIsToggled_ThenSaved`;
  - `GivenPreferences_WhenCheckNowFindsNothing_ThenUpToDateIsSaid`;
  - `GivenFlatpak_WhenPreferencesOpen_ThenNoUpdateRows`;
  - plus the l10n parity test.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.** Run `GEN`. Regenerate the goldens if the shell goldens change; they shouldn't.
- [ ] **Step 4: Run them again.** Run `TEST test/features/updates test/features/shell test/core/l10n`. Expected: PASS.
- [ ] **Step 5: Commit.** `feat: offer an update when one is out`.

### Task 7: Closing and installing

**Files:**
- Create in `lib/features/updates/`:
  - `application/update_close.dart`
  - `data/windows_setup_installer.dart`
  - `data/linux_helper_installer.dart`
  - `data/linux_update_helper.sh` (added as an asset, and to the `pubspec.yaml` assets)
- Modify:
  - `lib/features/updates/presentation/update_dialog.dart`, so that `readyToInstall` runs the close
  - `lib/core/di/providers.dart`
- Test in `test/features/updates/`: `application/update_close_test.dart`, `data/windows_setup_installer_test.dart`,
  `data/linux_helper_installer_test.dart`, and `data/linux_update_helper_test.dart`, which runs the real script with
  `sh` against fixtures

**Interfaces:**
- Produces:
  - **`Future<bool> closeForUpdate(BuildContext, WidgetRef, {required ReleaseInfo release, required File package})`.**
    It runs these steps in order:
    1. If unsaved changes are held (`signOutControllerProvider`), confirm with the sign-out unsaved strings; a refusal
       answers false.
    2. If `activeRunsControllerProvider.anyRunning`, confirm with "A scan is running. It will pause, and you can
       resume it after the update." (new strings).
    3. End every `sessionActivitiesProvider` activity, and run `WindowGeometryController.record()`.
    4. `PendingUpdateStore.write(from, to)`.
    5. `UpdateInstaller.launch(...)`.
    6. `exit(0)`, through an injectable `void Function(int) exitApp` for tests.
  - **`WindowsSetupInstaller({ProcessStarter start})`.** It starts the package detached
    (`ProcessStartMode.detached`) with the Global Constraints arguments. `/DIR=` is one argument with the path quoted
    as Inno expects.
  - **`LinuxHelperInstaller({ProcessStarter start, required bool appImage})`.**
    - It copies `linux_update_helper.sh` from assets beside the package, and runs
      `setsid sh helper.sh <pid> <mode> <package> <location> <executable>` detached.
    - `<mode>` is `installer` or `appimage`.
  - **`linux_update_helper.sh`**, a POSIX `sh` script that:
    1. waits for `<pid>` to exit, polling with `kill -0`, for at most 60 seconds;
    2. runs the installer with `sh <package> --yes --prefix <location>`, or for `appimage` does
       `chmod +x <package> && mv -f <package> <location>`, copying to a temp file beside the location first when `mv`
       crosses filesystems;
    3. on success, runs `<executable>` detached; on failure, runs the old one;
    4. removes its own folder.

- [ ] **Step 1: Write the failing tests.**

  **`closeForUpdate`:**
  - `GivenUnsavedEdits_WhenDeclined_ThenNothingRuns`;
  - `GivenARunningScan_WhenConfirmed_ThenTheMarkerIsWrittenAndTheInstallerLaunched`;
  - `GivenNothingPending_WhenClosed_ThenGeometryRecordedActivitiesEndedAndExit`.

  **Installers:**
  - `GivenAFolderWithSpaces_WhenTheSetupIsStarted_ThenDirIsOneQuotedArgument`, with `C:\Program Files\Ålexandria`
    (Review Focus 5);
  - `GivenTheLinuxInstallerKind_WhenLaunched_ThenSetsidHelperWithInstallerMode`.

  **Helper script**, run by `sh` in a temp folder against a fake installer that writes a marker file:
  - `GivenASucceedingInstaller_WhenTheHelperRuns_ThenItWaitsInstallsRelaunchesAndCleansUp`;
  - `GivenAFailingInstaller_WhenTheHelperRuns_ThenTheOldExecutableIsRelaunched`;
  - `GivenAnAppImageMode_WhenTheHelperRuns_ThenTheFileIsReplacedAndExecutable`;
  - `GivenALocationWithSpaces_WhenTheHelperRuns_ThenItIsHandledIntact` (Review Focus 5).

  The script tests are skipped on Windows (`skip: Platform.isWindows`).
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.** `providers.dart` picks the installer by kind: `windowsInstaller` → Windows, the two Linux
  kinds → helper, otherwise null.
- [ ] **Step 4: Run them again.** Run `TEST test/features/updates`. Expected: PASS.
- [ ] **Step 5: Commit.** `feat: install an update and start again`.

### Task 8: Docs and changelog

- [ ] **Step 1: Edit the documents.**
  - **Vision:** §1.2 / the "In-process, offline by default" principle now states the one exception, the update check,
    which can be turned off.
  - **Operations & Infrastructure:** "no aggregator and no telemetry" stays, and the update request is described: the
    URL, what is sent, and the cadence.
  - **System Requirements:** a new §3.x "Updates — UP", with FR-UP-01 … for the check, the prompt, skip, Check now,
    verify, install by kind, staging and the failure notice. Also the Preferences row and the settings keys.
  - **Use Case Specification:** a new "UC-5x Update the application", with alternative flows for manual, verify
    failure, unsaved edits, a running scan and a failed update.
  - **Technology Stack:** `crypto` and `win32_registry`.
  - **README:** "What it does".
  - **CHANGELOG `[Unreleased]`:** Added.
- [ ] **Step 2: Commit.** `docs: describe the startup update check`.

### Task 9: Verification (Part 1)

- [ ] **Step 1: Run the checks.** Run `ci-check analyze`, then `ci-check test`, then `ci-check integration`. Expected:
  all pass.
- [ ] **Step 2: Restore the host package configs** (Task 0).

---

## Part 2 — packaging and release (branch `feature/staged-installers`, merged by the owner)

### Task 10: Staged Linux installer

**Files:**
- Modify: `packaging/linux/install.sh`, `ci/release-build.sh` (smoke tests), `ci/analyze.sh` (runs the new test)
- Create: `packaging/linux/test-install.sh`, a shell test that needs no root and runs in `analyze`

**Interfaces:**
- Produces: the installer behaviour of §3 step 4 for Linux.
  - Extract into `<prefix>.staging`.
  - Move the recorded old paths to `<prefix>.backup`, move the new paths in, rewrite the manifest, then remove the
    backup.
  - A failure before the swap removes the staging folder; a failure during the swap restores the backup.
  - `--yes --prefix` is unchanged.

- [ ] **Step 1: Write the failing test `test-install.sh`.** It builds an installer from `install.sh` plus a tiny
  payload tarball, then asserts:
  - a fresh install;
  - a replace keeps `unrelated.txt`;
  - a replace whose payload is truncated (extraction fails) leaves the old `alexandria` intact and no staging folder
    behind;
  - uninstall still removes only recorded paths.
- [ ] **Step 2: Run it.** Run `sh packaging/linux/test-install.sh`. Expected: FAIL on the truncated case.
- [ ] **Step 3: Implement the staging.** Add the same truncated-payload case to `release-build.sh`'s smoke tests, and
  call `test-install.sh` from `ci/analyze.sh`.
- [ ] **Step 4: Run it again**, then `shellcheck packaging/linux/*.sh`. Expected: PASS, clean.
- [ ] **Step 5: Commit.** `fix: keep the old install if replacing fails`.

### Task 11: Staged Windows installer and update mode

**Files:**
- Modify: `packaging/windows/installer.iss`
- Modify: `.github/workflows/ci.yml`, giving its `Release build (windows)` job an installer smoke step

**Interfaces:**
- Produces:
  - **Files are installed to `{app}.staging`.**
    - In `CurStepChanged(ssPostInstall)`, the previous installation's payload paths, as `RemovePayload` knows them, are
      moved into `{app}.backup`.
    - Then the staged paths are moved into `{app}`, and the backup is deleted.
    - A failure restores the backup and aborts with an error.
  - **`NextButtonClick` no longer removes anything before copying.** The ReplaceHere confirmation stays for interactive
    runs; a choice to remove an installation elsewhere still happens, after the swap.
  - **`/UPDATE`:**
    - `function IsUpdate(): Boolean` reads the switch;
    - the MsgBox prompts take their default answers (replace here, and keep elsewhere);
    - `[Run] Filename: "{app}\{#AppExeName}"; Check: IsUpdate; Flags: nowait runasoriginaluser` starts the
      application again.
  - **Smoke step** (PowerShell), after the build:
    - compile the setup;
    - install silently to a temp dir;
    - write `unrelated.txt`;
    - run the setup again with `/UPDATE`;
    - assert that `alexandria.exe` and `unrelated.txt` exist and that no `.staging` or `.backup` folder remains.

- [ ] **Step 1:** Write the smoke step first. It describes the required behaviour. Note in the ledger that it can only
  run on GitHub's Windows runner, after the push.
- [ ] **Step 2:** Implement the `installer.iss` changes.
- [ ] **Step 3:** Compile locally only if Inno Setup is available. It isn't on this machine, so the check is the
  Windows CI leg on the pull request. Expected: green.
- [ ] **Step 4: Commit.** `fix: stage the Windows install and add update mode`.

### Task 12: Checksums in the release

**Files:**
- Modify: `ci/release-build.sh`, `.github/workflows/release-windows.yml`, `yggdrasil.yml`

- [ ] **Step 1: Generate the sums.**
  - **`release-build.sh`**, after `dist/` is complete: `(cd dist && sha256sum -- * > alexandria-<v>-linux-SHA256SUMS)`,
    excluding the sums file, then `sha256sum -c` to self-verify.
  - **`release-windows.yml`**, in "Gather the packages": the same in Git Bash, as `alexandria-<v>-windows-SHA256SUMS`
    in `dist/windows`.
- [ ] **Step 2: Publish them.** Add `"dist/*-SHA256SUMS"` to `release.build.files`, and
  `"alexandria-ui-windows/*-SHA256SUMS"` to `release.windows.files`.
- [ ] **Step 3: Version define.** If Task 5 ruled that the version needs a define, both build commands pass
  `--dart-define=ALEXANDRIA_VERSION=<v>`.
- [ ] **Step 4: Check it.** Run `ci-check analyze`. `pipeline_config.py describe alexandria-ui` (yggdrasil) accepts
  the yml.
- [ ] **Step 5: Commit.** `build: publish checksums with each release`.
- [ ] **Step 6: Open the pull request into `develop`, for the owner to merge.** It touches `yggdrasil.yml`.
