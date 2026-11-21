#!/bin/sh
# Alexandria fork of webview_cef 0.6.2: added file (see FORK.md).
#
# Tests the checks third/download.cmake makes on the CEF distribution it
# downloads and unpacks, with CMake in script mode against local files: no
# network, no CEF. Writes only to a temporary directory under $TMPDIR.
# CMAKE names the cmake to run (default: cmake on PATH).
set -eu
here=$(cd "$(dirname "$0")" && pwd)
download="$here/../../third/download.cmake"
cmake=${CMAKE:-cmake}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
failures=0

check() {
  _what=$1
  shift
  if "$@"; then
    printf 'ok   %s\n' "$_what"
  else
    printf 'FAIL %s\n' "$_what"
    sed 's/^/     /' "$work/out"
    failures=$((failures + 1))
  fi
}

# run BEFORE AFTER — runs a script of the CMake lines BEFORE, download.cmake,
# then AFTER, with its output in $work/out; answers whether it succeeded.
# Retries do not wait.
run() {
  printf '%s\ninclude("%s")\nset(cef_download_retry_seconds 0)\n%s\n' \
    "$1" "$download" "$2" > "$work/case.cmake"
  "$cmake" -P "$work/case.cmake" > "$work/out" 2>&1
}

said() { grep -qF "$1" "$work/out"; }

# The "archive" served: what the CDN's SHA-1 describes. A truncated copy is
# what a dropped connection leaves.
printf 'the whole archive\n' > "$work/archive"
head -c 5 "$work/archive" > "$work/truncated"
sha1=$("$cmake" -E sha1sum "$work/archive" | cut -d' ' -f1)

download_ok() {
  run '' "download_file(\"file://$work/archive\" \"$work/got\" $sha1)" &&
    cmp -s "$work/archive" "$work/got"
}
check "a download with the published SHA-1 is kept" download_ok

download_truncated() {
  ! run '' "download_file(\"file://$work/truncated\" \"$work/cut\" $sha1)" &&
    said 'Could not download' && said 'attempt 3 of 3' && test ! -e "$work/cut"
}
check "a truncated download is retried, then stops the build and is deleted" download_truncated

download_missing() {
  ! run '' "download_file(\"file://$work/absent\" \"$work/none\" $sha1)" &&
    said 'Could not download' && test ! -e "$work/none"
}
check "a download that fails stops the build" download_missing

mkdir "$work/tree"
printf 'v\n' > "$work/tree/version-of-something"
(cd "$work" && "$cmake" -E tar cjf good.tar.bz2 tree)
extract_ok() {
  run '' "extract_file(\"$work/good.tar.bz2\" \"$work/unpacked\")" &&
    test -f "$work/unpacked/version-of-something"
}
check "an archive unpacks into the folder" extract_ok

printf 'not bzip2 at all\n' > "$work/broken.tar.bz2"
extract_broken() {
  ! run '' "extract_file(\"$work/broken.tar.bz2\" \"$work/nothing\")" &&
    said 'Could not unpack'
}
check "an archive that cannot be unpacked stops the build" extract_broken

# Every archive the script can choose has a published SHA-1 to check against.
# The ${...} below are CMake's, for CMake to expand.
# shellcheck disable=SC2016
has_sha1() {
  run "set(CMAKE_SYSTEM_NAME $1)
set(CMAKE_SYSTEM_PROCESSOR $2)
set(CMAKE_HOST_SYSTEM_PROCESSOR $2)" \
    'if(NOT cef_prebuilt_sha1 MATCHES "^[0-9a-f]+$")
  message(FATAL_ERROR "no SHA-1 for ${cef_prebuilt_version}")
endif()
string(LENGTH "${cef_prebuilt_sha1}" length)
if(NOT length EQUAL 40)
  message(FATAL_ERROR "not a SHA-1 for ${cef_prebuilt_version}: ${cef_prebuilt_sha1}")
endif()'
}
check "the Linux x64 archive has a SHA-1" has_sha1 Linux x86_64
check "the Linux arm64 archive has a SHA-1" has_sha1 Linux aarch64
check "the Windows archive has a SHA-1" has_sha1 Windows AMD64
check "the macOS arm64 archive has a SHA-1" has_sha1 Darwin arm64
check "the macOS x64 archive has a SHA-1" has_sha1 Darwin x86_64

if [ "$failures" -gt 0 ]; then
  printf '%s check(s) failed\n' "$failures"
  exit 1
fi
printf 'all download checks passed\n'
