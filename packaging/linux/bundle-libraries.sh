#!/bin/sh
# IR-16: bundles ffmpeg, and everything ffmpeg needs, into a Linux bundle.
#
# The core links ffmpeg. The Windows packages carry the DLLs beside the
# executable; on Linux only the packages that go through a package manager can
# ask the system for them. The portable tarball, the self-extracting installer,
# and the AppImage cannot — "portable" that only runs where ffmpeg is already
# installed is not portable — so they carry their own copies, put there by this
# script.
#
# Deliberately NOT run before the .deb or the Flatpak are built. The .deb
# declares the distribution's ffmpeg packages as Depends and the Flatpak gets
# them from its runtime extension; either one carrying a second copy as well
# would be dead weight that shadows the system's. The release workflow builds
# those two from a pristine bundle and only then calls this.
#
# Usage: bundle-libraries.sh <native-directory>
#
# The directory is native/linux, not the built bundle. The bundle is wiped and
# reassembled by every `flutter build linux` — see the install rules in
# linux/CMakeLists.txt — so anything written into it directly survives only
# until the next build, which is exactly how the v0.0.1 .deb, AppImage, and
# Flatpak came to ship without the core. native/linux is an input to the build
# instead, so what this script puts there is reproduced into every bundle.
#
# What "everything ffmpeg needs" means is the interesting part. libavcodec
# alone pulls in dozens of codec libraries, and each of those pulls in more, so
# the set is computed by walking the dependency graph rather than listed. The
# walk stops at DENY below: those come from the host, always. Bundling a copy
# of glibc, of the graphics stack, or of the sound daemon's client library is
# how a bundle that works on the build machine segfaults everywhere else.

set -eu

LIB_DIR=${1:-}
[ -n "$LIB_DIR" ] || { echo "usage: $0 <native-directory>" >&2; exit 2; }
[ -d "$LIB_DIR" ] || { echo "error: no such directory: $LIB_DIR" >&2; exit 1; }

LICENSE_DIR="$LIB_DIR/licenses"
CORE="$LIB_DIR/libalexandria_ffi.so"

[ -f "$CORE" ] || { echo "error: the core is not in $LIB_DIR — put it there first" >&2; exit 1; }

for tool in ldd patchelf; do
  command -v "$tool" > /dev/null 2>&1 || { echo "error: $tool is required" >&2; exit 1; }
done

# Libraries that must come from the host, matched as prefixes against the
# soname. glibc and its siblings because a bundled copy loaded next to the
# host's dynamic loader is undefined behaviour; the graphics, display, and
# sound stacks because they have to match the drivers and daemons actually
# running on the machine. This mirrors the AppImage project's excludelist,
# which exists because every one of these has broken somebody's bundle.
DENY="
ld-linux libc. libm. libdl. libpthread. librt. libresolv. libnsl. libutil.
libcrypt. libstdc++. libgcc_s.
libGL libEGL libGLX libGLdispatch libOpenGL libglapi
libX11 libxcb libXext libXfixes libXrender libXrandr libXi libXcursor
libXinerama libXdamage libXcomposite libXau libXdmcp libxshmfence
libwayland libdrm libgbm
libva libvdpau
libglib-2.0 libgobject-2.0 libgio-2.0 libgmodule-2.0 libdbus-1
libasound libpulse libjack
libselinux libudev libsystemd libcap
"

# The exact-match half of the same decision, kept in a file because it is long,
# largely vendored, and worth reviewing as a list rather than as shell. See
# host-libraries.txt for where it comes from.
HOST_LIST="$(dirname "$0")/host-libraries.txt"
[ -f "$HOST_LIST" ] || { echo "error: $HOST_LIST is missing" >&2; exit 1; }

is_denied() {
  _soname=$1

  for _prefix in $DENY; do
    case $_soname in
      "$_prefix"*) return 0 ;;
    esac
  done

  grep -qxF "$_soname" "$HOST_CLEAN" && return 0
  return 1
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

HOST_CLEAN="$WORK/host"
sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$HOST_LIST" | grep -v '^$' > "$HOST_CLEAN"
echo "Treating $(wc -l < "$HOST_CLEAN") named libraries as host-provided, plus the categories in DENY."
echo
QUEUE="$WORK/queue"
SEEN="$WORK/seen"
BUNDLED="$WORK/bundled"
: > "$QUEUE"
: > "$SEEN"
: > "$BUNDLED"

# Resolves a binary's direct dependencies to "soname<TAB>path" lines. Entries
# without a path — statically resolved names such as linux-vdso — are dropped.
direct_dependencies() {
  ldd "$1" 2> /dev/null | awk '
    $2 == "=>" && $3 ~ /^\// { print $1 "\t" $3 }
  '
}

# Seed the walk with ffmpeg itself: whatever the core links by name.
direct_dependencies "$CORE" \
  | grep -E '^(libav|libsw)' \
  > "$QUEUE" || true

if [ ! -s "$QUEUE" ]; then
  echo "error: the core links no ffmpeg libraries — nothing to bundle, which means something is wrong" >&2
  exit 1
fi

echo "Seeded from the core's own linkage:"
cut -f1 "$QUEUE" | sed 's/^/  /'
echo

mkdir -p "$LIB_DIR" "$LICENSE_DIR"

# Breadth-first over the dependency graph. The queue is a file rather than a
# variable so the loop can append to it while reading it.
while :; do
  entry=$(head -1 "$QUEUE") || break
  [ -n "$entry" ] || break
  sed -i '1d' "$QUEUE"

  soname=$(printf '%s' "$entry" | cut -f1)
  path=$(printf '%s' "$entry" | cut -f2)

  grep -qxF "$soname" "$SEEN" && continue
  echo "$soname" >> "$SEEN"

  if is_denied "$soname"; then
    echo "  host   $soname"
    continue
  fi

  # Already in the bundle — the core itself, or something Flutter shipped.
  if [ -e "$LIB_DIR/$soname" ]; then
    echo "  have   $soname"
  else
    cp -L "$path" "$LIB_DIR/$soname"
    chmod 644 "$LIB_DIR/$soname"
    echo "$soname" >> "$BUNDLED"
    echo "  bundle $soname"
  fi

  direct_dependencies "$path" >> "$QUEUE"
done

echo

# Every bundled library has to find its siblings in the directory it now lives
# in, not in the one it was compiled against. $ORIGIN is resolved by the loader
# relative to the object doing the loading, so this is what makes the bundle
# relocatable — without it the host's ffmpeg is found first, or nothing is.
echo "Setting RUNPATH to \$ORIGIN:"
patchelf --set-rpath '$ORIGIN' "$CORE"
echo "  libalexandria_ffi.so"
while IFS= read -r soname; do
  patchelf --set-rpath '$ORIGIN' "$LIB_DIR/$soname"
  echo "  $soname"
done < "$BUNDLED"

echo

# LGPL obliges the licence texts to travel with the binaries, the same
# obligation the Windows job satisfies with FFMPEG-LICENSE.txt. Taken from the
# distribution's own copyright files so what ships describes what actually
# shipped.
echo "Collecting licences:"
: > "$WORK/packages"
while IFS= read -r soname; do
  package=$(dpkg-query -S "$(readlink -f "$LIB_DIR/$soname")" 2> /dev/null | cut -d: -f1) || continue
  [ -n "$package" ] || continue
  grep -qxF "$package" "$WORK/packages" && continue
  echo "$package" >> "$WORK/packages"

  copyright="/usr/share/doc/$package/copyright"
  if [ -f "$copyright" ]; then
    cp "$copyright" "$LICENSE_DIR/${package}.txt"
    echo "  $package"
  else
    echo "  $package (no copyright file found)" >&2
  fi
done < "$BUNDLED"

cat > "$LICENSE_DIR/README.txt" <<NOTICE
The libraries in the directory above, alongside the application, are unmodified
copies taken from Ubuntu 24.04 and are covered by the licences in this
directory.

FFmpeg is used here under the LGPL: the LGPL build, not the GPL one, linked
dynamically and unmodified. Nothing in this application re-encodes media, so
the encoders the GPL variant adds are not needed.

Replacing any of these libraries is a matter of replacing the file in the
directory above with a compatible build of the same soname.
NOTICE

echo
count=$(wc -l < "$BUNDLED")
size=$(du -sh "$LIB_DIR" | cut -f1)
echo "Bundled $count libraries. $LIB_DIR is now $size."
