# Contributing

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
  `ffmpeg.exe`. The core repository's
  [CONTRIBUTING.md](https://github.com/artur-rios/alexandria-api/blob/develop/CONTRIBUTING.md#windows)
  walks through installing one.
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

## Branching model

```txt
feature/<name> ─┐
fix/<name> ─────┴─▶ develop ──▶ release/x.y.z ──▶ main  (tag vx.y.z)
```

| Branch | Cut from | Merges into | How |
| --- | --- | --- | --- |
| `feature/<name>`, `fix/<name>` | `develop` | `develop` | Pull request, merge commit or squash. The branch is deleted on merge. |
| `release/x.y.z` | `develop` | `main` | Pull request, merge commit only. |
| `develop`, `main` | — | — | Protected: no direct pushes, no force pushes, no deletion. |

`develop` is the default branch and where all work lands; `main` holds only
what has been released. Branch names are lowercase: letters, digits, `.`, `_`
and `-`. A `release/` branch is a snapshot of `develop` and carries no commits
of its own: a fix for a release lands on `develop` through a `fix/` branch and a
new release branch is cut.

One use case = one branch = one issue = one pull request. Each use case is
implemented on its own branch created from an up-to-date `develop`, named
`feature/uc-##-use-case-name` (for example `feature/uc-01-sign-up`), and merged
back through a pull request into `develop`. The full process — issue status
lifecycle, the approval gates, the testing gate, and the Definition of Done — is
in the
[Development Workflow Document](docs/requirements/Development%20Workflow%20Document.md).

A pull request into `develop` or `main` needs every required check green before
it can be merged: `Analyze and generate`, `Unit and widget tests` and
`Integration` on Linux and Windows, `Release build` on Linux and Windows, and
`branch-policy`. The **Branch Policy** workflow
([`branch-policy.yml`](.github/workflows/branch-policy.yml)) enforces the model
above: into `develop` only from `feature/` or `fix/` branches cut from
`develop`, into `main` only from a `release/<major>.<minor>.<patch>` branch whose
every commit is already on `develop` and whose version has no tag yet. Tags
matching `v*` cannot be created, moved, or deleted except by the repository
owner. The owner can bypass these rules; that is for emergencies, not for
routine work.

## Commits and the changelog

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) with a lowercase subject, e.g.
`feat: play a playlist` or `fix: index a folder the moment it becomes a library`.

Record every change an owner would notice under `## [Unreleased]` in
[CHANGELOG.md](./CHANGELOG.md), in the same pull request that makes it.

## Versioning

Releases follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Alexandria UI is an application, so what a version number speaks for is what an
owner who installed it would notice: its behaviour, the catalog, settings, and
files it keeps, the way it is installed, and the core it can work with. From
1.0 on:

- **Major** — a release an existing installation has to be told about: a
  feature removed or changed in a way that breaks how the owner works, settings
  or data that do not carry over, an installation that is not upgraded in
  place, or a move to a core it cannot share a catalog with.
- **Minor** — new features that leave everything above working as it was.
- **Patch** — fixes and small changes that need nothing from the owner.

The project is not at 1.0 yet, and SemVer allows anything to change in a 0.x
release. This repository uses that latitude the way the
[core](https://github.com/artur-rios/alexandria-api/blob/develop/CONTRIBUTING.md#versioning)
does: before 1.0 a minor bump marks a breaking release — 0.1.0 renamed the
executable and, on Linux, the application id, so an existing installation
became a second entry instead of being upgraded — and it is also used for a
release that adds features. A patch bump is a release of fixes and small
changes only, such as 0.1.1's new icon. 0.x releases are published as GitHub
prereleases.

The version comes from the tag, and nowhere else. The release workflow stamps
it into the working copy of `pubspec.yaml` before building — the `.deb` and the
AppImage are named from it, and the application reports it as its own — while
the `pubspec.yaml` in git keeps the version the project develops against
(`1.0.0+1`) and is never bumped. So there is no version file to edit: choosing
`x.y.z` is naming the release branch `release/x.y.z` and the tag `vx.y.z`. It
must be numeric and dotted — the MSIX packager rejects anything else.

## Releasing

Every tag named `v<version>` on `main` builds the Windows and Linux packages and
publishes them as a GitHub Release
([`release.yml`](.github/workflows/release.yml)). The workflow refuses a tag
that points at a commit not on `main`. To release `x.y.z`:

1. On `develop`, through a normal `feature/` or `fix/` pull request — a release
   branch cannot carry commits of its own — rename `## [Unreleased]` in
   [CHANGELOG.md](./CHANGELOG.md) to `## [x.y.z] - <yyyy-mm-dd>` above a fresh,
   empty `## [Unreleased]`, and update the compare links at the bottom.
2. Cut the release branch from that `develop` and open a pull request into
   `main`:

   ```bash
   git switch develop && git pull
   git switch -c release/x.y.z
   git push -u origin release/x.y.z
   ```

3. Merge it with a merge commit once the checks pass, then tag the merge commit
   on `main` with an annotated tag and push it. The tag message is
   `Alexandria <version>`, a short summary of the release, and the commits it
   was built from (`Built from alexandria-ui <sha> against alexandria-api
   <CORE_REF>`):

   ```bash
   git switch main && git pull
   git tag -a vx.y.z
   git push origin vx.y.z
   ```

The release branch is deleted after the merge.

Running the workflow by hand (`workflow_dispatch`, with a version and no tag)
builds every package as a workflow artifact without publishing a release.

A release links the core at `CORE_REF`, which `ci.yml` and `release.yml` pin to
the same alexandria-api commit. Move both together: CI fails when they disagree,
or when `release.yml` names a branch instead of a commit.

Packages are produced unsigned. Code signing for Windows and Flatpak
distribution through a public remote are deliberately deferred — see
[Operations & Infrastructure Document §7.2](docs/requirements/Operations%20%26%20Infrastructure%20Document.md).
