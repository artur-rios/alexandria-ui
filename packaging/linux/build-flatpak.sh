#!/bin/sh
# IR-16: the Flatpak, assembled here rather than by flatpak-builder.
#
# Usage: build-flatpak.sh <bundle-directory> <output-file>
#
# The bundle is the pristine release bundle (the one set aside before ffmpeg is bundled into the portable packages): the
# Flatpak mounts org.freedesktop.Platform.ffmpeg-full instead of carrying ffmpeg.
#
# This does what io.github.artur_rios.Alexandria.yaml says, with flatpak's own commands: build-init, a copy of the files the
# manifest's `simple` module installs, build-finish with the manifest's finish-args and extension, build-export and
# build-bundle. flatpak-builder is not used because the manifest's module only copies files, and flatpak-builder runs even
# a copy inside a bubblewrap sandbox, which needs user namespaces. The release build runs in a container whose seccomp
# profile forbids creating them ("bwrap: Creating new namespace failed: Operation not permitted"), where a copy needs none.
# On a machine that allows namespaces, `flatpak-builder` builds the manifest itself and gives the same package; keep the
# two in step.
#
# The runtime and the SDK must be installed (flatpak install flathub org.freedesktop.Platform//24.08
# org.freedesktop.Sdk//24.08).

set -eu

BUNDLE=${1:-}
OUTPUT=${2:-}

[ -n "$BUNDLE" ] && [ -n "$OUTPUT" ] || {
  echo "usage: $0 <bundle-directory> <output-file>" >&2
  exit 2
}
[ -d "$BUNDLE" ] || { echo "error: no such directory: $BUNDLE" >&2; exit 1; }
[ -x "$BUNDLE/alexandria" ] || { echo "error: no executable at $BUNDLE/alexandria" >&2; exit 1; }

HERE=$(cd "$(dirname "$0")" && pwd)
APP_ID="io.github.artur_rios.Alexandria"
RUNTIME_VERSION="24.08"
EXTENSION="org.freedesktop.Platform.ffmpeg-full"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
BUILD="$WORK/build"
REPO="$WORK/repo"

flatpak build-init "$BUILD" "$APP_ID" org.freedesktop.Sdk org.freedesktop.Platform "$RUNTIME_VERSION"

APP="$BUILD/files"

# The mount point the extension below is attached to. It must exist or there is nothing for Flatpak to mount the extension
# onto.
mkdir -p "$APP/lib/ffmpeg"
install -Dm755 "$BUNDLE/alexandria" "$APP/bin/alexandria"
cp -r "$BUNDLE/data" "$APP/bin/data"
cp -r "$BUNDLE/lib" "$APP/bin/lib"
install -Dm644 "$HERE/${APP_ID}.desktop" "$APP/share/applications/${APP_ID}.desktop"
install -Dm644 "$HERE/${APP_ID}.metainfo.xml" "$APP/share/metainfo/${APP_ID}.metainfo.xml"
# The name the desktop entry's Icon= key refers to, which only resolves if a file of that name is installed in the icon theme.
install -Dm644 "$HERE/${APP_ID}.png" "$APP/share/icons/hicolor/512x512/apps/${APP_ID}.png"

# The metainfo is validated here, as flatpak-builder would have, when the validator is installed.
if command -v appstreamcli > /dev/null 2>&1; then
  appstreamcli validate --no-net "$APP/share/metainfo/${APP_ID}.metainfo.xml"
fi

# finish-args, the extension and the command of the manifest. add-ld-path puts the extension's directory on the loader's
# search path, so the core finds these rather than the base runtime's narrower build.
flatpak build-finish "$BUILD" \
  --command=alexandria \
  --socket=wayland \
  --socket=fallback-x11 \
  --share=ipc \
  --device=dri \
  --socket=pulseaudio \
  --filesystem=home \
  "--extension=${EXTENSION}=directory=lib/ffmpeg" \
  "--extension=${EXTENSION}=version=${RUNTIME_VERSION}" \
  "--extension=${EXTENSION}=add-ld-path=." \
  "--extension=${EXTENSION}=no-autodownload=false" \
  "--extension=${EXTENSION}=autodelete=false"

# --disable-sandbox: the icon validator would otherwise run in the same bubblewrap sandbox a container cannot create. It
# reads the one icon this script installs, from the repository.
flatpak build-export --disable-sandbox "$REPO" "$BUILD"
mkdir -p "$(dirname "$OUTPUT")"
flatpak build-bundle "$REPO" "$OUTPUT" "$APP_ID"

echo "Built $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"
