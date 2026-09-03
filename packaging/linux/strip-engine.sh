#!/bin/sh
# IR-16: strips the browser engine's debug symbols out of a Linux bundle.
#
# The page viewer draws saved HTML with CEF (UC-25, FR-VW-05), and the official
# CEF distribution ships its shared objects unstripped: `libcef.so` alone is
# about 1.3 GB, of which roughly 245 MB is the library and the rest is symbols
# nobody installing Alexandria can use. Unstripped, every Linux package carries
# that — a 1.5 GB tarball, a 1.5 GB .deb, a 1.5 GB AppImage — for symbols a
# debugger would need the matching Chromium source to make sense of anyway.
#
# So the engine is stripped for distribution, which is what CEF's own packaging
# guidance says to do. Linux only, and not an oversight on the other side: the
# Windows distribution keeps its debug information in separate `.pdb` files,
# which the plugin does not put beside `libcef.dll`, so a Windows package is
# already carrying the library alone. This is not a size optimisation applied to the whole
# bundle: the application's own libraries and the core keep their symbols,
# because a crash report from an owner is worth having and they cost megabytes
# rather than gigabytes.
#
# Takes every directory that holds a copy of the engine, because the release
# job has two of them and stripping one is not enough. `flutter build linux`
# wipes and reassembles the bundle from the plugin's downloaded copy of CEF,
# and the release job builds several times — flutter_distributor re-runs a
# build of its own for the .deb — so a strip applied only to a built bundle is
# undone by the next build. Stripping the plugin's copy as well is what makes
# every later build install an engine that is already stripped.
#
# Usage: strip-engine.sh <directory> [<directory> ...]

set -eu

[ $# -gt 0 ] || { echo "usage: $0 <directory> [<directory> ...]" >&2; exit 2; }

command -v strip > /dev/null 2>&1 || {
  echo "error: strip is required" >&2
  exit 1
}

# The engine's own libraries, named rather than globbed. Everything else beside
# them was built by this project or by Flutter, and is not this script's to
# touch — a glob over the directory would quietly start stripping the core the
# day somebody renames a file.
ENGINE="libcef.so libGLESv2.so libEGL.so libvk_swiftshader.so libvulkan.so.1"

total_before=0
total_after=0

for dir in "$@"; do
  [ -d "$dir" ] || { echo "error: no such directory: $dir" >&2; exit 1; }

  # libcef.so is the reason this script exists; its absence means this copy of
  # the bundle has no page engine in it, which is a broken build rather than a
  # smaller one.
  [ -f "$dir/libcef.so" ] || {
    echo "error: $dir holds no libcef.so — that build has no page engine" >&2
    exit 1
  }

  echo "$dir"
  for name in $ENGINE; do
    file="$dir/$name"
    # The optional ones: the graphics libraries travel with CEF on the
    # platforms that need them and are simply not there on the ones that do
    # not.
    [ -f "$file" ] || continue

    before=$(stat -c%s "$file")
    # --strip-unneeded, not --strip-all: it removes the symbols that are not
    # needed to relocate the library, and leaves it a working shared object.
    strip --strip-unneeded "$file"
    after=$(stat -c%s "$file")

    total_before=$((total_before + before))
    total_after=$((total_after + after))
    printf '  %-24s %6s MB -> %5s MB\n' \
      "$name" "$((before / 1048576))" "$((after / 1048576))"
  done
  echo
done

echo "The engine went from $((total_before / 1048576)) MB to $((total_after / 1048576)) MB."
