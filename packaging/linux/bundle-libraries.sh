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
# Usage: bundle-libraries.sh <bundle-to-scan> <output-directory>
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

SCAN=${1:-}
LIB_DIR=${2:-}
[ -n "$SCAN" ] && [ -n "$LIB_DIR" ] || {
  echo "usage: $0 <bundle-to-scan> <output-directory>" >&2
  exit 2
}
[ -d "$SCAN" ] || { echo "error: no such directory: $SCAN" >&2; exit 1; }
[ -d "$LIB_DIR" ] || { echo "error: no such directory: $LIB_DIR" >&2; exit 1; }

LICENSE_DIR="$LIB_DIR/licenses"
CORE="$LIB_DIR/libalexandria_ffi.so"

[ -f "$CORE" ] || { echo "error: the core is not in $LIB_DIR — put it there first" >&2; exit 1; }
[ -x "$SCAN/alexandria" ] || { echo "error: no executable in $SCAN" >&2; exit 1; }

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
libasound libpulse
libselinux libudev libsystemd libcap
"

# The exact-match half of the same decision, kept in a file because it is long,
# largely vendored, and worth reviewing as a list rather than as shell. See
# host-libraries.txt for where it comes from.
HOST_LIST="$(dirname "$0")/host-libraries.txt"
[ -f "$HOST_LIST" ] || { echo "error: $HOST_LIST is missing" >&2; exit 1; }

# Bundled even though the vendored list says otherwise.
#
# The excludelist assumes JACK is part of the base system. It is not: a desktop
# that has never installed a JACK server has no libjack.so.0, mpv links it
# whether or not anyone uses it, and the program then fails to start rather
# than falling back to another audio output. The client library is LGPL, so
# carrying it raises nothing the rest of the bundle does not already raise.
FORCE_BUNDLE="libjack."

# Libraries whose copyleft licensing is not in question. Named deliberately and
# kept short: this is a list of things somebody checked, not the output of a
# guess. Anything else in the bundle still needs a person to look at it, which
# is what licenses/PACKAGES.txt is for.
KNOWN_COPYLEFT="libx264. libx265. libmpv. libpostproc. libxvidcore."

is_denied() {
  _soname=$1

  for _prefix in $FORCE_BUNDLE; do
    case $_soname in
      "$_prefix"*) return 1 ;;
    esac
  done

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

# Seed the walk with everything the bundle links: the executable and every
# shared object beside it, the core included.
#
# Seeding from the core alone was not enough, and the gap was invisible on a
# build machine, which has everything installed already.
# libmedia_kit_video_plugin.so links libmpv, and nothing bundled it — and
# because Flutter links its plugins into the executable, the result was not a
# program that failed to play video but one that failed to start at all.
#
# Anything the bundle needs is in scope here. What gets left to the host is
# decided by DENY and host-libraries.txt, which is where that judgement
# belongs, rather than by which binary the walk happened to start from.
for _binary in "$SCAN/alexandria" "$SCAN"/lib/*.so*; do
  [ -e "$_binary" ] || continue
  direct_dependencies "$_binary" >> "$QUEUE"
done

if [ ! -s "$QUEUE" ]; then
  echo "error: the bundle appears to link nothing at all, which cannot be right" >&2
  exit 1
fi

echo "Seeded from the executable and $(ls "$SCAN"/lib/*.so* 2> /dev/null | wc -l) libraries beside it."
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

  # Already present: something Flutter shipped in the bundle, the core, or a
  # library an earlier iteration already placed.
  if [ -e "$SCAN/lib/$soname" ] || [ -e "$LIB_DIR/$soname" ]; then
    echo "  have   $soname"
  else
    cp -L "$path" "$LIB_DIR/$soname"
    chmod 644 "$LIB_DIR/$soname"
    # The path it came from is recorded alongside the name, because the copy
    # is the one thing dpkg cannot identify: asking it about a file under this
    # directory matches no package, which is how licence collection came to
    # resolve nothing at all while reporting success.
    printf '%s\t%s\n' "$soname" "$path" >> "$BUNDLED"
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
while IFS= read -r entry; do
  soname=$(printf '%s' "$entry" | cut -f1)
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
: > "$WORK/copyleft"
while IFS= read -r entry; do
  soname=$(printf '%s' "$entry" | cut -f1)
  origin=$(printf '%s' "$entry" | cut -f2)

  # The system path, not our copy of it.
  package=$(dpkg-query -S "$(readlink -f "$origin")" 2> /dev/null | cut -d: -f1) || continue
  [ -n "$package" ] || {
    echo "  $soname: no owning package (not from a .deb?)" >&2
    continue
  }
  grep -qxF "$package" "$WORK/packages" && continue
  echo "$package" >> "$WORK/packages"

  copyright="/usr/share/doc/$package/copyright"
  if [ -f "$copyright" ]; then
    cp "$copyright" "$LICENSE_DIR/${package}.txt"
    echo "  $package"

    # Known-copyleft libraries are named, not inferred.
    #
    # An earlier version of this tried to classify by reading the License:
    # fields of each Debian copyright file. It was wrong in both directions:
    # it flagged libpng, libffi, zstd, lz4 and bz2, none of which are GPL,
    # because their copyright files carry a GPL stanza for packaging or a dual
    # licence — and it cleared libx264, libx265 and libmpv, which are, because
    # theirs mention LGPL somewhere. Reading a Debian copyright file properly
    # is not something this script can do, so it no longer pretends to.
    #
    # What it can do is name the ones whose copyleft status is not in doubt,
    # and hand over the full list for a person to review.
    for _known in $KNOWN_COPYLEFT; do
      case $soname in
        "$_known"*) printf '%s	%s
' "$soname" "$package" >> "$WORK/copyleft" ;;
      esac
    done
  else
    echo "  $package (no copyright file found)" >&2
  fi
done < "$BUNDLED"

echo

# A licence step that resolves nothing and says nothing is worse than none at
# all: it reported "no bundled library declares GPL" while having examined
# zero of them, and it shipped bundles with no licence texts while LGPL
# requires them. Silence here is now a failure.
collected=$(ls -1 "$LICENSE_DIR" 2> /dev/null | grep -c '[.]txt$' || true)
bundled=$(wc -l < "$BUNDLED")
if [ "$bundled" -gt 0 ] && [ "$collected" -eq 0 ]; then
  echo "::error::$bundled libraries were bundled and not one licence was collected" >&2
  exit 1
fi
echo "Collected $collected licence files for $bundled bundled libraries."

echo
sort -u "$WORK/packages" > "$LICENSE_DIR/PACKAGES.txt"
echo "Every bundled library's package is listed in licenses/PACKAGES.txt."

if [ -s "$WORK/copyleft" ]; then
  sort -u "$WORK/copyleft" > "$LICENSE_DIR/COPYLEFT.tsv"
  echo "::warning::the bundle carries $(sort -u "$WORK/copyleft" | wc -l) libraries known to be copyleft"
  echo
  echo "Known-copyleft libraries in this bundle:"
  sort -u "$WORK/copyleft" | sed 's/^/  /'
  echo
  echo "Distributing these alongside the application carries their obligations."
  echo "This list is what is known, not what was proven: the other packages in"
  echo "PACKAGES.txt have not been classified by anything here."
fi

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
