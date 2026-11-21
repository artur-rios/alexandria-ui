#!/bin/sh
# Tests packaging/linux/install.sh without root, a release build, or anything
# installed: it builds small installers from the real head and a fake bundle,
# runs them into a temporary home, and checks what a replacement leaves.
#
# What it pins above all is staging (update-check design §3 step 4): a
# replacement whose payload cannot be unpacked leaves the old installation
# exactly as it was, so a failed update never leaves the owner without the
# application. Run from the repository root: sh packaging/linux/test-install.sh
set -eu

here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT INT TERM

export HOME="$work/home"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
mkdir -p "$HOME"
prefix="$work/My Apps/alexandria"
failures=0

# Where the installer records what it wrote: the system folder as root (which is
# how the analyze check's container runs), the user's state folder otherwise.
if [ "$(id -u)" -eq 0 ]; then
  manifest=/var/lib/alexandria/install.manifest
else
  manifest="$XDG_STATE_HOME/alexandria/install.manifest"
fi

check() {
  _what=$1
  shift
  if "$@"; then
    printf 'ok   %s\n' "$_what"
  else
    printf 'FAIL %s\n' "$_what"
    failures=$((failures + 1))
  fi
}

# build VERSION [truncate] — an installer for a fake bundle of VERSION; with
# "truncate", one whose payload is cut short.
build() {
  _version=$1
  _bundle="$work/bundle-$_version"
  rm -rf "$_bundle"
  mkdir -p "$_bundle/lib" "$_bundle/data"
  printf '#!/bin/sh\necho %s\n' "$_version" > "$_bundle/alexandria"
  head -c 200000 /dev/urandom > "$_bundle/lib/libalexandria_ffi.so"
  printf 'data %s\n' "$_version" > "$_bundle/data/version.txt"
  printf '[Desktop Entry]\nType=Application\nName=Alexandria\nExec=alexandria\n' \
    > "$_bundle/io.github.artur_rios.Alexandria.desktop"
  tar czf "$work/payload-$_version.tar.gz" -C "$_bundle" .

  _installer="$work/installer-$_version${2:+-$2}.sh"
  sed "s/@VERSION@/$_version/" "$here/install.sh" > "$_installer"
  if [ "${2:-}" = truncate ]; then
    _size=$(wc -c < "$work/payload-$_version.tar.gz")
    head -c $((_size / 2)) "$work/payload-$_version.tar.gz" >> "$_installer"
  else
    cat "$work/payload-$_version.tar.gz" >> "$_installer"
  fi
  printf '%s' "$_installer"
}

no_staging() {
  [ ! -e "$prefix/.staging-update" ] && [ ! -e "$prefix/.backup-update" ]
}

v1=$(build 1.0.0)
v2=$(build 2.0.0)
broken=$(build 3.0.0 truncate)

sh "$v1" --yes --prefix "$prefix" > /dev/null
check "a fresh install places the executable" \
  test "$("$prefix/alexandria")" = 1.0.0

echo "not ours" > "$prefix/unrelated.txt"

sh "$v2" --yes --prefix "$prefix" > /dev/null
check "a replacement installs the new version" \
  test "$("$prefix/alexandria")" = 2.0.0
check "a replacement keeps a file it did not write" \
  test -f "$prefix/unrelated.txt"
check "a replacement leaves no staging behind" \
  no_staging
check "a replacement records the new version" \
  grep -q '^version=2.0.0$' "$manifest"

if sh "$broken" --yes --prefix "$prefix" > "$work/broken.log" 2>&1; then
  check "a payload that cannot be unpacked fails the install" false
else
  check "a payload that cannot be unpacked fails the install" true
fi
check "a failed replacement keeps the old version runnable" \
  test "$("$prefix/alexandria")" = 2.0.0
check "a failed replacement keeps the old libraries" \
  test -s "$prefix/lib/libalexandria_ffi.so"
check "a failed replacement keeps the old data" \
  grep -q 'data 2.0.0' "$prefix/data/version.txt"
check "a failed replacement leaves no staging behind" \
  no_staging
check "a failed replacement keeps the old manifest" \
  grep -q '^version=2.0.0$' "$manifest"

sh "$v2" --uninstall --yes > /dev/null
check "uninstall removes what was installed" test ! -e "$prefix/alexandria"
check "uninstall keeps a file it did not write" test -f "$prefix/unrelated.txt"

if [ "$failures" -gt 0 ]; then
  printf '%s check(s) failed\n' "$failures"
  exit 1
fi
printf 'all install checks passed\n'
