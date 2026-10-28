# shellcheck shell=bash
# shellcheck disable=SC2034 # the variables are read by the scripts that source this file
# The versions this repository builds against, in one place. Sourced by the other scripts under ci/ and read by the
# two GitHub Actions workflows that remain (.github/workflows/ci.yml and release-windows.yml), so a Windows build
# and a Linux one cannot disagree about them. Not run on its own.
#
# FLUTTER_VERSION is pinned rather than "whatever stable is today", because pubspec.lock is committed and is the real
# pin: the Flutter SDK constrains its own pinned packages, so a newer SDK rewrites the lock during `flutter pub get`
# and the build then runs against dependencies nobody chose. It must match the SDK the committed lock was resolved
# with. Upgrading is a deliberate change to both, never a side effect of a fresh runner.
# FLUTTER_SHA256 comes from https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json; change
# it together with FLUTTER_VERSION (Renovate proposes the version only, so its pull request must carry the new
# checksum too, or ci/flutter-env.sh stops at the checksum).
#
# renovate: datasource=github-tags depName=flutter/flutter versioning=regex:^(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)$
FLUTTER_VERSION=3.47.1
FLUTTER_SHA256=a1d8166c0309267cb7dc99f1424eecf08b86946ad3b50723c6f59945964aea45

# The core is a separate repository. Building it here rather than committing a binary keeps the shared library out of
# git history and makes a drift between the two repositories fail the build instead of going unnoticed.
#
# Pinned to a commit rather than tracking `main`, so that a core change lands here deliberately: re-vendoring the header
# and regenerating the bindings is part of moving CORE_REF, and a moving target would make the drift check pass against
# whatever the core happened to be that morning. The checks, the release build and both Windows workflows read this one
# value, so a release links against the commit the integration suite ran against (ci/analyze.sh refuses a value that is
# not a full commit id, because a tag or a branch could build twice and ship two different cores).
#
# The default address is GitHub's read-only mirror of alexandria-api; ALEXANDRIA_API_URL points the scripts at another
# copy (the Forgejo repository, a local clone).
#
# The 0.5 core with the music-removal follow-ups, merged as alexandria-api#140: its migration 26 deletes the run
# failures earlier runs recorded on audio files, which migration 25 left behind. The version is still 0.5.0 and no
# export changed; the header differs from the previous pin's (alexandria-api#137, an ancestor of this one) only in one
# doc comment, re-vendored here. This application accepts `>=0.5.0 <0.6.0`. The pin and the vendored header move
# together: the drift check in ci/integration.sh is exactly the guard against them moving apart.
CORE_REPOSITORY=artur-rios/alexandria-api
CORE_REF=1353826aca82db16d116483646a3c41c5a10f781

# The Rust toolchain that builds the core (the workflows used dtolnay/rust-toolchain@stable, which was 1.99.1). Jenkins
# installs it with rustup (RUSTUP_VERSION's rustup-init, checked against RUSTUP_SHA256) in ci/core.sh; the GitHub workflows
# that build the core (ci.yml's integration and sandboxed page engine jobs, release-windows.yml) read RUST_VERSION from here
# and install exactly it with dtolnay/rust-toolchain, so no build floats on `stable`.
#
# renovate: datasource=github-tags depName=rust-lang/rust
RUST_VERSION=1.99.1
# renovate: datasource=github-tags depName=rust-lang/rustup
RUSTUP_VERSION=1.29.2
RUSTUP_SHA256=5be191e8c70a5007074254cb74d78dbfdd25cd5a61c27de7b8e5410122ec24f4
