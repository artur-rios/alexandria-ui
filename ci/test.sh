#!/usr/bin/env bash
# The `test` check: the steps of ci.yml's `test` job on its Linux leg ("Unit and widget tests (linux)"). The Windows leg
# stays on GitHub Actions. yggdrasil.yml runs it in the pinned Ubuntu image from the repository's root, and keeps
# coverage/lcov.info as the build's artifact.
#
# Both platforms run this suite because of the goldens: the shell goldens hold text, and text is the one thing a
# renderer does differently on each operating system. A golden made on one and only ever checked on the other is a
# golden nobody is checking.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# shellcheck source=ci/flutter-env.sh
. ci/flutter-env.sh

flutter pub get

# IR-11: a key present in one language and absent from the other fails the build. The parity test in test/core/l10n is
# what enforces it.
echo "== Localization parity"
flutter test test/core/l10n

echo "== Test with coverage"
flutter test --coverage

# IR-02: proven against the fixture package, so what runs here is the plugin itself rather than a reimplementation of its
# logic. Linux only: it exercises the analyzer plugin, which has no platform-dependent behaviour to catch.
echo "== Layering rules against the fixtures"
flutter test analysis_test --timeout 5x
