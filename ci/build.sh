#!/usr/bin/env bash
# The `build` check: the steps of ci.yml's `build` job on its Linux leg ("Release build (linux)"). The Windows leg stays
# on GitHub Actions. yggdrasil.yml runs it in the pinned Ubuntu image from the repository's root.
#
# `analyze` and `test` ran first in the workflow (`needs`); the checks of a pull request run side by side, and a failure of
# either is its own failed check.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# shellcheck source=ci/flutter-env.sh
. ci/flutter-env.sh

# libmpv is media_kit_video's build-time dependency on Linux: its CMakeLists links PkgConfig::mpv, and without the
# development package the desktop build fails at the generate step rather than at link time (UC-19). The browser engine
# links against NSS. build-essential: Flutter's CMake looks for `cc` and `c++`, which clang alone does not provide.
ensure_packages build-essential clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libmpv-dev mpv libnss3 libnspr4

flutter pub get

flutter build linux --release
