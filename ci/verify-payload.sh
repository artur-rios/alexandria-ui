#!/usr/bin/env bash
# Verifies that a Linux payload (the staged bundle: executable, core and libraries) resolves every library it links on a
# machine with only a desktop, and so is "plug and play". Run by ci/release-build.sh:
#
#     ci/verify-payload.sh <payload-directory>
#
# The claim is tested, not assumed: the runner (or the agent) installed ffmpeg, libmpv, and GTK in order to build, so
# resolving there proves nothing. The container gets GTK and the graphics stack, what packaging/linux/host-libraries.txt
# assumes is present on any machine with a desktop and drivers, and nothing else this application needs. Everything beyond
# that has to come out of the payload. The executable as well as the core are checked, because Flutter links its plugins
# into the executable: a missing libmpv there is not a program that cannot play video, it is a program that cannot start.
#
# The old workflow ran `docker run ubuntu:24.04` over the payload. The release build runs in a container of its own on the
# release agent, with no Docker engine, so:
#
#   with a Docker engine (a developer's machine)   the same `docker run`, on the pinned Ubuntu image;
#   without one                                      a bare root file system is assembled from Ubuntu's packages with apt:
#                                                    the base system, the desktop packages below and their dependencies,
#                                                    nothing else. The payload's libraries are resolved with
#                                                    `ldd` chrooted into it. The same set of packages,
#                                                    without a container.
set -euo pipefail

payload=${1:?usage: verify-payload.sh <payload-directory>}
[ -d "$payload" ] || { echo "no such directory: $payload" >&2; exit 1; }
payload=$(cd "$payload" && pwd)

# The image the docker path runs: the one yggdrasil.yml builds in.
image=$(sed -n 's/^[[:space:]]*image:[[:space:]]*\(ubuntu:[^@]*@sha256:[0-9a-f]*\).*/\1/p' yggdrasil.yml | head -1)
: "${image:=ubuntu:24.04}"

# What a machine with a desktop and drivers has: GTK, the graphics, video and sound client libraries.
desktop_packages="libgtk-3-0t64 libgl1 libegl1 libdrm2 libva2 libva-drm2 libva-x11-2 libva-wayland2 libvdpau1 libxcb-shape0 libasound2t64 libpulse0 libpipewire-0.3-0 libusb-1.0-0"

report() {
  # stdin: the ldd output of everything checked.
  tee /tmp/ldd.txt
  # ldd says "not found"; the loader called directly says "cannot open shared object file".
  if grep -Eq "not found|cannot open shared object file" /tmp/ldd.txt; then
    echo "the payload does not resolve on a machine with only a desktop" >&2
    echo "Unresolved:" >&2
    grep -E "not found|cannot open shared object file" /tmp/ldd.txt | sort -u | sed 's/^/  /' >&2
    return 1
  fi
  echo "Everything the payload needs resolves, from itself or from a plain desktop."
}

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  echo "-- Resolution inside $image with only a desktop added (docker)"
  docker run --rm -v "$payload:/payload:ro" "$image" sh -c "
    set -e
    apt-get update -qq > /dev/null
    apt-get install -y -qq $desktop_packages > /dev/null
    echo '--- executable ---'
    ldd /payload/alexandria 2>&1
    echo '--- core ---'
    ldd /payload/lib/libalexandria_ffi.so 2>&1
    echo '--- every staged library ---'
    for lib in /payload/lib/*.so*; do ldd \"\$lib\" 2>&1; done
  " | report
  exit 0
fi

[ "$(id -u)" -eq 0 ] || { echo "ci/verify-payload.sh: without a Docker engine this assembles a root file system and chroots into it, and needs root" >&2; exit 1; }

echo "-- Resolution in a bare Ubuntu root file system with only a desktop added (apt, no Docker engine)"
bare=$(mktemp -d)
trap 'rm -rf "$bare"' EXIT
empty_status=$(mktemp)

# The packages of a bare Ubuntu image: everything Essential or Priority required, which is what the base image is, then the
# desktop packages; each with its dependencies, resolved against an empty dpkg database so that apt names all of them
# (not only the ones this machine lacks).
apt-get update -qq >/dev/null
base_packages=$(apt-cache dumpavail | awk -v RS= -F'\n' '
  { essential = 0; required = 0; name = ""
    for (i = 1; i <= NF; i++) {
      if ($i ~ /^Package: /) name = substr($i, 10)
      if ($i == "Essential: yes") essential = 1
      if ($i == "Priority: required") required = 1
    }
    if (name != "" && (essential || required)) print name }' | sort -u)
# shellcheck disable=SC2086
closure=$(apt-get -o "Dir::State::status=$empty_status" -s install --no-install-recommends $base_packages $desktop_packages 2>/dev/null \
  | sed -n 's/^Inst \([^ ]*\) .*/\1/p' | sort -u)
[ -n "$closure" ] || { echo "ci/verify-payload.sh: apt resolved no packages" >&2; exit 1; }

debs=$(mktemp -d)
# shellcheck disable=SC2086
(cd "$debs" && apt-get download -qq $closure)
for deb in "$debs"/*.deb; do dpkg-deb -x "$deb" "$bare"; done
rm -rf "$debs" "$empty_status"

# The loader finds /payload as a plain copy: a chroot cannot see outside itself, and mounting needs more than root.
cp -a "$payload" "$bare/payload"

ldd_in_root=${VERIFY_PAYLOAD_LDD:-/usr/bin/ldd}   # overridable only to test that a broken ldd fails the check

# ldd (libc-bin, in the bare root) lists every library of a file, found or not. It must also have worked: its exit status is
# kept for each file, its listing must contain libc.so.6 (everything dynamic links it, so a listing without it is a broken
# loader or chroot, not a payload), and every line must be one ldd prints for a library, the loader or the vdso.
failures=0
resolve() {
  local file=$1 out rc=0 line
  out=$(chroot "$bare" "$ldd_in_root" "$file" 2>&1) || rc=$?
  printf '%s\n' "$out"
  if [ "$rc" -ne 0 ]; then
    echo "ci/verify-payload.sh: ldd exited $rc for $file" >&2
    failures=1
  fi
  if ! grep -q 'libc\.so\.6 =>' <<<"$out"; then
    echo "ci/verify-payload.sh: no 'libc.so.6 =>' line in the listing of $file; the chroot or ldd is broken" >&2
    failures=1
  fi
  while IFS= read -r line; do
    case $line in
      *"(0x"*")" | *"=> not found") ;;   # a library, the loader or the vdso; "not found" is reported below
      *)
        echo "ci/verify-payload.sh: unexpected output for $file: $line" >&2
        failures=1
        ;;
    esac
  done <<<"$out"
}

listing=$(mktemp)
{
  echo "--- executable ---"
  resolve /payload/alexandria
  echo "--- core ---"
  resolve /payload/lib/libalexandria_ffi.so
  echo "--- every staged library ---"
  for library in "$payload"/lib/*.so*; do
    [ -e "$library" ] || continue
    resolve "/payload/lib/$(basename "$library")"
  done
} > "$listing"
report < "$listing" || failures=1
rm -f "$listing"
[ "$failures" -eq 0 ]
