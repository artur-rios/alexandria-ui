# shellcheck shell=bash
# Puts the pinned Flutter SDK on PATH. Sourced by the other scripts under ci/, not run.
#
# The workflows used subosito/flutter-action with FLUTTER_VERSION, which does not exist as an image: the SDK is fetched
# here from Flutter's release archive and checked against the checksum in ci/pins.sh (an Ubuntu image with the tools
# Flutter needs, which ci/apt-packages.sh installs when they are missing). Needs ci/pins.sh's FLUTTER_VERSION and
# FLUTTER_SHA256.
#
# FLUTTER_SDK_DIR reuses an unpacked SDK between runs (default: a directory under $TMPDIR).

# shellcheck source=ci/pins.sh
. ci/pins.sh
# shellcheck source=ci/apt-packages.sh
. ci/apt-packages.sh

# What `flutter` itself needs; the desktop and test packages are each script's own.
ensure_packages ca-certificates curl git unzip xz-utils zip

FLUTTER_SDK_DIR=${FLUTTER_SDK_DIR:-${TMPDIR:-/tmp}/flutter-$FLUTTER_VERSION}

if [ ! -x "$FLUTTER_SDK_DIR/bin/flutter" ]; then
  _flutter_work=$(mktemp -d)
  echo "ci/flutter-env.sh: fetching Flutter $FLUTTER_VERSION"
  curl --fail --silent --show-error --location --retry 3 -o "$_flutter_work/flutter.tar.xz" \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  echo "$FLUTTER_SHA256  $_flutter_work/flutter.tar.xz" | sha256sum -c -
  # --no-same-owner: as root, tar would keep the archive's uid, and git then refuses the SDK as "dubious ownership".
  tar -xJf "$_flutter_work/flutter.tar.xz" --no-same-owner -C "$_flutter_work"
  mkdir -p "$(dirname "$FLUTTER_SDK_DIR")"
  rm -rf "$FLUTTER_SDK_DIR"
  mv "$_flutter_work/flutter" "$FLUTTER_SDK_DIR"
  rm -rf "$_flutter_work"
  unset _flutter_work
fi

export FLUTTER_ROOT=$FLUTTER_SDK_DIR
export FLUTTER_HOME=$FLUTTER_SDK_DIR
export PATH="$FLUTTER_SDK_DIR/bin:$FLUTTER_SDK_DIR/bin/cache/dart-sdk/bin:$PATH"
export CI=true

flutter config --no-analytics --no-cli-animations >/dev/null
dart --disable-analytics >/dev/null
flutter --version
