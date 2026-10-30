#!/usr/bin/env bash
# The `integration` check: the steps of ci.yml's `integration` job on its Linux leg ("Integration (linux)"). The Windows
# leg stays on GitHub Actions. yggdrasil.yml runs it in the pinned Ubuntu image from the repository's root.
#
# It builds the Alexandria core at the pinned commit (ci/core.sh), bundles it, and runs every file of integration_test/
# against the real Linux application under a virtual display. The packages the runner carried and the image does not are
# installed with apt by ci/apt-packages.sh (as root, which is how the agents run checks).
#
# The page engine's sandboxed test (integration_test/viewers/saved_page_engine_test.dart, the hostile saved page) does not
# run here. The old job lifted AppArmor's restriction on unprivileged user namespaces (`sysctl -w
# kernel.apparmor_restrict_unprivileged_userns=0`) so Chromium could create its sandbox; a container cannot change a host
# setting, and its seccomp profile forbids the namespaces anyway. Run as root, as the agents do, the file's hostile-page test is
# skipped (it expects the engine to refuse to start as root) and its refusal test runs instead. The security gate is the GitHub
# Actions job `Sandboxed page engine (linux)` in .github/workflows/ci.yml, an actionsCheck, which runs the hostile-page test on
# a throw-away runner and fails if the sandbox cannot be created. Run by hand as another user, on a host that lets Chromium
# create a sandbox, this script runs it too.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# shellcheck source=ci/flutter-env.sh
. ci/flutter-env.sh
# shellcheck source=ci/core.sh
. ci/core.sh

build_core

# Now that the core has been built, its generated header exists and can actually be compared.
echo "== Check the vendored header against the core's"
if ! diff -u "${CORE_DIR:-core}/crates/alexandria-ffi/src/header.h" native/include/alexandria_ffi.h; then
  echo "native/include/alexandria_ffi.h has drifted from the core's header. Re-copy it and run 'dart run ffigen --config ffigen.yaml'." >&2
  exit 1
fi

echo "== Bundle the core"
mkdir -p native/linux
cp "${CORE_DIR:-core}/target/release/libalexandria_ffi.so" native/linux/

# libmpv is media_kit_video's build-time dependency on Linux: its CMakeLists links PkgConfig::mpv, and without the
# development package the desktop build fails at the generate step rather than at link time (UC-19).
# libnss3 / libnspr4: the page viewer's browser engine (webview_cef) links against them. xvfb: the display the suite
# runs under. libsqlite3-0 and libglu1-mesa: the shared libraries the test binary loads.
ensure_packages clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev xvfb xauth libmpv-dev mpv \
  libnss3 libnspr4 libsqlite3-0 libglu1-mesa

flutter pub get

# One file per invocation, deliberately. On desktop, `flutter test` starts the application once per run, and the second
# file in a single invocation fails to launch with "Unable to start the app on the device", whichever file that happens to
# be. Looping is what lets the suite hold more than one file.
#
# ALEXANDRIA_AUTH_MODE is deliberately not set. The application puts the core into local auth mode itself, before
# initializing it, and a runner that set the variable would hide a regression in that: the suite would pass on the
# runner's configuration rather than on the application's.
echo "== Integration suite"
mapfile -t suites < <(find integration_test -name '*_test.dart' | sort)
for suite in "${suites[@]}"; do
  echo "== $suite"
  xvfb-run -a flutter test "$suite" -d linux
done
