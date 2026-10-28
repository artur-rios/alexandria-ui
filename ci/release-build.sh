#!/usr/bin/env bash
# The release files (`release.build` in yggdrasil.yml), run on the release agent from the checkout of the release's tag:
# the Linux job of the old release.yml, step for step. The Windows packages are the release-windows.yml workflow.
# Everything lands flat in dist/, named with the version:
#
#   dist/alexandria-<version>-linux-x64.tar.gz           the portable archive
#   dist/alexandria-installer-<version>-linux-x64.sh     the self-extracting installer
#   dist/alexandria-<version>-linux-x86_64.AppImage
#   dist/alexandria_ui-<version>+1-linux.deb             (flutter_distributor's name)
#   dist/alexandria-<version>.flatpak
#   dist/alexandria-<version>-downloads.md               which file to download, and the licence notice
#
# RELEASE_VERSION is the tag without its v (set by the pipeline; 0.0.0 when this is run by hand). The release itself, its
# notes (the changelog's section) and the upload are the pipeline's: the old job's "GitHub Release" step is gone.
#
# Everything is installed with apt as root, which is how the release agent runs this (it replaces the old job's `sudo`).
#
# HOW EACH PACKAGE GETS FFMPEG.
#
# The core links ffmpeg, so libavcodec, libavdevice, libavfilter, libavformat, libavutil, libswresample, and libswscale
# have to be there wherever it runs. The five packages do not get one answer, because they are not one kind of thing:
#
#   .deb       depends on the distribution's packages, which is the entire point of a .deb. Targets Ubuntu 24.04, since
#              the soname is part of each package's name and moves between releases. Verified by installing the built
#              package, so the names are checked against a real apt rather than trusted.
#
#   Flatpak    mounts org.freedesktop.Platform.ffmpeg-full. The base runtime ships ffmpeg without H.264, H.265, or AAC,
#              which for a personal media library means the common case does not play.
#
#   AppImage   carries its own, along with the tarball and the installer. None of the three has anything to ask:
#   tarball    "portable" that runs only where ffmpeg is already installed is not portable.
#   installer  packaging/linux/bundle-libraries.sh walks the dependency graph and copies the closure, leaving glibc, the
#              graphics stack, and the sound daemons to the host.
#
# The two answers are mutually exclusive per package (a bundled copy inside the .deb would shadow the system's and then go
# unpatched), which is why the .deb is built and the Flatpak's source set aside BEFORE the bundling step, and everything
# else after it.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
root=$PWD

# The pipeline always sets RELEASE_VERSION (with RELEASE_TAG). Under CI (CI is set, or a tag is) a missing one is an error, not a
# 0.0.0 release; by hand it defaults to 0.0.0. Checked before ci/flutter-env.sh, which exports CI itself.
if { [ -n "${CI:-}" ] || [ -n "${RELEASE_TAG:-}" ]; } && [ -z "${RELEASE_VERSION:-}" ]; then
  echo "ci/release-build.sh: RELEASE_VERSION is not set; the release build needs the version of the tag" >&2
  exit 1
fi

# shellcheck source=ci/flutter-env.sh
. ci/flutter-env.sh
# shellcheck source=ci/core.sh
. ci/core.sh

# The packaging tools, pinned. The checksum next to a version moves with it.
# renovate: datasource=github-releases depName=AppImage/appimagetool
APPIMAGETOOL_VERSION=1.9.1
APPIMAGETOOL_SHA256=ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0
# renovate: datasource=github-releases depName=AppImage/type2-runtime
APPIMAGE_RUNTIME_VERSION=20251108
APPIMAGE_RUNTIME_SHA256=2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d
# renovate: datasource=dart depName=flutter_distributor
FLUTTER_DISTRIBUTOR_VERSION=0.6.10

version=${RELEASE_VERSION:-0.0.0}

# The MSIX packager accepts only a numeric dotted version (the Windows build resolves the same way), and the packages here
# are named with it. Checked first, so a bad version fails in seconds rather than after the packages are built.
if ! printf '%s' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "ci/release-build.sh: the version must be three numbers, such as 1.2.3 (RELEASE_VERSION), got: $version" >&2
  exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "ci/release-build.sh: this installs system packages and a Flatpak runtime, and the release agent runs it as root; this is not root" >&2
  exit 1
fi

# Output of an earlier run goes first. native/linux is an input to the build, and the ffmpeg libraries a previous run bundled
# into it would end up in the .deb, which must not carry them. (A fresh checkout has none of these.)
rm -rf dist stage packaging/linux/bundle native/linux
mkdir dist

echo "== Build the Alexandria core"
# Ubuntu's libav* are GPL-enabled builds (libavcodec links x264, x265 and xvid, and libpostproc is GPL), which is why the
# bundled licences name them as copyleft and a Linux package that carries them is a combined work under the GPL.
# libavcodec-extra adds still more and is not needed here.
build_core

echo "== Install the packaging toolchain"
# apparmor: apparmor_parser, which checks the profiles the .deb and the installer write.
ensure_packages clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libmpv-dev mpv libnss3 libnspr4 \
  flatpak appstream libfuse2t64 fakeroot patchelf apparmor squashfs-tools file
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --system -y flathub org.freedesktop.Platform//24.08 org.freedesktop.Sdk//24.08

# flutter_distributor's AppImage maker shells out to `appimagetool` and does not supply it (the first tagged run failed
# with a bare "appimagetool: not found" after the .deb had already been built).
#
# Unpacked rather than run as an AppImage. Mounting one needs FUSE, which a runner may or may not give a process, and
# `--appimage-extract` sidesteps that entirely: what ends up on PATH is a plain wrapper around the extracted AppRun.
echo "== Install appimagetool $APPIMAGETOOL_VERSION"
tools=$(mktemp -d)
curl --fail --silent --show-error --location --retry 3 -o "$tools/appimagetool.AppImage" \
  "https://github.com/AppImage/appimagetool/releases/download/${APPIMAGETOOL_VERSION}/appimagetool-x86_64.AppImage"
echo "$APPIMAGETOOL_SHA256  $tools/appimagetool.AppImage" | sha256sum -c -
chmod +x "$tools/appimagetool.AppImage"
(cd "$tools" && ./appimagetool.AppImage --appimage-extract >/dev/null)
rm -rf /opt/appimagetool
mv "$tools/squashfs-root" /opt/appimagetool
# ARCH is defaulted in the wrapper rather than exported into the job: appimagetool refuses to guess the architecture, and
# flutter_distributor invokes it through /bin/sh with an environment this script does not control.
cat > /usr/local/bin/appimagetool <<'WRAPPER'
#!/bin/sh
exec env ARCH="${ARCH:-x86_64}" /opt/appimagetool/AppRun "$@"
WRAPPER
chmod +x /usr/local/bin/appimagetool
# The runtime appimagetool embeds in an AppImage, which it would otherwise download from the "continuous" release at build
# time, unpinned and unchecked. packaging/linux/build-appimage.sh passes it on.
curl --fail --silent --show-error --location --retry 3 -o /opt/appimagetool/runtime-x86_64 \
  "https://github.com/AppImage/type2-runtime/releases/download/${APPIMAGE_RUNTIME_VERSION}/runtime-x86_64"
echo "$APPIMAGE_RUNTIME_SHA256  /opt/appimagetool/runtime-x86_64" | sha256sum -c -
export APPIMAGE_RUNTIME_FILE=/opt/appimagetool/runtime-x86_64
rm -rf "$tools"
# Proves the wrapper actually executes, here rather than four steps later inside a packaging tool's stack trace.
appimagetool --help >/dev/null

flutter pub get

# Every package downstream takes its version from the pubspec rather than from the tag: flutter_distributor names the .deb
# and the AppImage from it, and the application reports it as its own version. Left alone, a v0.0.1 release would carry a
# file called alexandria-1.0.0+1-linux.deb and an application that called itself 1.0.0. Stamped here so the tag is the one
# source of that number.
#
# The working copy only: nothing is committed. The pubspec in git keeps the version the project develops against. The
# build number after the + was GitHub's run number; the checkout has none to take, so it is 1.
echo "== Stamp the version into the pubspec"
sed -i "s/^version: .*/version: ${version}+${RELEASE_BUILD_NUMBER:-1}/" pubspec.yaml
grep '^version:' pubspec.yaml

# Into native/linux, before the build, rather than into the bundle after it. linux/CMakeLists.txt installs this directory
# into the bundle, and every `flutter build linux` wipes and reassembles that bundle, so a copy made afterwards lasts only
# until the next build. flutter_distributor runs a build per package, which is how the v0.0.1 .deb, AppImage, and Flatpak
# all shipped without the core in them.
echo "== Stage the core for the build"
mkdir -p native/linux
cp "${CORE_DIR:-core}/target/release/libalexandria_ffi.so" native/linux/

echo "== flutter build linux"
flutter build linux --release

echo "== Verify the build produced a complete bundle"
test -f build/linux/x64/release/bundle/lib/libalexandria_ffi.so || {
  echo "the build did not install the core into the bundle" >&2
  exit 1
}
echo "The core is in the bundle, installed by the build itself."

# Chromium ships unstripped: `libcef.so` alone is 1.3 GB of library and symbols, and every Linux package here would carry
# all of it. Stripped, the whole bundle is about 390 MB rather than 1.5 GB.
#
# Both copies, and this is the part worth reading twice. The plugin's own downloaded copy is stripped as well as the built
# bundle's, because every later `flutter build linux` reassembles the bundle from that copy, and flutter_distributor runs
# a build of its own for the .deb. Strip only the bundle and the .deb ships the unstripped engine anyway.
echo "== Strip the page engine"
sh packaging/linux/strip-engine.sh \
  build/linux/x64/release/bundle/lib \
  linux/flutter/ephemeral/.plugin_symlinks/webview_cef/third/cef/Release

# Records what the core needs at runtime, so a package that cannot load it is diagnosable from the build log rather than
# only from a user's machine. Deliberately not a gate: every library resolves here because this machine installed them to
# build the core, so passing would say nothing about the machine the package lands on.
echo "== Report the core's runtime dependencies"
echo "Libraries libalexandria_ffi.so needs at runtime:"
ldd build/linux/x64/release/bundle/lib/libalexandria_ffi.so | grep -E "libav|libsw" || true

# ORDER MATTERS BELOW (see the note at the top). All five packages are built from build/linux/x64/release/bundle. So the
# two that must not contain ffmpeg are built first, from the pristine bundle, and only then is ffmpeg bundled into it for
# the three that must.

echo "== Build the .deb"
# Debian's Installed-Size is in kilobytes, measured here rather than maintained by hand in the config where it would be
# wrong from the first build that changed the bundle's size.
size=$(du -sk build/linux/x64/release/bundle | cut -f1)
sed -i "s/^installed_size: .*/installed_size: ${size}/" linux/packaging/deb/make_config.yaml
grep '^installed_size:' linux/packaging/deb/make_config.yaml

dart pub global activate flutter_distributor "$FLUTTER_DISTRIBUTOR_VERSION"
export PATH="${PUB_CACHE:-$HOME/.pub-cache}/bin:$PATH"
flutter_distributor package --platform linux --targets deb --skip-clean

# Installing it is the only honest test of a dependency list: dpkg-deb will happily build a package naming libraries that
# do not exist, and the failure would surface on somebody's machine at install time. apt resolves the names here instead.
# This machine is 24.04, which is the release the Depends list targets.
echo "== Verify the .deb installs and carries the core"
package=$(find dist -name '*.deb' -print -quit)
test -n "$package"
echo "Package: $package"
dpkg-deb --info "$package" | sed -n '/Depends/p'

# Read once into a variable: `grep -q` stops at its first match and a pipe from dpkg-deb would then fail with SIGPIPE under
# pipefail.
contents=$(dpkg-deb --contents "$package")
echo "-- Contents"
grep -E 'alexandria_ffi|libav|libsw' <<<"$contents" || true

# The core must be inside. flutter_distributor re-runs `flutter build` for every target, so anything copied into the bundle
# beforehand is only still there if that rebuild left it alone, which is exactly the assumption worth checking rather than
# trusting.
grep -q 'libalexandria_ffi[.]so' <<<"$contents" || {
  echo "the .deb does not contain the core" >&2
  exit 1
}

# And ffmpeg must not be, or the bundled copy would shadow the system's and then go unpatched.
if grep -qE 'lib(av|sw)[a-z]+[.]so' <<<"$contents"; then
  echo "the .deb carries ffmpeg; it is supposed to depend on it" >&2
  exit 1
fi

apt-get install -y "./$package"
test -x /opt/alexandria/alexandria

# Installing must have left the page engine's AppArmor profile behind (make_config.yaml), in a form the parser accepts,
# and removing the package must take it away again. (Ubuntu restricts user namespaces through AppArmor, so without it
# saved pages would never reach the browser engine.)
test -f /etc/apparmor.d/alexandria || {
  echo "the .deb installed no AppArmor profile; saved pages would never reach the browser engine on Ubuntu" >&2
  exit 1
}
apparmor_parser --skip-kernel-load -T /etc/apparmor.d/alexandria

apt-get remove -y alexandria
test ! -e /etc/apparmor.d/alexandria || {
  echo "removing the .deb left its AppArmor profile behind" >&2
  exit 1
}

# Taken now, while the bundle is still pristine. The Flatpak is built at the end, by which point the directory it would
# otherwise copy has ffmpeg in it.
echo "== Set the Flatpak's source aside"
cp -r build/linux/x64/release/bundle packaging/linux/bundle

# From here on the bundle carries ffmpeg. See the script for how the dependency closure is computed and what is
# deliberately left to the host.
echo "== Bundle ffmpeg for the portable packages"
sh packaging/linux/bundle-libraries.sh build/linux/x64/release/bundle native/linux

# The step above wrote into the build's input, not its output, so the bundle does not have ffmpeg in it until a build puts
# it there. This rebuild is what every package produced from here on picks up.
echo "== Rebuild with ffmpeg in the bundle"
flutter build linux --release
ls build/linux/x64/release/bundle/lib/libavcodec.so.* >/dev/null || {
  echo "the rebuild did not install ffmpeg into the bundle" >&2
  exit 1
}

# Staged rather than assembled in place, so the desktop entry and the icon the installer needs do not also end up as stray
# files inside the AppImage. This directory is what the tarball, the installer, and the AppImage are all made from, so
# verifying it verifies all three.
echo "== Stage the payload"
rm -rf stage && mkdir -p dist stage
cp -r build/linux/x64/release/bundle/. stage/
cp packaging/linux/io.github.artur_rios.Alexandria.desktop stage/
cp packaging/linux/io.github.artur_rios.Alexandria.png stage/

# DT_RUNPATH is not inherited: a library's own dependencies are resolved using that library's runpath, never the
# executable's. Flutter ships its plugin libraries without one, so libmedia_kit_video_plugin.so could not see libmpv sitting
# in the very same directory, and bundling libmpv fixed nothing until this did.
#
# Done on the staged copy rather than in the bundle, because the .deb and the Flatpak were built from that bundle already
# and neither wants it: both resolve their libraries from the system, where the default search path is correct.
echo "== Make every staged library findable"
for library in stage/lib/*.so*; do
  [ -e "$library" ] || continue
  # shellcheck disable=SC2016 # $ORIGIN is the loader's, not the shell's
  patchelf --set-rpath '$ORIGIN' "$library"
done
echo "Set RUNPATH on $(find stage/lib -maxdepth 1 -name '*.so*' | wc -l) libraries."

# The claim being made is "plug and play": unpack it on a machine that has a desktop and nothing else, and it runs. So that
# is what is tested; see the script for how, and for what it does where there is no container engine.
echo "== Verify the payload runs on a machine with only a desktop"
bash ci/verify-payload.sh "$root/stage"

echo "== Build the portable archive"
ls stage/lib/libavcodec.so.* >/dev/null || {
  echo "the portable archive would ship without ffmpeg" >&2
  exit 1
}
tar czf "dist/alexandria-${version}-linux-x64.tar.gz" -C stage .

# The head is a complete shell script that ends in the payload marker; concatenating the archive onto it is the whole of
# what makes it self-extracting. The version is substituted here so the script can report it without it having to be
# passed in at run time.
echo "== Build the self-extracting installer"
installer="dist/alexandria-installer-${version}-linux-x64.sh"
sed "s/@VERSION@/${version}/" packaging/linux/install.sh > /tmp/head.sh
cat /tmp/head.sh "dist/alexandria-${version}-linux-x64.tar.gz" > "$installer"
chmod +x "$installer"
rm -f /tmp/head.sh

# An installer that cannot install is the failure this checks for, and it is cheap enough to check here rather than leave
# for whoever downloads it. Runs the three paths that matter: a fresh install, a replacement of that install, and removal.
# First as an unprivileged user, then as root (which also writes the page engine's AppArmor profile).
echo "== Smoke-test the installer"
smoke=$(mktemp -d)
chmod 755 "$smoke"
cp "$installer" "$smoke/installer.sh"
chmod 755 "$smoke/installer.sh"
id alexandria-smoke >/dev/null 2>&1 || useradd --create-home --shell /bin/sh alexandria-smoke
user_home=$(getent passwd alexandria-smoke | cut -d: -f6)
as_user() { runuser -u alexandria-smoke -- env HOME="$user_home" "$@"; }
prefix="$user_home/alexandria-smoke"

as_user "$smoke/installer.sh" --prefix "$prefix" --yes
test -x "$prefix/alexandria"
test -f "$prefix/lib/libalexandria_ffi.so"
test -f "$user_home/.local/share/icons/hicolor/512x512/apps/io.github.artur_rios.Alexandria.png"

# What the installer places must be as self-contained as what it came from, licences included.
ls "$prefix"/lib/libavcodec.so.* >/dev/null
test -f "$prefix/lib/licenses/README.txt"

# A file the installer did not write must survive the replacement below, which is the whole point of removing recorded
# paths rather than the directory.
echo "not ours" | as_user tee "$prefix/unrelated.txt" >/dev/null

as_user "$smoke/installer.sh" --prefix "$prefix" --yes
test -x "$prefix/alexandria"
test -f "$prefix/unrelated.txt"

as_user "$smoke/installer.sh" --uninstall --yes
test ! -e "$prefix/alexandria"
test -f "$prefix/unrelated.txt"

rm -rf "$prefix"

# As root it also writes the page engine's AppArmor profile, which only --uninstall may take away again.
root_prefix=/opt/alexandria-smoke
"$smoke/installer.sh" --prefix "$root_prefix" --yes
test -f /etc/apparmor.d/alexandria-install
apparmor_parser --skip-kernel-load -T /etc/apparmor.d/alexandria-install
"$smoke/installer.sh" --uninstall --yes
test ! -e /etc/apparmor.d/alexandria-install
test ! -e "$root_prefix/alexandria"
rm -rf "$smoke"
userdel --remove alexandria-smoke >/dev/null 2>&1 || true

# From the same staged payload the tarball is made from, so the two carry identical contents and whatever is verified for
# one holds for the other. See the script for why flutter_distributor's AppImage maker is not used for this.
echo "== Build the AppImage"
sh packaging/linux/build-appimage.sh stage "dist/alexandria-${version}-linux-x86_64.AppImage"

# Unpacked and inspected rather than trusted. The AppImage is assembled from the staged payload, so this also confirms that
# what was staged is what came out the other side.
echo "== Verify the AppImage carries ffmpeg"
image=$(find dist -name '*.AppImage' -print -quit)
test -n "$image"
chmod +x "$image"
extract=$(mktemp -d)
(cd "$extract" && "$root/$image" --appimage-extract >/dev/null)
found=$(find "$extract/squashfs-root" -name 'libavcodec.so.*' -print -quit)
test -n "$found" || {
  echo "the AppImage does not carry ffmpeg" >&2
  exit 1
}
echo "AppImage carries $(basename "$found")"
find "$extract/squashfs-root" -name 'libalexandria_ffi.so' -print -quit
rm -rf "$extract"

# Built from the copy set aside before the bundling step, so it carries no ffmpeg of its own: it mounts the ffmpeg-full
# extension instead, which is what the manifest's add-extensions block arranges. Not with flatpak-builder: the manifest only
# copies files, and flatpak-builder runs even that in a bubblewrap sandbox, which a container cannot create ("bwrap: Creating
# new namespace failed"). packaging/linux/build-flatpak.sh does what the manifest says with flatpak's own commands.
echo "== Build the Flatpak"
sh packaging/linux/build-flatpak.sh packaging/linux/bundle "dist/alexandria-${version}.flatpak"

# The old job's publication step wrote a body above the generated notes: which file to download and what it needs, and the
# licence notice (packaging/downloads.md, with @VERSION@ for the version). The pipeline publishes the changelog's section as
# the notes, so the text travels as a file of the release.
echo "== Write the downloads note"
sed "s/@VERSION@/${version}/g" packaging/downloads.md > "dist/alexandria-${version}-downloads.md"

# flutter_distributor nests its output under a version directory. The assets are gathered flat, by name, as the old job's
# "Collect the assets" step did.
echo "== Collect the assets"
find dist -mindepth 2 -type f \( -name '*.deb' -o -name '*.AppImage' -o -name '*.flatpak' -o -name '*.tar.gz' \) \
  -exec mv -n {} dist/ \;
find dist -mindepth 1 -type d -empty -delete
count=$(find dist -maxdepth 1 -type f | wc -l)
test "$count" -gt 0 || {
  echo "no assets were collected" >&2
  exit 1
}
echo "Publishing $count assets:"
ls -l dist
