#!/bin/sh
# IR-16: the AppImage, assembled here rather than by flutter_distributor.
#
# Usage: build-appimage.sh <payload-directory> <output-file>
#
# The payload is the same staged directory the portable tarball is made from,
# so the AppImage and the tarball carry identical contents — and whatever was
# verified for one holds for the other.
#
# flutter_distributor still builds the .deb, which it does correctly. Its
# AppImage maker is not used because it resolves and copies dependencies of its
# own on top of the bundle it is given, which put it in three kinds of trouble:
# the AppImage it produced was 109 MB of libraries nobody chose, its own
# concurrent copies collided with each other ("libicuuc.so.74: File exists"),
# and because it re-runs `flutter build` first, it packaged a bundle that the
# build had just cleared. Assembling the directory ourselves is about twenty
# lines and leaves nothing to discover after the fact.

set -eu

PAYLOAD=${1:-}
OUTPUT=${2:-}

[ -n "$PAYLOAD" ] && [ -n "$OUTPUT" ] || {
  echo "usage: $0 <payload-directory> <output-file>" >&2
  exit 2
}
[ -d "$PAYLOAD" ] || { echo "error: no such directory: $PAYLOAD" >&2; exit 1; }

APP_ID="io.github.artur_rios.Alexandria"
EXE_NAME="alexandria_desktop"

command -v appimagetool > /dev/null 2>&1 || {
  echo "error: appimagetool is required and was not found" >&2
  exit 1
}

[ -x "$PAYLOAD/$EXE_NAME" ] || { echo "error: no executable at $PAYLOAD/$EXE_NAME" >&2; exit 1; }
[ -f "$PAYLOAD/${APP_ID}.desktop" ] || { echo "error: the payload carries no desktop entry" >&2; exit 1; }
[ -f "$PAYLOAD/${APP_ID}.png" ] || { echo "error: the payload carries no icon" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
APPDIR="$WORK/AppDir"

mkdir -p "$APPDIR/usr/bin" \
         "$APPDIR/usr/share/applications" \
         "$APPDIR/usr/share/icons/hicolor/512x512/apps"

# The whole payload goes under usr/bin, executable and lib/ together. The
# executable's RUNPATH is $ORIGIN/lib, so keeping them adjacent is what lets it
# find the core and everything beside it without AppRun setting a search path.
cp -r "$PAYLOAD/." "$APPDIR/usr/bin/"

# appimagetool looks for all three of these at the AppDir root, and the icon's
# filename has to match the desktop entry's Icon= key.
cat > "$APPDIR/AppRun" <<'APPRUN'
#!/bin/sh
HERE=$(dirname "$(readlink -f "$0")")
exec "$HERE/usr/bin/alexandria_desktop" "$@"
APPRUN
chmod 755 "$APPDIR/AppRun"

# Exec is the bare name: inside an AppImage it is AppRun that starts the
# program, and an absolute path from the build machine would mean nothing on
# the machine it runs on.
sed "s|^Exec=.*|Exec=${EXE_NAME}|" "$PAYLOAD/${APP_ID}.desktop" \
  > "$APPDIR/${APP_ID}.desktop"
cp "$APPDIR/${APP_ID}.desktop" "$APPDIR/usr/share/applications/"

cp "$PAYLOAD/${APP_ID}.png" "$APPDIR/${APP_ID}.png"
cp "$PAYLOAD/${APP_ID}.png" "$APPDIR/usr/share/icons/hicolor/512x512/apps/"

mkdir -p "$(dirname "$OUTPUT")"

# --no-appstream because the metainfo is validated by the Flatpak build
# already, and appstreamcli's absence on a runner should not be what decides
# whether an AppImage can be produced.
ARCH=x86_64 appimagetool --no-appstream "$APPDIR" "$OUTPUT"

chmod 755 "$OUTPUT"
echo "Built $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"
