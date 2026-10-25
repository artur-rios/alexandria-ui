#!/usr/bin/env bash
# The `analyze` check: the steps of ci.yml's `analyze` job ("Analyze and generate"), in the same order. yggdrasil.yml runs
# it in the pinned Ubuntu image from the repository's root.
#
# Flutter comes from ci/flutter-env.sh. The packages the runner carried and the image does not are installed with apt
# by ci/apt-packages.sh (as root, which is how the agents run checks): clang and libclang for ffigen, and a C++
# compiler for the fork's native policy tests.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# shellcheck source=ci/flutter-env.sh
. ci/flutter-env.sh

ensure_packages clang libclang-dev g++

flutter pub get
dart pub get --directory tools/alexandria_lints

# The drift check lives in the integration check rather than here. The core's header is not committed
# (`crates/alexandria-ffi/build.rs` generates it with cbindgen and the core's .gitignore excludes it), so a clone alone
# never contains it, and comparing against a clone reported drift unconditionally. The integration check builds the
# core, which is what makes the header exist, so that is where the comparison can be honest.

echo "== Regenerate and check for a diff"
dart run ffigen --config ffigen.yaml
dart run build_runner build
flutter gen-l10n
# Untracked files too: `git diff` alone never sees a generated file that was never committed.
git add --intent-to-add --all
if ! git diff --exit-code; then
  echo "Generated output differs from what is committed. Run the generators and commit the result." >&2
  exit 1
fi

# The release build links the core at CORE_REF too (ci/release-build.sh), and a release that linked against a different
# commit than the one the integration suite ran against would ship something nothing had tested. Both read it from
# ci/pins.sh, as do the Windows workflows, so they cannot disagree; what is left to check is that it names a commit.
echo "== Core pin"
echo "CORE_REF: $CORE_REF"
if ! printf '%s' "$CORE_REF" | grep -Eq '^[0-9a-f]{40}$'; then
  echo "ci/pins.sh: CORE_REF must be a full commit id. A tag or a branch name could build twice and ship two different cores." >&2
  exit 1
fi

echo "== Analyze"
flutter analyze --fatal-infos --fatal-warnings

# The project's own source must be clean. The rules are proven to actually fire by the fixture suite in the `test`
# check: a plugin that failed to load would report nothing here and look like a pass.
echo "== Layering rules"
dart run custom_lint

# The page viewer's browser engine is a vendored, patched webview_cef (third_party/webview_cef/FORK.md): upstream ran
# Chromium with web security and the sandbox off (NFR-12). This fails when the vendored copy differs from the upstream
# release in any file FORK.md does not list, or a patched file lacks its fork notice, so a change to the fork is always a
# recorded one.
echo "== Vendored webview_cef matches its recorded patches"
sh tools/check-webview-cef-fork.sh

# The fork's navigation, subresource, switch and sandbox rules, as plain C++ without a browser. The engine itself is
# exercised by the integration suite's saved-page test.
echo "== Vendored webview_cef policy tests"
sh third_party/webview_cef/test/native/run.sh
