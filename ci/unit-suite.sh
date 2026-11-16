#!/usr/bin/env bash
# Runs the unit and widget suite with coverage, in a few bundles rather than one entry point per file. Used by
# ci/test.sh (Linux) and by the Windows leg of .github/workflows/ci.yml:
#
#     ci/unit-suite.sh [<bundles>]        (default 4)
#
# `flutter test` compiles its entry points one after the other on a single compiler, whatever --concurrency says, so
# with one entry point per test file most of a run was compiling. This writes the suite's files into a few bundles
# under build/test-bundles/ (not committed), each file's `main` in a group named after its path so a failure still names
# its file. A bundle is compiled once and runs its share in one process, and the bundles run side by side. The files are
# shared out by size, largest first, onto the lightest bundle, so the bundles finish at about the same time.
#
# What a bundle gives up is the process per file: the files of a bundle share an isolate. Nothing in the suite may
# depend on running alone, so this is also a check that no test leaks into the next. `flutter test <file>` still runs
# one file in its own process, which is the loop for one area.
#
# Two kinds of file are not bundled, and stay entry points of their own:
# - The golden suites. A golden's path is resolved against the directory of the entry point being run, and
#   test/flutter_test_config.dart, which installs the tolerant comparator, applies only to entry points under test/.
# - The files that drive the page engine's plugin (they name its `webview_cef` channel). Its WebviewManager is a
#   process-wide singleton that remembers it was initialized and cannot be reset, so a file that starts it would leave
#   the next one unable to see a refused start.
#
# The localization parity test (IR-11) is part of the suite, and a parity failure fails the run by name.
# coverage/lcov.info is written as before.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

count=${1:-4}
directory=build/test-bundles

mapfile -t alone < <({
  find test -name '*_golden_test.dart'
  grep -rl --include='*_test.dart' webview_cef test
} | sort -u)
# Size, then path, for every file that is bundled; largest first.
mapfile -t sized < <(find test -name '*_test.dart' -exec wc -c {} + |
  awk '$2 != "total" { print $1 "\t" $2 }' |
  grep -v -F -f <(printf '\t%s\n' "${alone[@]}") |
  sort -k1,1nr -k2,2)
if [ "${#sized[@]}" -eq 0 ]; then
  echo "ci/unit-suite.sh: no test files under test/" >&2
  exit 1
fi

# Each file onto the lightest bundle so far.
declare -a weight members
for ((i = 0; i < count; i++)); do weight[i]=0; members[i]=; done
for line in "${sized[@]}"; do
  size=${line%%$'\t'*}
  file=${line#*$'\t'}
  lightest=0
  for ((i = 1; i < count; i++)); do
    if [ "${weight[i]}" -lt "${weight[lightest]}" ]; then lightest=$i; fi
  done
  weight[lightest]=$((weight[lightest] + size))
  members[lightest]+="$file"$'\n'
done

rm -rf "$directory"
mkdir -p "$directory"
entries=()
for ((i = 0; i < count; i++)); do
  [ -n "${members[i]}" ] || continue
  mapfile -t files < <(printf '%s' "${members[i]}" | sort)
  bundle="$directory/bundle_${i}_test.dart"
  {
    echo '// Written by ci/unit-suite.sh. Do not edit and do not commit.'
    echo "import 'package:flutter_test/flutter_test.dart';"
    echo
    for index in "${!files[@]}"; do
      echo "import '../../${files[index]}' as t$index;"
    done
    echo
    echo 'void main() {'
    for index in "${!files[@]}"; do
      echo "  group('${files[index]#test/}', t$index.main);"
    done
    echo '}'
  } > "$bundle"
  entries+=("$bundle")
done
entries+=("${alone[@]}")

echo "== Unit and widget suite: ${#sized[@]} files in $((${#entries[@]} - ${#alone[@]})) bundles, ${#alone[@]} on their own"
printf '   %s\n' "${entries[@]}"
flutter test --coverage --concurrency="$count" "${entries[@]}"
